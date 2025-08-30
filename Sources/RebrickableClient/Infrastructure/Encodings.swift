import Foundation

#if !os(macOS)
    import MobileCoreServices
#endif
#if canImport(UniformTypeIdentifiers)
    import UniformTypeIdentifiers
#endif

public enum HTTPMethod: String {
    case options = "OPTIONS"
    case get = "GET"
    case head = "HEAD"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
    case trace = "TRACE"
    case connect = "CONNECT"
}

// ParameterEncoding protocol moved to `Infrastructure/Protocols/ParameterEncoding.swift`

class URLEncoding: ParameterEncoding {
    func encode(request: URLRequest, with parameters: [String: any Sendable]?) throws -> URLRequest
    {
        var urlRequest = request

        guard let parameters else { return urlRequest }

        guard let url = urlRequest.url else { throw DownloadException.requestMissingURL }

        if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
            !parameters.isEmpty
        {
            urlComponents.queryItems = APIHelper.mapValuesToQueryItems(parameters)
            urlRequest.url = urlComponents.url
        }

        return urlRequest
    }
}

class FormDataEncoding: ParameterEncoding {
    let contentTypeForFormPart: (_ fileURL: URL) -> String?

    init(contentTypeForFormPart: @escaping (_ fileURL: URL) -> String?) {
        self.contentTypeForFormPart = contentTypeForFormPart
    }

    func encode(request: URLRequest, with parameters: [String: any Sendable]?) throws -> URLRequest
    {
        var urlRequest = request

        guard let parameters, !parameters.isEmpty else { return urlRequest }

        let boundary = "Boundary-\(UUID().uuidString)"

        urlRequest.setValue(
            "multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        for (key, value) in parameters {
            for value in value as? Array ?? [value] {
                switch value {
                case let fileURL as URL:
                    urlRequest = try configureFileUploadRequest(
                        urlRequest: urlRequest, boundary: boundary, name: key, fileURL: fileURL)
                case let string as String:
                    if let data = string.data(using: .utf8) {
                        urlRequest = configureDataUploadRequest(
                            urlRequest: urlRequest, boundary: boundary, name: key, data: data)
                    }
                case let number as NSNumber:
                    if let data = number.stringValue.data(using: .utf8) {
                        urlRequest = configureDataUploadRequest(
                            urlRequest: urlRequest, boundary: boundary, name: key, data: data)
                    }
                case let data as Data:
                    urlRequest = configureDataUploadRequest(
                        urlRequest: urlRequest, boundary: boundary, name: key, data: data)
                case let uuid as UUID:
                    if let data = uuid.uuidString.data(using: .utf8) {
                        urlRequest = configureDataUploadRequest(
                            urlRequest: urlRequest, boundary: boundary, name: key, data: data)
                    }
                default:
                    fatalError("Unprocessable value \(value) with key \(key)")
                }
            }
        }

        var body = urlRequest.httpBody.orEmpty

        body.append("\r\n--\(boundary)--\r\n")

        urlRequest.httpBody = body

        return urlRequest
    }

    private func configureFileUploadRequest(
        urlRequest: URLRequest, boundary: String, name: String, fileURL: URL
    ) throws -> URLRequest {
        var urlRequest = urlRequest

        var body = urlRequest.httpBody.orEmpty

        let fileData = try Data(contentsOf: fileURL)

        let mimetype = contentTypeForFormPart(fileURL) ?? mimeType(for: fileURL)

        let fileName = fileURL.lastPathComponent

        if !body.isEmpty { body.append("\r\n") }

        body.append("--\(boundary)\r\n")
        body.append(
            "Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\n")
        body.append("Content-Type: \(mimetype)\r\n")
        body.append("\r\n")
        body.append(fileData)

        urlRequest.httpBody = body

        return urlRequest
    }

    private func configureDataUploadRequest(
        urlRequest: URLRequest, boundary: String, name: String, data: Data
    ) -> URLRequest {
        var urlRequest = urlRequest

        var body = urlRequest.httpBody.orEmpty

        if !body.isEmpty { body.append("\r\n") }

        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n")
        body.append("\r\n")
        body.append(data)

        urlRequest.httpBody = body

        return urlRequest
    }

    func mimeType(for url: URL) -> String {
        let pathExtension = url.pathExtension

        if #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) {
            #if canImport(UniformTypeIdentifiers)
                if let utType = UTType(filenameExtension: pathExtension) {
                    return utType.preferredMIMEType ?? "application/octet-stream"
                }
            #else
                return "application/octet-stream"
            #endif
        } else {
            if let uti = UTTypeCreatePreferredIdentifierForTag(
                kUTTagClassFilenameExtension, pathExtension as NSString, nil)?.takeRetainedValue(),
                let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?
                    .takeRetainedValue()
            {
                return mimetype as String
            }
            return "application/octet-stream"
        }
        return "application/octet-stream"
    }
}

class FormURLEncoding: ParameterEncoding {
    func encode(request: URLRequest, with parameters: [String: any Sendable]?) throws -> URLRequest
    {
        var urlRequest = request

        var requestBodyComponents = URLComponents()
        let queryItems = APIHelper.mapValuesToQueryItems(parameters ?? [:])

        let percentEncodedQueryItems = queryItems?.compactMap { queryItem in
            URLQueryItem(
                name: queryItem.name.addingPercentEncoding(withAllowedCharacters: .alphanumerics)
                    ?? queryItem.name,
                value: queryItem.value?.addingPercentEncoding(withAllowedCharacters: .alphanumerics)
                    ?? queryItem.value,
            )
        }
        requestBodyComponents.queryItems = percentEncodedQueryItems

        if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
            urlRequest.setValue(
                "application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        }

        urlRequest.httpBody = requestBodyComponents.query?.data(using: .utf8)

        return urlRequest
    }
}

class OctetStreamEncoding: ParameterEncoding {
    func encode(request: URLRequest, with parameters: [String: any Sendable]?) throws -> URLRequest
    {
        var urlRequest = request

        guard let body = parameters?["body"] else { return urlRequest }

        if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
            urlRequest.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        }

        switch body {
        case let fileURL as URL:
            urlRequest.httpBody = try Data(contentsOf: fileURL)
        case let data as Data:
            urlRequest.httpBody = data
        default:
            fatalError("Unprocessable body \(body)")
        }

        return urlRequest
    }
}

extension Data {
    fileprivate mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) { append(data) }
    }
}

extension Data? {
    fileprivate var orEmpty: Data { self ?? Data() }
}

extension JSONDataEncoding: ParameterEncoding {}
