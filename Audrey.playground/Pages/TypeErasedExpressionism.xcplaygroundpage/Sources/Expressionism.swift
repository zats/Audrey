// MARK: Expression Type

public protocol Expression {
    typealias Value
    typealias Derived
    
    var isNullable: Bool { get }
    
    func derive(value:  Value) -> Derived
    
    // Not intended for public use, instead call `matches(sequence:)`
    func matches<G: GeneratorType where G.Element == Value>(generator: G) -> Bool
}

public extension Expression {
    func matches<S: SequenceType where S.Generator.Element == Value>(sequence: S) -> Bool {
        return matches(sequence.generate())
    }
}

public extension Expression where Derived: Expression, Derived.Value == Value {
    func matches<G: GeneratorType where G.Element == Value>(generator: G) -> Bool {
        var generator = generator
        guard let first = generator.next() else {
            return isNullable
        }
        return derive(first).matches(generator)
    }
}

// MARK: AnyExpressionession

private class _AnyExpressionBoxBase<T, D>: Expression {
    var isNullable: Bool {
        fatalError()
    }
    
    func derive(value: T) -> D {
        fatalError()
    }
    
    func matches<G : GeneratorType where G.Element == T>(generator: G) -> Bool {
        fatalError()
    }
}

private class _AnyExpressionBox<E: Expression>: _AnyExpressionBoxBase<E.Value, E.Derived> {
    let base: E
    
    override var isNullable: Bool {
        return base.isNullable
    }
    
    init(_ base: E) {
        self.base = base
    }
    
    override func derive(value: E.Value) -> E.Derived {
        return base.derive(value)
    }
}

public final class AnyExpression<T>: Expression {
    private let box: _AnyExpressionBoxBase<T, AnyExpression>
    
    public var isNullable: Bool {
        return box.isNullable
    }
    
    public init<E: Expression where E.Value == T, E.Derived == AnyExpression>(_ base: E) {
        self.box = _AnyExpressionBox(base)
    }
    
    public func derive(value: T) -> AnyExpression<T> {
        return box.derive(value)
    }
}
