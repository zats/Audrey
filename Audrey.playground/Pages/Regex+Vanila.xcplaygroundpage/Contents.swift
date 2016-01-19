//: [Previous](@previous)

import Foundation


class Regex {
    var isNullable: Bool {
        return false
    }

    func derive(char: Character) -> Regex {
        return self
    }
    
    func matches(string: String.CharacterView) -> Bool {
        if string.isEmpty {
            return isNullable
        } else {
            return derive(string.first!)
                .matches(string.dropFirst())
        }
    }
    
    func matches(string: String) -> Bool {
        return matches(string.characters)
    }
}

class Empty: Regex {
    override func derive(char: Character) -> Regex {
        return Empty()
    }
}

class Blank: Regex {
    override func derive(char: Character) -> Regex {
        return Empty()
    }
    
    override var isNullable: Bool {
        return true
    }
}

class Any: Primitive {
    required init() {
        super.init(char: "")
    }
    
    override private convenience init(char: Character) {
        self.init()
    }
    
    override func derive(char: Character) -> Regex {
        return Blank()
    }
}

class Primitive: Regex {
    let char: Character
    init(char: Character) {
        self.char = char
    }
    
    override func derive(char: Character) -> Regex {
        if char == self.char {
            return Blank()
        } else {
            return Empty()
        }
    }
    
    override var isNullable: Bool {
        return false
    }
}

class Choice: Regex {
    let lhs: Regex
    let rhs: Regex

    init(lhs: Regex, rhs: Regex) {
        self.lhs = lhs
        self.rhs = rhs
    }
    
    override func derive(char: Character) -> Regex {
        return Choice(lhs: lhs.derive(char), rhs: rhs.derive(char))
    }
    
    override var isNullable: Bool {
        return lhs.isNullable || rhs.isNullable
    }
}

class Sequence: Regex {
    let first: Regex
    let second: Regex
    init(first: Regex, second: Regex) {
        self.first = first
        self.second = second
    }
    
    override func derive(char: Character) -> Regex {
        if first.isNullable {
            return Choice(lhs: Sequence(first: first.derive(char), second: second), rhs: second.derive(char))
        } else {
            return Sequence(first: first.derive(char), second: second)
        }
    }
    
    override var isNullable: Bool {
        return first.isNullable && second.isNullable
    }
}

class Repetition: Regex {
    let regex: Regex
    init(regex: Regex) {
        self.regex = regex
    }
    
    override func derive(char: Character) -> Regex {
        return Sequence(first: regex.derive(char), second: self)
    }
    
    override var isNullable: Bool {
        return true
    }
}

class Intersection: Regex {
    let first: Regex
    let second: Regex
    init(first: Regex, second: Regex) {
        self.first = first
        self.second = second
    }
    
    override func derive(char: Character) -> Regex {
        return Intersection(first: first.derive(char), second: second.derive(char))
    }
    
    override var isNullable: Bool {
        return first.isNullable && second.isNullable
    }
}

class Difference: Regex {
    let first: Regex
    let second: Regex
    init(first: Regex, second: Regex) {
        self.first = first
        self.second = second
    }
    
    override var isNullable: Bool {
        return first.isNullable && !second.isNullable
    }
    
    override func derive(char: Character) -> Regex {
        return Difference(first: first.derive(char), second: second.derive(char))
    }
}

class Complemet: Regex {
    let regex: Regex
    init(regex: Regex) {
        self.regex = regex
    }
    
    override var isNullable: Bool {
        return !regex.isNullable
    }
    
    override func derive(char: Character) -> Regex {
        return Complemet(regex: regex.derive(char))
    }
}

let a = Primitive(char: "a")
let b = Primitive(char: "b")
let c = Primitive(char: "c")
let ab = Sequence(first: a, second: b)
let seq1 = Sequence(first: Repetition(regex: Any()), second: Primitive(char: "a"))
let seq2 = Sequence(first: Primitive(char: "b"), second: Repetition(regex: Any()))
let expr = Sequence(first: seq1, second: seq2)
expr.matches("23426745124ab")
let lit = Complemet(regex: Primitive(char: "a"))
lit.matches("b")