/*
 * @file ASManifest.swift
 * @description Define ASManifest class
 * @par Copyright
 *   Copyright (C) 2025 Steel Wheels Project
 */

import MultiDataKit
import Foundation

public class ASManifest
{
        public static let FileName = "manifest.json"

        static let ScriptsDirectoryName = "scripts"
        static let ImagesDirectoryName  = "images"

        private var mScriptFileNames: Array<String>
        private var mImageFileNames:  Array<String>

        public init() {
                mScriptFileNames = []
                mImageFileNames  = []
        }

        public func addScriptFileName(name nm: String){
                mScriptFileNames.append(nm)
        }

        public var scriptFileNames: Array<String> { get {
                return mScriptFileNames
        }}

        public func scriptFileName(at index: Int) -> String? {
                if 0 <= index && index < mScriptFileNames.count {
                        return mScriptFileNames[index] ;
                } else {
                        return nil
                }
        }

        public func addImagesFileName(name nm: String){
                mImageFileNames.append(nm)
        }

        public var imageFileNames: Array<String> { get {
                return mImageFileNames
        }}

        public func imageFileName(at index: Int) -> String? {
                if 0 <= index && index < mImageFileNames.count {
                        return mImageFileNames[index] ;
                } else {
                        return nil
                }
        }

        public func save(to pkgdir: URL) -> NSError? {
                let manfile = pkgdir.appending(path: ASManifest.FileName)

                var text = "{\n"

                let scrnames = mScriptFileNames.map{ "\"" + $0 + "\"" }
                text += "\(ASManifest.ScriptsDirectoryName): [\n"
                text += "\t" + scrnames.joined(separator: ",") + "\n"
                text += "]\n"

                let imgnames = mImageFileNames.map{ "\"" + $0 + "\"" }
                text += "\(ASManifest.ImagesDirectoryName): [\n"
                text += "\t" + imgnames.joined(separator: ",") + "\n"
                text += "]\n"

                text += "}\n"

                do {
                        try text.write(to: manfile, atomically: false, encoding: .utf8)
                        return nil
                } catch {
                        return MIError.error(errorCode: .fileError, message: "Failed to save info URL: \(manfile.path)")
                }
        }

        public static func load(from pkgdir: URL) -> Result<ASManifest, NSError> {
                let manfile = pkgdir.appending(path: ASManifest.FileName)

                /* read the manifest file */
                let script: String
                do {
                        script = try String(contentsOf: manfile, encoding: .utf8)
                } catch {
                        let err = MIError.error(errorCode: .fileError, message: "Failed to load \(ASManifest.FileName) from \(manfile.path)")
                        return .failure(err)
                }

                /* parse the manifest file */
                /* parse manifest file */
                switch MIJsonFile.load(string: script) {
                case .success(let value):
                        return ASManifest.load(value: value, packageDir: pkgdir)
                case .failure(let err):
                        return .failure(err)
                }
        }

        private static func load(value val: MIValue, packageDir pkgdir: URL) -> Result<ASManifest, NSError> {
                switch val.value {
                case .dictionaryValue(let dict):
                        let manifest = ASManifest()
                        /* load script section */
                        switch load(value: dict, category: ASManifest.ScriptsDirectoryName) {
                        case .success(let names):
                                if names.count > 0 {
                                        for name in names {
                                                manifest.addScriptFileName(name: name)
                                        }
                                } else {
                                        let err = MIError.error(errorCode: .fileError, message: "\"\(ASManifest.ScriptsDirectoryName)\" section must have at least one file path")
                                        return .failure(err)
                                }
                        case .failure(let err):
                                return .failure(err)
                        }
                        /* load image section */
                        switch load(value: dict, category: ASManifest.ImagesDirectoryName) {
                        case .success(let names):
                                for name in names {
                                        manifest.addImagesFileName(name: name)
                                }
                        case .failure(let err):
                                return .failure(err)
                        }
                        return .success(manifest)
                default:
                        let err = MIError.error(errorCode: .fileError, message: "Dictionary info is required")
                        return .failure(err)
                }
        }

        private static func load(value dict: Dictionary<String, MIValue>, category cat: String) -> Result<Array<String>, NSError> {
                /* parse section */
                guard let scrval = dict[cat] else {
                        return .success([])
                }

                /* parse content of "scripts" section */
                var result: Array<String> = []
                switch scrval.value {
                case .arrayValue(let svals):
                        for sval in svals {
                                switch sval.value {
                                case .stringValue(let str):
                                        result.append(str)
                                default:
                                        let err = MIError.error(errorCode: .fileError, message: "The item in \(cat) section must have path string")
                                        return .failure(err)
                                }
                        }
                        return .success(result)
                default:
                        let err = MIError.error(errorCode: .fileError, message: "The scripts section in \(ASManifest.FileName) must have array of URLs")
                        return .failure(err)
                }
        }
}

