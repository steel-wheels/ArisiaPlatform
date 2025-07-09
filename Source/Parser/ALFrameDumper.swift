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
        func dump(_ indent: Int = 0) {
                printIndent(indent) ; dump(string: "{\n")

                for name in self.slots.keys.sorted() {
                        if let value = self.value(slotName: name) {
                                printIndent(indent + 1)
                                dump(string: name + ": ")
                                dump(value: value, indent: indent)
                                dump(string: "\n")
                        }
                }

                printIndent(indent) ; dump(string: "}\n")
        }

        private func dump(value: ALFrameValue,  indent: Int) {
                switch value {
                case .value(let val):
                        dump(string: val.toString())
                case .frame(let child):
                        child.dump(indent + 1)
                case .path(let paths):
                        var is1stpath = true
                        for path in paths {
                                if is1stpath {
                                        is1stpath = false
                                } else {
                                        dump(string: ".")
                                }
                                dump(string: path)
                                is1stpath = false
                        }
                case .array(let elms):
                        dump(string: "[")
                        var is1stpath = true
                        for elm in elms {
                                if is1stpath {
                                        is1stpath = false
                                } else {
                                        dump(string: ", ")
                                }
                                dump(value: elm, indent: 0)
                        }
                        dump(string: "]")
                case .text(let str):
                        dump(string: "%{" + str + "}%")
                }
        }

        private func dump(string str: String){
                print(str, terminator: "")
        }

        private func printIndent(_ idt: Int) {
                for _ in 0..<idt {
                        print("    ", terminator: "")
                }
        }
}
