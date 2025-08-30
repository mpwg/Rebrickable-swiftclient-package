import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

open class OpenAPIClientAPIConfiguration: @unchecked Sendable {
    // MARK: - OpenAPI Client Configuration
    public var basePath: String
    public var customHeaders: [String: String]
    public var credential: URLCredential?
    public var requestBuilderFactory: RequestBuilderFactory
    public var apiResponseQueue: DispatchQueue
    public var codableHelper: CodableHelper

    public var successfulStatusCodeRange: Range<Int>

    public var interceptor: OpenAPIInterceptor

    public init(
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

    public static let shared = OpenAPIClientAPIConfiguration()
}
