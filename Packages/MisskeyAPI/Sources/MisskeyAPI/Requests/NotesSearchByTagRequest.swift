import APIKit
import Foundation

public extension MisskeyAPI {
  struct NotesSearchByTagRequest: Request, Encodable, Sendable {
    public var path: String { "notes/search-by-tag" }
    public var method: HTTPMethod { .post }

    public typealias Response = [Note]

    public var reply: Bool?
    public var renote: Bool?
    public var withFiles: Bool?
    public var poll: Bool?
    public var sinceId: String?
    public var untilId: String?
    public var limit: Int?
    public var tag: String?
    public var query: [[String]]?

    public init(
      reply: Bool? = nil,
      renote: Bool? = nil,
      withFiles: Bool? = false,
      poll: Bool? = nil,
      sinceId: String? = nil,
      untilId: String? = nil,
      limit: Int? = 10,
      tag: String? = nil,
      query: [[String]]? = nil
    ) {
      self.reply = reply
      self.renote = renote
      self.withFiles = withFiles
      self.poll = poll
      self.sinceId = sinceId
      self.untilId = untilId
      self.limit = limit
      self.tag = tag
      self.query = query
    }
  }
}
