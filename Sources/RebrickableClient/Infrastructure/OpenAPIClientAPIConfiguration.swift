import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

internal class OpenAPIClientAPIConfiguration: @unchecked Sendable {
    // MARK: - OpenAPI Client Configuration

    internal var basePath: String
    internal var customHeaders: [String: String]
    internal var credential: URLCredential?
    internal var requestBuilderFactory: RequestBuilderFactory
    internal var apiResponseQueue: DispatchQueue
    internal var codableHelper: CodableHelper

    internal var successfulStatusCodeRange: Range<Int>

    internal var interceptor: OpenAPIInterceptor

    internal init(
        basePath: String = "https://rebrickable.com",
        customHeaders: [String: String] = [:],
        credential: URLCredential? = nil,
        requestBuilderFactory: RequestBuilderFactory = URLSessionRequestBuilderFactory(),
        apiResponseQueue: DispatchQueue = .main,
        codableHelper: CodableHelper = CodableHelper(),
        successfulStatusCodeRange: Range<Int> = 200..<300,
        interceptor: OpenAPIInterceptor = DefaultOpenAPIInterceptor(),
    ) {
        self.basePath = basePath
        self.customHeaders = customHeaders
        self.credential = credential
        self.requestBuilderFactory = requestBuilderFactory
        self.apiResponseQueue = apiResponseQueue
        self.codableHelper = codableHelper
        self.successfulStatusCodeRange = successfulStatusCodeRange
        self.interceptor = interceptor
    }

    internal static let shared = OpenAPIClientAPIConfiguration()
}
