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

        private var mScriptFileNames: Array<String>

        public init() {
                mScriptFileNames = []
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

        public func save(to pkgdir: URL) -> NSError? {
                let manfile = pkgdir.appending(path: ASManifest.FileName)

                let pathstrs = mScriptFileNames.map{ "\"" + $0 + "\"" }

                var text = "{\n"
                text += "  scripts: [\n"
                text += pathstrs.joined(separator: ",\n")
                text += "  \n]\n"
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

                        /* parse "scripts" section */
                        guard let scrval = dict["scripts"] else {
                                let err = MIError.error(errorCode: .fileError, message: "\"scripts\" section is required")
                                return .failure(err)
                        }
                        /* parse content of "scripts" section */
                        switch scrval.value {
                        case .arrayValue(let svals):
                                for sval in svals {
                                        switch sval.value {
                                        case .stringValue(let str):
                                                manifest.addScriptFileName(name: str)
                                        default:
                                                let err = MIError.error(errorCode: .fileError, message: "The item scripts section in \(ASManifest.FileName) must have string URL")
                                                return .failure(err)
                                        }
                                }
                                return .success(manifest)
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

