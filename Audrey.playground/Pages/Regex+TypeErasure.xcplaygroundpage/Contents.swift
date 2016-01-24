
protocol Expression {
    typealias Value
    typealias Derived
    
    func derive(value:  Value) -> Derived
    func matches(sequence: [Value]) -> Bool
}

extension Expression {
    var isNullable: Bool {
        return false
    }
}

extension Expression where Derived == AnyExpression<Value> {
    /// If your expression derives into anything else than AnyExpression, you should implement `matches` manually
    func matches(sequence: [Value]) -> Bool {
        print("sequence:", sequence)
        guard let first = sequence.first else {
            return isNullable
        }
        return derive(first).matches(Array(sequence.dropFirst()))
    }
}

struct AnyExpression<T>: Expression {
    typealias Value = T
    typealias Derived = AnyExpression<T>
    
    private let _derive: (Value -> Derived)
    // It's important for `isNullable` not to change once the expression is passed to `AnyExpression`
    private let _isNullable: Bool
    
    init<U: Expression where U.Value == Value, U.Derived == AnyExpression<T>>(_ expression: U) {
        _derive = expression.derive
        _isNullable = expression.isNullable
    }
    
    var isNullable: Bool {
        return _isNullable
    }
    
    func derive(value: Value) -> AnyExpression<Value> {
        return _derive(value)
    }
}

struct Empty<T>: Expression {
    func derive(value: T) -> AnyExpression<T> {
        return AnyExpression(Empty())
    }
}

struct Blank<T>: Expression {
    func derive(value: T) -> AnyExpression<T> {
        return AnyExpression(Empty())
    }
}

struct Primitive<T>: Expression {
    let block: T -> Bool
    init(_ block: T -> Bool) {
        self.block = block
    }
    
    var isNullable: Bool {
        return false
    }
    
    func derive(value: T) -> AnyExpression<T> {
        if block(value) {
            print(__FUNCTION__, "matches", value)
            return AnyExpression(Blank())
        }
        print(__FUNCTION__,"not matches", value)
        return AnyExpression(Empty())
    }
}

struct Sequence<T>: Expression {
    private let first: AnyExpression<T>
    private let second: AnyExpression<T>
    
    init(_ first: AnyExpression<T>, _ second: AnyExpression<T>) {
        self.first = first
        self.second = second
    }
    
    func derive(value: T) -> AnyExpression<T> {
        if first.isNullable {
            print("Sequence derive", value)
            return AnyExpression(Choice(
                AnyExpression(Sequence(first.derive(value),second)),
                second.derive(value)
            ))
        }
        print("Sequence derive not nullable", value, first, second)
        return AnyExpression(Sequence(first.derive(value), AnyExpression(second)))
    }
}

struct Choice<T>: Expression {
    private let lhs: AnyExpression<T>
    private let rhs: AnyExpression<T>
    
    var isNullable: Bool {
        return lhs.isNullable || rhs.isNullable
    }
    
    init(_ lhs: AnyExpression<T>, _ rhs: AnyExpression<T>) {
        self.lhs = lhs
        self.rhs = rhs
    }
    
    func derive(value: T) -> AnyExpression<T> {
        print("Choice", __FUNCTION__, value)
        return AnyExpression(Choice(lhs.derive(value), rhs.derive(value)))
    }
}

let a = [1, 2, 3]
let strings = ["a", "b", "c"]

let expr = Sequence(
    AnyExpression(Sequence(
        AnyExpression(Primitive{$0 == 1}),
        AnyExpression(Primitive{$0 == 2})
    )),
    AnyExpression(Primitive{$0 == 3})
)
expr.matches(a)
