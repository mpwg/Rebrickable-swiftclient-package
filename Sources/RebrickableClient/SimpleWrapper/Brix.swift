open class Brix {
    // Class implementation goes here
    var ApiKey: String = ""

    private let config = OpenAPIClientAPIConfiguration.shared

    public init(apiKey: String) {
        self.ApiKey = apiKey
        config.customHeaders["Authorization"] = "key \(apiKey)"
    }

    public func GetColors() async {
    do {
        // Implementation for getting colors goes here
        let result = try await LegoAPI.legoColorsList(
            page: 1, pageSize: 20, ordering: nil, apiConfiguration: config)
        print(result)
    } catch {
        print("Error fetching colors: \(error)")
    }
}
