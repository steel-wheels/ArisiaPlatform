/*
 * @file ALFrameDumper.swift
 * @description Define ALFrameEncoder class
 * @par Copyright
 *   Copyright (C) 2025 Steel Wheels Project
 */

import MultiDataKit
import Foundation

public extension ALFrame
{
        func encode() -> String {
                return encode(indent: 0)
        }

        private func encode(indent: Int) -> String {
                var result: String = indentString(indent: indent) + "{\n"

                for name in self.slots.keys.sorted() {
                        if let value = self.value(slotName: name) {
                                result += indentString(indent: indent + 1) + name + ": "
                                result += encode(value: value, indent: indent) + "\n"
                        }
                }

                result += indentString(indent: indent) + "}\n"
                return result
        }

        private func encode(value: ALFrameValue,  indent: Int) -> String {
                let result: String
                switch value {
                case .value(let val):
                        result = val.toString()
                case .frame(let child):
                        result = child.encode(indent: indent+1)
                case .path(let paths):
                        var locres: String = ""
                        var is1stpath = true
                        for path in paths {
                                if is1stpath {
                                        is1stpath = false
                                } else {
                                        locres += "."
                                }
                                locres += path
                                is1stpath = false
                        }
                        result = locres
                case .array(let elms):
                        var locres = "["
                        var is1stpath = true
                        for elm in elms {
                                if is1stpath {
                                        is1stpath = false
                                } else {
                                        locres += ", "
                                }
                                locres += encode(value: elm, indent: 0)
                        }
                        result = locres + "]"
                case .text(let str):
                        result = "%{" + str + "}%"
                }
                return result
        }

        private func indentString(indent idt: Int) -> String {
                var result = ""
                for _ in 0..<idt {
                        result += "    "
                }
                return result
        }
}
