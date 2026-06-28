import APIKit
import Foundation

extension Error {
  var isCancellation: Bool {
    switch self {
    case is CancellationError:
      true
    case let error as URLError:
      error.code == .cancelled
    case let error as SessionTaskError:
      switch error {
      case .connectionError(let error):
        error.isCancellation
      default:
        false
      }
    default:
      false
    }
  }
}
