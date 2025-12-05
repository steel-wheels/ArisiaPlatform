/**
 * @file       ASFrameEditor.swift
 * @brief      Define ASFrameEditor class
 * @par Copyright
 *   Copyright (C) 2025 Steel Wheels Project
 */

import MultiFrameKit
import MultiUIKit
import MultiDataKit
import JavaScriptCore
#if os(OSX)
import  AppKit
#else   // os(OSX)
import  UIKit
#endif  // os(OSX)

public class ASFrameEditorView: MIStack
{
        public typealias UpdatedCallback = (_ frameid: Int) -> Void

        public enum SlotValue {
                case    value(MIValue)
                case    file(String)    // relative path from package directory
                case    event(String)
        }

        private var mFrameView:         MIStack?  = nil
        private var mButtons:           MIStack?  = nil
        private var mUpdateButton:      MIButton? = nil
        private var mCancelButton:      MIButton? = nil

        private var mFrame:             ASFrame?   = nil
        private var mPackage:           ASPackage? = nil
        private var mSlotValues:        Dictionary<String, SlotValue>       = [:]
        private var mEditFields:        Dictionary<String, MIInterfaceView> = [:]

        private var mCallback:          UpdatedCallback? = nil
        private var mIsModified:        Bool = false

        open override func setup(frame frm: CGRect) {
                super.setup(frame: frm)

                let frameview = MIStack()
                self.addArrangedSubView(frameview)
                mFrameView = frameview

                let buttons = MIStack()
                buttons.axis = .horizontal
                buttons.distribution = .fillEqually
                mButtons = buttons

                let updatebtn = MIButton()
                updatebtn.title = "Update"
                updatebtn.setButtonPressedCallback({
                        [weak self] () -> Void in
                        if let myself = self {
                                myself.updateButtonPressed()
                        }
                })
                buttons.addArrangedSubView(updatebtn)
                mUpdateButton = updatebtn

                let cancelbtn = MIButton()
                cancelbtn.title = "Cancel"
                cancelbtn.setButtonPressedCallback({
                        [weak self] () -> Void in
                        if let myself = self {
                                myself.cancelButtonPressed()
                        }
                })
                buttons.addArrangedSubView(cancelbtn)
                mCancelButton = cancelbtn

                self.addArrangedSubView(buttons)
        }

        public func set(target frame: ASFrame, package pkg: ASPackage, updatedCallback cbfunc: @escaping UpdatedCallback) {
                mFrame             = frame
                mPackage           = pkg
                mSlotValues        = self.loadSlotValues(from: frame)
                mCallback          = cbfunc
                setViewContent()
        }

        private func loadSlotValues(from frame: ASFrame) ->  Dictionary<String, SlotValue> {
                var result:  Dictionary<String, SlotValue>  = [:]
                for slot in frame.slots {
                        if ASFrame.isBuiltinSlotName(name: slot.name){
                                continue
                        }
                        switch slot.value {
                        case .value(let ival):
                                switch ival .type {
                                case .nilType, .arrayType, .dictionaryType:
                                        NSLog("[Error] Not supported at \(#file)")
                                case .booleanType, .signedIntType, .unsignedIntType, .floatType:
                                        result[slot.name] = .value(ival)
                                case .stringType:
                                        switch slot.name {
                                        case "file":
                                                if let str = ival.stringValue {
                                                        result[slot.name] = .file(str)
                                                } else {
                                                        NSLog("[Error] Not supported at \(#file)")
                                                }
                                        default:
                                                result[slot.name] = .value(ival)
                                        }
                                @unknown default:
                                        NSLog("[Error] Unknown type at \(#file)")
                                }
                        case .event(let str):
                                result[slot.name] = .event(str)
                        case .frame(_), .path(_):
                                break
                        }
                }
                return result
        }

        private func setViewContent() {
                guard let frameview = mFrameView else {
                        NSLog("[Error] Can not happen at \(#function)")
                        return
                }

                frameview.removeAllSubviews()
                mEditFields = [:]

                for (name, val) in mSlotValues {
                        let subview = allocateValueField(name: name, value: val)
                        frameview.addArrangedSubView(subview)
                }

                updateButtonStatus()
        }

