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
                                /* allocate frame ids */
                                let _ = ASFrameCommand.initFrameIds(frame: frame)
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
