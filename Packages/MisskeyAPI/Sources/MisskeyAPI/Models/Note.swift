import Foundation

public extension MisskeyAPI {
  final class Note: Decodable, Identifiable, Sendable {
    public let id: String
    public let createdAt: Date
    public let deletedAt: Date?
    public let text: String?
    public let cw: String?
    public let userId: String
    public let user: User
    public let replyId: String?
    public let renoteId: String?
    public let reply: Note?
    public let renote: Note?
    public let isHidden: Bool?
    public let visibility: String
    public let mentions: [String]?
    public let visibleUserIds: [String]?
    public let fileIds: [String]?
    public let files: [DriveFile]?
    public let tags: [String]?
    public let poll: Poll?
    public let emojis: [String: String]?
    public let channelId: String?
    public let channel: Channel?
    public let localOnly: Bool?
    public let reactionAcceptance: String?
    public let reactionEmojis: [String: String]
    public let reactions: [String: Int]
    public let reactionCount: Int
    public let renoteCount: Int
    public let repliesCount: Int
    public let uri: String?
    public let url: String?
    public let myReaction: String?

    public struct Channel: Decodable, Identifiable, Sendable {
      public let id: String
      public let name: String
      public let color: String
      public let isSensitive: Bool
      public let allowRenoteToExternal: Bool
      public let userId: String?
    }

    public struct Poll: Decodable, Sendable {
      public let expiresAt: Date?
      public let multiple: Bool
      public let choices: [Choice]

      public struct Choice: Decodable, Sendable {
        public let isVoted: Bool
        public let text: String
        public let votes: Int
      }
    }
  }
}
