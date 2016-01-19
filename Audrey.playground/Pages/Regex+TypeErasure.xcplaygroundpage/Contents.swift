//: > @zats Ah, to do that you'd need to be able to use the protocol type `Expression<Value>`. Can jury-rig one yourself: [https://t.co/V5y9BqadFd](https://t.co/V5y9BqadFd)
//: [tweet](https://twitter.com/jckarter/status/689875733808689153)

protocol Expression {
    typealias Value
    typealias Derived
    
    func derive(value:  Value) -> Derived
}

struct Empty<T>: Expression {
    typealias Value = T
    typealias Derived = Empty<T>
    
    func derive(value: Value) -> Derived {
        return Empty<T>()
    }
}

struct Blank<T>: Expression {
    typealias Value = T
    typealias Derived = Blank<T>
    
    func derive(value: Value) -> Derived {
        return Blank<T>()
    }
}

struct Primitive<T where T: Equatable>: Expression {
    typealias Value = T
    typealias Derived = Blank<T>
    
    let value: Value
    init(value: Value) {
        self.value = value
    }
    
    func derive(value: Value) -> Derived {
        if self.value == value {
            return Blank<T>()
        } else {
            return Empty<T>() // ❗️ Cannot convert return expression of type Empty<T> to return type Blank<T>
        }
    }
}

