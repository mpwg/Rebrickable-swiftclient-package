public class Brix {
    // Class implementation goes here
    public var ApiKey: String = ""

    private let config = OpenAPIClientAPIConfiguration.shared

    public init(apiKey: String) {
        self.ApiKey = apiKey
        config.customHeaders["Authorization"] = "key \(apiKey)"
    }

}
