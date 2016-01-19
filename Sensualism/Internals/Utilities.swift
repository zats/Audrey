import Foundation

extension Dictionary {
    func merge(other: Dictionary<Key, Value>) -> Dictionary<Key, Value> {
        var copy = self
        for (key, value) in other {
            copy[key] = value
        }
        return copy
    }
}

extension NSRange {
    var rangeValue: Range<Int> {
        return Range<Int>(start: location, end: NSMaxRange(self))
    }
}
