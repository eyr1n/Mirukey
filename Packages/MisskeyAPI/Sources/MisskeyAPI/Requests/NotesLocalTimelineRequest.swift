import APIKit
import Foundation

public extension MisskeyAPI {
  struct NotesLocalTimelineRequest: Request, Encodable, Sendable {
    public var path: String { "notes/local-timeline" }
    public var method: HTTPMethod { .post }

    public typealias Response = [Note]

    public var withFiles: Bool?
    public var withRenotes: Bool?
    public var withReplies: Bool?
    public var limit: Int?
    public var sinceId: String?
    public var untilId: String?
    public var allowPartial: Bool?
    public var sinceDate: Int?
    public var untilDate: Int?

    public init(
      withFiles: Bool? = false,
      withRenotes: Bool? = true,
      withReplies: Bool? = false,
      limit: Int? = 10,
      sinceId: String? = nil,
      untilId: String? = nil,
      allowPartial: Bool? = false,
      sinceDate: Int? = nil,
      untilDate: Int? = nil
    ) {
      self.withFiles = withFiles
      self.withRenotes = withRenotes
      self.withReplies = withReplies
      self.limit = limit
      self.sinceId = sinceId
      self.untilId = untilId
      self.allowPartial = allowPartial
      self.sinceDate = sinceDate
      self.untilDate = untilDate
    }
  }
}
