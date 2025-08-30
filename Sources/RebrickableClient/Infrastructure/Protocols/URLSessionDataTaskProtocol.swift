import Foundation

// MARK: - URLSession Data Task Protocol

internal protocol URLSessionDataTaskProtocol {
    func resume()

    var taskIdentifier: Int { get }

    var progress: Progress { get }

    func cancel()
}
