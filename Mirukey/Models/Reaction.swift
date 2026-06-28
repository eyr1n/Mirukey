import Foundation

struct Reaction: Identifiable {
  let raw: String
  let count: Int?
  let url: URL?

  init(_ raw: String, count: Int? = nil, url: URL? = nil) {
    self.raw = raw
    self.count = count
    self.url = url
  }

  var id: String { raw }

  var isCustom: Bool {
    raw.hasPrefix(":") && raw.hasSuffix(":") && raw.count >= 2
  }

  var key: String {
    isCustom ? String(raw.dropFirst().dropLast()) : raw
  }

  var name: String {
    raw
      .replacingOccurrences(of: ":", with: "")
      .replacingOccurrences(of: "@.", with: "")
  }

  var localName: String {
    key.hasSuffix("@.") ? String(key.dropLast(2)) : key
  }

  var isRemote: Bool {
    isCustom && key.contains("@") && !key.hasSuffix("@.")
  }

  private var sortRank: Int {
    guard isCustom else { return 2 }
    return isRemote ? 1 : 0
  }

  func resolvingURL(
    emojiURL: (String) -> URL?,
    noteEmojiURLs: [String: String]? = nil
  ) -> Reaction {
    guard isCustom else {
      return self
    }
    if let value = noteEmojiURLs?[key] {
      return Reaction(raw, count: count, url: URL(string: value))
    }
    return Reaction(raw, count: count, url: emojiURL(localName))
  }

  static func sorted(
    from counts: [String: Int],
    emojiURL: (String) -> URL?,
    noteEmojiURLs: [String: String]? = nil
  ) -> [Reaction] {
    counts
      .map {
        Reaction($0.key, count: $0.value)
          .resolvingURL(emojiURL: emojiURL, noteEmojiURLs: noteEmojiURLs)
      }
      .sorted(by: shouldSortBefore)
  }

  private static func shouldSortBefore(
    _ lhs: Reaction,
    _ rhs: Reaction
  ) -> Bool {
    if lhs.count != rhs.count {
      return (lhs.count ?? 0) > (rhs.count ?? 0)
    }
    if lhs.sortRank != rhs.sortRank {
      return lhs.sortRank < rhs.sortRank
    }
    return lhs.raw.localizedCompare(rhs.raw) == .orderedAscending
  }
}
