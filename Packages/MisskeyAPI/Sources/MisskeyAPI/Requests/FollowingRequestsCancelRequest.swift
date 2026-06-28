import APIKit
import Foundation

public extension MisskeyAPI {
  struct FollowingRequestsCancelRequest: Request, Encodable, Sendable {
    public var path: String { "following/requests/cancel" }
    public var method: HTTPMethod { .post }

    public typealias Response = User

    public var userId: String
    
    public init(userId: String) {
      self.userId = userId
    }
  }
}
