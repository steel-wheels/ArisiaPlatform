/*
 * @file ALFrame.swift
 * @description Define ALFrame class
 * @par Copyright
 *   Copyright (C) 2025 Steel Wheels Project
 */

import MultiDataKit
import Foundation

public enum ALFrameValue
{
        case value(MIValue)
        case text(String)
        case frame(ALFrame)
}

public class ALFrame
{
        private var mSlots: Dictionary<String, ALFrameValue> = [:]

        public init(){
                mSlots = [:]
        }

        public func set(slotName name: String, value val: ALFrameValue) {
                mSlots[name] = val
        }

        public func value(slotName name: String) -> ALFrameValue? {
                return mSlots[name]
        }
}
