import APIKit
import Foundation

public extension MisskeyAPI {
  struct NotesCreateRequest: Request, Encodable, Sendable {
    public var path: String { "notes/create" }
    public var method: HTTPMethod { .post }

    public struct Response: Decodable, Sendable {
      public let createdNote: Note
    }

    public var visibility: Visibility
    public var visibleUserIds: [String]?
    public var cw: String?
    public var localOnly: Bool
    public var replyId: String?
    public var renoteId: String?
    public var channelId: String?
    public var text: String?
    public var fileIds: [String]?
    public var poll: Poll?

    public enum Visibility: String, Encodable, Sendable {
      case `public`
      case home
      case followers
      case specified
    }

    public struct Poll: Encodable, Sendable {
      public var choices: [String]
      public var multiple: Bool?
      public var expiresAt: Int?
      public var expiredAfter: Int?

      public init(
        choices: [String],
        multiple: Bool? = nil,
        expiresAt: Int? = nil,
        expiredAfter: Int? = nil
      ) {
        self.choices = choices
        self.multiple = multiple
        self.expiresAt = expiresAt
        self.expiredAfter = expiredAfter
      }
    }

    public init(
      visibility: Visibility = .public,
      visibleUserIds: [String]? = nil,
      cw: String? = nil,
      localOnly: Bool = false,
      replyId: String? = nil,
      renoteId: String? = nil,
      channelId: String? = nil,
      text: String? = nil,
      fileIds: [String]? = nil,
      poll: Poll? = nil
    ) {
      self.visibility = visibility
      self.visibleUserIds = visibleUserIds
      self.cw = cw
      self.localOnly = localOnly
      self.replyId = replyId
      self.renoteId = renoteId
      self.channelId = channelId
      self.text = text
      self.fileIds = fileIds
      self.poll = poll
    }
  }
}
