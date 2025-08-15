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

        private var mPackageDir:        URL
        private var mScriptURLs:        Array<URL>

        public var packageDirectory: URL { get { return mPackageDir }}
        public var scriotURLs: Array<URL> { get { return mScriptURLs }}

        public init(packageDirectory pkgdir: URL){
                mPackageDir     = pkgdir
                mScriptURLs     = []
        }

        public func add(scriptURL url: URL){
                mScriptURLs.append(url)
        }

        public func toString() -> String {
                var result = "manifest: {\n"

                result += "  scripts: [\n"
                for scr in mScriptURLs {
                        result += "    \"\(scr.path)\"\n"
                }
                result += "  }\n"

                result += "}\n"
                return result
        }

        public static func load(packageDirectory pkgdir: URL) -> Result<ASManifest, NSError> {
                /* load manifest file */
                let mfile = pkgdir.appending(path: ASManifest.FileName)
                let script: String
                do {
                        script = try String(contentsOf: mfile, encoding: .utf8)
                } catch {
                        let err = MIError.error(errorCode: .fileError, message: "Failed to load \(ASManifest.FileName) from \(mfile.path)")
                        return .failure(err)
                }
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
                        let result = ASManifest(packageDirectory: pkgdir)

                        /* parse "scripts" section */
                        guard let scrval = dict["scripts"] else {
                                let err = MIError.error(errorCode: .fileError, message: "\"scripts\" section is required")
                                return .failure(err)
                        }
                        switch scrval.value {
                        case .arrayValue(let svals):
                                for sval in svals {
                                        switch sval.value {
                                        case .stringValue(let str):
                                                let url = URL(fileURLWithPath: str)
                                                result.add(scriptURL: url)
                                        default:
                                                let err = MIError.error(errorCode: .fileError, message: "The item scripts section in \(ASManifest.FileName) must have string URL")
                                                return .failure(err)
                                        }
                                }
                                return .success(result)
                        default:
                                let err = MIError.error(errorCode: .fileError, message: "The scripts section in \(ASManifest.FileName) must have array of URLs")
                                return .failure(err)
                        }
                default:
                        let err = MIError.error(errorCode: .fileError, message: "Dictionary info is required")
                        return .failure(err)
                }
        }
}

