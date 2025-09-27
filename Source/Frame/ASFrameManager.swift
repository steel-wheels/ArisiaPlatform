/*
 * @file ASFrame.swift
 * @description Define ASFrame class
 * @par Copyright
 *   Copyright (C) 2025 Steel Wheels Project
 */

import MultiDataKit
import MultiUIKit
import Foundation

@MainActor public class ASFrameManager
{
        public typealias DetectedFrame = ASDropDetector.DetectedFrame

        private var mRootFrame          : ASFrame
        private var mUniqueIndex        : Int

        public var rootFrame: ASFrame { get {
                return mRootFrame
        }}

        public init(frame frm: ASFrame){
                mRootFrame   = frm
                mUniqueIndex = ASFrame.setFrameIds(frame: frm, frameId: 0)
        }

        public func add(contentsOf frame: ASFrame){
                mUniqueIndex = ASFrame.setFrameIds(frame: frame, frameId: mUniqueIndex)
                for slot in frame.slots {
                        mRootFrame.set(slotName: slot.name, value: slot.value)
                }
        }

        public func insert(name nm: String, frame frm: ASFrame, at dpoint: DetectedFrame){
                //NSLog("dropped at \(dpoint.description)")
                if mRootFrame.frameSlots.count == 0 {
                        //NSLog("Successed to add 1st item")
                        mUniqueIndex = ASFrame.setFrameIds(frame: frm, frameId: mUniqueIndex)
                        mRootFrame.set(slotName: nm, value: .frame(frm))
                } else if insert(destination: mRootFrame, name: nm, source: frm, at: dpoint) {
                        //NSLog("Successed to insert")
                } else {
                        NSLog("[Error] Failed to insert")
                }
        }

        private func insert(destination dstfrm: ASFrame, name nm: String, source srcfrm: ASFrame, at dpoint: DetectedFrame) -> Bool {
                for slotidx in 0..<dstfrm.slots.count {
                        let dstslot = dstfrm.slots[slotidx]
                        switch dstslot.value {
                        case .frame(let child):
                                if child.frameId() == dpoint.frameId {
                                        return doInsert(parent: dstfrm, childName: dstslot.name, name: nm, source: srcfrm, at: dpoint)
                                } else {
                                        return insert(destination: child, name: nm, source: srcfrm, at: dpoint)
                                }
                        case .event(_), .path(_), .value(_):
                                break
                        }
                }
                return false
        }

        private func doInsert(parent parfrm: ASFrame, childName cname: String, name nm: String, source srcfrm: ASFrame, at dpoint: DetectedFrame) -> Bool {
                let result: Bool
                switch parfrm.flameClass() {
                case .hbox:
                        result = doInsert(hBox: parfrm, childName: cname, name: nm, source: srcfrm, at: dpoint)
                case .vbox:
                        result = doInsert(vBox: parfrm, childName: cname, name: nm, source: srcfrm, at: dpoint)
                default:
                        NSLog("[Error] Can not happen at \(#function)")
                        result = false
                }
                return result
        }

        private func doInsert(hBox parfrm: ASFrame, childName cname: String, name nm: String, source srcfrm: ASFrame, at dpoint: DetectedFrame) -> Bool {
                let result: Bool
                switch dpoint.position {
                case .left, .right, .center:
                        /* insert into the current box */
                        mUniqueIndex = ASFrame.setFrameIds(frame: srcfrm, frameId: mUniqueIndex)
                        if dpoint.position == .right {
                                result = parfrm.insert(slotName: nm, frame: srcfrm, after: cname)
                        } else {
                                result = parfrm.insert(slotName: nm, frame: srcfrm, before: cname)
                        }
                case .top, .bottom:
                        if let newbox = makeBox(parent: parfrm, slotName: cname, axis: .vertical) {
                                if dpoint.position == .top {
                                        result = newbox.insert(slotName: nm, frame: srcfrm, before: cname)
                                } else {
                                        result = newbox.insert(slotName: nm, frame: srcfrm, after: cname)
                                }
                        } else {
                                NSLog("[Error] Failed to make box at \(#file)")
                                result = false
                        }
                }
                return result
        }

