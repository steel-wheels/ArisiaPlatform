/*
 * @file ASFrame.swift
 * @description Define ASFrame class
 * @par Copyright
 *   Copyright (C) 2025 Steel Wheels Project
 */

import MultiDataKit
import Foundation

public enum ASFrameType
{
        case box
        case button
}

public enum ASFrameValue
{
        case value(MIValue)                     // scalar value only
        case event(String)
        case frame(ASFrame)
        case path(Array<String>)
}

public class ASFrame
{
        private var mType:  ASFrameType
        private var mSlots: Dictionary<String, ASFrameValue> = [:]

        public init(type typ: ASFrameType){
                mType  = typ
                mSlots = [:]
        }

        public var type:  ASFrameType { get { return mType }}
        public var slots: Dictionary<String, ASFrameValue> { get { return mSlots }}

        public func set(slotName name: String, value val: ASFrameValue) {
                mSlots[name] = val
        }

        public func value(slotName name: String) -> ASFrameValue? {
                return mSlots[name]
        }
}
