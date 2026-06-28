import Foundation

public extension MisskeyAPI {
  struct EmojiSimple: Decodable, Sendable {
    public let aliases: [String]
    public let name: String
    public let category: String?
    public let url: String
    public let localOnly: Bool?
    public let isSensitive: Bool?
  }
}
