import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

open class RequestBuilder<T>: @unchecked Sendable, Identifiable {
    public var credential: URLCredential?
    public var headers: [String: String]
    public let parameters: [String: any Sendable]?
    public let method: String
    public let URLString: String
    public let requestTask: RequestTask = .init()
    public let requiresAuthentication: Bool
    public let apiConfiguration: OpenAPIClientAPIConfiguration

    /// Optional block to obtain a reference to the request's progress instance when available.
    public var onProgressReady: ((Progress) -> Void)?

    public required init(
        method: String,
        URLString: String,
        parameters: [String: any Sendable]?,
        headers: [String: String] = [:],
        requiresAuthentication: Bool,
        apiConfiguration: OpenAPIClientAPIConfiguration = OpenAPIClientAPIConfiguration.shared,
    ) {
        self.method = method
        self.URLString = URLString
        self.parameters = parameters
        self.headers = headers
        self.requiresAuthentication = requiresAuthentication
        self.apiConfiguration = apiConfiguration

        addHeaders(apiConfiguration.customHeaders)
        addCredential()
    }

    // MARK: - Initialization

    open func addHeaders(_ aHeaders: [String: String]) {
        for (header, value) in aHeaders {
            headers[header] = value
        }
    }

    @discardableResult
    open func execute(
        completion _:
        @Sendable @escaping (_ result: Swift.Result<Response<T>, ErrorResponse>) -> Void,
    )
        -> RequestTask {
        requestTask
    }

    // MARK: - Execution

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @discardableResult
    open func execute() async throws(ErrorResponse) -> Response<T> {
        do {
            let requestTask = requestTask
            return try await withTaskCancellationHandler {
                try Task.checkCancellation()
                return try await withCheckedThrowingContinuation { continuation in
                    guard !Task.isCancelled else {
                        continuation.resume(throwing: CancellationError())
                        return
                    }

                    self.execute { result in
                        switch result {
                        case .success(let response):
                            nonisolated(unsafe) let response = response
                            continuation.resume(returning: response)
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                }
            } onCancel: {
                requestTask.cancel()
            }
        } catch {
            if let errorResponse = error as? ErrorResponse {
                throw errorResponse
            } else {
                throw ErrorResponse.error(-3, nil, nil, error)
            }
        }
    }

    public func addHeader(name: String, value: String) -> Self {
        if !value.isEmpty {
            headers[name] = value
        }
        return self
    }

    // MARK: - Mutators

    open func addCredential() {
        credential = apiConfiguration.credential
    }
}
