import Foundation

// MARK: - URLSession Protocol

internal protocol URLSessionProtocol: Sendable {
    func dataTaskFromProtocol(
        with request: URLRequest,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, (any Error)?) -> Void,
    )
        -> URLSessionDataTaskProtocol
}
