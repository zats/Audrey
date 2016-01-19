
enum Expression<T> {
    case Failure
    case Success
    case Primitive(block: T -> Bool)
}

extension Expression {
    var isNullable: Bool {
        switch self {
        case .Failure:
            return false
        case .Success:
            return true
        case .Primitive:
            return false
        }
    }
    
    func derive(value: T) -> Expression<T> {
        print(self)
        switch self {
        case .Failure:
            return .Failure
        case .Success:
            return .Failure
        case let .Primitive(block):
            return block(value) ? .Success : .Failure
        }
    }
    
    func matches(array: Array<T>) -> Bool {
        guard let first = array.first else {
            return isNullable
        }
        return derive(first).matches(Array(array.dropFirst()))
    }
}

let expr: Expression<Int> = .Primitive(block: { $0 == 1 })
let x: [Int] = [1]
expr.matches(x)
