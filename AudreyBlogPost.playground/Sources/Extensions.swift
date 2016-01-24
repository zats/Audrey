import Foundation

public extension String {
    public var entireStringRange: NSRange {
        return NSRange(location: 0, length: self.characters.count)
    }
}

public extension NSRange {
    public func rangeForString(string: String) -> Range<String.Index> {
        return Range(
            start: string.startIndex.advancedBy(location),
            end:string.startIndex.advancedBy(NSMaxRange(self))
        )
    }
}

