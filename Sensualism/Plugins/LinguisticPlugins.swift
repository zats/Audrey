import Foundation


private struct StorageFieldName {
    static let lexicalClass = "lexicalClass"
    static let lemma = "lemma"
}

public struct LemmaPlugin: TokenizerPlugin {
    private let tagger: NSLinguisticTagger
    private let options: NSLinguisticTaggerOptions
    
    public init(tagger: NSLinguisticTagger, options: NSLinguisticTaggerOptions) {
        self.tagger = tagger
        self.options = options
    }
    
    public func tokens(string string: String) -> [Token] {
        var result: [Token] = []
        let range = NSRange(location: 0, length: string.characters.count)
        tagger.string = string
        tagger.enumerateTagsInRange(range, scheme: NSLinguisticTagSchemeNameTypeOrLexicalClass, options: options) { lemma, tokenRange, _, _  in
            guard !lemma.isEmpty else {
                return
            }
            let value = (string as NSString).substringWithRange(tokenRange)
            let token = Token(value: value, range: tokenRange.rangeValue, lemma: lemma)
            result.append(token)
        }
        return result
    }
    
    public func merge(lhs: [String: AnyObject], _ rhs: [String: AnyObject]) -> [String: AnyObject] {
        return lhs.merge(rhs)
    }
}

extension Token {
    init(value: String, range: Range<Int>, lemma: String) {
        self.init(value: value, range: range, storage: ["lemma": lemma])
    }
    
    public var lemma: String? {
        return storage["lemma"] as? String
    }
}

public struct LexicalClassPlugin: TokenizerPlugin {
    private let tagger: NSLinguisticTagger
    private let options: NSLinguisticTaggerOptions
    
    public init(tagger: NSLinguisticTagger, options: NSLinguisticTaggerOptions) {
        self.tagger = tagger
        self.options = options
    }
    
    public func tokens(string string: String) -> [Token] {
        var result: [Token] = []
        let range = NSRange(location: 0, length: string.characters.count)
        tagger.string = string
        tagger.enumerateTagsInRange(range, scheme: NSLinguisticTagSchemeNameTypeOrLexicalClass, options: options) { tag, tokenRange, _, _  in
            let value = (string as NSString).substringWithRange(tokenRange)
            let token = Token(value: value, range: tokenRange.rangeValue, lexicalClasses: [tag])
            result.append(token)
        }
        return result
    }
    
    public func merge(lhs: [String: AnyObject], _ rhs: [String: AnyObject]) -> [String: AnyObject] {
        let lhsClass = lhs[StorageFieldName.lexicalClass] as? Set<String>
        let rhsClass = rhs[StorageFieldName.lexicalClass] as? Set<String>
        switch (lhsClass, rhsClass) {
        case (.None, .None):
            return lhs
        case (.Some, .None):
            return lhs
        case (.None, .Some):
            return rhs
        case let (.Some(lhsClass), .Some(rhsClass)):
            var copy = lhs
            copy[StorageFieldName.lexicalClass] = lhsClass.union(rhsClass)
            return copy
        }
    }
}

extension Token {
    init(value: String, range: Range<Int>, lexicalClasses: Set<String>) {
        self.init(value: value, range: range, storage: [StorageFieldName.lexicalClass: lexicalClasses])
    }
    
    public var lexicalClasses: Set<String>? {
        return storage[StorageFieldName.lexicalClass] as? Set<String>
    }
}