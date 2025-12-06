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

public enum ASFrameCommand {
        public typealias DetectedPoint = MIViewFinder.DetectedPoint

        case insert(String, ASFrame, DetectedPoint) // frame name, frame, detected point

        @MainActor  public func execute(rootFrame root: ASFrame) -> ASFrameCommandResult {
                let result: ASFrameCommandResult
                switch self {
                case .insert(let name, let frame, let dpoint):
                        let command = ASFrameInsertCommand(rootFrame: root)
                        let ecode = command.insert(sourceName: name, sourceFrame: frame, detectedPoint: dpoint)
                        result = ecode.toCommandResult()
                }
                return result
        }
}

public enum ASFrameCommandResult {
        case ok
        case error(String)              // error message
}

private class ASFrameInsertCommand
{
        public typealias DetectedPoint = MIViewFinder.DetectedPoint

        public enum ResultCode {
                case ok
                case fail
                case noTarget

                public func toCommandResult() -> ASFrameCommandResult {
                        switch self {
                        case .ok:       return .ok
                        case .fail:     return .error("Failed to insert frame")
                        case .noTarget: return .error("Can not happen")
                        }
                }
        }

        var mRootFrame: ASFrame

        public init(rootFrame frame: ASFrame) {
                self.mRootFrame = frame
        }

        public func insert(sourceName name: String, sourceFrame frame: ASFrame, detectedPoint dpoint: DetectedPoint) -> ResultCode {
                if childFrameCount(frame: mRootFrame) == 0 {
                        mRootFrame.set(slotName: name, value: .frame(frame))
                        return .ok
                } else {
                        return insert(targetFrame: mRootFrame, sourceName: name, sourceFrame: frame, detectedPoint: dpoint)
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

        private func insert(targetFrame target: ASFrame, sourceName name: String, sourceFrame frame: ASFrame, detectedPoint dpoint: DetectedPoint) -> ResultCode {
                for slotidx in 0..<target.slots.count {
                        let dstslot = target.slots[slotidx]
                        switch dstslot.value {
                        case .frame(let child):
                                if child.frameId() == MFInterfaceTagToFrameId(interfaceTag: dpoint.tag) {
                                        if doInsert(parent: target, childName: dstslot.name, name: name, source: frame, at: dpoint) {
                                                return .ok
                                        } else {
                                                return .fail
                                        }
                                } else {
                                        let ecode = insert(targetFrame: child, sourceName: name, sourceFrame: frame, detectedPoint: dpoint)
                                        switch ecode {
                                        case .ok:
                                                return .ok
                                        case .noTarget:
                                                break // contine this loop
                                        default:
                                                return ecode
                                        }
                                }
                        case .event(_), .path(_), .value(_):
                                break
                        }
                }
                return .noTarget
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
