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
        private var mContext:           MFContext
        private var mConsoleStortage:   MITextStorage
        private var mScript:            Array<String>

        public init(context ctxt: MFContext, consoleStorage strg: MITextStorage){
                mContext         = ctxt
                mConsoleStortage = strg
                mScript          = []

                /* add console object */
                let console = MFConsole(storage: strg)
                ctxt.setObject(console, forKeyedSubscript: "console" as NSString)
        }
        
        public func compile(frame frm: ASFrame, into ownerview: MFStack) -> NSError? {
                if let err = compile(frame: frm, path: ["root"], into: ownerview) {
                        return err
                }

                /* Evaluate the script */
                let scr = mScript.joined(separator: "\n")
                NSLog("JavaScript: \(scr)")
                let ecnt = mContext.execute(script: scr)
                if(ecnt == 0){
                        return nil // no error
                } else {
                        return MIError.error(errorCode: .parseError, message: "Some evaluation error: \(ecnt)")
                }
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

                let props: Array<String> = []
                exportObject(path: pth, object: stack, properties: props)
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

                let props: Array<String> = [
                        MFButton.TitleSlotName
                ]
                exportObject(path: pth, object: button, properties: props)
                return nil
        }

        private func exportObject(path pth: Array<String>, object obj: NSObject, properties props: Array<String>){
                let varname = pth.joined(separator: "_")
                mContext.setObject(obj, forKeyedSubscript: varname as NSString)
                mScript.append("/* define object: \(varname) */")

                for prop in props {
                        defineProperty(objectName: varname, propertyName: prop)
                }
        }

        private func defineProperty(objectName objname: String, propertyName propname: String) {
                mScript.append("/* define property \(propname) for object: \(objname) */")
                let stmt: String = "Object.defineProperty(\(objname), '\(propname)', {\n"
                                 + "  get()  { return \(objname)._value(\"\(propname)\") ; },\n"
                                 + "  set(v) { \(objname)._setValue(\"\(propname)\", v) ; }\n"
                                 + "}) ;"
                mScript.append(stmt)
        }
}

