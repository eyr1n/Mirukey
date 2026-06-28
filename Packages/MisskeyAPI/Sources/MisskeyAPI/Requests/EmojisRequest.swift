import APIKit
import Foundation

public extension MisskeyAPI {
  struct EmojisRequest: Request, Encodable, Sendable {
    public var path: String { "emojis" }
    public var method: HTTPMethod { .post }

    public struct Response: Decodable, Sendable {
      public let emojis: [EmojiSimple]
    }

    public init() {}
  }
}
