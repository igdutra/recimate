import Foundation
@testable import ReciMate

/// `invalidData` carries a reason, so it cannot be compared with a plain value.
/// `true` when `error` is `invalidData` with a non-empty reason.
func isInvalidDataWithReason(_ error: any Error) -> Bool {
    guard case let .invalidData(reason)? = error as? RecipeError else { return false }
    return !reason.isEmpty
}
