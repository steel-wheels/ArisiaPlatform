/*
 * @file ALStack.swift
 * @description Define ALStack class
 * @par Copyright
 *   Copyright (C) 2025 Steel Wheels Project
 */

import MultiDataKit
import Foundation

public class ALStack
{
        private var mPackageDirectory:          URL
        private var mFrameScriptURLs:           Array<URL>

        public var frameScriptURLs: Array<URL> { get{ return mFrameScriptURLs }}

        public init(packageDirectory pkgdir: URL) {
                mPackageDirectory       = pkgdir
                mFrameScriptURLs        = []
        }

        public func add(frameScriptPath path: String) {
                let path = mPackageDirectory.appending(path: path)
                mFrameScriptURLs.append(path)
        }
}

