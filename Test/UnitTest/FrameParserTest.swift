/*
 * @file FrameParserTest.swift
 * @description Define FrameParserTest function
 * @par Copyright
 *   Copyright (C) 2025 Steel Wheels Project
 */

import ArisiaScript
import MultiDataKit
import Foundation

public func frameParserTest() -> Bool
{
        var result = true

        let script0 = "{}"
        let script1 =     "{\n"
                        + " a : 10\n"
                        + " b : -10\n"
                        + " c : -12.3\n"
                        + " d : \"string\"\n"
                        + " e : true\n"
                        + " f : false\n"
                        + " g : nil\n"
                        + "}\n"
        let script2 =    "{\n"
                        + " a: p0\n"
                        + " b: p0.p1\n"
                        + " c: [1, 2]\n"
                        + "}"
        result = testParser(script: script0) && result
        result = testParser(script: script1) && result
        result = testParser(script: script2) && result
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
                print(frame.encode())
                result = true
        case .failure(let err):
                print("[Error] " + MIError.errorToString(error: err))
                result = false
        }
        return result
}
