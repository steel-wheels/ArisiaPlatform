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


public class ASFrameCommand
{
        public static func initFrameIds(frame frm: ASFrame) -> Int {
                let cmd = ASInitFrameIdsCommand(rootFrame: frm)
                return cmd.initFrameIds()
        }

        public static func getMaxFrameId(frame frm: ASFrame) -> Int {
                let cmd   = ASMaxFrameIdCommand(rootFrame: frm)
                return cmd.maxFrameId()
        }

        public static func search(frame frm: ASFrame, frameId fid: Int) -> ASFrame? {
                let cmd = ASSearchFrameCommand(rootFrame: frm)
                return cmd.search(frameId: fid)
        }
}

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

private class ASSearchFrameCommand
{
        var mRootFrame: ASFrame

        public init(rootFrame frame: ASFrame) {
                self.mRootFrame = frame
        }

        public func search(frameId fid: Int) -> ASFrame? {
                return search(frame: mRootFrame, frameId: fid)
        }

        private func search(frame frm: ASFrame, frameId fid: Int) -> ASFrame? {
                if frm.frameId() == fid {
                        return frm
                }
                for slot in frm.slots {
                        switch slot.value {
                        case .frame(let child):
                                if let result = search(frame: child, frameId: fid) {
                                        return result
                                }
                        default:
                                break
                        }
                }
                return nil
        }

        public func searchName(frameId fid: Int) -> String? {
                return searchName(frame: mRootFrame, frameId: fid)
        }

        private func searchName(frame frm: ASFrame, frameId fid: Int) -> String? {
                for slot in frm.slots {
                        switch slot.value {
                        case .frame(let child):
                                if child.frameId() == fid {
                                        return slot.name
                                }
                                if let name = searchName(frame: child, frameId: fid) {
                                        return name
                                }
                        case .event(_), .path(_), .value(_):
                                break
                        }
                }
                return nil
        }
}

private class ASFrameInsertCommand
{
        public typealias DetectedPoint = MIViewFinder.DetectedPoint

        private var mRootFrame:         ASFrame
        private var mNextFrameId:       Int

        public init(rootFrame frame: ASFrame) {
                self.mRootFrame = frame

                let maxcmd   = ASMaxFrameIdCommand(rootFrame: frame)
                mNextFrameId = maxcmd.maxFrameId() + 1
        }

        public func insert(sourceName name: String, sourceFrame frame: ASFrame, detectedPoint dpoint: DetectedPoint) -> Int? {
                /* assign unique frame id */
                NSLog("insert 1")
                let newframeid = mNextFrameId
                frame.setFrameId(newframeid)
                mNextFrameId += 1

                /* if the root frame empry, add the child */
                if isEmprtFrame(frame: mRootFrame) {
                        NSLog("insert 2")
                        let box = makeBox(frameClass: .hbox)
                        box.set(slotName: name, value: .frame(frame))
                        mRootFrame.set(slotName: boxName(frameId: box.frameId()), value: .frame(box))
                        return newframeid
                }

                /* get detected frame name */
                NSLog("insert 3")
                let searchcmd = ASSearchFrameCommand(rootFrame: mRootFrame)
                let frameid = MFInterfaceTagToFrameId(interfaceTag: dpoint.tag)
                guard let dname = searchcmd.searchName(frameId: frameid) else {
                        NSLog("[Error] No frame name for \(frameid) at \(#file)")
                        return nil
                }
                NSLog("insert 4 dname=\(dname)")

                /* get stack hierarcy */
                NSLog("insert 5")
                var stack: Array<ASFrame> = []
                guard searchByFrameid(&stack, targetFrame: mRootFrame, frameId: frameid) else {
                        NSLog("[Error] Failed to search frame: \(#file)")
                        return nil
                }
                if insert(stack: &stack, sourceName: name, sourceFrame: frame, detectedPoint: dpoint, detectedName: dname) {
                        return newframeid
                }
                NSLog("insert 6")
                return nil
        }

        private func isEmprtFrame(frame src: ASFrame) -> Bool {
                for slot in src.slots {
                        switch slot.value {
                        case .frame(_):
                                return false
                        case .event(_), .path(_), .value(_):
                                break
                        }
                }
                return true
        }

