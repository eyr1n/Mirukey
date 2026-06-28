import Foundation

public extension MisskeyAPI {
  struct Meta: Decodable, Sendable {
    public let maintainerName: String?
    public let maintainerEmail: String?
    public let version: String
    public let name: String?
    public let shortName: String?
    public let uri: String
    public let description: String?
    public let langs: [String]
    public let iconUrl: String?
    public let maxNoteTextLength: Double
    public let ads: [Ad]
    public let notesPerOneAd: Double
    public let maxFileSize: Double

    public struct Ad: Decodable, Sendable {
      public let id: String
      public let url: String
      public let place: String
      public let ratio: Double
      public let imageUrl: String
      public let dayOfWeek: Int
      public let isSensitive: Bool?
    }
  }
}
