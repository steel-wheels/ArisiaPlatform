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
        public struct FrameItem {
                var file:       URL
                var frame:      ALFrame
        }

        private var mFrams:     Array<FrameItem>

        public init() {
                mFrams = []
        }
}

