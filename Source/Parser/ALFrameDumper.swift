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

                for (name, value) in self.slots {
                        printIndent(indent + 1)
                        dump(string: name + ": ")

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
                        case .text(let str):
                                dump(string: "%{" + str + "}%")
                        }

                        dump(string: "\n")
                }

                printIndent(indent) ; dump(string: "}\n")
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
