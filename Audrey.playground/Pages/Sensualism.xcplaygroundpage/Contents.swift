import Foundation

//MARK: - Tokens

protocol TokenValue {
}

struct Token {
    let string: String
    var range: Range<String.Index>
    var values: [TokenValue]
    
    func merge(other: Token) -> Token {
        var result = self
        result.values += other.values
        return result
    }
}

protocol TokenizerPlugin {
    func process(text: String) -> [Token]
}

//MARK: - Linguistic Tagger Plugins

enum LinguisticTag: TokenValue {
    case Lemma(lemma: String)
    case LexicalClass(`class`: String)
    case TokenType(type: String)
    
    init?(scheme: String, value: String) {
        switch scheme {
        case NSLinguisticTagSchemeLemma:
            self = .Lemma(lemma: value)
        case NSLinguisticTagSchemeLexicalClass:
            self = .LexicalClass(`class`: value)
        case NSLinguisticTagSchemeTokenType:
            self = .TokenType(type: value)
        default:
            return nil
        }
    }
}

struct LinguisticTaggerPlugin: TokenizerPlugin {
    private let tagger: NSLinguisticTagger
    let fallbackPrefix: String?
    let scheme: String
    let options: NSLinguisticTaggerOptions
    
    init(scheme: String, options: NSLinguisticTaggerOptions, fallbackPrefix: String? = nil) {
        self.tagger = NSLinguisticTagger(tagSchemes: [scheme], options: Int(options.rawValue))
        self.scheme = scheme
        self.options = options
        self.fallbackPrefix = fallbackPrefix
    }
    
    func process(text: String) -> [Token] {
        let result = _process(text)
        
        guard let fallbackPrefix = fallbackPrefix else {
            return result
        }
        return _process(result, text: text, fallbackPrefix: fallbackPrefix)
    }
    
    private func _process(result: [Token], text: String, fallbackPrefix: String) -> [Token] {
        let blackList: Set<String>
        switch scheme {
        case NSLinguisticTagSchemeLexicalClass:
            blackList = [NSLinguisticTagOtherWord]
        case NSLinguisticTagSchemeLemma:
            blackList = [""]
        default:
            blackList = []
        }
        let otherWordsCount = result.reduce(0) { result, token in
            return result + token.values.reduce(0) { result, value in
                if case let LinguisticTag.LexicalClass(`class`) = value {
                    return blackList.contains(`class`) ? 1 : 0
                } else if case let LinguisticTag.Lemma(lemma) = value {
                    return blackList.contains(lemma) ? 1 : 0
                } else {
                    return 1
                }
            }
        }
        guard Float(otherWordsCount) / Float(result.count) > 0.7 else {
            return result
        }
        
        // For simple commands adding a prefix
        let prefix = fallbackPrefix
        let prefixRange = Range(start: prefix.startIndex, end: prefix.endIndex)
        let offset = -prefix.characters.count
        let augmentedResult = _process(prefix + text)
        return augmentedResult.flatMap { token in
            if prefixRange.contains(token.range.endIndex) {
                return nil
            }
            var token = token
            token.range.startIndex = token.range.startIndex.advancedBy(offset)
            token.range.endIndex = token.range.endIndex.advancedBy(offset)
            return token
        }
    }
    
    private func _process(text: String) -> [Token] {
        let entireTextRange = text.entireStringRange
        tagger.string = text
        return (tagger
            .tagsInRange(entireTextRange, scheme: scheme, options: options) ?? [])
            .flatMap { tuple in
                guard let tag = LinguisticTag(scheme: scheme, value: tuple.tag) else {
                    return nil
                }
                return Token(
                    string: text.substringWithRange(tuple.range),
                    range: tuple.range,
                    values: [tag])
            }

    }
}

private extension NSLinguisticTagger {
    func tagsInRange(range: NSRange, scheme: String, options: NSLinguisticTaggerOptions) -> [(tag: String, range: Range<String.Index>)]? {
        guard let string = self.string else {
            return nil
        }
        var results: [(tag: String, range: Range<String.Index>)] = []
        enumerateTagsInRange(range, scheme: scheme, options: options) { tag, range, _, _ in
            results.append((tag: tag, range: range.rangeInString(string)))
        }
        return results
    }
}

//MARK: - Data Detector plugin

enum DetectedData: TokenValue {
    case PhoneNumber(phoneNumber: String)
    case Link(URL: NSURL)
    case Date(date: NSDate, duration: NSTimeInterval?, timeZone: NSTimeZone?)
    case Address(components: [String: String])
    case Transit(airline: String?, flight: String)
}

