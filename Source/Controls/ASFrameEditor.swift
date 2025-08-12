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
        private var mButtons:           MIStack?  = nil
        private var mUpdateButton:      MIButton? = nil
        private var mCancelButton:      MIButton? = nil
        private var mEditFields:        Dictionary<String, MITextField> = [:]

        private var mTargetFrame:       ASFrame?  = nil
        private var mCachedFrame:       ASFrame?  = nil

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

        public func set(target frame: ASFrame, width wid: MIContentSize.Length) {
                mTargetFrame    = frame
                mCachedFrame    = frame.clone()
                load(frame: frame, width: wid)
        }

        private func load(frame frm: ASFrame, width wid: MIContentSize.Length){
                guard let frameview = mFrameView else {
                        NSLog("[Error] Can not happen at \(#function)")
                        return
                }
                frameview.removeAllSubviews()
                mEditFields = [:]

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
                                        NSLog("[Error] Array/Dictionary value is not supported at \(#file)")
                                @unknown default:
                                        NSLog("[Error] supported type value at \(#file)")
                                }
                        }
                }

                if let buttons = mButtons {
                        buttons.set(contentSize: MIContentSize(width: wid,
                                                               height: .none))
                }

                updateButtonStatus()
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
                        self.mIsModified = true
                        self.updateButtonStatus()
                })
                result.addArrangedSubView(field)

                mEditFields[nm] = field

                return result
        }

        private func store(frame frm: ASFrame){
                for (name, value) in frm.slots {
                        switch value {
                        case .event(let str):
                                storeEventField(name: name, value: str)
                        case .frame(_):
                                // not supported
                                break
                        case .path(_):
                                // not supported
                                break
                        case .value(let mval):
                                switch mval.value {
                                case .booleanValue(let ival):
                                        storeBoolField(name: name, value: ival)
                                case .signedIntValue(let ival):
                                        storeIntField(name: name, value: ival)
                                case .unsignedIntValue(let ival):
                                        storeIntField(name: name, value: Int(ival))
                                case .floatValue(let ival):
                                        storeFloatField(name: name, value: ival)
                                case .stringValue(let ival):
                                        storeStringField(name: name, value: ival)
                                case .dictionaryValue(_), .arrayValue(_), .nilValue:
                                        NSLog("[Error] Array/Dictionary value is not supported at \(#file)")
                                @unknown default:
                                        NSLog("[Error] supported type value at \(#file)")
                                }
                        }
                }
                mIsModified = false
        }

        private func storeEventField(name nm: String, value val: String) {
                storeStringField(name: nm, value: val)
        }

        private func storeBoolField(name nm: String, value val: Bool) {
                storeStringField(name: nm, value: "\(val)")
        }

        private func storeIntField(name nm: String, value val: Int) {
                storeStringField(name: nm, value: "\(val)")
        }

        private func storeFloatField(name nm: String, value val: Double) {
                storeStringField(name: nm, value: "\(val)")
        }

        private func storeStringField(name nm: String, value val: String) {
                if let field = mEditFields[nm] {
                        field.stringValue = val
                } else {
                        NSLog("[Error] field \(nm) is not found at \(#file)")
                }
        }

        private func updateSlot(name nm: String, value str: String) {
                /* update cache */
                if let target = mCachedFrame {
                        target.set(slotName: nm, stringValue: str)
                }
        }

        private func updateButtonPressed() {
                if let cache = mCachedFrame {
                        mTargetFrame = cache
                        mCachedFrame = cache.clone()
                }
        }

        private func cancelButtonPressed() {
                if let view = mFrameView, let target = mTargetFrame {
                        /* Restore source values */
                        mCachedFrame = target.clone()
                        store(frame: target)
                        view.requireDisplay()
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

