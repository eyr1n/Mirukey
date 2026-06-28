import APIKit
import Foundation

public extension MisskeyAPI {
  struct DriveFilesCreateRequest: Request, Encodable, Sendable {
    public var path: String { "drive/files/create" }
    public var method: HTTPMethod { .post }

    public typealias Response = DriveFile

    public var folderId: String?
    public var name: String?
    public var comment: String?
    public var isSensitive: Bool
    public var force: Bool
    public var file: File

    public struct File: Encodable, Sendable {
      public var data: Data
      public var filename: String
      public var mimeType: String

      public init(data: Data, filename: String, mimeType: String) {
        self.data = data
        self.filename = filename
        self.mimeType = mimeType
      }
    }

    public init(
      folderId: String? = nil,
      name: String? = nil,
      comment: String? = nil,
      isSensitive: Bool = false,
      force: Bool = false,
      file: File
    ) {
      self.folderId = folderId
      self.name = name
      self.comment = comment
      self.isSensitive = isSensitive
      self.force = force
      self.file = file
    }

    public var bodyParameters: BodyParameters? {
      var parts: [MultipartFormDataBodyParameters.Part] = []
      if let folderId {
        parts.append(.init(data: Data(folderId.utf8), name: "folderId"))
      }
      if let name {
        parts.append(.init(data: Data(name.utf8), name: "name"))
      }
      if let comment {
        parts.append(.init(data: Data(comment.utf8), name: "comment"))
      }
      parts.append(.init(data: Data((isSensitive ? "true" : "false").utf8), name: "isSensitive"))
      parts.append(.init(data: Data((force ? "true" : "false").utf8), name: "force"))
      parts.append(
        .init(data: file.data, name: "file", mimeType: file.mimeType, fileName: file.filename)
      )
      return MultipartFormDataBodyParameters(parts: parts)
    }
  }
}
