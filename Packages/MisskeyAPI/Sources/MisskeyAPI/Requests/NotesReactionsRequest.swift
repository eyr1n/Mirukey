import APIKit
import Foundation

public extension MisskeyAPI {
  struct NotesReactionsRequest: Request, Encodable, Sendable {
    public var path: String { "notes/reactions" }
    public var method: HTTPMethod { .post }

    public typealias Response = [NoteReaction]

    public var noteId: String
    public var type: String?
    public var limit: Int?
    public var sinceId: String?
    public var untilId: String?
    
    public init(
      noteId: String,
      type: String? = nil,
      limit: Int? = 10,
      sinceId: String? = nil,
      untilId: String? = nil
    ) {
      self.noteId = noteId
      self.type = type
      self.limit = limit
      self.sinceId = sinceId
      self.untilId = untilId
    }
  }
}
