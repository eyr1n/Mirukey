import APIKit
import Foundation

public extension MisskeyAPI {
  struct NotesReactionsCreateRequest: Request, Encodable, Sendable {
    public var path: String { "notes/reactions/create" }
    public var method: HTTPMethod { .post }

    public typealias Response = Void

    public var noteId: String
    public var reaction: String
    
    public init(noteId: String, reaction: String) {
      self.noteId = noteId
      self.reaction = reaction
    }
  }
}
