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
        public struct Slot {
                var name:       String
                var value:      ASFrameValue
        }

        private var mSlots:     Array<Slot> = []

        public init(){
                mSlots = []
        }

        public var slots: Array<Slot> { get { return mSlots }}

        public var frameSlots: Array<Slot> { get {
                var result: Array<Slot> = []
                for slot in mSlots {
                        switch slot.value {
                        case .frame(_):
                                result.append(slot)
                        default:
                                break ;
                        }
                }
                return result
        }}

        public func set(slotName name: String, value val: ASFrameValue) {
                for i in 0..<mSlots.count {
                        let slot = mSlots[i]
                        if slot.name == name {
                                mSlots[i] = Slot(name: name, value: val)
                                return
                        }
                }
                let slot = Slot(name: name, value: val)
                mSlots.append(slot)
        }

        public func set(slotName name: String, stringValue str: String) {
                set(slotName: name, value: .value(MIValue(stringValue: str)))
        }

        public func set(slotName name: String, intValue ival: Int) {
                set(slotName: name, value: .value(MIValue(signedIntValue: ival)))
        }

        public func insert(slotName name: String, frame frm: ASFrame, before sname: String) -> Bool {
                let newslot = Slot(name: name, value: .frame(frm))
                for i in 0..<mSlots.count {
                        let slot = mSlots[i]
                        if slot.name == sname {
                                mSlots.insert(newslot, at: i)
                                return true
                        }
                }
                NSLog("[Error] No slot name \(sname) at \(#file)")
                return false
        }

        public func insert(slotName name: String, frame frm: ASFrame, after sname: String) -> Bool {
                let newslot = Slot(name: name, value: .frame(frm))
                for i in 0..<mSlots.count {
                        let slot = mSlots[i]
                        if slot.name == sname {
                                if i+1 < mSlots.count {
                                        mSlots.insert(newslot, at: i+1)
                                } else {
                                        mSlots.append(newslot)
                                }
                                return true
                        }
                }
                NSLog("[Error] No slot name \(sname) at \(#file)")
                return false
        }

        public func value(slotName name: String) -> ASFrameValue? {
                for slot in slots {
                        if slot.name == name {
                                return slot.value
                        }
                }
                return nil
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
                for slot in mSlots {
                        result.set(slotName: slot.name, value: slot.value.clone())
                }
                return result
        }
}

extension ASFrame
{
        public enum FrameClass: String {
                case vbox       = "VBox"
                case hbox       = "HBox"
                case button     = "Button"
                case image      = "Image"

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
                                return .vbox
                        }
                } else {
                        NSLog("[Error] No frame class name at \(#function)")
                        return .vbox
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
                for slot in frm.slots {
                        switch slot.value {
                        case .frame(let child):
                                result = setFrameIds(frame: child, frameId: result)
                        case .event(_), .path(_), .value(_):
                                break
                        }
                }
                return result
        }
}
