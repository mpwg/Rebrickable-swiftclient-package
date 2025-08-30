import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - URLSession Protocol conformances

extension URLSession: URLSessionProtocol {
    public func dataTaskFromProtocol(
        with request: URLRequest,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, (any Error)?) -> Void,
    )
        -> URLSessionDataTaskProtocol {
        dataTask(with: request, completionHandler: completionHandler)
    }
}

extension URLSessionDataTask: URLSessionDataTaskProtocol {}

// MARK: - URLSessionDataTask helpers
