/*
 * @file ParserTest.swift
 * @description Define ParserTest function
 * @par Copyright
 *   Copyright (C) 2025 Steel Wheels Project
 */

import ArisiaScript
import MultiDataKit
import Foundation

public func parserTest() -> Bool
{
        var result = true
        result = testParser(script: "{}") && result
        return result
}

private func testParser(script scr: String) -> Bool
{
        print("[script] \(scr)")

        let parser = ALFrameParser()
        let result: Bool
        switch parser.parse(string: scr) {
        case .success(let frame):
                print("[Parse result]")
                frame.dump()
                result = true
        case .failure(let err):
                print("[Error] " + MIError.errorToString(error: err))
                result = false
        }
        return result
}
