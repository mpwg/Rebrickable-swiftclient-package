import Foundation

// MARK: - URLSession Request Builders

internal class URLSessionRequestBuilder<T>: RequestBuilder<T>, @unchecked Sendable {
    internal required init(
        method: String,
        URLString: String,
        parameters: [String: any Sendable]?,
        headers: [String: String] = [:],
        requiresAuthentication: Bool,
        apiConfiguration: OpenAPIClientAPIConfiguration = OpenAPIClientAPIConfiguration.shared,
    ) {
        super.init(
            method: method,
            URLString: URLString,
            parameters: parameters,
            headers: headers,
            requiresAuthentication: requiresAuthentication,
            apiConfiguration: apiConfiguration,
        )
    }

    internal func createURLSession() -> URLSessionProtocol {
        URLSessionRequestBuilderConfiguration.shared.defaultURLSession
    }

    internal func contentTypeForFormPart(fileURL _: URL) -> String? { nil }

    internal func createURLRequest(
        urlSession _: URLSessionProtocol,
        method: HTTPMethod,
        encoding: ParameterEncoding,
        headers _: [String: String],
    ) throws
        -> URLRequest
    {
        guard let url = URL(string: URLString) else {
            throw DownloadException.requestMissingURL
        }

        var originalRequest = URLRequest(url: url)
        originalRequest.httpMethod = method.rawValue

        for (key, value) in buildHeaders() {
            originalRequest.setValue(value, forHTTPHeaderField: key)
        }

        let modifiedRequest = try encoding.encode(request: originalRequest, with: parameters)

        return modifiedRequest
    }

    @discardableResult
    override internal func execute(
        completion:
            @Sendable @escaping (_ result: Swift.Result<Response<T>, ErrorResponse>) -> Void,
    )
        -> RequestTask
    {
        let urlSession = createURLSession()

        guard let xMethod = HTTPMethod(rawValue: method) else {
            fatalError("Unsupported Http method - \(method)")
        }

        let encoding: ParameterEncoding

        switch xMethod {
        case .get, .head:
            encoding = URLEncoding()

        default:
            let contentType = headers["Content-Type"] ?? "application/json"

            if contentType.hasPrefix("application/") && contentType.contains("json") {
                encoding = JSONDataEncoding()
            } else if contentType.hasPrefix("multipart/form-data") {
                encoding = FormDataEncoding(
                    contentTypeForFormPart: contentTypeForFormPart(fileURL:),
                )
            } else if contentType.hasPrefix("application/x-www-form-urlencoded") {
                encoding = FormURLEncoding()
            } else if contentType.hasPrefix("application/octet-stream")
                || contentType.hasPrefix("image/")
            {
                encoding = OctetStreamEncoding()
            } else {
                fatalError("Unsupported Media Type - \(contentType)")
            }
        }

        do {
            let request = try createURLRequest(
                urlSession: urlSession, method: xMethod, encoding: encoding, headers: headers,
            )

            apiConfiguration.interceptor.intercept(
                urlRequest: request, urlSession: urlSession, requestBuilder: self,
            ) { result in
                switch result {
                case .success(let modifiedRequest):
                    let dataTask = urlSession.dataTaskFromProtocol(with: modifiedRequest) {
                        data, response, error in
                        self.cleanupRequest()

                        if let error {
                            self.retryRequest(
                                urlRequest: modifiedRequest, urlSession: urlSession, statusCode: -1,
                                data: data, response: response, error: error,
                                completion: completion,
                            )
                            return
                        }

                        guard let httpResponse = response as? HTTPURLResponse else {
                            self.retryRequest(
                                urlRequest: modifiedRequest, urlSession: urlSession, statusCode: -2,
                                data: data, response: response,
                                error: DecodableRequestBuilderError.nilHTTPResponse,
                                completion: completion,
                            )
                            return
                        }

                        guard
                            self.apiConfiguration.successfulStatusCodeRange.contains(
                                httpResponse.statusCode,
                            )
                        else {
                            self.retryRequest(
                                urlRequest: modifiedRequest, urlSession: urlSession,
                                statusCode: httpResponse.statusCode, data: data,
                                response: httpResponse,
                                error: DecodableRequestBuilderError.unsuccessfulHTTPStatusCode,
                                completion: completion,
                            )
                            return
                        }

                        self.processRequestResponse(
                            urlRequest: request, data: data, httpResponse: httpResponse,
                            error: error, completion: completion,
                        )
                    }

                    self.onProgressReady?(dataTask.progress)

                    URLSessionRequestBuilderConfiguration.shared.credentialStore[
                        dataTask.taskIdentifier,
                    ] = self.credential

                    self.requestTask.set(task: dataTask)

                    dataTask.resume()

                case .failure(let error):
                    self.apiConfiguration.apiResponseQueue.async {
                        completion(.failure(ErrorResponse.error(415, nil, nil, error)))
                    }
                }
            }
        } catch {
            apiConfiguration.apiResponseQueue.async {
                completion(.failure(ErrorResponse.error(415, nil, nil, error)))
            }
        }

        return requestTask
    }

    private func cleanupRequest() {
        if let task = requestTask.get() {
            URLSessionRequestBuilderConfiguration.shared.credentialStore[task.taskIdentifier] = nil
        }
    }

