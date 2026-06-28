import APIKit
import Foundation

public extension MisskeyAPI {
  struct MiAuthCheckRequest: Request, Sendable {
    public var path: String { "miauth/\(sessionID)/check" }
    public var method: HTTPMethod { .post }

    public struct Response: Decodable, Sendable {
      public let ok: Bool
      public let token: String?
    }

    private let sessionID: String
    
    public init(sessionID: String) {
      self.sessionID = sessionID
    }
  }
}
