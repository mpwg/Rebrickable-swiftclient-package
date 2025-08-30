import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

extension URLSession: URLSessionProtocol {
    public func dataTaskFromProtocol(
        with request: URLRequest,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, (any Error)?) -> Void,
    ) -> URLSessionDataTaskProtocol {
        dataTask(with: request, completionHandler: completionHandler)
    }
}

extension URLSessionDataTask: URLSessionDataTaskProtocol {}
