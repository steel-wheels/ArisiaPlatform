/*
 * @file ALStack.swift
 * @description Define ALStack class
 * @par Copyright
 *   Copyright (C) 2025 Steel Wheels Project
 */

import MultiDataKit
import Foundation

public class ALStack
{
        private var mPackageDirectory:          URL
        private var mFrameScriptURLs:           Array<URL>
        private var mFrameTable:                Dictionary<String, ALFrame>

        public var frameScriptURLs: Array<URL> { get{ return mFrameScriptURLs }}

        public init(packageDirectory pkgdir: URL) {
                mPackageDirectory       = pkgdir
                mFrameScriptURLs        = []
                mFrameTable             = [:]
        }

        public func add(frameScriptPath path: String) {
                let path = mPackageDirectory.appending(path: path)
                mFrameScriptURLs.append(path)
        }

        public func loadFrame(at index: Int) -> Result<ALFrame, NSError> {
                guard index < mFrameScriptURLs.count else {
                        let err = MIError.error(errorCode: .fileError, message: "No frame at \(index)")
                        return .failure(err)
                }
                /* load from cache */
                let url = mFrameScriptURLs[index]
                if let frame = mFrameTable[url.path] {
                        return .success(frame)
                }
                /* allocate frame */
                let script: String
                do {
                        script = try String(contentsOf: url, encoding: .utf8)
                } catch {
                        let err = MIError.error(errorCode: .fileError, message: "Failed to load script from \(url.path)")
                        return .failure(err)
                }
                //NSLog("(\(#function): loaded text: \(text)")
                let parser = ALFrameParser()
                switch parser.parse(string: script) {
                case .success(let frame):
                        // save the loaded frame
                        mFrameTable[url.path] = frame
                        return .success(frame)
                case .failure(let err):
                        return .failure(err)
                }
        }
}

