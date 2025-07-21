/*
 * @file ASFrame.swift
 * @description Define ASFrame class
 * @par Copyright
 *   Copyright (C) 2025 Steel Wheels Project
 */

import MultiDataKit
import MultiUIKit
import Foundation

@MainActor public class ASFrameManager
{
        private var mRootFrame        : ASFrame

        public var rootFrame: ASFrame { get {
                return mRootFrame
        }}

        public init(){
                mRootFrame      = ASFrame()
        }

        public func add(contentsOf frame: ASFrame){
                for (name, val) in frame.slots {
                        mRootFrame.set(slotName: name, value: val)
                }
        }

        public func add(point pt: CGPoint, name nm: String, frame frm: ASFrame){
                mRootFrame.set(slotName: nm, value: .frame(frm))
        }
}
