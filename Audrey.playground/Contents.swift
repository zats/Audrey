//: Playground - noun: a place where people can play

import Foundation

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
