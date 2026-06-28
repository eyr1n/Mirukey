import APIKit
import Foundation

public extension MisskeyAPI {
  struct NotesShowRequest: Request, Encodable, Sendable {
    public var path: String { "notes/show" }
    public var method: HTTPMethod { .post }

    public typealias Response = Note

    public var noteId: String
    
    public init(noteId: String) {
      self.noteId = noteId
    }
  }
}
