/*
 * @file ASStack.swift
 * @description Define ASStack class
 * @par Copyright
 *   Copyright (C) 2025 Steel Wheels Project
 */

import MultiDataKit
import Foundation

public class ASStack
{
        private var mPackage:           ASPackage
        private var mFrames:            Dictionary<String, ASFrame> // File name in package, Frame

        public init(package pkg: ASPackage) {
                mPackage        = pkg
                mFrames         = [:]
        }

        public var package: ASPackage { get {
                return mPackage
        }}

        public var scriptFileNames: Array<String> {
                return mPackage.scriptFileNames ;
        }

        public func scriptFileName(at index: Int) -> String? {
                return mPackage.scriptFileName(at: index)
        }

        public func script(fileName name: String) -> Result<String, NSError> {
                return mPackage.script(fileName: name)
        }

        public func frame(fileName fname: String) -> Result<ASFrame, NSError> {
                if let frm = mFrames[fname] {
                        return .success(frm)
                }
                switch self.script(fileName: fname) {
                case .success(let script):
                        let parser = ASFrameParser()
                        switch parser.parse(string: script) {
                        case .success(let frm):
                                return .success(frm)
                        case .failure(let err):
                                return .failure(err)
                        }
                case .failure(let err):
                        return .failure(err)
                }
        }

        public func setFrame(fileName name: String, frame frm: ASFrame){
                mFrames[name] = frm
                mPackage.setScript(fileName: name, script: frm.encode())
        }

        public func save() -> NSError? {
                return mPackage.save()
        }

        public func save(to pkgdir: URL) -> NSError? {
                return mPackage.save(to: pkgdir)
        }
}
