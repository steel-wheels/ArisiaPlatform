/*
 * @file UnitTest.swift
 * @description Define UnitTest application
 * @par Copyright
 *   Copyright (C) 2025 Steel Wheels Project
 */

import ArisiaScript
import Foundation

func UnitTest() -> Void
{
        var result = true ;
        result = parserTest() && result
        if result {
                print("[Summary] OK")
        } else {
                print("[Summary] Error")
        }
}

print("UnitTest")
UnitTest()


