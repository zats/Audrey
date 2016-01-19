import Foundation

/**
 *  Type representing a token of a sentence
 */
public struct Token {
    public var value: String
    // TODO: Replace with Range<String.Index>
    public var range: Range<Int>
    var storage: [String: AnyObject]
}

extension Token {
    func merge(other: Token, plugins: [TokenizerPlugin]) -> Token {
        let storage = plugins.reduce(self.storage, combine: { storage, plugin in
            let newStorage = plugin.merge(storage, other.storage)
            return storage.merge(newStorage)
        })
        return Token(
            value: self.value,
            range: self.range,
            storage: storage
        )
    }
}

public struct Tokenizer {
    private let plugins: [TokenizerPlugin]
    public init(plugins: [TokenizerPlugin]) {
        self.plugins = plugins
    }
    
    public func tokenize(string: String) -> [Token] {
        var storage = TokenStorage()
        plugins.forEach { plugin in
            plugin.tokens(string: string).forEach { token in
                storage.insert(token, plugins: plugins)
            }
        }
        return storage.tokens
    }
}

extension Tokenizer {
    /**
        If too many tokens contain "Other word" tag, it will try to prefix the string attempting 
        to make it into a full sentance. This works well on simple commands, i.e. 
        "Order me pizza" -> "Could you please Order me pizza"
        Also it'll remove the prefix and corresponding tokens once input was tokenized.
     */
    public func tokenize(string: String, fallbackPrefix: String) -> [Token] {
        let tokens = tokenize(string)
        let otherWordsCount = tokens.reduce(0) {
            if let classes = $1.lexicalClasses {
                return $0 + (classes.contains(NSLinguisticTagOtherWord) ? 1 : 0)
            } else {
                return $0
            }
        }
        guard Double(otherWordsCount) >= Double(tokens.count) * 0.5 else {
            return tokens
        }
        let prefix = fallbackPrefix
        return self.tokenize(prefix + string).filter { token in
            // if token is in the prefix range, don't include it
            return token.range.startIndex >= prefix.characters.count
        }.map { token in
            // adjust token ranges
            var token = token
            token.range.startIndex -= prefix.characters.count
            token.range.endIndex -= prefix.characters.count
            return token
        }

    }
}