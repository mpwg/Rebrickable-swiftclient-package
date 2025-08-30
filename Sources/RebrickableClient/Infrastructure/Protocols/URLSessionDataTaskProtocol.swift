import Foundation

// MARK: - URLSession Data Task Protocol

public protocol URLSessionDataTaskProtocol {
    func resume()

    var taskIdentifier: Int { get }

    var progress: Progress { get }

    func cancel()
}
