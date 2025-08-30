import Foundation

// MARK: - URLSession Request Builder Factory

public class URLSessionRequestBuilderFactory: RequestBuilderFactory {
    public init() {}

    public func getNonDecodableBuilder<T>() -> RequestBuilder<T>.Type {
        URLSessionRequestBuilder<T>.self
    }

    public func getBuilder<T: Decodable>() -> RequestBuilder<T>.Type {
        URLSessionDecodableRequestBuilder<T>.self
    }
}
