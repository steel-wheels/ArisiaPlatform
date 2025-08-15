/*
 * @file ASStack.swift
 * @description Define ASStack class
 * @par Copyright
 *   Copyright (C) 2025 Steel Wheels Project
 */

import MultiDataKit
import Foundation

public class ASStack
{
        private var mFrames: Array<ASFrame>

        public init() {
                mFrames = []
        }

        public func countOfFrames() -> Int {
                return mFrames.count
        }

        public func append(frame frm: ASFrame){
                mFrames.append(frm)
        }

        public func clear() {
                mFrames = []
        }

        public func frame(at index: Int) -> ASFrame? {
                if 0 <= index && index < mFrames.count {
                        return mFrames[index]
                } else {
                        return nil
                }
        }
}
