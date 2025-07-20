/*
 * @file StackParserTest.swift
 * @description Define StackParserTest function
 * @par Copyright
 *   Copyright (C) 2025 Steel Wheels Project
 */

import ArisiaPlatform
import MultiDataKit
import Foundation

public func stackParserTest() -> Bool
{
        guard let resdir = FileManager.default.resourceDirectory(forClass: ASStack.self) else {
                print("[Error] No resource directory")
                return false
        }
        let pkgdir = resdir.appending(path: "Tests/Hello.astack")
        let result0 = testParser(packageDirectory: pkgdir)
        return result0
}

private func testParser(packageDirectory pkdir: URL) -> Bool
{
        let result: Bool
        switch ASStackLoader.load(packageDirectory: pkdir) {
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

