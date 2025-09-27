/*
 * @file ASDropDetector.swift
 * @description Define ASDropDetector class
 * @par Copyright
 *   Copyright (C) 2025 Steel Wheels Project
 */

import MultiUIKit
import Foundation

public class ASDropDetector: MIVisitor
{
        public enum DetectedPosition {
                case center
                case top
                case bottom
                case left
                case right

                public var description: String { get {
                        let result: String
                        switch self {
                        case .center:   result = "center"
                        case .top:      result = "top"
                        case .bottom:   result = "bottom"
                        case .left:     result = "left"
                        case .right:    result = "right"
                        }
                        return result
                }}
        }

        public struct DetectedFrame {
                var     position:       DetectedPosition
                var     frameId:        Int

                public init(position pos: DetectedPosition, frameId fid: Int){
                        self.position   = pos
                        self.frameId    = fid
                }

                public var description: String { get {
                        return "{DetectedView frame=\(self.frameId)  " + position.description + "}"
                }}
        }

        private var mPoints:            Array<CGPoint>
        private var mDetectedFrame:      DetectedFrame?

        public override init() {
                mPoints         = []
                mDetectedFrame  = nil
        }

        private func currentPoint() -> CGPoint {
                if let pt = mPoints.last {
                        return pt
                } else {
                        NSLog("[Error] Emppty points at \(#file)")
                        return CGPoint.zero
                }
        }

        private func pushPoint(_ pt: CGPoint) {
                mPoints.append(pt)
        }

        private func pushOffset(point pt: CGPoint, against frame: CGRect) {
                let newx: CGFloat
                let diffx = pt.x - frame.origin.x
                if diffx >= 0.0 {
                        newx = diffx
                } else {
                        NSLog("[Error] Failed to get offset at \(#file)")
                        newx = 0.0
                }
                let newy: CGFloat
                let diffy = pt.y - frame.origin.y
                if diffy >= 0.0 {
                        newy = diffy
                } else {
                        NSLog("[Error] Failed to get offset at \(#file)")
                        newy = 0.0
                }
                pushPoint(CGPoint(x: newx, y: newy))
        }

        private func popPoint() {
                if mPoints.count > 1 {
                        mPoints.removeLast()
                } else {
                        NSLog("[Error] Failed to pop at \(#file)")
                }
        }

        public func detect(point pt: CGPoint, in root: MIStack) -> DetectedFrame? {
                mPoints         = [pt]
                mDetectedFrame  = nil
                root.accept(visitor: self)
                return mDetectedFrame
        }

        public override func visit(stack src: MIStack) {
                //dumpPoint(label: "box", view: src)
                if isInFrame(point: currentPoint(), view: src) {
                        let subviews = src.arrangedSubviews
                        if subviews.count > 0 {
                                for subview in subviews {
                                        subview.accept(visitor: self)
                                        if let _ = mDetectedFrame {
                                                return // already detected
                                        }
                                }
                        } else {
                                mDetectedFrame = DetectedFrame(position: .center, frameId: src.coreTag)
                        }
                } else {
                        //NSLog("Not in stack frame at \(#function)")
                }
        }

        public override func visit(button src: MIButton) {
                //dumpPoint(label: "button", view: src)
                if isInFrame(point: currentPoint(), view: src) {
                        //NSLog("In button frame at \(#function)")
                        let dpos = detectedPosition(point: currentPoint(), frame: src.buttonFrame())
                        mDetectedFrame = DetectedFrame(position: dpos, frameId: src.coreTag)
                }
        }

        public override func visit(imageView src: MIImageView) {
                //dumpPoint(label: "image", view: src)
                if isInFrame(point: currentPoint(), view: src) {
                        //NSLog("In image frame at \(#function)")
                        let dpos = detectedPosition(point: currentPoint(), frame: src.imageFrame())
                        mDetectedFrame = DetectedFrame(position: dpos, frameId: src.coreTag)
                } else {
                        //NSLog("Not in image frame at \(#function)")
                }
        }

        private func isInFrame(point pt: CGPoint, view v: MIInterfaceView) -> Bool {
                return v.frame.contains(pt)
        }

        private func detectedPosition(point pt: CGPoint, frame frm: CGRect) -> DetectedPosition {
                let MARGIN: CGFloat = 10.0

                /* horizontal distance */
                let hmin  = frm.origin.x - MARGIN
                let hmax  = frm.origin.x + frm.size.width + MARGIN
                let hdist = ((pt.x < hmin) ? hmin - pt.x : 0.0)
                          + ((hmax < pt.x) ? pt.x - hmax : 0.0)

                /* vertical distance */
                let vdist: CGFloat
                #if os(OSX)
                let vmin = frm.origin.y - frm.size.height - MARGIN
                let vmax = frm.origin.y + MARGIN
                #else
                let vmin  = frm.origin.y - MARGIN
                let vmax  = frm.origin.y + frm.size.height + MARGIN
                #endif
                vdist = ((pt.y < vmin) ? vmin - pt.y : 0.0)
                      + ((vmax < pt.y) ? pt.y - vmax : 0.0)

                NSLog("(\(#function) pt.x\(pt.x) pt.y:\(pt.y)")
                NSLog("(\(#function) hmin\(hmin) hmax:\(hmax)")
                NSLog("(\(#function) vmin\(vmin) vmax:\(vmax)")
                NSLog("(\(#function) hdist:\(hdist) vdist:\(vdist)")

                let result: DetectedPosition
                if hdist >= vdist {
                        /* select horizontal position */
                        if pt.x < hmin {
                                result = .left
                        } else if hmax < pt.x {
                                result = .right
                        } else {
                                result = .center
                        }
                } else {
                        /* select vetical position */
                        #if os(OSX)
                        if pt.y < vmin {
                                result = .bottom
                        } else if vmax < pt.y {
                                result = .top
                        } else {
                                result = .center
                        }
                        #else
                        if pt.y < vmin {
                                result = .top
                        } else if vmax < pt.y {
                                result = .bottom
                        } else {
                                result = .center
                        }
                        #endif
                }
                NSLog("(\(#function) result = \(result.description)")
                return result
        }

        private func dumpPoint(label lab: String, view src: MIInterfaceView){
                NSLog("\(lab): {")
                NSLog(" point:  \(currentPoint().description)")
                NSLog(" frame:  \(src.frame.description)")
                NSLog(" bounds: \(src.bounds.description)")
                if let imgview = src as? MIImageView {
                        let imgrect = imgview.imageFrame()
                        NSLog(" image:  \(imgrect.description)")
                }
                if let btnview = src as? MIButton {
                        let btnrect = btnview.buttonFrame()
                        NSLog(" button: \(btnrect.description)")
                }
                NSLog("}")
        }
}