    private func retryRequest(
        urlRequest: URLRequest,
        urlSession: URLSessionProtocol,
        statusCode: Int,
        data: Data?,
        response: URLResponse?,
        error: Error,
        completion:
            @Sendable @escaping (_ result: Swift.Result<Response<T>, ErrorResponse>) -> Void,
    ) {
        apiConfiguration.interceptor.retry(
            urlRequest: urlRequest, urlSession: urlSession, requestBuilder: self, data: data,
            response: response, error: error,
        ) { retry in
            switch retry {
            case .retry:
                self.execute(completion: completion)
            case .dontRetry:
                self.apiConfiguration.apiResponseQueue.async {
                    completion(.failure(ErrorResponse.error(statusCode, data, response, error)))
                }
            }
        }
    }

    fileprivate func processRequestResponse(
        urlRequest _: URLRequest, data: Data?, httpResponse: HTTPURLResponse, error _: Error?,
        completion: @escaping (_ result: Swift.Result<Response<T>, ErrorResponse>) -> Void,
    ) {
        switch T.self {
        case is Void.Type:
            completion(.success(Response(response: httpResponse, body: () as! T, bodyData: data)))
        default:
            fatalError("Unsupported Response Body Type - \(String(describing: T.self))")
        }
    }

    internal func buildHeaders() -> [String: String] {
        var httpHeaders: [String: String] = [:]
        for (key, value) in apiConfiguration.customHeaders {
            httpHeaders[key] = value
        }
        for (key, value) in headers {
            httpHeaders[key] = value
        }
        return httpHeaders
    }

    fileprivate func getFileName(fromContentDisposition contentDisposition: String?) -> String? {
        guard let contentDisposition else { return nil }

        let items = contentDisposition.components(separatedBy: ";")

        var filename: String?

        for contentItem in items {
            let filenameKey = "filename="
            guard let range = contentItem.range(of: filenameKey) else { continue }

            filename = contentItem
            return filename?.replacingCharacters(in: range, with: "").replacingOccurrences(
                of: "\"", with: "",
            ).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return filename
    }

    fileprivate func getPath(from url: URL) throws -> String {
        guard var path = URLComponents(url: url, resolvingAgainstBaseURL: true)?.path else {
            throw DownloadException.requestMissingPath
        }

        if path.hasPrefix("/") { path.remove(at: path.startIndex) }

        return path
    }

    fileprivate func getURL(from urlRequest: URLRequest) throws -> URL {
        guard let url = urlRequest.url else { throw DownloadException.requestMissingURL }
        return url
    }
}

// MARK: - URLSession Decodable Request Builder

internal class URLSessionDecodableRequestBuilder<T: Decodable>: URLSessionRequestBuilder<T>,
    @unchecked Sendable
{
    override fileprivate func processRequestResponse(
        urlRequest: URLRequest,
        data: Data?,
        httpResponse: HTTPURLResponse,
        error: Error?,
        completion: @escaping (_ result: Swift.Result<Response<T>, ErrorResponse>) -> Void,
    ) {
        switch T.self {
        case is String.Type:
            let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
            completion(
                .success(Response<T>(response: httpResponse, body: body as! T, bodyData: data)),
            )

        case is URL.Type:
            do {
                guard error == nil else { throw DownloadException.responseFailed }
                guard let data else { throw DownloadException.responseDataMissing }

                let fileManager = FileManager.default
                let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[
                    0,
                ]
                let requestURL = try getURL(from: urlRequest)

                var requestPath = try getPath(from: requestURL)

                if let headerFileName = getFileName(
                    fromContentDisposition: httpResponse.allHeaderFields["Content-Disposition"]
                        as? String,
                ) {
                    requestPath = requestPath.appending("/\(headerFileName)")
                } else {
                    requestPath = requestPath.appending("/tmp.OpenAPIClient.\(UUID().uuidString)")
                }

                let filePath = cachesDirectory.appendingPathComponent(requestPath)
                let directoryPath = filePath.deletingLastPathComponent().path

                try fileManager.createDirectory(
                    atPath: directoryPath, withIntermediateDirectories: true, attributes: nil,
                )
                try data.write(to: filePath, options: .atomic)

                completion(
                    .success(
                        Response(response: httpResponse, body: filePath as! T, bodyData: data)),
                )
            } catch let requestParserError as DownloadException {
                completion(
                    .failure(ErrorResponse.error(400, data, httpResponse, requestParserError)),
                )
            } catch {
                completion(.failure(ErrorResponse.error(400, data, httpResponse, error)))
            }

        case is Void.Type:
            completion(.success(Response(response: httpResponse, body: () as! T, bodyData: data)))

        case is Data.Type:
            completion(.success(Response(response: httpResponse, body: data as! T, bodyData: data)))

        default:
            guard let unwrappedData = data, !unwrappedData.isEmpty else {
                if let expressibleByNilLiteralType = T.self as? ExpressibleByNilLiteral.Type {
                    completion(
                        .success(
                            Response(
                                response: httpResponse,
                                body: expressibleByNilLiteralType.init(nilLiteral: ()) as! T,
                                bodyData: data,
                            ),
                        ),
                    )
                } else {
                    completion(
                        .failure(
                            ErrorResponse.error(
                                httpResponse.statusCode, nil, httpResponse,
                                DecodableRequestBuilderError.emptyDataResponse,
                            ),
                        ),
                    )
                }
                return
            }

            let decodeResult = apiConfiguration.codableHelper.decode(T.self, from: unwrappedData)

            switch decodeResult {
            case .success(let decodableObj):
                completion(
                    .success(
                        Response(
                            response: httpResponse, body: decodableObj, bodyData: unwrappedData,
                        ),
                    ),
                )
            case .failure(let error):
                completion(
                    .failure(
                        ErrorResponse.error(
                            httpResponse.statusCode, unwrappedData, httpResponse, error,
                        ),
                    ),
                )
            }
        }
    }
}
