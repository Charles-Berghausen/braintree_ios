import Foundation

/// :nodoc: This class is exposed for internal Braintree use only. Do not use. It is not covered by Semantic Versioning and may change or be removed at any time.
/// Contains information specific to a merchant's Braintree integration
@_documentation(visibility: private)
@objcMembers public class BTConfiguration: NSObject {

    /// :nodoc: This property is exposed for internal Braintree use only. Do not use. It is not covered by Semantic Versioning and may change or be removed at any time.
    /// The merchant account's configuration as a `BTJSON` object
    public let json: BTJSON?

    /// :nodoc: This property is exposed for internal Braintree use only. Do not use. It is not covered by Semantic Versioning and may change or be removed at any time.
    /// The environment (production or sandbox)
    public var environment: String? {
        json?["environment"].asString()
    }

    /// :nodoc: This initalizer is exposed for internal Braintree use only. Do not use. It is not covered by Semantic Versioning and may change or be removed at any time.
    ///  Used to initialize a `BTConfiguration`
    /// - Parameter json: The `BTJSON` to initialize with
    @objc(initWithJSON:)
    public init(json: BTJSON?) {
        self.json = json
    }
}
