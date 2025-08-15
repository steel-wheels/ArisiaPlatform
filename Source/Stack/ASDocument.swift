/*
 * @file ASDocyment.swift
 * @description Define ASDocument class
 * @par Copyright
 *   Copyright (C) 2025 Steel Wheels Project
 */

import MultiDataKit
import Foundation

public class ASDocument
{
        private var mManifest:          ASManifest
        private var mStack:             ASStack

        public var stack: ASStack { return mStack }

        public init(manifest man: ASManifest){
                mManifest       = man
                mStack          = ASStack()
        }

        public func loadScripts() -> NSError? {
                mStack.clear()
                for url in mManifest.scriotURLs {
                        /* load from file */
                        let script: String
                        do {
                                script = try String(contentsOf: url, encoding: .utf8)
                        } catch {
                                let err = MIError.error(errorCode: .fileError, message: "Failed to load script from \(url.path)")
                                return err
                        }
                        /* parse the script */
                        let parser = ASFrameParser()
                        switch parser.parse(string: script) {
                        case .success(let frame):
                                mStack.append(frame: frame)
                        case .failure(let err):
                                return err
                        }
                }
                return nil
        }

        public static func load(packageDirectory pkgdir: URL) -> Result<ASDocument, NSError> {
                switch ASManifest.load(packageDirectory: pkgdir) {
                case .success(let manifest):
                        //NSLog("MANIFEST: \(manifest.toString())")
                        let newdoc = ASDocument(manifest: manifest)
                        if let err = newdoc.loadScripts() {
                                return .failure(err)
                        } else {
                                return .success(newdoc)
                        }
                case .failure(let err):
                        return .failure(err)
                }
        }
}
