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
        private var mTargetFrame:       ASFrame? = nil

        public func setTarget(frame frm: ASFrame){
                mTargetFrame = frm
                updateContents(frame: frm)
        }

        private func updateContents(frame frm: ASFrame){
                self.removeAllSubviews()
                for (name, value) in frm.slots {
                        switch value {
                        case .event(let estr):
                                allocateEventField(name: name, value: estr)
                        case .frame(_):
                                // not supported
                                break
                        case .path(_):
                                // not supported
                                break
                        case .value(let mval):
                                switch mval.value {
                                case .booleanValue(let bval):
                                        allocateBooleantField(name: name, value: bval)
                                case .floatValue(let fval):
                                        allocateFloatField(name: name, value: fval)
                                case .signedIntValue(let ival):
                                        allocateIntField(name: name, value: ival)
                                case .stringValue(let sval):
                                        allocateStringField(name: name, value: sval)
                                case .unsignedIntValue(let uval):
                                        allocateIntField(name: name, value: Int(uval))
                                case .dictionaryValue(_), .arrayValue(_), .nilValue:
                                        NSLog("[Error] Array/Dictionary value is not supported at \(#function)")
                                @unknown default:
                                        NSLog("[Error] supported type value at \(#function)")
                                }
                        }
                }
                self.requireDisplay()
        }

        private func allocateEventField(name nm: String, value val: String) {
                allocateStringField(name: nm, value: val)
        }

        private func allocateBooleantField(name nm: String, value val: Bool) {
                allocateStringField(name: nm, value: "\(val)")
        }

        private func allocateIntField(name nm: String, value val: Int) {
                allocateStringField(name: nm, value: "\(val)")
        }

        private func allocateFloatField(name nm: String, value val: Double) {
                allocateStringField(name: nm, value: "\(val)")
        }

        private func allocateStringField(name nm: String, value val: String) {
                let label = MILabel()
                label.title = nm + ":"

                let field = MITextField()
                field.setCallback({
                        (_ str: String) -> Void in
                        self.updateSlot(name: nm, value: str)
                })

                self.addArrangedSubView(label)
                self.addArrangedSubView(field)
        }

        private func updateSlot(name nm: String, value str: String) {
                if let target = mTargetFrame {
                        target.set(slotName: nm, stringValue: str)
                }
        }
}

