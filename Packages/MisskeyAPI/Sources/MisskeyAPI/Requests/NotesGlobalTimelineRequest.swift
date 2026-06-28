import APIKit
import Foundation

public extension MisskeyAPI {
  struct NotesGlobalTimelineRequest: Request, Encodable, Sendable {
    public var path: String { "notes/global-timeline" }
    public var method: HTTPMethod { .post }

    public typealias Response = [Note]

    public var withFiles: Bool?
    public var withRenotes: Bool?
    public var limit: Int?
    public var sinceId: String?
    public var untilId: String?
    public var sinceDate: Int?
    public var untilDate: Int?

    public init(
      withFiles: Bool? = false,
      withRenotes: Bool? = true,
      limit: Int? = 10,
      sinceId: String? = nil,
      untilId: String? = nil,
      sinceDate: Int? = nil,
      untilDate: Int? = nil
    ) {
      self.withFiles = withFiles
      self.withRenotes = withRenotes
      self.limit = limit
      self.sinceId = sinceId
      self.untilId = untilId
      self.sinceDate = sinceDate
      self.untilDate = untilDate
    }
  }
}
