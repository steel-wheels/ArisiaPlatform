/*
 * @file ASFrameCompiler.swift
 * @description Define ASFrameCompiler class
 * @par Copyright
 *   Copyright (C) 2025 Steel Wheels Project
 */

import MultiFrameKit
import MultiUIKit
import MultiDataKit
import Foundation

@MainActor public class ASFrameCompiler
{
        private var mContext: MFContext

        public init(context ctxt: MFContext){
                mContext = ctxt
        }
        
        public func compile(frame frm: ASFrame, into ownerview: MFStack) -> NSError? {
                return compile(frame: frm, path: [], into: ownerview)
        }

        private func compile(frame ownerframe: ASFrame, path pth: Array<String>, into ownerview: MFStack) -> NSError? {
                let result: NSError?
                switch ASFrameManager.typeOfFrame(source: ownerframe){
                case .box:
                        result = compile(boxFrame: ownerframe, path: pth, into: ownerview)
                case .button:
                        result = compile(buttonFrame: ownerframe, path: pth, into: ownerview)
                case .none:
                        result = MIError.error(errorCode: .parseError, message: "Unknown frame class")
                }
                return result
        }

        private func compile(boxFrame ownerframe: ASFrame, path pth: Array<String>, into ownerview: MFStack) -> NSError? {
                let stack = MFStack(context: mContext)
                for (slotname, slotvalue) in ownerframe.slots {
                        switch slotvalue {
                        case .value(let sval):
                                stack.setValue(name: slotname, value: sval)
                        case .frame(let sframe):
                                var spath = pth ; spath.append(slotname)
                                if let err = compile(frame: sframe, path: spath, into: stack) {
                                        return err
                                }
                        case .event(_):
                                return MIError.error(
                                        errorCode: .parseError,
                                        message: "The frame can not have event slot"
                                )
                        case .path(_):
                                return MIError.error(
                                        errorCode: .parseError,
                                        message: "The frame can not have path slot"
                                )
                        }
                }
                ownerview.addArrangedSubView(stack)
                return nil
        }

        private func compile(buttonFrame ownerframe: ASFrame, path pth: Array<String>, into ownerview: MFStack) -> NSError? {
                let button = MFButton(context: mContext)
                for (slotname, slotvalue) in ownerframe.slots {
                        switch slotvalue {
                        case .value(let sval):
                                switch slotname {
                                case MFButton.TitleSlotName:
                                        button.setValue(
                                                name: MFButton.TitleSlotName,
                                                value: sval
                                        )
                                case ASFrameManager.ClassSlotName:
                                        break
                                default:
                                        return MIError.error(
                                          errorCode: .parseError,
                                          message: "The button does not have \"\(slotname)\" slot"
                                        )
                                }
                        case .event(let text):
                                switch slotname {
                                case MFButton.ClickedEventName:
                                        button.setValue(
                                                name:  "_" + MFButton.ClickedEventName,
                                                value: MIValue(stringValue: text)
                                        )
                                default:
                                        return MIError.error(
                                          errorCode: .parseError,
                                          message: "The button does not have \"\(slotname)\" event"
                                        )
                                }
                        case .path(_):
                                return MIError.error(
                                        errorCode: .parseError,
                                        message: "The button can not have path slot"
                                )
                        case .frame(_):
                                return MIError.error(
                                        errorCode: .parseError,
                                        message: "The button can not have frame slot"
                                )
                        }
                }
                ownerview.addArrangedSubView(button)
                return nil
        }
}

