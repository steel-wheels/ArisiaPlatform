/*
 * @file ASFrame.swift
 * @description Define ASFrame class
 * @par Copyright
 *   Copyright (C) 2025 Steel Wheels Project
 */

import MultiDataKit
import Foundation

public enum ASFrameValue
{
        case value(MIValue)                     // scalar value only
        case event(String)
        case frame(ASFrame)
        case path(Array<String>)

        public func clone() -> ASFrameValue {
                let result: ASFrameValue
                switch self {
                case .value(let val):
                        result = .value(val)
                case .event(let estr):
                        result = .event(estr)
                case .frame(let frm):
                        result = .frame(frm.clone())
                case .path(let pth):
                        result = .path(pth)
                }
                return result
        }
}

public class ASFrame
{
        private var mSlots: Dictionary<String, ASFrameValue> = [:]

        public init(){
                mSlots = [:]
        }

        public var slots: Dictionary<String, ASFrameValue> { get { return mSlots }}

        public func set(slotName name: String, value val: ASFrameValue) {
                mSlots[name] = val
        }

        public func value(slotName name: String) -> ASFrameValue? {
                return mSlots[name]
        }

        public func set(slotName name: String, stringValue str: String) {
                let val: ASFrameValue = .value(MIValue(stringValue: str))
                self.set(slotName: name, value: val)
        }

        public func stringValue(slotName name: String) -> String? {
                if let val = self.value(slotName: name) {
                        switch val {
                        case .value(let mival):
                                switch mival.value {
                                case .stringValue(let str):
                                        return str
                                default:
                                        break
                                }
                        default:
                                break
                        }
                }
                return nil
        }

        public func set(slotName name: String, intValue ival: Int) {
                let val: ASFrameValue = .value(MIValue(signedIntValue: ival))
                self.set(slotName: name, value: val)
        }

        public func intValue(slotName name: String) -> Int? {
                if let val = self.value(slotName: name) {
                        switch val {
                        case .value(let mival):
                                switch mival.value {
                                case .signedIntValue(let val):
                                        return val
                                default:
                                        break
                                }
                        default:
                                break
                        }
                }
                return nil
        }

        public func clone() -> ASFrame {
                let result = ASFrame()
                for (name, val) in mSlots {
                        result.set(slotName: name, value: val.clone())
                }
                return result
        }
}

extension ASFrame
{
        public enum FrameClass: String {
                case box        = "Box"
                case button     = "Button"

                public func toString() -> String {
                        return self.rawValue
                }

                public static func decode(string str: String) -> FrameClass? {
                        return FrameClass(rawValue: str)
                }
        }

        public static let ClassSlotName         = "class"
        public static let FrameIdSlotName       = "frameid"

        public static func isBuiltinSlotName(name nm: String) -> Bool {
                let bnames: Array<String> = [
                        ASFrame.ClassSlotName,
                        ASFrame.FrameIdSlotName
                ]
                for bname in bnames {
                        if bname == nm {
                                return true
                        }
                }
                return false
        }

        public func setFrameClass(_ fclass: FrameClass){
                self.set(slotName: ASFrame.ClassSlotName, stringValue: fclass.toString())
        }

        public func flameClass() -> FrameClass {
                if let str = self.stringValue(slotName: ASFrame.ClassSlotName) {
                        if let cls = FrameClass.decode(string: str) {
                                return cls
                        } else {
                                NSLog("[Error] Unknown frame class \(str) at \(#function)")
                                return .box
                        }
                } else {
                        NSLog("[Error] No frame class name at \(#function)")
                        return .box
                }
        }

        public func setFrameId(_ fid: Int){
                self.set(slotName: ASFrame.FrameIdSlotName, intValue: fid)
        }

        public func frameId() -> Int {
                if let val = self.intValue(slotName: ASFrame.FrameIdSlotName) {
                        return val
                } else {
                        NSLog("[Error] No frame id at \(#function)")
                        return -1
                }
        }

        public static func setFrameIds(frame frm: ASFrame, frameId fid: Int) -> Int {
                frm.setFrameId(fid)
                var result   = fid + 1
                for (_, val) in frm.slots {
                        switch val {
                        case .frame(let child):
                                result = setFrameIds(frame: child, frameId: result)
                        case .event(_), .path(_), .value(_):
                                break
                        }
                }
                return result
        }
}
