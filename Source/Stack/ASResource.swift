/*
 * @file ASResource.swift
 * @description Define ASResource class
 * @par Copyright
 *   Copyright (C) 2025 Steel Wheels Project
 */

import MultiDataKit
import MultiUIKit
import Foundation
#if os(OSX)
import  AppKit
#else   // os(OSX)
import  UIKit
#endif  // os(OSX)

public class ASResource
{
        public init(){
        }

        public static func URLOfNullImage() -> URL {
                if let resdir = FileManager.default.resourceDirectory(forClass: ASResource.self) {
                        return resdir.appendingPathComponent("Images/no-image.png")
                } else {
                        fatalError("[Error] No resource directory at \(#file)")
                }
        }
}

