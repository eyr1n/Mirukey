import APIKit
import Foundation

public extension MisskeyAPI {
  struct MeRequest: Request, Encodable, Sendable {
    public var path: String { "i" }
    public var method: HTTPMethod { .post }

    public typealias Response = User

    public init() {}
  }
}
