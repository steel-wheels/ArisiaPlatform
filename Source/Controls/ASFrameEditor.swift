/**
 * @file       ASFrameEditor.swift
 * @brief      Define ASFrameEditor class
 * @par Copyright
 *   Copyright (C) 2025 Steel Wheels Project
 */

import MultiFrameKit
import MultiUIKit
import JavaScriptCore
#if os(OSX)
import  AppKit
#else   // os(OSX)
import  UIKit
#endif  // os(OSX)

public class ASFrameEditor: MIStack
{
        private var mFrameView:         MIStack?  = nil
        private var mUpdateButton:      MIButton? = nil
        private var mCancelButton:      MIButton? = nil
        private var mEditFields:        Array<MITextField> = []

        private var mTargetFrame:       ASFrame?  = nil
        private var mCachedFrame:       ASFrame?  = nil

        open override func setup(frame frm: CGRect) {
                super.setup(frame: frm)

                let frameview = MIStack()
                self.addArrangedSubView(frameview)
                mFrameView = frameview

                let buttons = MIStack()
                buttons.axis = .horizontal

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

        public func set(target frame: ASFrame) {
                mTargetFrame    = frame
                mCachedFrame    = frame.clone()
                load(frame: frame)
        }

        private func load(frame frm: ASFrame){
                guard let frameview = mFrameView else {
                        NSLog("[Error] Can not happen at \(#function)")
                        return
                }
                frameview.removeAllSubviews()
                mEditFields = []

                for (name, value) in frm.slots {
                        switch value {
                        case .event(let estr):
                                let subview = allocateEventField(name: name, value: estr)
                                frameview.addArrangedSubView(subview)
                        case .frame(_):
                                // not supported
                                break
                        case .path(_):
                                // not supported
                                break
                        case .value(let mval):
                                switch mval.value {
                                case .booleanValue(let bval):
                                        let subview = allocateBooleantField(name: name, value: bval)
                                        frameview.addArrangedSubView(subview)
                                case .floatValue(let fval):
                                        let subview = allocateFloatField(name: name, value: fval)
                                        frameview.addArrangedSubView(subview)
                                case .signedIntValue(let ival):
                                        let subview = allocateIntField(name: name, value: ival)
                                        frameview.addArrangedSubView(subview)
                                case .stringValue(let sval):
                                        let subview = allocateStringField(name: name, value: sval)
                                        frameview.addArrangedSubView(subview)
                                case .unsignedIntValue(let uval):
                                        let subview = allocateIntField(name: name, value: Int(uval))
                                        frameview.addArrangedSubView(subview)
                                case .dictionaryValue(_), .arrayValue(_), .nilValue:
                                        NSLog("[Error] Array/Dictionary value is not supported at \(#function)")
                                @unknown default:
                                        NSLog("[Error] supported type value at \(#function)")
                                }
                        }
                }

                frameview.requireDisplay()
        }

        private func allocateEventField(name nm: String, value val: String) -> MIStack {
                return allocateStringField(name: nm, value: val)
        }

        private func allocateBooleantField(name nm: String, value val: Bool) -> MIStack {
                return allocateStringField(name: nm, value: "\(val)")
        }

        private func allocateIntField(name nm: String, value val: Int) -> MIStack {
                return allocateStringField(name: nm, value: "\(val)")
        }

        private func allocateFloatField(name nm: String, value val: Double) -> MIStack {
                return allocateStringField(name: nm, value: "\(val)")
        }

        private func allocateStringField(name nm: String, value val: String) -> MIStack {
                let result = MIStack()
                result.axis = .vertical

                let label = MILabel()
                label.title = nm + ":"
                result.addArrangedSubView(label)

                let field = MITextField()
                field.stringValue = val
                field.setCallback({
                        (_ str: String) -> Void in
                        NSLog("ASFrameEditor: field callback: \(str)")
                        self.updateSlot(name: nm, value: str)
                })
                result.addArrangedSubView(field)

                mEditFields.append(field)

                return result
        }

        private func updateSlot(name nm: String, value str: String) {
                /* update cache */
                if let target = mCachedFrame {
                        target.set(slotName: nm, stringValue: str)
                }
        }

        private func updateButtonPressed() {
                if let view = mFrameView, let cache = mCachedFrame {
                        mTargetFrame = cache
                        mCachedFrame = cache.clone()
                        view.requireDisplay()
                }
        }

        private func cancelButtonPressed() {
                if let view = mFrameView, let target = mTargetFrame {
                        //mTargetFrame = do not touch
                        mCachedFrame = target.clone()
                        view.requireDisplay()
                }
        }
}

