import Foundation

public protocol URLSessionDataTaskProtocol {
    func resume()

    var taskIdentifier: Int { get }

    var progress: Progress { get }

    func cancel()
}
