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
                let frame = ASFrame()
                frame.set(slotName: "title", value: .value(MIValue(stringValue: "Hello")))

                mFrameEditor.setTarget(frame: frame)
        }

        override var representedObject: Any? {
                didSet {
                // Update the view, if already loaded.
                }
        }


}

