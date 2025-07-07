/*
 * @file ALFrameParser.swift
 * @description Define ALFrameParser class
 * @par Copyright
 *   Copyright (C) 2025 Steel Wheels Project
 */

import MultiDataKit
import Foundation

public class ALFrameParser
{
        public init() {
                
        }

        public func parse(string str: String) -> Result<ALFrame, NSError>
        {
                let stream = MIStringStream(string: str)
                switch MITokenizer.tokenize(stream: stream) {
                case .success(let tokens):
                        return parse(tokens: tokens)
                case .failure(let err):
                        return .failure(err)
                }
        }

        private func parse(tokens: Array<MIToken>) -> Result<ALFrame, NSError>
        {
                var index: Int = 0
                return parseFrame(index: &index, tokens: tokens)
        }

        private func parseFrame(index: inout Int, tokens: Array<MIToken>) -> Result<ALFrame, NSError>
        {
                if let err = requireSymbol(index: &index, symbol: "{", tokens: tokens) {
                        return .failure(err)
                }

                let newframe = ALFrame()
                while(index < tokens.count) {
                        if tokens[index].isSymbol(c: "}") {
                                break
                        } else {
                                switch parseSlot(index: &index, tokens: tokens) {
                                case .success((let  name, let val)):
                                        newframe.set(slotName: name, value: val)
                                case .failure(let err):
                                        return .failure(err)
                                }
                        }
                }

                index += 1 // for last "}"
                return .success(newframe)
        }

        private func parseSlot(index: inout Int, tokens: Array<MIToken>) -> Result<(String, ALFrameValue), NSError>
        {
                // get identifier
                let ident: String
                switch requireIdentifier(index: &index, tokens: tokens) {
                case .success(let str):
                        ident = str
                case .failure(let err):
                        return .failure(err)
                }

                // get ":"
                if let err = requireSymbol(index: &index, symbol: ":", tokens: tokens) {
                        return .failure(err)
                }

                // get value
                let value: ALFrameValue
                switch parseValue(index: &index, tokens: tokens) {
                case .success(let val):
                        value = val
                case .failure(let err):
                        return .failure(err)
                }

                return .success((ident, value))
        }

        private func parseValue(index: inout Int, tokens: Array<MIToken>) -> Result<ALFrameValue, NSError>
        {
                if let err = checkIndex(index: index, tokens: tokens) {
                        return .failure(err)
                }
                let value: ALFrameValue
                switch tokens[index].value {
                case .bool(let val):
                        value = .value(MIValue(booleanValue: val))
                case .string(let val):
                        value = .value(MIValue(stringValue: val))
                case .uint(let val):
                        value = .value(MIValue(unsignedIntValue: val))
                case .int(let val):
                        value = .value(MIValue(signedIntValue: val))
                case .float(let val):
                        value = .value(MIValue(floatValue: val))
                case .identifier(let ident):
                        switch ident {
                        case "nil":
                                value = .value(MIValue())
                        default:
                                switch parsePath(index: &index, paths: [ident], tokens: tokens) {
                                case .success(let paths):
                                        value = .path(paths)
                                case .failure(let err):
                                        return .failure(err)
                                }
                        }
                case .comment(_):
                        value = .value(MIValue())
                case .symbol(let c):
                        let err = MIError.parseError(message: "Unexpected character: \(c)",
                                                     line: MIToken.lastLine(tokens: tokens))
                        return .failure(err)
                case .text(let text):
                        let err = MIError.parseError(message: "Unexpected text \"\(text)\"",
                                                     line: MIToken.lastLine(tokens: tokens))
                        return .failure(err)
                @unknown default:
                        let err = MIError.parseError(message: "Unknown error",
                                                     line: MIToken.lastLine(tokens: tokens))
                        return .failure(err)
                }
                return .success(value)
        }

        private func parsePath(index: inout Int, paths path: Array<String>, tokens: Array<MIToken>) -> Result<Array<String>, NSError>
        {
                var result: Array<String> = path

                var docont = true
                while docont {
                        if let err = checkIndex(index: index, tokens: tokens) {
                                return .failure(err)
                        }
                        switch tokens[index+1].value {
                        case .symbol(let c):
                                if(c == "."){
                                        index += 1
                                        if let err = checkIndex(index: index, tokens: tokens) {
                                                return .failure(err)
                                        }
                                        switch tokens[index+1].value {
                                        case .identifier(let ident):
                                                result.append(ident)
                                                index += 1
                                        default:
                                                let err = MIError.parseError(
                                                        message: "identifier is required after .",
                                                        line: MIToken.lastLine(tokens: tokens))
                                                return .failure(err)
                                        }
                                } else {
                                        docont = false
                                }
                        default:
                                docont = false
                        }
                }
                return .success(result)
        }

        private func requireIdentifier(index: inout Int, tokens: Array<MIToken>) -> Result<String, NSError> {
                if let err = checkIndex(index: index, tokens: tokens) {
                        return .failure(err)
                }
                if let ident = tokens[index].toIdentifier() {
                        index += 1
                        return .success(ident)
                } else {
                        let err = MIError.parseError(message: "identifier is required",
                                                     line: MIToken.lastLine(tokens: tokens))
                        return .failure(err)
                }
        }

        private func requireSymbol(index: inout Int, symbol sym: Character, tokens: Array<MIToken>) -> NSError? {
                if let err = checkIndex(index: index, tokens: tokens) {
                        return err
                }
                if tokens[index].isSymbol(c: sym) {
                        index += 1
                        return nil // no error
                } else {
                        let err = MIError.parseError(message: "\"{\" is required",
                                                     line: MIToken.lastLine(tokens: tokens))
                        return err
                }
        }

        private func checkIndex(index idx: Int, tokens: Array<MIToken>) -> NSError? {
                if idx < tokens.count {
                        return nil      // no error
                } else {
                        let err = MIError.parseError(message: "Unexpected end of token",
                                                     line: MIToken.lastLine(tokens: tokens))
                        return err
                }
        }
}
