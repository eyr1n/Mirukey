import APIKit
import Foundation

public extension MisskeyAPI {
  struct NotesRenotesRequest: Request, Encodable, Sendable {
    public var path: String { "notes/renotes" }
    public var method: HTTPMethod { .post }

    public typealias Response = [Note]

    public var noteId: String
    public var limit: Int?
    public var sinceId: String?
    public var untilId: String?
    
    public init(
      noteId: String,
      limit: Int? = 10,
      sinceId: String? = nil,
      untilId: String? = nil
    ) {
      self.noteId = noteId
      self.limit = limit
      self.sinceId = sinceId
      self.untilId = untilId
    }
  }
}
