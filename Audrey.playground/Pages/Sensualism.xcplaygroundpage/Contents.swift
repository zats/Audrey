import Foundation
//MARK: - Tokens

protocol Token {
}

protocol TokenizerPlugin {
    func process(text: String) -> [Token]
}

//MARK: - Linguistic Tagger Plugins

enum LinguisticTag: Token {
    case Lemma(lemma: String)
    case LexicalClass(`class`: String)
    case LexicalType(type: String)
}

//MARK: - Data Detector plugin

enum DetectedData: Token {
    case PhoneNumber(phoneNumber: String)
    case Link(URL: NSURL)
    case Date(date: NSDate, duration: NSTimeInterval?, timeZone: NSTimeZone?)
    case Address(components: [String: String])
    case Transit(airline: String?, flight: String)
}

private extension DetectedData {
    init?(result: NSTextCheckingResult) {
        let type = result.resultType
        
        if type.contains(.Link) {
            self = .Link(URL: result.URL!)
        } else if type.contains(.PhoneNumber) {
            self = .PhoneNumber(phoneNumber: result.phoneNumber!)
        } else if type.contains(.Address) {
            self = .Address(components: result.addressComponents!)
        } else if type == . {
        } else {
            return nil
        }
    }
}


public struct DataDetectorPlugin: TokenizerPlugin {
    struct Kinds: OptionSetType {
        let rawValue: Int
        
        init(rawValue: Int) { self.rawValue = rawValue }
        
        static let PhoneNumber = Kinds(rawValue: 1)
        static let Link = Kinds(rawValue: 2)
        static let Date = Kinds(rawValue: 4)
        static let Address = Kinds(rawValue: 8)
        static let Transit = Kinds(rawValue: 16)
        
        var dataDetectorTypes: NSTextCheckingType {
            return .Link
        }
    }
    
    let kinds: Kinds
    private let detector: NSDataDetector
    
    init(kinds: Kinds) {
        self.kinds = kinds
        self.detector = try! NSDataDetector(types: kinds.dataDetectorTypes.rawValue)
    }
    
    func process(text: String) -> [Token] {
        
    }
}

//MARK: - Tokenizer

struct Tokenizer {
    struct TokenResult {
        let string: String
        let clusters: [TokenCluster]
    }
    
    struct TokenCluster {
        let range: Range<String.Index>
        let tokens: [Token]
    }
    
    init(plugins: [TokenizerPlugin]) {
        
    }
    
    func process(string: String) -> Result {
        
    }
}
