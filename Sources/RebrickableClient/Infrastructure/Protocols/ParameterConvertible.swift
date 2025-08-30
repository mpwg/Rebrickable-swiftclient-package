import Foundation

protocol ParameterConvertible {
    func asParameter(codableHelper: CodableHelper) -> any Sendable
}
