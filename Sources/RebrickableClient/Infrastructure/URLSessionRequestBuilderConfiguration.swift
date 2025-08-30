import Foundation

// MARK: - URLSession Request Builder Configuration

class URLSessionRequestBuilderConfiguration: @unchecked Sendable {
    private init() {
        defaultURLSession = URLSession(
            configuration: .default, delegate: sessionDelegate, delegateQueue: nil,
        )
    }

    static let shared = URLSessionRequestBuilderConfiguration()

    // Store the URLSession's delegate to retain its reference
    let sessionDelegate = SessionDelegate()

    // Store the URLSession to retain its reference
    let defaultURLSession: URLSession

    // Store current URLCredential for every URLSessionTask
    var credentialStore = SynchronizedDictionary<Int, URLCredential>()
}

// MARK: - Session Delegate

final class SessionDelegate: NSObject, URLSessionTaskDelegate {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void,
    ) {
        var disposition: URLSession.AuthChallengeDisposition = .performDefaultHandling

        var credential: URLCredential?

        if challenge.previousFailureCount > 0 {
            disposition = .rejectProtectionSpace
        } else {
            credential =
                URLSessionRequestBuilderConfiguration.shared.credentialStore[task.taskIdentifier]
                    ?? session
                    .configuration.urlCredentialStorage?.defaultCredential(
                        for: challenge.protectionSpace,
                    )

            if credential != nil {
                disposition = .useCredential
            }
        }

        completionHandler(disposition, credential)
    }
}
