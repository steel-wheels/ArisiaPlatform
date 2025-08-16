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
        private var mScriptPaths:       Array<String>   // file offsets against the package dir

        public var packageDirectory: URL           { get { return mPackageDir  }}
        public var scriptPaths:      Array<String> { get { return mScriptPaths }}

        public init(packageDirectory pkgdir: URL){
                mPackageDir     = pkgdir
                mScriptPaths    = []
        }

        public func set(packageDirectory url: URL){
                mPackageDir = url
        }

        public func add(scriptPath pth: String){
                mScriptPaths.append(pth)
        }

        public func toString() -> String {
                let pathstrs = mScriptPaths.map{ "\"" + $0 + "\"" }

                var result = "{\n"
                result += "  scripts: [\n"
                result += pathstrs.joined(separator: ",\n")
                result += "  \n]\n"

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
                                                result.add(scriptPath: str)
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

