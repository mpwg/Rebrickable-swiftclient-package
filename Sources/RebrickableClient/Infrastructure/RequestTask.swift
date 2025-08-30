import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

public final class RequestTask: @unchecked Sendable {
    // MARK: - Request Task
    private let lock = NSRecursiveLock()
    private var task: URLSessionDataTaskProtocol?

    func set(task: URLSessionDataTaskProtocol) {
        lock.withLock {
            self.task = task
        }
    }

    func get() -> URLSessionDataTaskProtocol? {
        lock.withLock {
            task
        }
    }

    public func cancel() {
        lock.withLock {
            task?.cancel()
            task = nil
        }
    }
}
