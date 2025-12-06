/*
 * @file ASFrame.swift
 * @description Define ASFrame class
 * @par Copyright
 *   Copyright (C) 2025 Steel Wheels Project
 */

import MultiDataKit
import MultiFrameKit
import MultiUIKit
import Foundation

@MainActor public class ASFrameManager
{
        public typealias DetectedPoint = MIViewFinder.DetectedPoint

        private var mRootFrame          : ASFrame

        public var rootFrame: ASFrame { get {
                return mRootFrame
        }}

        public init(frame frm: ASFrame){
                mRootFrame   = frm
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
