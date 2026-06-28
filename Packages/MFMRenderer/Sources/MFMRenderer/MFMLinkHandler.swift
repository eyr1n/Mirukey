import SwiftUI

public enum MFMLink: Hashable {
  case mention(acct: String)
  case hashtag(tag: String)
}

public struct MFMLinkHandler {
  private let handle: (MFMLink) -> Void

  public init(_ handle: @escaping (MFMLink) -> Void = { _ in }) {
    self.handle = handle
  }

  public func callAsFunction(_ link: MFMLink) {
    handle(link)
  }
}

private struct MFMLinkHandlerKey: EnvironmentKey {
  static let defaultValue = MFMLinkHandler()
}

extension EnvironmentValues {
  public var mfmLinkHandler: MFMLinkHandler {
    get { self[MFMLinkHandlerKey.self] }
    set { self[MFMLinkHandlerKey.self] = newValue }
  }
}
