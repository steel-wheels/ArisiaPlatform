/*
 * @file UnitTest.swift
 * @description Define UnitTest application
 * @par Copyright
 *   Copyright (C) 2025 Steel Wheels Project
 */

import ArisiaPlatform
import Foundation

func UnitTest() -> Void
{
        let result0 = frameParserTest()
        let result1 = stackParserTest()
        if result0 && result1 {
                print("[Summary] OK")
        } else {
                print("[Summary] Error")
        }
}

print("UnitTest")
UnitTest()


