import Foundation

// MARK: - Default OpenAPI Interceptor

internal class DefaultOpenAPIInterceptor: OpenAPIInterceptor {
    internal init() {}

    internal func intercept(
        urlRequest: URLRequest,
        urlSession _: URLSessionProtocol,
        requestBuilder _: RequestBuilder<some Any>,
        completion: @escaping (Result<URLRequest, any Error>) -> Void,
    ) {
        completion(.success(urlRequest))
    }

    internal func retry(
        urlRequest _: URLRequest,
        urlSession _: URLSessionProtocol,
        requestBuilder _: RequestBuilder<some Any>,
        data _: Data?,
        response _: URLResponse?,
        error _: Error,
        completion: @escaping (OpenAPIInterceptorRetry) -> Void,
    ) {
        completion(.dontRetry)
    }
}
