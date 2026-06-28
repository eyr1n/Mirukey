import Foundation

public extension MisskeyAPI {
  final class DriveFolder: Decodable, Identifiable, Sendable {
    public let id: String
    public let createdAt: Date
    public let name: String
    public let parentId: String?
    public let foldersCount: Int?
    public let filesCount: Int?
    public let parent: DriveFolder?
  }
}
