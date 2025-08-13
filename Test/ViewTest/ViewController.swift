//
//  ViewController.swift
//  ViewTest
//
//  Created by Tomoo Hamada on 2025/08/09.
//

import ArisiaPlatform
import MultiDataKit
import Cocoa

class ViewController: NSViewController
{

        @IBOutlet weak var mFrameEditor: ASFrameEditor!

        override func viewDidLoad() {
                super.viewDidLoad()

                // Do any additional setup after loading the view.
                var fid: Int = 0

                let frame = ASFrame()
                frame.setFrameId(fid) ; fid += 1
                frame.set(slotName: "title", value: .value(MIValue(stringValue: "Hello")))
                frame.set(slotName: "value0", value: .value(MIValue(stringValue: "10.0")))
                frame.set(slotName: "value1", value: .value(MIValue(stringValue: "-12.3")))

                mFrameEditor.set(target: frame, width: .none, updatedCallback: {
                        (_ frameid: Int) -> Void in
                        NSLog("Updated callback: frame-id: \(frameid)")
                })
        }

        override var representedObject: Any? {
                didSet {
                // Update the view, if already loaded.
                }
        }


}

