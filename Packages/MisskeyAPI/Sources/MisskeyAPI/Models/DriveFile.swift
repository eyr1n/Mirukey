import Foundation

public extension MisskeyAPI {
  struct DriveFile: Decodable, Identifiable, Sendable {
    public let id: String
    public let createdAt: Date
    public let name: String
    public let type: String
    public let md5: String
    public let size: Int
    public let isSensitive: Bool
    public let isSensitiveByModerator: Bool?
    public let blurhash: String?
    public let properties: Properties
    public let url: String
    public let thumbnailUrl: String?
    public let comment: String?
    public let folderId: String?
    public let folder: DriveFolder?
    public let userId: String?
    public let user: User?

    public struct Properties: Decodable, Sendable {
      public let width: Double?
      public let height: Double?
      public let orientation: Double?
      public let avgColor: String?
    }
  }
}
