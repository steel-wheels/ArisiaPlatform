/*
 * @file ASFrameDumper.swift
 * @description Define ASFrameEncoder class
 * @par Copyright
 *   Copyright (C) 2025 Steel Wheels Project
 */

import MultiDataKit
import Foundation

public extension ASFrame
{
        func encode() -> String {
                return encode(indent: 0)
        }

        private func encode(indent: Int) -> String {
                var result: String = indentString(indent: indent) + "{\n"

                for slot in self.slots {
                        result += indentString(indent: indent + 1) + slot.name + ": "
                        result += encode(value: slot.value, indent: indent) + "\n"
                }

                result += indentString(indent: indent) + "}\n"
                return result
        }

        private func encode(value: ASFrameValue,  indent: Int) -> String {
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
                case .event(let str):
                        result = "event() %{" + str + "}%"
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
