/*
 * @file StackParserTest.swift
 * @description Define StackParserTest function
 * @par Copyright
 *   Copyright (C) 2025 Steel Wheels Project
 */

import ArisiaScript
import MultiDataKit
import Foundation

public func stackParserTest() -> Bool
{
        let script0 = "{\n"
                    + "  scripts: [\"a\"]\n"
                    + "}\n"
        let result0 = testParser(script: script0)
        return result0
}

private func testParser(script scr: String) -> Bool
{
        print("[script] \(scr)")

        let result: Bool
        switch ALStackLoader.load(script: scr) {
        case .success(let stack):
                print("[Parse result]")
                print(stack.encode())
                result = true
        case .failure(let err):
                print("[Error] " + MIError.errorToString(error: err))
                result = false
        }
        return result
}

