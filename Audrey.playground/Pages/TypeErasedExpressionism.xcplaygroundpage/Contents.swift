public struct Empty<T>: Expression {
    public let isNullable = false
    
    public func derive(value: T) -> AnyExpression<T> {
        return AnyExpression(Empty())
    }
}

public struct Blank<T>: Expression {
    public let isNullable = true
    
    public func derive(value: T) -> AnyExpression<T> {
        return AnyExpression(Empty())
    }
}

struct Primitive<T>: Expression {
    let isNullable = false
    
    let block: T -> Bool
    init(_ block: T -> Bool) {
        self.block = block
    }
    
    func derive(value: T) -> AnyExpression<T> {
        if block(value) {
            return AnyExpression(Blank())
        }
        return AnyExpression(Empty())
    }
}

public struct Any<T>: Expression {
    public let isNullable = false
    
    public func derive(value: T) -> AnyExpression<T> {
        return AnyExpression(Blank())
    }
}

public struct Sequence<T>: Expression {
    public let first: AnyExpression<T>
    public let second: AnyExpression<T>
    
    public var isNullable: Bool {
        return first.isNullable && second.isNullable
    }
    
    public init<E1: Expression, E2: Expression where
        E1.Value == T, E2.Derived == AnyExpression<T>,
        E2.Value == T, E1.Derived == AnyExpression<T>>(_ first: E1, _ second: E2) {
            self.first = AnyExpression(first)
            self.second = AnyExpression(second)
    }
    
    public func derive(value: T) -> AnyExpression<T> {
        if first.isNullable {
            return AnyExpression(Choice(
                Sequence(first.derive(value), second),
                second.derive(value)
            ))
        }
        return AnyExpression(Sequence(
            first.derive(value),
            second
        ))
    }
} 

public struct Choice<T>: Expression {
    public let first: AnyExpression<T>
    public let second: AnyExpression<T>
    
    public var isNullable: Bool {
        return first.isNullable || second.isNullable
    }
    
    public init<E1: Expression, E2: Expression where
        E1.Value == T, E1.Derived == AnyExpression<T>,
        E2.Value == T, E2.Derived == AnyExpression<T>>(_ first: E1, _ second: E2) {
            self.first = AnyExpression(first)
            self.second = AnyExpression(second)
    }
    
    public func derive(value: T) -> AnyExpression<T> {
        return AnyExpression(Choice(first.derive(value), second.derive(value)))
    }
}

/**
 Zero or more expressions
 */
public struct Repetition<T>: Expression {
    public let expression: AnyExpression<T>
    
    public let isNullable: Bool = true
    
    public init<E: Expression where E.Value == T, E.Derived == AnyExpression<T>>(_ expression: E) {
        self.expression = AnyExpression(expression)
    }
    
    public func derive(value: T) -> AnyExpression<T> {
        return AnyExpression(Sequence(expression.derive(value), self))
    }
}

public struct Intersection<T>: Expression {
    public let first: AnyExpression<T>
    public let second: AnyExpression<T>
    
    public var isNullable: Bool {
        return first.isNullable && second.isNullable
    }
    
    public init<E1: Expression, E2: Expression where
        E1.Value == T, E1.Derived == AnyExpression<T>,
        E2.Value == T, E2.Derived == AnyExpression<T>>(_ first: E1, _ second: E2) {
            self.first = AnyExpression(first)
            self.second = AnyExpression(second)
    }
    
    public func derive(value: T) -> AnyExpression<T> {
        return AnyExpression(Intersection(first.derive(value), second.derive(value)))
    }
}

public struct Difference<T>: Expression {
    public let first: AnyExpression<T>
    public let second: AnyExpression<T>
    
    public var isNullable: Bool {
        return first.isNullable && !second.isNullable
    }
    
    public init<E1: Expression, E2: Expression where
        E1.Value == T, E1.Derived == AnyExpression<T>,
        E2.Value == T, E2.Derived == AnyExpression<T>>(_ first: E1, _ second: E2) {
            self.first = AnyExpression(first)
            self.second = AnyExpression(second)
    }
    
    public func derive(value: T) -> AnyExpression<T> {
        return AnyExpression(Difference(first.derive(value), second.derive(value)))
    }
}

let arr: [Int] = [1]
let one = Primitive{$0 == 1}
let two = Primitive{$0 == 2}
let three = Primitive{$0 == 3}
let seq = Difference(one, two)
seq.matches(arr)
