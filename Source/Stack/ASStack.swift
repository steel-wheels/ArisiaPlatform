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
        public struct FrameRecord {
                public var path:        String    // offset against the package directory
                public var frame:       ASFrame

                public init(path pth: String, frame frm: ASFrame){
                        self.path  = pth
                        self.frame = frm
                }
        }

        private var mFrames:            Array<FrameRecord>

        public var frameRecords: Array<FrameRecord> { get { return mFrames }}

        public init() {
                mFrames         = []
        }

        public func countOfFrames() -> Int {
                return mFrames.count
        }

        public func append(path pth: String, frame frm: ASFrame){
                mFrames.append(FrameRecord(path: pth, frame: frm))
        }

        public func clear() {
                mFrames = []
        }

        public func frameRecord(at index: Int) -> FrameRecord? {
                if 0 <= index && index < mFrames.count {
                        return mFrames[index]
                } else {
                        return nil
                }
        }

        public func frame(at index: Int) -> ASFrame? {
                if let finfo = frameRecord(at: index) {
                        return finfo.frame
                } else {
                        return nil
                }
        }
}
