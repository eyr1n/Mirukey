import Foundation

public extension MisskeyAPI {
  struct NoteReaction: Decodable, Identifiable, Sendable {
    public let id: String
    public let createdAt: Date
    public let user: User
    public let type: String
  }
}