        private func allocateValueField(name nm: String, value sval: SlotValue) -> MIStack {
                let result = MIStack()
                result.axis = .vertical

                let label = MILabel()
                label.title = nm + ":"
                result.addArrangedSubView(label)

                switch sval {
                case .value(let orgval):
                        let field = MITextField()
                        field.set(value: orgval)
                        field.setCallback({
                                (_ newval: String) -> Void in
                                NSLog("ASFrameEditor: field callback: (value) \(nm) \(newval)")
                                self.mSlotValues[nm] = .value(MIValue(stringValue: newval))
                                self.mIsModified = true
                                self.updateButtonStatus()
                        })
                        mEditFields[nm] = field
                        result.addArrangedSubView(field)
                case .file(let orgval):
                        let selector = MIFileSelector()
                        if orgval.count > 0 {
                                selector.url = URL(filePath: orgval)
                        } else {
                                selector.url = nil
                        }
                        selector.setCallback({
                                (_ url: URL) -> Void in
                                NSLog("ASFrameEditor: field callback: (url) \(nm) \(url.path)")
                                switch self.urlToPath(at: url) {
                                case .success(let path):
                                        self.mSlotValues[nm] = .file(path)
                                        self.mIsModified = true
                                        self.updateButtonStatus()
                                case .failure(let err):
                                        NSLog("[Error] \(MIError.toString(error: err)) at \(#file)")
                                }
                        })
                        mEditFields[nm] = selector
                        result.addArrangedSubView(selector)
                case .event(let orgval):
                        let field = MITextField()
                        field.set(value: MIValue(stringValue: orgval))
                        field.setCallback({
                                (_ newval: String) -> Void in
                                NSLog("ASFrameEditor: field callback: (event) \(nm) \(newval)")
                                self.mSlotValues[nm] = .event(newval)
                                self.mIsModified = true
                                self.updateButtonStatus()
                        })
                        mEditFields[nm] = field
                        result.addArrangedSubView(field)
                }
                return result
        }

        private func urlToPath(at url: URL) -> Result<String, NSError> {
                guard let pkg = mPackage else {
                        let err = MIError.error(errorCode: .fileError,
                                                message: "No package directory",
                                                atFile: #file,
                                                function: #function)
                        return .failure(err)
                }
                return pkg.importFile(from: url)
        }

        private func updateButtonPressed() {
                guard let frame = mFrame else {
                        NSLog("[Error] No frame is defined at \(#file)")
                        return
                }
                storeSlotValues(to: frame, from: mSlotValues)
                mIsModified = false
                if let cbfunc = mCallback {
                        cbfunc(frame.frameId())
                }
        }

        private func cancelButtonPressed() {
                guard let frame = mFrame else {
                        NSLog("[Error] No frame is defined at \(#file)")
                        return
                }

                mSlotValues = self.loadSlotValues(from: frame)
                for (name, slot) in mSlotValues {
                        if let field = mEditFields[name] as? MITextField {
                                switch slot {
                                case .value(let val):
                                        field.set(value: val)
                                case .file(let path):
                                        field.set(value: MIValue(stringValue: path))
                                case .event(let estr):
                                        field.set(value: MIValue(stringValue: estr))
                                }
                        } else if let _ = mEditFields[name] as? MIFileSelector {
                                // nothing have to do
                        } else {
                                NSLog("[Error] No text field at \(#function)")
                        }
                }

                mIsModified = false

                if let view = mFrameView {
                        view.requireDisplay()
                }
        }

        private func storeSlotValues(to frame: ASFrame, from values: Dictionary<String, SlotValue>) {
                for (name, slot) in values {
                        switch slot {
                        case .value(let val):
                                frame.set(slotName: name, value: .value(val))
                        case .file(let path):
                                frame.set(slotName: name, value: .value(MIValue(stringValue: path)))
                        case .event(let estr):
                                frame.set(slotName: name, value: .event(estr))
                        }
                }
        }

        private func updateButtonStatus() {
                guard let updatebtn = mUpdateButton, let cancelbtn = mCancelButton else {
                        NSLog("[Error] No buttons are defined at \(#file)")
                        return
                }
                updatebtn.isEnabled     = mIsModified
                cancelbtn.isEnabled     = mIsModified
        }
}


