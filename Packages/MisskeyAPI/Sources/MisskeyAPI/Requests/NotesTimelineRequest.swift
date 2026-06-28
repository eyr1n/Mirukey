import APIKit
import Foundation

public extension MisskeyAPI {
  struct NotesTimelineRequest: Request, Encodable, Sendable {
    public var path: String { "notes/timeline" }
    public var method: HTTPMethod { .post }

    public typealias Response = [Note]

    public var limit: Int?
    public var sinceId: String?
    public var untilId: String?
    public var sinceDate: Int?
    public var untilDate: Int?
    public var allowPartial: Bool?
    public var includeMyRenotes: Bool?
    public var includeRenotedMyNotes: Bool?
    public var includeLocalRenotes: Bool?
    public var withFiles: Bool?
    public var withRenotes: Bool?

    public init(
      limit: Int? = 10,
      sinceId: String? = nil,
      untilId: String? = nil,
      sinceDate: Int? = nil,
      untilDate: Int? = nil,
      allowPartial: Bool? = false,
      includeMyRenotes: Bool? = true,
      includeRenotedMyNotes: Bool? = true,
      includeLocalRenotes: Bool? = true,
      withFiles: Bool? = false,
      withRenotes: Bool? = true
    ) {
      self.limit = limit
      self.sinceId = sinceId
      self.untilId = untilId
      self.sinceDate = sinceDate
      self.untilDate = untilDate
      self.allowPartial = allowPartial
      self.includeMyRenotes = includeMyRenotes
      self.includeRenotedMyNotes = includeRenotedMyNotes
      self.includeLocalRenotes = includeLocalRenotes
      self.withFiles = withFiles
      self.withRenotes = withRenotes
    }
  }
}
