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

        private var mFrameView:         MIStack?  = nil
        private var mButtons:           MIStack?  = nil
        private var mUpdateButton:      MIButton? = nil
        private var mCancelButton:      MIButton? = nil

        private var mFrame:             ASFrame?  = nil
        private var mValues:            Dictionary<String, MIValue>     = [:]
        private var mEditFields:        Dictionary<String, MITextField> = [:]

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

        public func set(target frame: ASFrame, width wid: MIContentSize.Length, updatedCallback cbfunc: @escaping UpdatedCallback) {
                mFrame    = frame
                mValues   = load(from: frame)
                mCallback = cbfunc
                set(values: mValues, width: wid)
        }

        private func set(values vals: Dictionary<String, MIValue>,  width wid: MIContentSize.Length) {
                guard let frameview = mFrameView else {
                        NSLog("[Error] Can not happen at \(#function)")
                        return
                }

                frameview.removeAllSubviews()
                mEditFields = [:]

                for (name, val) in vals {
                        let subview = allocateValueField(name: name, value: val)
                        frameview.addArrangedSubView(subview)
                }

                if let buttons = mButtons {
                        buttons.set(contentSize: MIContentSize(width: wid,
                                                               height: .none))
                }

                updateButtonStatus()
                frameview.requireDisplay()
        }

        private func allocateValueField(name nm: String, value val: MIValue) -> MIStack {
                let result = MIStack()
                result.axis = .vertical

                let label = MILabel()
                label.title = nm + ":"
                result.addArrangedSubView(label)

                let field = MITextField()
                field.set(value: val)
                field.setCallback({
                        (_ str: String) -> Void in
                        //NSLog("ASFrameEditor: field callback: \(str)")
                        self.mValues[nm] = MIValue(stringValue: str)
                        self.mIsModified = true
                        self.updateButtonStatus()
                })
                result.addArrangedSubView(field)

                mEditFields[nm] = field

                return result
        }

        private func updateButtonPressed() {
                guard let frame = mFrame else {
                        NSLog("[Error] No frame is defined at \(#file)")
                        return
                }
                store(to: frame, from: mValues)
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
                mValues = load(from: frame)
                for (name, val) in mValues {
                        if let field = mEditFields[name] {
                                field.set(value: val)
                        }
                }
                mIsModified = false

                if let view = mFrameView {
                        view.requireDisplay()
                }
        }

        private func load(from frame: ASFrame) ->  Dictionary<String, MIValue> {
                var result:  Dictionary<String, MIValue>  = [:]
                for (name, value) in frame.slots {
                        if ASFrame.isBuiltinSlotName(name: name){
                                continue
                        }
                        switch value {
                        case .value(let ival):
                                result[name] = ival
                        case .event(_), .frame(_), .path(_):
                                break
                        }
                }
                return result
        }

        private func store(to frame: ASFrame, from values: Dictionary<String, MIValue>) {
                for (name, val) in values {
                        frame.set(slotName: name, value: .value(val))
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


