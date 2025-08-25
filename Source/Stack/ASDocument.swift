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
        private var mResource:          ASResource
        private var mStack:             ASStack

        public var stack:    ASStack    { return mStack }
        public var resource: ASResource { return mResource }

        public init(resource res: ASResource){
                mResource       = res
                mStack          = ASStack()
        }

        public func loadScripts() -> NSError? {
                mStack.clear()
                for path in mResource.scriptPaths {
                        /* load from file */
                        let script: String
                        let url = mResource.packageDirectory.appendingPathComponent(path)
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

                /* put resource file */
                let manfile  = pkgdir.appendingPathComponent(ASResource.FileName)
                let manifest = mResource.toString().data(using: .utf8)
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
                mResource.set(packageDirectory: pkgdir)

                return nil
        }

        public static func load(packageDirectory pkgdir: URL) -> Result<ASDocument, NSError> {
                switch ASResource.load(packageDirectory: pkgdir) {
                case .success(let resource):
                        //NSLog("MANIFEST: \(manifest.toString())")
                        let newdoc = ASDocument(resource: resource)
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
