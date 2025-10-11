/*
 * @file ASDocyment.swift
 * @description Define ASDocument class
 * @par Copyright
 *   Copyright (C) 2025 Steel Wheels Project
 */

import MultiDataKit
import Foundation

public class ASPackage
{
        public enum PackageDirectory {
                case temporary(URL)
                case user(URL)

                public var toURL: URL {
                        let result: URL
                        switch self {
                        case .temporary(let url): result = url
                        case .user(let url):      result = url
                        }
                        return result
                }
        }

        private var mPackageDirectory:  PackageDirectory
        private var mManifest:          ASManifest
        private var mScripts:           Dictionary<String, String>      // File name, Script

        /* Use loadNewPackage or loadPackage() to allocate thie object */
        private init(packageDirectory pkgdir: PackageDirectory, manifest mani: ASManifest) {
                mPackageDirectory = pkgdir
                mManifest         = mani
                mScripts          = [:]
        }

        public func localToFullPath(path pth: String) -> URL {
                return mPackageDirectory.toURL.appending(path: pth)
        }

        public func setScript(fileName fname: String, script scr: String) {
                mScripts[fname] = scr
        }

        public var scriptFileNames: Array<String> {
                return mManifest.scriptFileNames
        }

        public func scriptFileName(at index: Int) -> String? {
                return mManifest.scriptFileName(at: index)
        }

        public func script(fileName fname: String) -> Result<String, NSError> {
                if let scr = mScripts[fname] {
                        return .success(scr)
                }
                let fpath = mPackageDirectory.toURL.appending(path: fname)
                do {
                        let scr = try String(contentsOf: fpath, encoding: .utf8)
                        mScripts[fname] = scr
                        return .success(scr)
                } catch {
                        let err = MIError.error(errorCode: .fileError, message: "Failed to read \(fpath.path)", atFile: #file, function: #function)
                        return .failure(err)
                }
        }

        public func save() -> NSError? {
                return saveFile(to: mPackageDirectory.toURL)
        }

        public func save(to pkgdir: URL) -> NSError? {
                return saveFile(to: pkgdir)
        }

        private func saveFile(to pkgdir: URL) -> NSError? {
                let fmgr = FileManager.default

                /* If the directory is not exist, make it */
                if !fmgr.fileExists(atPath: pkgdir.path) {
                        if let err = fmgr.createDirectory(at: pkgdir) {
                                return err
                        }
                }
                /* save the manifest files */
                if let err = mManifest.save(to: pkgdir) {
                        return err
                }
                /* save script files */
                for fname in mManifest.scriptFileNames {
                        switch self.script(fileName: fname) {
                        case .success(let scr):
                                let scrurl = mPackageDirectory.toURL.appending(path: fname)
                                do {
                                        try scr.write(to: scrurl, atomically: false, encoding: .utf8)
                                } catch {
                                        let err = MIError.error(errorCode: .fileError, message: "Failed to save \(scrurl.path)", atFile: #file, function: #function)
                                        return err
                                }
                        case .failure(let err):
                                return err
                        }
                }
                return nil
        }

        public static func loadNewPackage() -> Result<ASPackage, NSError> {
                /* Copy default stack in the resource into temporary directory */
                guard let resdir = FileManager.default.resourceDirectory(forClass: ASPackage.self) else {
                        let err = MIError.error(errorCode: .fileError, message: "No resource directory", atFile: #file, function: #function)
                        NSLog("lNP 1")
                        return .failure(err)
                }
                let resstack = resdir.appending(path: "Stacks/Default.astack")

                let tempdir = URL(fileURLWithPath: NSTemporaryDirectory())
                let tempstack = tempdir.appending(path: "temporary.astack")

                if let err = FileManager.default.copyFile(from: resstack, to: tempstack) {
                        return .failure(err)
                }
                return loadPackage(from: .temporary(tempstack))
        }

        public static func load(from pkgdir: URL) -> Result<ASPackage, NSError> {
                return loadPackage(from: .user(pkgdir))
        }

        private static func loadPackage(from dir: PackageDirectory) -> Result<ASPackage, NSError> {
                let pkgdir = dir.toURL

                /* parse manifest file */
                let manifest: ASManifest
                switch ASManifest.load(from: pkgdir) {
                case .success(let result):
                        manifest = result
                case .failure(let err):
                        return .failure(err)
                }

                /* check file existence */
                if let err = ASPackage.checkScriptFiles(manifest: manifest, packageDirectory: pkgdir){
                        return .failure(err)
                }

                let package = ASPackage(packageDirectory: dir, manifest: manifest)
                return .success(package)
        }

        private static func checkScriptFiles(manifest man: ASManifest, packageDirectory pkgdir: URL) -> NSError? {
                for file in man.scriptFileNames {
                        let fpath = pkgdir.appending(path: file)
                        if !FileManager.default.fileExists(atPath: fpath.path) {
                                let err = MIError.error(errorCode: .fileError, message: "The script file \(file) is not exit", atFile: #file, function: #function)
                                return err
                        }
                }
                return nil
        }
}

