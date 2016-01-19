import Foundation

public struct AddressDetectingPlugin: TokenizerPlugin {
    let detector: NSDataDetector
    
    public init() {
        // ! = 🐱☠️
        detector = try! NSDataDetector(types: NSTextCheckingType.Address.rawValue)
    }
    
    public func tokens(string string: String) -> [Token] {
        var tokens: [Token] = []
        let range = NSRange(location: 0, length: string.characters.count)
        detector.enumerateMatchesInString(string, options: [], range: range) { result, flags, _ in
            guard let range = result?.range else {
                assertionFailure("No range, no result?")
                return
            }
            let address = (string as NSString).substringWithRange(range)
            let token = Token(value: address, range: range.rangeValue, address: address)
            tokens.append(token)
        }
        return tokens
    }
    
    public func merge(lhs: [String : AnyObject], _ rhs: [String : AnyObject]) -> [String : AnyObject] {
        return lhs.merge(rhs)
    }
}

extension Token {
    init(value: String, range: Range<Int>, address: String) {
        self.init(value: value, range: range, storage: [
            "address": address
        ])
    }
    
    public var address: String? {
        return storage["address"] as? String
    }
}