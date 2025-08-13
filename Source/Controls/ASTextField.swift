/**
 * @file       ASTextField.swift
 * @brief      Extend MITextField class
 * @par Copyright
 *   Copyright (C) 2025 Steel Wheels Project
 */

import MultiUIKit
import MultiDataKit
import JavaScriptCore
#if os(OSX)
import  AppKit
#else   // os(OSX)
import  UIKit
#endif  // os(OSX)

public extension MITextField
{
        func get(valueType vtype: MIValueType) -> MIValue? {
                let result: MIValue?
                switch vtype {
                case .booleanType:
                        switch self.stringValue {
                        case "true":    result = MIValue(booleanValue: true)
                        case "false":   result = MIValue(booleanValue: false)
                        default:
                                NSLog("[Error] Boolean value expected: \(self.stringValue) at \(#file)")
                                result = nil
                        }
                case .signedIntType:
                        if let ival = self.signedIntValue {
                                result = MIValue(signedIntValue: ival)
                        } else {
                                NSLog("[Error] Signed integer value expected: \(self.stringValue) at \(#file)")
                                result = nil
                        }
                case .unsignedIntType:
                        if let ival = self.unsignedIntValue {
                                result = MIValue(unsignedIntValue: ival)
                        } else {
                                NSLog("[Error] Unsigned integer value expected: \(self.stringValue) at \(#file)")
                                result = nil
                        }
                case .floatType:
                        if let ival = self.floatValue {
                                result = MIValue(floatValue: ival)
                        } else {
                                NSLog("[Error] Float value expected: \(self.stringValue) at \(#file)")
                                result = nil
                        }
                case .stringType:
                        result = MIValue(stringValue: self.stringValue)
                case .nilType, .arrayType, .dictionaryType:
                        NSLog("[Error] Unsupported type: \(vtype.name) at \(#file)")
                        result = nil
                @unknown default:
                        NSLog("[Error] Can not happen at \(#file)")
                        result = nil
                }
                return result
        }

        func set(value val: MIValue){
                switch val.value {
                case .booleanValue(let ival):
                        self.stringValue = ival ? "true" : "false"
                case .signedIntValue(let ival):
                        self.signedIntValue = ival
                case .unsignedIntValue(let ival):
                        self.unsignedIntValue = ival
                case .floatValue(let ival):
                        self.floatValue = ival
                case .stringValue(let ival):
                        self.stringValue = ival
                case .nilValue, .arrayValue(_), .dictionaryValue(_):
                        NSLog("[Error] Unsupported value type: \(val.type.name) at \(#file)")
                @unknown default:
                        NSLog("[Error] Can not happen: \(val.type.name) at \(#file)")
                }
        }
}

