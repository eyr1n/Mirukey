import APIKit
import Foundation

public extension MisskeyAPI {
  struct FollowingCreateRequest: Request, Encodable, Sendable {
    public var path: String { "following/create" }
    public var method: HTTPMethod { .post }

    public typealias Response = User

    public var userId: String
    public var withReplies: Bool?
    
    public init(userId: String, withReplies: Bool? = nil) {
      self.userId = userId
      self.withReplies = withReplies
    }
  }
}
