import Foundation

internal protocol ParameterEncoding {
    func encode(request: URLRequest, with parameters: [String: any Sendable]?) throws -> URLRequest
}