private func ~=(lhs: NSTextCheckingType, rhs: NSTextCheckingType) -> Bool {
    return lhs == rhs
}

private extension DetectedData {
    init?(result: NSTextCheckingResult) {
        let type = result.resultType
        switch type {
        case NSTextCheckingType.Address where result.addressComponents != nil:
            self = .Address(components: result.addressComponents!)
        case NSTextCheckingType.Link where result.URL != nil:
            self = .Link(URL: result.URL!)
        case NSTextCheckingType.PhoneNumber where result.phoneNumber != nil:
            self = .PhoneNumber(phoneNumber: result.phoneNumber!)
        case NSTextCheckingType.TransitInformation where result.components?[NSTextCheckingFlightKey] != nil:
            self = .Transit(airline: result.components![NSTextCheckingAirlineKey], flight: result.components![NSTextCheckingFlightKey]!)
        case NSTextCheckingType.Date where result.date != nil:
            self = .Date(date: result.date!, duration: result.duration == 0 ? nil : result.duration, timeZone: result.timeZone)
        default:
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
            var result: NSTextCheckingType = []
            if self.contains(.PhoneNumber) { result.insert(.PhoneNumber) }
            if self.contains(.Link) { result.insert(.Link) }
            if self.contains(.Date) { result.insert(.Date) }
            if self.contains(.Address) { result.insert(.Address) }
            if self.contains(.Transit) { result.insert(.TransitInformation) }
            return result
        }
    }
    
    let kinds: Kinds
    private let detector: NSDataDetector
    
    init(kinds: Kinds) {
        self.kinds = kinds
        self.detector = try! NSDataDetector(types: kinds.dataDetectorTypes.rawValue)
    }
    
    func process(text: String) -> [Token] {
        return detector
            .matchesInString(text, options: [], range: text.entireStringRange)
            .flatMap{
                guard let token = DetectedData(result: $0) else {
                    return nil
                }
                let range = $0.range.rangeInString(text)
                return Token(
                    string: text.substringWithRange(range),
                    range: range,
                    values: [token])
            }
    }
}

//MARK: - Tokenizer

struct Tokenizer {
    struct Result {
        let text: String
        let tokens: [Token]
    }
    
    let plugins: [TokenizerPlugin]
    
    init(plugins: [TokenizerPlugin]) {
        self.plugins = plugins
    }
    
    func process(text: String) -> Result {
        var hash: [RangeHash: Token] = [:]
        for plugin in plugins {
            for token in plugin.process(text) {

                let rangeHash = RangeHash(token, text)
                let newToken: Token
                if let existentToken = hash[rangeHash] {
                    newToken = existentToken.merge(token)
                } else {
                    newToken = token
                }
                hash[rangeHash] = newToken
            }
        }
        return Result(text: text, tokens: hash.values.sort{ token1, token2 in token1.range.startIndex < token2.range.startIndex })
    }
}

private struct RangeHash: Hashable {
    let token: Token
    let string: String
    
    init(_ token: Token, _ string: String) {
        self.token = token
        self.string = string
    }
    
    var hashValue: Int {
        return string.startIndex.distanceTo(token.range.startIndex) ^ string.startIndex.distanceTo(token.range.endIndex)
    }
}

private func == (lhs: RangeHash, rhs: RangeHash) -> Bool {
    return lhs.token.range == rhs.token.range
}


// MARK: - Utility

extension String {
    var entireStringRange: NSRange {
        return NSRange(location: 0, length: characters.count)
    }
}

extension NSRange {
    func rangeInString(string: String) -> Range<String.Index> {
        return Range(
            start: string.startIndex.advancedBy(self.location),
            end: string.startIndex.advancedBy(NSMaxRange(self))
        )
    }
}

//MARK: - Example

let options: NSLinguisticTaggerOptions = [.OmitOther, .JoinNames, .OmitPunctuation, .OmitWhitespace]
let lemmaPlugin = LinguisticTaggerPlugin(scheme: NSLinguisticTagSchemeLemma, options: options)
let lexicalClassPlugin = LinguisticTaggerPlugin(scheme: NSLinguisticTagSchemeLexicalClass, options: options, fallbackPrefix: "Siri, ")
let dataDetectorPlugin = DataDetectorPlugin(kinds: [.Address, .Date])
let tokenizer = Tokenizer(plugins: [lemmaPlugin, lexicalClassPlugin, dataDetectorPlugin])

let sampleText = "remind me to bring some socks tomorrow"
tokenizer.process(sampleText).tokens.forEach{print($0)}

