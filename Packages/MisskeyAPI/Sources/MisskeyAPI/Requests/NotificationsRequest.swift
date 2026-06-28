import APIKit
import Foundation

public extension MisskeyAPI {
  struct NotificationsRequest: Request, Encodable, Sendable {
    public var path: String { "i/notifications" }
    public var method: HTTPMethod { .post }

    public typealias Response = [Notification]

    public var limit: Int?
    public var sinceId: String?
    public var untilId: String?
    public var markAsRead: Bool?
    public var includeTypes: [String]?
    public var excludeTypes: [String]?
    
    public init(
      limit: Int? = 10,
      sinceId: String? = nil,
      untilId: String? = nil,
      markAsRead: Bool? = true,
      includeTypes: [String]? = nil,
      excludeTypes: [String]? = nil
    ) {
      self.limit = limit
      self.sinceId = sinceId
      self.untilId = untilId
      self.markAsRead = markAsRead
      self.includeTypes = includeTypes
      self.excludeTypes = excludeTypes
    }
  }
}
