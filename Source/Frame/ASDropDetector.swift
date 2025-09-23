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
        public enum DetectedHorizontalPosition {
                case left
                case center
                case right

                public var description: String { get {
                        let result: String
                        switch self {
                        case .left:     result = "left"
                        case .center:   result = "center"
                        case .right:    result = "right"
                        }
                        return result
                }}
        }

        public enum DetectedVerticalPosition {
                case top
                case middle
                case bottom

                public var description: String { get {
                        let result: String
                        switch self {
                        case .top:      result = "top"
                        case .middle:   result = "middle"
                        case .bottom:   result = "bottom"
                        }
                        return result
                }}
        }

        public struct DetectedPosition {
                var horizontal:         DetectedHorizontalPosition
                var vertical:           DetectedVerticalPosition

                public init(horizontal h: DetectedHorizontalPosition, vertical v: DetectedVerticalPosition){
                        self.horizontal = h
                        self.vertical   = v
                }

                public var description: String { get {
                        return "{position holizontal=\(self.horizontal.description) vertical=\(self.vertical.description)}"
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
                                let center = DetectedPosition(horizontal: .center, vertical: .middle)
                                mDetectedFrame = DetectedFrame(position: center, frameId: src.coreTag)
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
                let hpos: DetectedHorizontalPosition
                if pt.x < frm.origin.x {
                        hpos = .left
                } else if pt.x < frm.origin.x + frm.size.width {
                        hpos = .center
                } else {
                        hpos = .right
                }
                let vpos: DetectedVerticalPosition
                #if os(OSX)
                if pt.y < frm.origin.y {
                        vpos = .bottom
                } else if pt.y <= frm.origin.y + frm.size.height {
                        vpos = .middle
                } else {
                        vpos = .top
                }
                #else
                if pt.y < frm.origin.y {
                        vpos = .top
                } else if pt.y <= frm.origin.y + frm.size.height {
                        vpos = .middle
                } else {
                        vpos = .bottom
                }
                #endif
                return DetectedPosition(horizontal: hpos, vertical: vpos)
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