        // deeper box frame first
        private func searchByFrameid(_ result: inout Array<ASFrame>, targetFrame target: ASFrame, frameId fid: Int) -> Bool {
                if target.frameId() == fid {
                        if isBox(frame: target) {
                                result.append(target)
                        }
                        return true
                }
                for slot in target.slots {
                        switch slot.value {
                        case .frame(let child):
                                if searchByFrameid(&result, targetFrame: child, frameId: fid) {
                                        if isBox(frame: target) {
                                                result.append(target)
                                        }
                                        return true
                                }
                        case .event(_), .path(_), .value(_):
                                break
                        }
                }
                return false // not found
        }


        private func insert(stack dststack: inout Array<ASFrame>, sourceName name: String, sourceFrame frame: ASFrame, detectedPoint dpoint: DetectedPoint, detectedName dname: String) -> Bool {
                guard dststack.count > 0 else {
                        NSLog("[Error] empty stack at \(#file)")
                        return false
                }

                // dststack.count > 0
                NSLog("insert step 1")
                let dst0frm = dststack[0]
                guard isBox(frame: dst0frm) else {
                        NSLog("[Error] HBox is required")
                        return false
                }
                if insert(box: dst0frm, sourceName: name, sourceFrame: frame, detectedPoint: dpoint, detectedName: dname) {
                        return true
                }

                // dststack.count >= 2
                NSLog("insert step 2")
                guard dststack.count >= 2 else {
                        NSLog("[Error] too short stack at \(#file)")
                        return false
                }
                NSLog("insert step 3")
                let dst1frm = dststack[1]
                guard isBox(frame: dst1frm) else {
                        NSLog("[Error] Box is required at \(#file)")
                        return false
                }
                NSLog("insert step 4")
                guard let sname = slotName(parent: dst1frm, child: dst0frm) else {
                        NSLog("[Error] No children: \(#file)")
                        return false
                }
                NSLog("insert step 5")
                if insert(box: dst1frm, sourceName: name, sourceFrame: frame, detectedPoint: dpoint, detectedName: sname) {
                        return true
                }

                NSLog("[Error] Failed to insert at \(#file)")
                return false
        }

        private func insert(box dstbox: ASFrame, sourceName name: String, sourceFrame frame: ASFrame, detectedPoint dpoint: DetectedPoint, detectedName dname: String) -> Bool {
                let result: Bool
                switch dstbox.frameClass() {
                case .vbox:
                        switch dpoint.position {
                        case .top:
                                let box = makeBox(frameClass: .hbox)
                                box.set(slotName: name, value: .frame(frame))
                                result = dstbox.insert(slotName: boxName(frameId: box.frameId()), frame: box, before: dname)
                        case .bottom:
                                let box = makeBox(frameClass: .hbox)
                                box.set(slotName: name, value: .frame(frame))
                                result = dstbox.insert(slotName: boxName(frameId: box.frameId()), frame: box, after: dname)
                        case .left, .right:
                                result = false // not supported
                        @unknown default:
                                NSLog("[Error] Can not happen")
                                result = false
                        }
                case .hbox:
                        switch dpoint.position {
                        case .left:
                                result = dstbox.insert(slotName: name, frame: frame, before: dname)
                        case .right:
                                result = dstbox.insert(slotName: name, frame: frame, after: dname)
                        case .top, .bottom:
                                result = false // not supported
                        @unknown default:
                                NSLog("[Error] Can not happen")
                                result = false
                        }
                case .button, .image:
                        NSLog("[Error] Unexpected frame type at \(#file)")
                        result = false
                }
                return result
        }

        private func isBox(frame src: ASFrame) -> Bool {
                switch src.frameClass() {
                case .vbox, .hbox:
                        return true
                case .button, .image:
                        return false
                }
        }

        private func slotName(parent pframe: ASFrame, child cframe: ASFrame) -> String? {
                for slot in pframe.slots {
                        switch slot.value {
                        case .frame(let child):
                                if child.frameId() == cframe.frameId() {
                                        return slot.name
                                }
                        case .event(_), .path(_), .value(_):
                                break
                        }
                }
                return nil
        }

        private func makeBox(frameClass fcls: ASFrame.FrameClass) -> ASFrame {
                let box = ASFrame() ;
                box.setFrameClass(fcls)
                box.setFrameId(mNextFrameId)
                mNextFrameId += 1
                return box
        }

        private func boxName(frameId fid: Int) -> String {
                return "box_\(fid)"
        }

        /*
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
                switch parfrm.frameClass() {
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
        }*/
}
