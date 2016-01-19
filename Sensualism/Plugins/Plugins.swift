import Foundation


public protocol TokenizerPlugin {
    /**
     Produces array of tokens out of specified `string`
     
     - parameter string: Source string to analize
     
     - returns: Array of tokens.
     */
    func tokens(string string: String) -> [Token]
    
    // TODO: make it semantically easier to use
    /**
     Merges two values from the token storage
     
     - parameter lhs: First `Token` storage
     - parameter rhs: Second `Token` storage
     
     - returns: New storage value
     */
    func merge(lhs: [String: AnyObject], _ rhs: [String: AnyObject]) -> [String: AnyObject]
}
