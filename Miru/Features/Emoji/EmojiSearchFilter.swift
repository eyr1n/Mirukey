import Foundation
import MisskeyAPI

enum EmojiSearchFilter {
  static func filter(
    customEmojis: [MisskeyAPI.EmojiSimple],
    unicodeEmojis: [UnicodeEmoji],
    recentEmojis: [String],
    query: String
  ) -> [String] {
    let query = Reaction(query.trimmingCharacters(in: .whitespacesAndNewlines))
      .name.lowercased()
    guard !query.isEmpty else { return recentEmojis }
    return searchCustom(emojis: customEmojis, query: query)
      .map { ":\($0.name):" }
      + searchUnicode(emojis: unicodeEmojis, query: query).map(\.char)
  }

  private static func searchCustom(
    emojis: [MisskeyAPI.EmojiSimple],
    query: String
  ) -> [MisskeyAPI.EmojiSimple] {
    let max = 100
    var matches: [MisskeyAPI.EmojiSimple] = []
    var seen: Set<String> = []

    func add(_ emoji: MisskeyAPI.EmojiSimple) {
      if seen.insert(emoji.name).inserted { matches.append(emoji) }
    }

    if let exactMatch = emojis.first(where: { $0.name == query }) {
      add(exactMatch)
    }

    if query.contains(" ") {
      let keywords = query.split(separator: " ").map(String.init)

      for emoji in emojis where keywords.allSatisfy({ emoji.name.contains($0) })
      {
        add(emoji)
        if matches.count >= max { break }
      }
      if matches.count >= max { return matches }

      for emoji in emojis
      where keywords.allSatisfy({ keyword in
        emoji.name.contains(keyword)
          || emoji.aliases.contains { $0.contains(keyword) }
      }) {
        add(emoji)
        if matches.count >= max { break }
      }
    } else {
      for emoji in emojis where emoji.aliases.contains(where: { $0 == query }) {
        add(emoji)
        if matches.count >= max { break }
      }
      if matches.count >= max { return matches }

      for emoji in emojis where emoji.name.hasPrefix(query) {
        add(emoji)
        if matches.count >= max { break }
      }
      if matches.count >= max { return matches }

      for emoji in emojis
      where emoji.aliases.contains(where: { $0.hasPrefix(query) }) {
        add(emoji)
        if matches.count >= max { break }
      }
      if matches.count >= max { return matches }

      for emoji in emojis where emoji.name.contains(query) {
        add(emoji)
        if matches.count >= max { break }
      }
      if matches.count >= max { return matches }

      for emoji in emojis
      where emoji.aliases.contains(where: { $0.contains(query) }) {
        add(emoji)
        if matches.count >= max { break }
      }
    }

    return matches
  }

  private static func searchUnicode(
    emojis: [UnicodeEmoji],
    query: String
  ) -> [UnicodeEmoji] {
    let max = 100
    var matches: [UnicodeEmoji] = []
    var seen: Set<String> = []

    func add(_ emoji: UnicodeEmoji) {
      if seen.insert(emoji.char).inserted { matches.append(emoji) }
    }

    if let exactMatch = emojis.first(where: { $0.name == query }) {
      add(exactMatch)
    }

    if query.contains(" ") {
      let keywords = query.split(separator: " ").map(String.init)

      for emoji in emojis where keywords.allSatisfy({ emoji.name.contains($0) })
      {
        add(emoji)
        if matches.count >= max { break }
      }
      if matches.count >= max { return matches }

      for emoji in emojis
      where keywords.allSatisfy({ keyword in
        emoji.aliases.contains { $0.contains(keyword) }
      }) {
        add(emoji)
        if matches.count >= max { break }
      }
    } else {
      for emoji in emojis where emoji.name.hasPrefix(query) {
        add(emoji)
        if matches.count >= max { break }
      }
      if matches.count >= max { return matches }

      for emoji in emojis
      where emoji.aliases.contains(where: { $0.hasPrefix(query) }) {
        add(emoji)
        if matches.count >= max { break }
      }

      for emoji in emojis where emoji.name.contains(query) {
        add(emoji)
        if matches.count >= max { break }
      }
      if matches.count >= max { return matches }

      for emoji in emojis
      where emoji.aliases.contains(where: { $0.contains(query) }) {
        add(emoji)
        if matches.count >= max { break }
      }
    }

    return matches
  }
}
