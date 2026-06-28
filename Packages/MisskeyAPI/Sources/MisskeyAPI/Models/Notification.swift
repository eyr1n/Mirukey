import Foundation

extension MisskeyAPI {
  public enum Notification: Decodable, Identifiable, Sendable {
    case note(Note)
    case mention(Mention)
    case reply(Reply)
    case renote(Renote)
    case quote(Quote)
    case reaction(Reaction)
    case pollEnded(PollEnded)
    case follow(Follow)
    case receiveFollowRequest(ReceiveFollowRequest)
    case followRequestAccepted(FollowRequestAccepted)
    case roleAssigned(RoleAssigned)
    case achievementEarned(AchievementEarned)
    case exportCompleted(ExportCompleted)
    case login(Login)
    case sensitiveFlagAssigned(SensitiveFlagAssigned)
    case createToken(CreateToken)
    case app(App)
    case reactionGrouped(ReactionGrouped)
    case renoteGrouped(RenoteGrouped)
    case test(Test)
    case unknown(Unknown)

    public var id: String { payload.id }
    public var createdAt: Date { payload.createdAt }
    public var type: String { payload.type }

    private var payload: any Payload {
      switch self {
      case .note(let payload): payload
      case .mention(let payload): payload
      case .reply(let payload): payload
      case .renote(let payload): payload
      case .quote(let payload): payload
      case .reaction(let payload): payload
      case .pollEnded(let payload): payload
      case .follow(let payload): payload
      case .receiveFollowRequest(let payload): payload
      case .followRequestAccepted(let payload): payload
      case .roleAssigned(let payload): payload
      case .achievementEarned(let payload): payload
      case .exportCompleted(let payload): payload
      case .login(let payload): payload
      case .sensitiveFlagAssigned(let payload): payload
      case .createToken(let payload): payload
      case .app(let payload): payload
      case .reactionGrouped(let payload): payload
      case .renoteGrouped(let payload): payload
      case .test(let payload): payload
      case .unknown(let payload): payload
      }
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      let type = try container.decode(String.self, forKey: .type)
      self =
        switch type {
        case "note": .note(try .init(from: decoder))
        case "mention": .mention(try .init(from: decoder))
        case "reply": .reply(try .init(from: decoder))
        case "renote": .renote(try .init(from: decoder))
        case "quote": .quote(try .init(from: decoder))
        case "reaction": .reaction(try .init(from: decoder))
        case "pollEnded": .pollEnded(try .init(from: decoder))
        case "follow": .follow(try .init(from: decoder))
        case "receiveFollowRequest":
          .receiveFollowRequest(try .init(from: decoder))
        case "followRequestAccepted":
          .followRequestAccepted(try .init(from: decoder))
        case "roleAssigned": .roleAssigned(try .init(from: decoder))
        case "achievementEarned": .achievementEarned(try .init(from: decoder))
        case "exportCompleted": .exportCompleted(try .init(from: decoder))
        case "login": .login(try .init(from: decoder))
        case "sensitiveFlagAssigned":
          .sensitiveFlagAssigned(try .init(from: decoder))
        case "createToken": .createToken(try .init(from: decoder))
        case "app": .app(try .init(from: decoder))
        case "reaction:grouped": .reactionGrouped(try .init(from: decoder))
        case "renote:grouped": .renoteGrouped(try .init(from: decoder))
        case "test": .test(try .init(from: decoder))
        default: .unknown(try .init(from: decoder))
        }
    }

    public protocol Payload: Decodable, Identifiable, Sendable {
      var id: String { get }
      var createdAt: Date { get }
      var type: String { get }
    }

    public struct Note: Payload {
      public let id: String
      public let createdAt: Date
      public let type: String
      public let user: User
      public let userId: String
      public let note: MisskeyAPI.Note
    }

    public struct Mention: Payload {
      public let id: String
      public let createdAt: Date
      public let type: String
      public let user: User
      public let userId: String
      public let note: MisskeyAPI.Note
    }

    public struct Reply: Payload {
      public let id: String
      public let createdAt: Date
      public let type: String
      public let user: User
      public let userId: String
      public let note: MisskeyAPI.Note
    }

    public struct Renote: Payload {
      public let id: String
      public let createdAt: Date
      public let type: String
      public let user: User
      public let userId: String
      public let note: MisskeyAPI.Note
    }

    public struct Quote: Payload {
      public let id: String
      public let createdAt: Date
      public let type: String
      public let user: User
      public let userId: String
      public let note: MisskeyAPI.Note
    }

    public struct Reaction: Payload {
      public let id: String
      public let createdAt: Date
      public let type: String
      public let user: User
      public let userId: String
      public let note: MisskeyAPI.Note
      public let reaction: String
    }

    public struct PollEnded: Payload {
      public let id: String
      public let createdAt: Date
      public let type: String
      public let user: User
      public let userId: String
      public let note: MisskeyAPI.Note
    }

    public struct Follow: Payload {
      public let id: String
      public let createdAt: Date
      public let type: String
      public let user: User
      public let userId: String
    }

    public struct ReceiveFollowRequest: Payload {
      public let id: String
      public let createdAt: Date
      public let type: String
      public let user: User
      public let userId: String
    }

    public struct FollowRequestAccepted: Payload {
      public let id: String
      public let createdAt: Date
      public let type: String
      public let user: User
      public let userId: String
      public let message: String?
    }

    public struct RoleAssigned: Payload {
      public let id: String
      public let createdAt: Date
      public let type: String
    }

    public struct AchievementEarned: Payload {
      public let id: String
      public let createdAt: Date
      public let type: String
      public let achievement: String
    }

    public struct ExportCompleted: Payload {
      public let id: String
      public let createdAt: Date
      public let type: String
      public let exportedEntity: String
      public let fileId: String
    }

    public struct Login: Payload {
      public let id: String
      public let createdAt: Date
      public let type: String
    }

    public struct SensitiveFlagAssigned: Payload {
      public let id: String
      public let createdAt: Date
      public let type: String
    }

    public struct CreateToken: Payload {
      public let id: String
      public let createdAt: Date
      public let type: String
    }

    public struct App: Payload {
      public let id: String
      public let createdAt: Date
      public let type: String
      public let body: String
      public let header: String?
      public let icon: String?
    }

    public struct ReactionGrouped: Payload {
      public let id: String
      public let createdAt: Date
      public let type: String
      public let note: MisskeyAPI.Note
      public let reactions: [GroupedReaction]
    }

    public struct GroupedReaction: Decodable, Sendable {
      public let user: User
      public let reaction: String
    }

    public struct RenoteGrouped: Payload {
      public let id: String
      public let createdAt: Date
      public let type: String
      public let note: MisskeyAPI.Note
      public let users: [User]
    }

    public struct Test: Payload {
      public let id: String
      public let createdAt: Date
      public let type: String
    }

    public struct Unknown: Payload {
      public let id: String
      public let createdAt: Date
      public let type: String
    }

    private enum CodingKeys: CodingKey {
      case type
    }
  }

}
