import APIKit
import Foundation

public extension MisskeyAPI {
  struct UsersShowRequest: Request, Encodable, Sendable {
    public var path: String { "users/show" }
    public var method: HTTPMethod { .post }

    public typealias Response = User

    public var userId: String?
    public var username: String?
    public var host: String?
    public var detailed: Bool?
    
    public init(
      userId: String? = nil,
      username: String? = nil,
      host: String? = nil,
      detailed: Bool? = true
    ) {
      self.userId = userId
      self.username = username
      self.host = host
      self.detailed = detailed
    }
  }
}
