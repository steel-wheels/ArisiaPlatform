/*
 * @file ALStackLoader.swift
 * @description Define ALStackLoader class
 * @par Copyright
 *   Copyright (C) 2025 Steel Wheels Project
 */

import MultiDataKit
import Foundation

public class ALStackLoader
{
        public static let ManifestFileName = "manifest.json"

        public static func load(packageDirectory pkgdir: URL) -> Result<ALStack, NSError> {
                /* load manifest file */
                let mfile = pkgdir.appending(path: ALStackLoader.ManifestFileName)
                let script: String
                do {
                        script = try String(contentsOf: mfile, encoding: .utf8)
                } catch {
                        let err = MIError.error(errorCode: .fileError, message: "Failed to load \(ALStackLoader.ManifestFileName) from \(mfile.path)")
                        return .failure(err)
                }
                /* parse manifest file */
                switch MIJsonFile.load(string: script) {
                case .success(let value):
                        return ALStackLoader.load(value: value, packageDir: pkgdir)
                case .failure(let err):
                        return .failure(err)
                }
        }

        private static func load(value val: MIValue, packageDir pkgdir: URL) -> Result<ALStack, NSError> {
                switch val.value {
                case .dictionaryValue(let dict):
                        let result = ALStack(packageDirectory: pkgdir)

                        /* parse "scripts" section */
                        let scrfiles: Array<String>
                        if let scrval = dict["scripts"] {
                                switch ALStackLoader.load(scripts: scrval) {
                                case .success(let files):
                                        scrfiles = files
                                case .failure(let err):
                                        return .failure(err)
                                }
                        } else {
                                let err = MIError.error(errorCode: .fileError, message: "\"scripts\" section is required")
                                return .failure(err)
                        }
                        for scrfile in scrfiles {
                                result.add(frameScriptPath: scrfile)
                        }
                        return .success(result)
                default:
                        let err = MIError.error(errorCode: .fileError, message: "Dictionary info is required")
                        return .failure(err)
                }
        }

        private static func load(scripts val: MIValue) -> Result<Array<String>, NSError> {
                switch val.value {
                case .arrayValue(let elms):
                        var result: Array<String> = []
                        for elm in elms {
                                switch elm.value {
                                case .stringValue(let str):
                                        result.append(str)
                                default:
                                        let err = MIError.error(errorCode: .fileError, message: "The URL of script is required")
                                        return .failure(err)
                                }
                        }
                        return .success(result)
                default:
                        let err = MIError.error(errorCode: .fileError, message: "Array of script URLs are required")
                        return .failure(err)
                }
        }
}
