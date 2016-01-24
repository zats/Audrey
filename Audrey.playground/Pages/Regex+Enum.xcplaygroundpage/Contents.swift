
public indirect enum Expression<T> {
    case Failure
    case Empty
    case Primitive(block: T -> Bool)
    case Or(lhs: Expression, rhs: Expression)
    case Then(lhs: Expression, rhs: Expression)
    case Not(expression: Expression)
    case Repeat(expression: Expression)
    case Intersection(lhs: Expression, rhs: Expression)
    case Difference(lhs: Expression, rhs: Expression)
}

extension Expression: CustomStringConvertible {
    public var description: String {
        switch self {
        case .Failure:
            return "Failure"
        case .Empty:
            return "Empty"
        case .Primitive:
            return "Primitive<\(T.self)>"
        case let .Or(lhs, rhs):
            return "\(lhs) || \(rhs)"
        case let .Then(lhs, rhs):
            return "\(lhs) && \(rhs)"
        case let .Not(expression):
            return "!\(expression)"
        case let .Repeat(expression):
            return "\(expression)*"
        case let .Difference(lhs, rhs):
            return "\(lhs) - \(rhs)"
        case let .Intersection(lhs, rhs):
            return "\(lhs) ∩ \(rhs)"
        }
    }
}

extension Expression {
    private var isMatching: Bool {
        switch self {
        case .Failure:
            return false
        case .Empty:
            return true
        case .Primitive:
            return false
        case let .Or(lhs, rhs):
            return lhs.isMatching || rhs.isMatching
        case let .Then(lhs, rhs):
            return lhs.isMatching && rhs.isMatching
        case let .Not(expression):
            return !expression.isMatching
        case .Repeat:
            return true
        case let .Intersection(lhs, rhs):
            return lhs.isMatching && rhs.isMatching
        case let .Difference(lhs, rhs):
            return lhs.isMatching && !rhs.isMatching
        }
    }
    
    private func derive(value: T) -> Expression<T> {
        switch self {
        case .Failure:
            return .Failure
        case .Empty:
            return .Failure
        case let .Primitive(block):
            return block(value) ? .Empty : .Failure
        case let .Or(lhs, rhs):
            return .Or(lhs: lhs.derive(value), rhs: rhs.derive(value))
        case let .Then(lhs, rhs):
            if lhs.isMatching {
                return .Or(lhs:
                    .Then(lhs: lhs.derive(value), rhs: rhs),
                    rhs: rhs.derive(value)
                )
            } else {
                return .Then(lhs: lhs.derive(value), rhs: rhs)
            }
        case let .Not(expression):
            return .Not(expression: expression.derive(value))
        case let .Repeat(expression):
            return .Then(lhs: expression.derive(value), rhs: self)
        case let .Difference(lhs, rhs):
            return .Difference(lhs: lhs.derive(value), rhs: rhs.derive(value))
        case let .Intersection(lhs, rhs):
            return .Intersection(lhs: lhs.derive(value), rhs: rhs.derive(value))
        }
    }
    
    func matches(array: Array<T>) -> Bool {
        guard let first = array.first else {
            return isMatching
        }
        return derive(first).matches(Array(array.dropFirst()))
    }
}

extension Expression {
    func then(other: Expression) -> Expression {
        return .Then(lhs: self, rhs: other)
    }
    
    static func not(exp: Expression) -> Expression {
        return .Not(expression: exp)
    }

    func or(other: Expression) -> Expression {
        return .Or(lhs: self, rhs: other)
    }
    
    static func primitive(block: T -> Bool) -> Expression {
        return .Primitive(block: block)
    }
}

func &&<T>(lhs: Expression<T>, rhs: Expression<T>) -> Expression<T> {
    return lhs.then(rhs)
}

func ||<T>(lhs: Expression<T>, rhs: Expression<T>) -> Expression<T> {
    return lhs.or(rhs)
}

prefix func !<T>(expression: Expression<T>) -> Expression<T> {
    return .not(expression)
}

postfix operator * {}
postfix func *<T>(expression: Expression<T>) -> Expression<T> {
    return .Repeat(expression: expression)
}

let expr: Expression<Int> = .primitive({$0 == 1})* && .primitive({$0 == 2}) && (.primitive({$0 == 3}) || .primitive({$0 == 4}))

let x: [Int] = [1, 2, 4]
expr.matches(x)