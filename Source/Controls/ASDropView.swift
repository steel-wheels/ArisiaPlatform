/**
 * @file       ASFDropView.swift
 * @brief      Define ASDropView class
 * @par Copyright
 *   Copyright (C) 2025 Steel Wheels Project
 */

import MultiFrameKit
import MultiUIKit
import JavaScriptCore
#if os(OSX)
import  AppKit
#else   // os(OSX)
import  UIKit
#endif  // os(OSX)

public class ASDropView: MFDropView
{
        public typealias CallbackFunction = (_ frame: ASFrame) -> Void

        public var droppingCallback: CallbackFunction? = nil

        #if os(OSX)
        open override func didDropped(point pt: CGPoint, symbol sym: MISymbol) {
                switch sym {
                case .buttonHorizontalTopPress:
                        switch loadFrame(fileName: "Frames/Button.as"){
                        case .success(let frame):
                                if let cbfunc = droppingCallback {
                                        cbfunc(frame)
                                } else {
                                        NSLog("DropCallback: \(frame.encode())")
                                }
                        case .failure(let err):
                                NSLog("[Error] " + MIError.toString(error: err))
                        }
                        break
                default:
                        NSLog("[Error] The drop item is ignored: \(sym.name)")
                }
        }
        #endif

        private func loadFrame(fileName fname: String) -> Result<ASFrame, NSError> {
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

