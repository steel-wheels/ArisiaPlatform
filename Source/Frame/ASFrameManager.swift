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
        public static let ClassSlotName        = "class"

        public enum FrameType: String {
                case box                = "Box"
                case button             = "Button"
        }

        private var mRootFrame        : ASFrame

        public var rootFrame: ASFrame { get {
                return mRootFrame
        }}

        public init(){
                switch ASFrameManager.loadBoxFrame() {
                case .success(let frame):
                        mRootFrame = frame
                case .failure(let err):
                        NSLog("[Error] \(MIError.errorToString(error: err)) at \(#file)")
                        mRootFrame      = ASFrame()
                }
        }

        public func add(contentsOf frame: ASFrame){
                for (name, val) in frame.slots {
                        mRootFrame.set(slotName: name, value: val)
                }
        }

        public func add(point pt: CGPoint, name nm: String, frame frm: ASFrame){
                mRootFrame.set(slotName: nm, value: .frame(frm))
        }

        public static func typeOfFrame(source src: ASFrame) -> FrameType? {
                guard let val = src.value(slotName: ClassSlotName) else {
                        NSLog("[Error] No class slot at \(#file)")
                        return nil
                }
                switch val {
                case .value(let sval):
                        switch sval.value {
                        case .stringValue(let str):
                                switch str {
                                case "Box":
                                        return .box
                                case "Button":
                                        return .button
                                default:
                                        NSLog("[Error] Unknown frame class \(str) at \(#file)")
                                }
                        default:
                                break
                        }
                default:
                        break
                }
                return nil
        }

        public static func loadBoxFrame() -> Result<ASFrame, NSError> {
                return loadFrame(fileName: "Frames/Box.as")
        }

        public static func loadButtonFrame() -> Result<ASFrame, NSError> {
                return loadFrame(fileName: "Frames/Button.as")
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
