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

public class ASFrameEditor: MIStack
{
        public typealias UpdatedCallback = (_ frameid: Int) -> Void

        public enum SlotValue {
                case    value(MIValue)
                case    url(URL?)
                case    event(String)
        }

        private var mFrameView:         MIStack?  = nil
        private var mButtons:           MIStack?  = nil
        private var mUpdateButton:      MIButton? = nil
        private var mCancelButton:      MIButton? = nil

        private var mFrame:             ASFrame?  = nil
        private var mSlotValues:        Dictionary<String, SlotValue>   = [:]
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

        public func set(target frame: ASFrame, updatedCallback cbfunc: @escaping UpdatedCallback) {
                mFrame             = frame
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
                                                        if str.count == 0 {
                                                                result[slot.name] = .url(nil)
                                                        } else {
                                                                result[slot.name] = .url(URL(filePath: str))
                                                        }
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
                frameview.requireDisplay()
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
                case .url(let orgval):
                        let selector = MIFileSelector()
                        selector.url = orgval
                        selector.setCallback({
                                (_ url: URL) -> Void in
                                NSLog("ASFrameEditor: field callback: (url) \(nm) \(url.path)")
                                self.mSlotValues[nm] = .url(url)
                                self.mIsModified = true
                                self.updateButtonStatus()
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
                                case .url(let urlp):
                                        if let url = urlp {
                                                field.set(value: MIValue(stringValue: url.path))
                                        } else {
                                                field.set(value: MIValue(stringValue: ""))
                                        }
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
                        case .url(let urlp):
                                if let url = urlp {
                                        frame.set(slotName: name, value: .value(MIValue(stringValue: url.path)))
                                } else {
                                        frame.set(slotName: name, value: .value(MIValue(stringValue: "")))
                                }
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


