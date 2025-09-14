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
                for (name, val) in frame.slots {
                        mRootFrame.set(slotName: name, value: val)
                }
        }

        public func add(point pt: CGPoint, name nm: String, frame frm: ASFrame){
                mUniqueIndex = ASFrame.setFrameIds(frame: frm, frameId: mUniqueIndex)
                mRootFrame.set(slotName: nm, value: .frame(frm))
        }

        public func search(coreTag ctag: Int) -> ASFrame? {
                return search(frame: mRootFrame, coreTag: ctag)
        }

        private func search(frame frm: ASFrame, coreTag ctag: Int) -> ASFrame? {
                if frm.frameId() == ctag {
                        return frm
                }
                for (_, val) in frm.slots {
                        switch val {
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
                if let resdir = FileManager.default.resourceDirectory(forClass: ASFrame.self) {
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
