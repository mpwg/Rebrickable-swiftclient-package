import Foundation

// MARK: - URLSession Protocol

public protocol URLSessionProtocol: Sendable {
    func dataTaskFromProtocol(
        with request: URLRequest,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, (any Error)?) -> Void,
    )
        -> URLSessionDataTaskProtocol
}
