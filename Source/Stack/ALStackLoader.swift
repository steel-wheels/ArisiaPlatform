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
        public static func load(from url: URL) -> Result<ALStack, NSError> {
                switch MIJsonFile.load(from: url) {
                case .success(let value):
                        return ALStackLoader.load(value: value)
                case .failure(let err):
                        return .failure(err)
                }
        }

        public static func load(script src: String) -> Result<ALStack, NSError> {
                switch MIJsonFile.load(string: src) {
                case .success(let value):
                        return ALStackLoader.load(value: value)
                case .failure(let err):
                        return .failure(err)
                }
        }

        private static func load(value val: MIValue) -> Result<ALStack, NSError> {
                switch val.value {
                case .dictionaryValue(let dict):
                        let result = ALStack()

                        /* parse "scripts" section */
                        let scripts: Array<URL>
                        if let scrval = dict["scripts"] {
                                switch ALStackLoader.load(scripts: scrval) {
                                case .success(let urls):
                                        scripts = urls
                                case .failure(let err):
                                        return .failure(err)
                                }
                        } else {
                                let err = MIError.error(errorCode: .fileError, message: "\"scripts\" section is required")
                                return .failure(err)
                        }
                        result.set(frameURLs: scripts)

                        return .success(result)
                default:
                        let err = MIError.error(errorCode: .fileError, message: "Dictionary info is required")
                        return .failure(err)
                }
        }

        private static func load(scripts val: MIValue) -> Result<Array<URL>, NSError> {
                switch val.value {
                case .arrayValue(let elms):
                        var result: Array<URL> = []
                        for elm in elms {
                                switch elm.value {
                                case .stringValue(let str):
                                        let url = URL(fileURLWithPath: str)
                                        result.append(url)
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
