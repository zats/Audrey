//: [Previous](@previous)

import Foundation


indirect enum Expression<T> {
    case Literal(block: T -> Bool)
    case Or(lhs: Expression<T>, rhs: Expression<T>)
    case Concat(lhs: Expression<T>, rhs: Expression<T>)
    case Any
    case ZeroOrMore(expression: Expression<T>)
    case OneOrMore(expression: Expression<T>)
}

extension Expression {
    func or(other: Expression<T>) -> Expression<T> {
        return .Or(lhs: self, rhs: other)
    }
    
    func concat(other: Expression<T>) -> Expression<T> {
        return .Concat(lhs: self, rhs: other)
    }
    
    static func zeroOrMore(expression: Expression<T>) -> Expression<T> {
        return .ZeroOrMore(expression: expression)
    }

    static func oneOrMore(expression: Expression<T>) -> Expression<T> {
        return .OneOrMore(expression: expression)
    }
}

enum MatchResult<T> {
    case Success(stack: [T], remainder: [T])
    case Failure(stack: [T], previous: [T])
}

extension Expression {
    func match(stack: [T]) -> [T]? {
        print("stack \(stack.count)")
        guard let first = stack.first else {
            //
            return nil
        }
        
        switch self {
        case .Any:
            return Array(stack.dropFirst())
        case let .Literal(block):
            if block(first) {
                return Array(stack.dropFirst())
            } else {
                return nil
            }
        case let .Or(lhs, rhs):
            if let result = lhs.match(stack) {
                return result
            } else if let result = rhs.match(stack) {
                return result
            } else {
                return nil
            }
        case let .Concat(lhs, rhs):
            if let s1 = lhs.match(stack), s2 = rhs.match(s1) {
                return s2
            }
            return nil
        case let .ZeroOrMore(expression):
            var stack: [T] = stack
            while let stack1 = expression.match(stack) {
                stack = stack1
            }
            return stack
        case let .OneOrMore(expression):
            guard var stack = expression.match(stack) else {
                return nil
            }
            while let stack1 = expression.match(stack) {
                stack = stack1
            }
            return stack
        }
    }
}

let sentence = "could you please get me an uber"
let tokens = sentence.componentsSeparatedByString(" ")

let get = Expression.Literal { $0 == "get" }
let expr: Expression<String> = get.concat(.zeroOrMore(.Any))

