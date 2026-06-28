import APIKit
import Foundation

public extension MisskeyAPI {
  struct NotesDeleteRequest: Request, Encodable, Sendable {
    public var path: String { "notes/delete" }
    public var method: HTTPMethod { .post }

    public typealias Response = Void

    public var noteId: String
    
    public init(noteId: String) {
      self.noteId = noteId
    }
  }
}
