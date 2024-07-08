// Parser.Swift

import Foundation

// A piece of YAML consists of 3 types of elements:
// - Scalars: Basic Values like strings, numbers and booleans
// - Sequences: Ordered lists
// - Mappings: Collections of Key-Value pairs

/// This Enum repesentd the types of elements in a YAML file
internal enum YAMLNode {
    case scalar(String)
    case sequence([YAMLNode])
    case mapping([String: YAMLNode])
}

/// This enum act as a tokens for the parser.
internal enum Token {
    case scalar(String)
    case dash
    case colon
    case newline
    case indent
    case dedent
}

struct YAMLParser {
    static func tokenize(yaml: String) -> [Token] {
        var tokens: [Token] = []
        var currentScalar = ""
        var currentIndentLevel = 0
        var indentStack: [Int] = []

        for line in yaml.split(separator: "\n") {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            let indentLevel = line.prefix { $0 == " " }.count

            if indentLevel > currentIndentLevel {
                tokens.append(.indent)
                indentStack.append(currentIndentLevel)
                currentIndentLevel = indentLevel
            } else if indentLevel < currentIndentLevel {
                while let lastIndent = indentStack.last, lastIndent >= indentLevel {
                    tokens.append(.dedent)
                    indentStack.removeLast()
                }

                currentIndentLevel = indentLevel
            }

            // Check if the line is a scalar
            if trimmedLine.hasPrefix("- ") {
                tokens.append(.dash)
                currentScalar = String(trimmedLine.dropFirst(2))
            } else if let colonIndex = trimmedLine.firstIndex(of: ":") {
                let key = String(trimmedLine[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                tokens.append(.scalar(key))
                tokens.append(.colon)
                currentScalar = String(trimmedLine[colonIndex...].dropFirst()).trimmingCharacters(in: .whitespaces)
            } else {
                currentScalar = trimmedLine
            }

            if !currentScalar.isEmpty {
                tokens.append(.scalar(currentScalar))
            }

            tokens.append(.newline)
        }

        while !indentStack.isEmpty {
            tokens.append(.dedent)
            indentStack.removeLast()
        }

        return tokens
    }

    static func parse(tokens: [Token]) -> YAMLNode? {
        var index = 0

        func parseNode() -> YAMLNode? {
            if index >= tokens.count {
                return nil
            }

            switch tokens[index] {
            case .scalar(let value):
                index += 1
                return .scalar(value)
            case .dash:
                index += 1
                var sequence: [YAMLNode] = []
                while index < tokens.count, tokens[index] != .newline, tokens[index] != .dedent {
                    if let node = parseNode() {
                        sequence.append(node)
                    }
                }
                return .sequence(sequence)
            case .colon:
                index += 1
                if let valueNode = parseNode() {
                    return valueNode
                }
            case .newline:
                index += 1
                return parseNode()
            case .indent:
                index += 1
                var mapping: [String: YAMLNode] = [:]
                while index < tokens.count, tokens[index] != .dedent {
                    if case .scalar(let key) = tokens[index] {
                        index += 1
                        if tokens[index] == .colon {
                            index += 1
                            if let valueNode = parseNode() {
                                mapping[key] = valueNode
                            }
                        }
                    }
                }
                return .mapping(mapping)
            case .dedent:
                index += 1
                return nil
            }
            return nil
        }
        
        return parseNode()
     }   
}