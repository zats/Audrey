import Foundation

extension String {
    var entireStringRange: NSRange {
        return NSRange(location: 0, length: self.characters.count)
    }
    
    func stringBySubstituting(substitutions: [(Range<String.Index>, String)]) -> String {
        var string = self
        var offset: Int = 0
        for (range, substitution) in substitutions {
            var range = range
            range.startIndex = range.startIndex.advancedBy(offset)
            range.endIndex = range.endIndex.advancedBy(offset)
            string.replaceRange(range, with: substitution)
            
            offset -= substitution.characters.count
        }
        return string
    }
}

extension NSRange {
    func rangeForString(string: String) -> Range<String.Index> {
        return Range(
            start: string.startIndex.advancedBy(location),
            end:string.startIndex.advancedBy(NSMaxRange(self))
        )
    }
}

extension NSLinguisticTagger {
    func tagsInRange(range: NSRange, scheme: String, options: NSLinguisticTaggerOptions) -> [(Range<String.Index>, String)] {
        guard let string = self.string else {
            return []
        }
        var tags: [(Range<String.Index>, String)] = []
        self.enumerateTagsInRange(range, scheme: scheme, options: options) { tag, range, _, _ in
            let range = range.rangeForString(string)
            tags.append((range, tag))
        }
        return tags
    }
}

let dictionary = ["read": "📚", "eat": "🍽"]
let string = "I ate cornflakes for breakfast. I'm reading the newspaper every day."

let options: NSLinguisticTaggerOptions = [.OmitPunctuation, .OmitWhitespace, .OmitOther, .JoinNames]
let schemes = NSLinguisticTagger.availableTagSchemesForLanguage("en")
let tagger = NSLinguisticTagger(tagSchemes: schemes, options: Int(options.rawValue))
tagger.string = string
let substitutions: [(Range<String.Index>, String)] = tagger.tagsInRange(string.entireStringRange, scheme: NSLinguisticTagSchemeLemma, options: options)
    .flatMap { (range, tag) in
        guard let emoji = dictionary[tag] else {
            return nil
        }
        return (range, emoji)
    }

let result = string.stringBySubstituting(substitutions)
print(result)
