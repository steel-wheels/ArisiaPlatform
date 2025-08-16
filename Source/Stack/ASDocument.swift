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
                for path in mManifest.scriptPaths {
                        /* load from file */
                        let script: String
                        let url = mManifest.packageDirectory.appendingPathComponent(path)
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
                                NSLog("loadScript -> frame -> \(frame.encode())")
                                mStack.append(path: path, frame: frame)
                        case .failure(let err):
                                return err
                        }
                }
                return nil
        }

        public func save(to pkgdir: URL) -> NSError? {
                let fmgr = FileManager.default

                /* remove directory if it exist */
                if fmgr.fileExists(atPath: pkgdir.path) {
                        do {
                                try fmgr.removeItem(at: pkgdir)
                        } catch {
                                return MIError.error(errorCode: .fileError, message: "Failed to remove \(pkgdir.path)")
                        }
                }

                /* make directory */
                do {
                        try fmgr.createDirectory(at: pkgdir, withIntermediateDirectories: false)
                } catch {
                        return MIError.error(errorCode: .fileError, message: "Failed to create \(pkgdir.path)")
                }

                /* put manifest file */
                let manfile  = pkgdir.appendingPathComponent(ASManifest.FileName)
                let manifest = mManifest.toString().data(using: .utf8)
                guard fmgr.createFile(atPath: manfile.path, contents: manifest) else {
                        return MIError.error(errorCode: .fileError, message: "Failed to create \(manfile.path)")
                }

                /* save frames */
                for frec in mStack.frameRecords {
                        let url = pkgdir.appendingPathComponent(frec.path)
                        let scr = frec.frame.encode()
                        if !fmgr.createFile(atPath: url.path, contents: scr.data(using: .utf8)) {
                                return MIError.error(errorCode: .fileError, message: "Failed to create \(url.path)")
                        }
                }

                /* replace package directory */
                mManifest.set(packageDirectory: pkgdir)

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
