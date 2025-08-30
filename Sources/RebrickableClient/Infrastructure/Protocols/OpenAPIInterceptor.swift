import Foundation

// MARK: - OpenAPI Interceptor Protocol

public enum OpenAPIInterceptorRetry {
    case retry
    case dontRetry
}

public protocol OpenAPIInterceptor {
    func intercept(
        urlRequest: URLRequest,
        urlSession: URLSessionProtocol,
        requestBuilder: RequestBuilder<some Any>,
        completion: @escaping (Result<URLRequest, Error>) -> Void,
    )

    func retry(
        urlRequest: URLRequest,
        urlSession: URLSessionProtocol,
        requestBuilder: RequestBuilder<some Any>,
        data: Data?,
        response: URLResponse?,
        error: Error,
        completion: @escaping (OpenAPIInterceptorRetry) -> Void,
    )
}
