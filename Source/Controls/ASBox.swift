/**
 * @file       ASFDropView.swift
 * @brief      Define ASDropView class
 * @par Copyright
 *   Copyright (C) 2025 Steel Wheels Project
 */

import MultiFrameKit
import MultiUIKit
import JavaScriptCore
#if os(OSX)
import  AppKit
#else   // os(OSX)
import  UIKit
#endif  // os(OSX)


// ASStack is already defined to present stack
public class ASBox: MFStack
{
        public typealias DroppingCallback = (_ stack: MIStack, _ point: CGPoint, _ name: String, _ frame: ASFrame) -> Void

        public func set(droppingCallback cbfunc: @escaping DroppingCallback) {
                super.set(droppedCallback: {
                        (_ stack: MIStack, _ point: CGPoint, _ symbol: MISymbol) -> Void in
                        switch symbol {
                        case .buttonHorizontalTopPress:
                                switch ASFrameManager.loadButtonFrame(){
                                case .success(let frame):
                                        cbfunc(stack, point, "button", frame)
                                case .failure(let err):
                                        NSLog("[Error] " + MIError.toString(error: err))
                                }
                        case .photo:
                                switch ASFrameManager.loadImageFrame() {
                                case .success(let frame):
                                        cbfunc(stack, point, "image", frame)
                                case .failure(let err):
                                        NSLog("[Error] " + MIError.toString(error: err))
                                }
                        default:
                                NSLog("[Error] The drop item is ignored: \(symbol.name)")
                        }
                })
        }
}

/*
public class ASDropView: MFDropView
{
        public typealias CallbackFunction = (_ point: CGPoint, _ name: String, _ frame: ASFrame) -> Void

        public var droppingCallback: CallbackFunction? = nil

        #if os(OSX)
        open override func didDropped(point pt: CGPoint, symbol sym: MISymbol) {
                switch sym {
                case .buttonHorizontalTopPress:

                        break
                case .photo:

                default:

                }
        }
        #endif
}

*/

