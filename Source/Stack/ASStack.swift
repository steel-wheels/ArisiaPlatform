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
        private var mFrames:            Dictionary<String, ASFrame> // File name, Frame

        private init(package pkg: ASPackage) {
                mPackage        = pkg
                mFrames         = [:]
        }

        public static func loadNewStack() -> Result<ASStack, NSError> {
                switch ASPackage.loadNewPackage() {
                case .success(let pkg):
                        let stack = ASStack(package: pkg)
                        return stack.setup()
                case .failure(let err):
                        return .failure(err)
                }
        }

        public static func load(from pkgdir: URL) -> Result<ASStack, NSError> {
                switch ASPackage.load(from: pkgdir) {
                case .success(let pkg):
                        let stack = ASStack(package: pkg)
                        return stack.setup()
                case .failure(let err):
                        return .failure(err)
                }
        }

        private func setup() -> Result<ASStack, NSError> {
                for sname in mPackage.scriptFileNames {
                        switch mPackage.script(fileName: sname) {
                        case .success(let scr):
                                let parser = ASFrameParser()
                                switch parser.parse(string: scr) {
                                case .success(let frame):
                                        mFrames[sname] = frame
                                case .failure(let err):
                                        return .failure(err)
                                }
                        case .failure(let err):
                                return .failure(err)
                        }
                }
                return .success(self)
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

        public func frame(name fname: String) -> ASFrame? {
                return mFrames[fname]
        }

        public func frame(at index: Int) -> ASFrame? {
                if let fname = scriptFileName(at: index) {
                        return frame(name: fname)
                } else {
                        return nil
                }
        }

        public func updateFrame(index idx: Int) {
                if let fname = scriptFileName(at: idx) {
                        if let frame = frame(name: fname) {
                                let scr = frame.encode()
                                mPackage.setScript(fileName: fname, script: scr)
                        }
                }
        }

        public func save(to url: URL) -> NSError? {
                return mPackage.save(to: url)
        }

        /*
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
        }*/

}
