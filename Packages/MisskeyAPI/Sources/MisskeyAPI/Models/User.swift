import Foundation

public extension MisskeyAPI {
  struct User: Decodable, Identifiable, Sendable {
    // UserLite
    public let id: String
    public let name: String?
    public let username: String
    public let host: String?
    public let avatarUrl: String?
    public let avatarBlurhash: String?
    public let avatarDecorations: [AvatarDecoration]
    public let isBot: Bool?
    public let isCat: Bool?
    public let requireSigninToViewContents: Bool?
    public let makeNotesFollowersOnlyBefore: Int?
    public let makeNotesHiddenBefore: Int?
    public let instance: Instance?
    public let emojis: [String: String]
    public let onlineStatus: String
    public let badgeRoles: [BadgeRole]?

    // UserDetailedNotMeOnly
    public let isLocked: Bool?
    public let description: String?
    public let isFollowing: Bool?
    public let isFollowed: Bool?
    public let hasPendingFollowRequestFromYou: Bool?
    public let hasPendingFollowRequestToYou: Bool?

    // MeDetailedOnly
    public let hasUnreadNotification: Bool?
    public let unreadNotificationsCount: Int?

    public struct AvatarDecoration: Decodable, Identifiable, Sendable {
      public let id: String
      public let angle: Double?
      public let flipH: Bool?
      public let url: String
      public let offsetX: Double?
      public let offsetY: Double?
    }

    public struct Instance: Decodable, Sendable {
      public let name: String?
      public let softwareName: String?
      public let softwareVersion: String?
      public let iconUrl: String?
      public let faviconUrl: String?
      public let themeColor: String?
    }

    public struct BadgeRole: Decodable, Sendable {
      public let name: String
      public let iconUrl: String?
      public let displayOrder: Double
    }
  }
}
