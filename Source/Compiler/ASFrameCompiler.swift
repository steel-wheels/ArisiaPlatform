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
        private var mPackage:           ASPackage
        private var mResource:          ASResource
        private var mScript:            Array<String>

        private struct EventDefinition {
                var name:       String
                var script:     String

                public init(_ ename: String, _ escr: String) {
                        name   = ename
                        script = escr
                }
        }

        public init(context ctxt: MFContext, consoleStorage strg: MITextStorage, package pkg: ASPackage, resource res: ASResource){
                mContext                = ctxt
                mConsoleStortage        = strg
                mPackage                = pkg
                mResource               = res
                mScript                 = []

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
                switch ownerframe.frameClass() {
                case .hbox:
                        result = compile(boxFrame: ownerframe, axis: .horizontal, path: pth, into: ownerview)
                case .vbox:
                        result = compile(boxFrame: ownerframe, axis: .vertical, path: pth, into: ownerview)
                case .button:
                        result = compile(buttonFrame: ownerframe, path: pth, into: ownerview)
                case .image:
                        result = compile(imageFrame: ownerframe, path: pth, into: ownerview)
                }
                return result
        }

        private func compile(boxFrame ownerframe: ASFrame, axis axs: MIStackCore.Axis, path pth: Array<String>, into ownerview: MFStack) -> NSError? {
                let stack = MFStack(context: mContext)
                stack.tag  = MFFrameIdToInterfaceTag(frameId: ownerframe.frameId())
                stack.axis = axs
                for slot in ownerframe.slots {
                        if isUntoucheableSlot(slotName: slot.name) {
                                continue
                        }
                        switch slot.value {
                        case .value(let sval):
                                stack.setValue(name: slot.name, value: sval)
                        case .frame(let sframe):
                                var spath = pth ; spath.append(slot.name)
                                if let err = compile(frame: sframe, path: spath, into: stack) {
                                        return err
                                }
                        case .event(_):
                                return MIError.error(
                                        errorCode: .parseError,
                                        message: "The \(slot.name) slot can not have event slot"
                                )
                        case .path(_):
                                return MIError.error(
                                        errorCode: .parseError,
                                        message: "The \(slot.name) slot can not have path slot"
                                )
                        }
                }
                ownerview.addArrangedSubView(stack)

                exportObject(path:              pth,
                             frame:             stack,
                             properties:        [],
                             eventDefinitions:  []
                )
                return nil
        }

        private func compile(buttonFrame ownerframe: ASFrame, path pth: Array<String>, into ownerview: MFStack) -> NSError? {
                var eventdefs: Array<EventDefinition> = []

                let button = MFButton(context: mContext)
                button.tag = MFFrameIdToInterfaceTag(frameId: ownerframe.frameId())
                for slot in ownerframe.slots {
                        if isUntoucheableSlot(slotName: slot.name) {
                                continue
                        }
                        switch slot.name {
                        case MFButton.TitleSlotName:
                                switch slot.value {
                                case .value(let val):
                                        button.setValue(
                                                name: MFButton.TitleSlotName,
                                                value: val
                                        )
                                default:
                                        return MIError.error(
                                                errorCode: .parseError,
                                                message: "The \"\(slot.name)\" slot must have string value"
                                        )
                                }
                        case MFButton.ClickedEventName:
                                switch slot.value {
                                case .event(let event):
                                        eventdefs.append(EventDefinition(MFButton.ClickedEventName, event))
                                default:
                                        return MIError.error(
                                                errorCode: .parseError,
                                                message: "The \"\(slot.name)\" slot must have event description"
                                        )
                                }
                        default:
                                switch slot.value {
                                case .value(let val):
                                        button.setValue(name: slot.name, value: val)
                                default:
                                        return MIError.error(
                                                errorCode: .parseError,
                                                message: "The \"\(slot.name)\" slot have path slot unexpected value"
                                        )
                                }
                        }
                }

                ownerview.addArrangedSubView(button)

                exportObject(path:              pth,
                             frame:             button,
                             properties:        [MFButton.TitleSlotName, MFButton.ClickedEventName],
                             eventDefinitions:  eventdefs
                )
                return nil
        }

        private func compile(imageFrame ownerframe: ASFrame, path pth: Array<String>, into ownerview: MFStack) -> NSError? {
                let image = MFImageView(context: mContext)

                image.tag = MFFrameIdToInterfaceTag(frameId: ownerframe.frameId())
                for slot in ownerframe.slots {
                        if isUntoucheableSlot(slotName: slot.name) {
                                continue
                        }
                        switch slot.name {
                        case MFImageView.FileSlotName:
                                switch slot.value {
                                case .value(let val):
                                        if let path = val.stringValue {
                                                switch mPackage.image(fileName: path) {
                                                case .success(let img):
                                                        image.image = img
                                                case .failure(let err):
                                                        return err
                                                }
                                        } else {
                                                return MIError.error(
                                                        errorCode: .parseError,
                                                        message: "The \"\(slot.name)\" slot must have string"
                                                )
                                        }
                                default:
                                        return MIError.error(
                                                errorCode: .parseError,
                                                message: "The \"\(slot.name)\" slot must have unexpected type value"
                                        )
                                }
                        default:
                                switch slot.value {
                                case .value(let val):
                                        image.setValue(name: slot.name, value: val)
                                default:
                                        return MIError.error(
                                                errorCode: .parseError,
                                                message: "The \"\(slot.name)\" slot have path slot unexpected value"
                                        )
                                }
                        }
                }

                ownerview.addArrangedSubView(image)
                exportObject(path:              pth,
                             frame:             image,
                             properties:        [MFImageView.FileSlotName],
                             eventDefinitions:  []
                )
                return nil
        }

        private func isUntoucheableSlot(slotName name: String) -> Bool {
                let result: Bool
                switch name {
                case ASFrame.ClassSlotName, ASFrame.FrameIdSlotName:
                        result = true
                default:
                        result = false
                }
                return result
        }

        private func exportObject(path pth: Array<String>, frame frm: MFFrame, properties props: Array<String>,
                                  eventDefinitions events: Array<EventDefinition>) {
                let varname = pth.joined(separator: "_")
                mContext.setObject(frm.core, forKeyedSubscript: varname as NSString)
                mScript.append("/* define object: \(varname) */")

                for prop in props {
                        defineProperty(objectName: varname, propertyName: prop)
                }
                for event in events {
                        defineEvent(objectName: varname, eventDefinition: event)
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

        private func defineEvent(objectName objname: String, eventDefinition event: EventDefinition) {
                mScript.append("/* define event \(event.name) for object: \(objname) */")
                let stmt: String = "\(objname).\(event.name) = function(){ \(event.script) } ;"
                mScript.append(stmt)
        }
}

