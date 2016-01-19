import Foundation

struct TokenStorage {
    private var storage: Set<TokenWrapper> = []
    
    var tokens: [Token] {
        return storage.flatMap{$0.token}.sort { lhs, rhs in
            return lhs.range.startIndex < rhs.range.startIndex
        }
    }
    
    mutating func insert(token: Token, plugins: [TokenizerPlugin]) {
        let wrapper = TokenWrapper(token: token)
        let newWrapper: TokenWrapper
        if let index = storage.indexOf(wrapper), existentToken = storage[index].token {
            let newToken = existentToken.merge(token, plugins: plugins)
            newWrapper = TokenWrapper(token: newToken)
        } else {
            newWrapper = TokenWrapper(token: token)
        }
        storage.insert(newWrapper)
    }
}

private struct TokenWrapper: Hashable {
    let token: Token?
    let range: Range<Int>
    
    init(range: Range<Int>) {
        self.range = range
        self.token = nil
    }
    
    init(token: Token) {
        self.token = token
        self.range = token.range
    }
    
    var hashValue: Int {
        return range.startIndex ^ range.endIndex
    }
}

private func ==(lhs: TokenWrapper, rhs: TokenWrapper) -> Bool {
    return lhs.range == rhs.range
}