/*
 * @file ASFrameCommand.swift
 * @description Define ASFrameCommand class
 * @par Copyright
 *   Copyright (C) 2025 Steel Wheels Project
 */

import MultiDataKit
import MultiUIKit
import MultiFrameKit
import Foundation


@MainActor public class ASFrameCommandQueue
{
        public typealias DetectedPoint = MIViewFinder.DetectedPoint

        public enum QueueElement {
                // new frameid
                case insert(Int)
        }

        private var mCommandQueue:      Array<QueueElement>

        public init() {
                mCommandQueue = []
        }

        private func push(command cmd: QueueElement){
                mCommandQueue.append(cmd)
        }

        // This operation is NOT pushed into the queue
        public func initFrameIds(frame frm: ASFrame) -> Int {
                let cmd = ASInitFrameIdsCommand(rootFrame: frm)
                return cmd.initFrameIds()
        }

        // This operation is NOT pushed into the queue
        public func getMaxFrameId(frame frm: ASFrame) -> Int {
                let cmd   = ASMaxFrameIdCommand(rootFrame: frm)
                return cmd.maxFrameId()
        }

        public func insert(rootFrame root: ASFrame, sourceName name: String, sourceFrame frame: ASFrame, detectedPoint dpoint: DetectedPoint) -> Bool {
                let command = ASFrameInsertCommand(rootFrame: root)
                if let newfid = command.insert(sourceName: name, sourceFrame: frame, detectedPoint: dpoint) {
                        push(command: .insert(newfid))
                        return true
                } else {
                        return false
                }
        }
}

private class ASInitFrameIdsCommand
{
        var mRootFrame: ASFrame

        public init(rootFrame frame: ASFrame) {
                self.mRootFrame = frame
        }

        public func initFrameIds() -> Int {
                return initFrameIds(frame: mRootFrame, frameId: 0)
        }

        private func initFrameIds(frame dst: ASFrame, frameId fid: Int) -> Int {
                dst.setFrameId(fid)
                var nextid = fid + 1
                for slot in dst.slots {
                        switch slot.value {
                        case .frame(let child):
                                nextid = initFrameIds(frame: child, frameId: nextid)
                        case .value(_), .event(_), .path(_):
                                break
                        }
                }
                return nextid
        }
}

private class ASMaxFrameIdCommand
{
        var mRootFrame: ASFrame

        public init(rootFrame frame: ASFrame) {
                self.mRootFrame = frame
        }

        public func maxFrameId() -> Int {
                let maxid = maxFrameId(frame: mRootFrame, minFrameId: -1)
                if maxid >= 0 {
                        return maxid
                } else {
                        NSLog("[Error] Unexpected frame id at \(#file)")
                        return 0
                }
        }

        private func maxFrameId(frame frm: ASFrame, minFrameId minid: Int) -> Int {
                var result = max(frm.frameId(), minid)
                for slot in frm.slots {
                        switch slot.value {
                        case .frame(let child):
                                result = maxFrameId(frame: child, minFrameId: result)
                        case .value(_), .event(_), .path(_):
                                break
                        }
                }
                return result
        }
}

private class ASFrameInsertCommand
{
        public typealias DetectedPoint = MIViewFinder.DetectedPoint

        var mRootFrame: ASFrame

        public init(rootFrame frame: ASFrame) {
                self.mRootFrame = frame
        }

        public func insert(sourceName name: String, sourceFrame frame: ASFrame, detectedPoint dpoint: DetectedPoint) -> Int? {
                /* assign unique frame id */
                let maxcmd = ASMaxFrameIdCommand(rootFrame: mRootFrame)
                let nextid = maxcmd.maxFrameId() + 1
                frame.setFrameId(nextid)
                if childFrameCount(frame: mRootFrame) == 0 {
                        mRootFrame.set(slotName: name, value: .frame(frame))
                        return nextid
                } else if insert(targetFrame: mRootFrame, sourceName: name, sourceFrame: frame, detectedPoint: dpoint) {
                        return nextid
                } else {
                        return nil
                }
        }

        private func childFrameCount(frame frm: ASFrame) -> Int {
                var result: Int = 0
                for slot in frm.slots {
                        switch slot.value {
                        case .frame(_):
                                result += 1
                        case .value(_), .event(_), .path(_):
                                break

                        }
                }
                return result
        }

        private func insert(targetFrame target: ASFrame, sourceName name: String, sourceFrame frame: ASFrame, detectedPoint dpoint: DetectedPoint) -> Bool {
                for slotidx in 0..<target.slots.count {
                        let dstslot = target.slots[slotidx]
                        switch dstslot.value {
                        case .frame(let child):
                                if child.frameId() == MFInterfaceTagToFrameId(interfaceTag: dpoint.tag) {
                                        if doInsert(parent: target, childName: dstslot.name, name: name, source: frame, at: dpoint) {
                                                return true
                                        } else {
                                                return false
                                        }
                                } else {
                                        if(insert(targetFrame: child, sourceName: name, sourceFrame: frame, detectedPoint: dpoint)){
                                                return true
                                        }
                                }
                        case .event(_), .path(_), .value(_):
                                break
                        }
                }
                return false
        }

        private func doInsert(parent parfrm: ASFrame, childName cname: String, name nm: String, source srcfrm: ASFrame, at dpoint: DetectedPoint) -> Bool {
                let result: Bool
                switch parfrm.flameClass() {
                case .hbox:
                        result = doInsert(hBox: parfrm, childName: cname, name: nm, source: srcfrm, at: dpoint)
                case .vbox:
                        result = doInsert(vBox: parfrm, childName: cname, name: nm, source: srcfrm, at: dpoint)
                default:
                        NSLog("[Error] Can not happen at \(#file)")
                        result = false
                }
                return result
        }

        private func doInsert(hBox parfrm: ASFrame, childName cname: String, name nm: String, source srcfrm: ASFrame, at dpoint: DetectedPoint) -> Bool {
                let result: Bool
                switch dpoint.position {
                case .left, .right:
                        /* insert into the current box */
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
                @unknown default:
                        NSLog("[Error] Unknown position at \(#file)")
                        result = false
                }
                return result
        }

        private func doInsert(vBox parfrm: ASFrame, childName cname: String, name nm: String, source srcfrm: ASFrame, at dpoint: DetectedPoint) -> Bool {
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
                case .top, .bottom:
                        /* insert into the current box */
                        if dpoint.position == .top {
                                result = parfrm.insert(slotName: nm, frame: srcfrm, before: cname)
                        } else {
                                result = parfrm.insert(slotName: nm, frame: srcfrm, after: cname)
                        }
                @unknown default:
                        NSLog("[Error] Unknown position at \(#file)")
                        result = false
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
}
