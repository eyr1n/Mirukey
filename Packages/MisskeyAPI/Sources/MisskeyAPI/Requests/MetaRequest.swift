import APIKit
import Foundation

public extension MisskeyAPI {
  struct MetaRequest: Request, Encodable, Sendable {
    public var path: String { "meta" }
    public var method: HTTPMethod { .post }

    public typealias Response = Meta

    public var detail: Bool

    public init(detail: Bool = true) {
      self.detail = detail
    }
  }
}
