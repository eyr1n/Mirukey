import SwiftUI

public struct MFMEmojiResolver {
  private let resolve: (String) -> URL?

  public init(_ resolve: @escaping (String) -> URL? = { _ in nil }) {
    self.resolve = resolve
  }

  public func callAsFunction(_ shortcode: String) -> URL? {
    resolve(shortcode)
  }
}

private struct MFMEmojiResolverKey: EnvironmentKey {
  static let defaultValue = MFMEmojiResolver()
}

extension EnvironmentValues {
  public var mfmEmojiResolver: MFMEmojiResolver {
    get { self[MFMEmojiResolverKey.self] }
    set { self[MFMEmojiResolverKey.self] = newValue }
  }
}
