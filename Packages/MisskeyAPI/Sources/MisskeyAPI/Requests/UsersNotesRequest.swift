import APIKit
import Foundation

public extension MisskeyAPI {
  struct UsersNotesRequest: Request, Encodable, Sendable {
    public var path: String { "users/notes" }
    public var method: HTTPMethod { .post }

    public typealias Response = [Note]

    public var userId: String
    public var withReplies: Bool?
    public var withRenotes: Bool?
    public var withChannelNotes: Bool?
    public var limit: Int?
    public var sinceId: String?
    public var untilId: String?
    public var sinceDate: Int?
    public var untilDate: Int?
    public var allowPartial: Bool?
    public var withFiles: Bool?
    
    public init(
      userId: String,
      withReplies: Bool? = false,
      withRenotes: Bool? = true,
      withChannelNotes: Bool? = false,
      limit: Int? = 10,
      sinceId: String? = nil,
      untilId: String? = nil,
      sinceDate: Int? = nil,
      untilDate: Int? = nil,
      allowPartial: Bool? = false,
      withFiles: Bool? = false
    ) {
      self.userId = userId
      self.withReplies = withReplies
      self.withRenotes = withRenotes
      self.withChannelNotes = withChannelNotes
      self.limit = limit
      self.sinceId = sinceId
      self.untilId = untilId
      self.sinceDate = sinceDate
      self.untilDate = untilDate
      self.allowPartial = allowPartial
      self.withFiles = withFiles
    }
  }
}
