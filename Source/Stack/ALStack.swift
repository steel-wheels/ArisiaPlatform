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
        private var mFrameURLs:     Array<URL>

        public var frameURLs: Array<URL> { get{ return mFrameURLs }}

        public init() {
                mFrameURLs = []
        }

        public func set(frameURLs urls: Array<URL>){
                mFrameURLs = urls
        }
}

