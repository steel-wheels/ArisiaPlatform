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

public class ASDropView: MFDropView
{
        public typealias CallbackFunction = (_ point: CGPoint, _ name: String, _ frame: ASFrame) -> Void

        public var droppingCallback: CallbackFunction? = nil

        #if os(OSX)
        open override func didDropped(point pt: CGPoint, symbol sym: MISymbol) {
                switch sym {
                case .buttonHorizontalTopPress:
                        switch ASFrameManager.loadButtonFrame(){
                        case .success(let frame):
                                if let cbfunc = droppingCallback {
                                        cbfunc(pt, "button", frame)
                                } else {
                                        NSLog("DropCallback: \(frame.encode())")
                                }
                        case .failure(let err):
                                NSLog("[Error] " + MIError.toString(error: err))
                        }
                        break
                default:
                        NSLog("[Error] The drop item is ignored: \(sym.name)")
                }
        }
        #endif
}