        private func doInsert(vBox parfrm: ASFrame, childName cname: String, name nm: String, source srcfrm: ASFrame, at dpoint: DetectedFrame) -> Bool {
                let result: Bool
                switch dpoint.position {
                case .left, .right:
                        if let newbox = makeBox(parent: parfrm, slotName: cname, axis: .horizontal) {
                                if dpoint.position == .right {
                                        result = newbox.insert(slotName: nm, frame: srcfrm, after: cname)
                                } else {
                                        result = newbox.insert(slotName: nm, frame: srcfrm, before: cname)
                                }
                        } else {
                                NSLog("[Error] Failed to make box at \(#file)")
                                result = false
                        }
                case .top, .bottom, .center:
                        /* insert into the current box */
                        mUniqueIndex = ASFrame.setFrameIds(frame: srcfrm, frameId: mUniqueIndex)
                        if dpoint.position == .top {
                                result = parfrm.insert(slotName: nm, frame: srcfrm, before: cname)
                        } else {
                                result = parfrm.insert(slotName: nm, frame: srcfrm, after: cname)
                        }
                }
                return result
        }

        private func makeBox(parent parfrm: ASFrame, slotName sname: String, axis axs: MIStackCore.Axis) -> ASFrame? {
                if let sval = parfrm.value(slotName: sname)  {
                        switch sval {
                        case .frame(let frame):
                                let box = ASFrame() ;
                                box.setFrameClass(axs == .horizontal ? .hbox : .vbox)
                                box.set(slotName: sname, value: .frame(frame))
                                parfrm.set(slotName: sname, value: .frame(box))
                                return box
                        case .value(_), .event(_), .path(_):
                                NSLog("[Error] Unexpected value at \(#file)")
                                return nil
                        }
                } else {
                        NSLog("[Error] Unexpected name \(sname) at \(#file)")
                        return nil
                }
        }

        public func search(coreTag ctag: Int) -> ASFrame? {
                return search(frame: mRootFrame, coreTag: ctag)
        }

        private func search(frame frm: ASFrame, coreTag ctag: Int) -> ASFrame? {
                if frm.frameId() == ctag {
                        return frm
                }
                for slot in frm.slots {
                        switch slot.value {
                        case .frame(let child):
                                if let result = search(frame: child, coreTag: ctag) {
                                        return result
                                }
                        default:
                                break
                        }
                }
                return nil
        }

        public static func loadBoxFrame() -> Result<ASFrame, NSError> {
                return loadFrame(fileName: "Frames/Box.as")
        }

        public static func loadButtonFrame() -> Result<ASFrame, NSError> {
                return loadFrame(fileName: "Frames/Button.as")
        }

        public static func loadImageFrame() -> Result<ASFrame, NSError> {
                return loadFrame(fileName: "Frames/Image.as")
        }

        public static func loadFrame(fileName fname: String) -> Result<ASFrame, NSError> {
                if let resdir = FileManager.default.resourceDirectory(forClass: ASDropView.self) {
                        let file = resdir.appending(path: fname)
                        let text: String
                        do {
                                text = try String(contentsOf: file, encoding: .utf8)
                        } catch {
                                let err = MIError.error(errorCode: .urlError, message: "Failed to load from \(file.path)")
                                return .failure(err)
                        }
                        let parser = ASFrameParser()
                        switch parser.parse(string: text) {
                        case .success(let frame):
                                return .success(frame)
                        case .failure(let err):
                                return .failure(err)
                        }
                } else {
                        let err = MIError.error(errorCode: .urlError, message: "No resource directory")
                        return .failure(err)
                }
        }
}
