import Foundation

// MARK: - Parameter Convertible Protocol

protocol ParameterConvertible {
    func asParameter(codableHelper: CodableHelper) -> any Sendable
}
