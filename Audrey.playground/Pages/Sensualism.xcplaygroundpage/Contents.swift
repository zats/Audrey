//: Playground - noun: a place where people can play

import Foundation
import Sensualism


// Query
let query = "Get uber to 430 Hayes Street"

// Tagger
let schemes = NSLinguisticTagger.availableTagSchemesForLanguage("en")
let options: NSLinguisticTaggerOptions = [.OmitWhitespace, .OmitPunctuation, .JoinNames]
let tagger = NSLinguisticTagger(tagSchemes: schemes, options: Int(options.rawValue))

// Plugins
let plugins: [TokenizerPlugin] = [
    LemmaPlugin(tagger: tagger, options: options),
    LexicalClassPlugin(tagger: tagger, options: options),
    AddressDetectingPlugin()
]

// Extract tokens
let tokenizer = Tokenizer(plugins: plugins)
let tokens = tokenizer.tokenize(query, fallbackPrefix: "Could you please ")


enum Token {
    case Lemma(original)
    case LexicalClass(lexicalClass: LexicalClass)    
}

enum Context {
    case Address(components: [String: String])
    case PhoneNumber(phoneNumber: String)
    case Link(URL: NSURL)
    case Transit(airline: String?, flight: String?)
}

public enum LexicalClass {
    case Verb
    case Adjective
    
    public init?(_ value: String) {
        return nil
    }
}