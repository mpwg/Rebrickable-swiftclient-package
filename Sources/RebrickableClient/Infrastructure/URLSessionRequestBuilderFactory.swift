import Foundation

// MARK: - URLSession Request Builder Factory

internal class URLSessionRequestBuilderFactory: RequestBuilderFactory {
    internal init() {}

    internal func getNonDecodableBuilder<T>() -> RequestBuilder<T>.Type {
        URLSessionRequestBuilder<T>.self
    }

    internal func getBuilder<T: Decodable>() -> RequestBuilder<T>.Type {
        URLSessionDecodableRequestBuilder<T>.self
    }
}
