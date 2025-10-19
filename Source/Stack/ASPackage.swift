/*
 * @file ASDocyment.swift
 * @description Define ASDocument class
 * @par Copyright
 *   Copyright (C) 2025 Steel Wheels Project
 */

import MultiDataKit
import MultiUIKit
#if os(OSX)
import  AppKit
#else   // os(OSX)
import  UIKit
#endif  // os(OSX)
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
        private var mImages:            Dictionary<String, MIImage>     // file name. Image

        /* Use loadNewPackage or loadPackage() to allocate thie object */
        private init(packageDirectory pkgdir: PackageDirectory, manifest mani: ASManifest) {
                mPackageDirectory = pkgdir
                mManifest         = mani
                mScripts          = [:]
                mImages           = [:]
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

        public func setImage(fileName fname: String, image img: MIImage) {
                mImages[fname] = img
        }

        public var imageFileNames: Array<String> {
                return mManifest.imageFileNames
        }

        public func imageFileName(at index: Int) -> String? {
                return mManifest.imageFileName(at: index)
        }

        public func image(fileName fname: String) -> Result<MIImage, NSError> {
                if let img = mImages[fname] {
                        return .success(img)
                }
                let path = mPackageDirectory.toURL.appending(path: fname)
                if let img = MIImage.load(from: path) {
                        mImages[fname] = img
                        return .success(img)
                } else {
                        let err = MIError.error(errorCode: .fileError, message: "Failed to read \(path.path)", atFile: #file, function: #function)
                        return .failure(err)
                }
        }

        public struct ImportedImage {
                public var filePath:    String
                public var fileURL:     URL

                public init(path pth: String, URL u: URL) {
                        self.filePath   = pth
                        self.fileURL    = u
                }
        }

        public func importImage(from src: URL) -> Result<ImportedImage, NSError> { // <local-path, error>
                let fmgr    = FileManager.default
                let fname   = src.lastPathComponent

                /* copy into the package directory */
                let dst = mPackageDirectory.toURL.appending(path: fname)
                if let err = fmgr.copyFile(from: src, to: dst) {
                        return .failure(err)
                }
                /* add the file name into image section in manifest */
                mManifest.addImagesFileName(name: fname)
                /* return */
                return .success(ImportedImage(path: fname, URL: dst))
        }

        public func save(to pkgdir: URL) -> NSError? {
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
                for fname in self.scriptFileNames {
                        switch self.script(fileName: fname) {
                        case .success(let scr):
                                let scrurl = pkgdir.appending(path: fname)
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
                /* copy image files */
                if pkgdir != mPackageDirectory.toURL {
                        for fname in self.imageFileNames {
                                let srcfile = mPackageDirectory.toURL.appending(path: fname)
                                let dstfile = pkgdir.appending(path: fname)
                                if let err = FileManager.default.copyFile(from: srcfile, to: dstfile) {
                                        return err
                                }
                        }
                }

                /* replace root dir */
                mPackageDirectory = .user(pkgdir)
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

