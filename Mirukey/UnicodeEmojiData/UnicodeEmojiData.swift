import Foundation

enum UnicodeEmojiData {
  static let entries: [UnicodeEmoji] = load()

  private static func load() -> [UnicodeEmoji] {
    let emojiList = loadEmojiList()
    let jaAliases = loadEmojiAliases("emoji_ja")
    let jaHiraAliases = loadEmojiAliases("emoji_ja_hira")
    let enAliases = loadEmojiAliases("emoji_en")

    return emojiList.map { entry in
      return UnicodeEmoji(
        char: entry.emoji,
        name: entry.label,
        aliases: Set(
          (jaAliases[entry.emoji] ?? []) + (jaHiraAliases[entry.emoji] ?? [])
            + (enAliases[entry.emoji] ?? [])
        ).sorted()
      )
    }
  }

  private static func loadEmojiList() -> [EmojiListEntry] {
    guard
      let url = Bundle.main.url(forResource: "emojilist", withExtension: "json")
    else { fatalError("failed to load emojilist") }
    do {
      return try JSONDecoder().decode(
        [EmojiListEntry].self,
        from: Data(contentsOf: url)
      )
    } catch { fatalError("failed to load emojilist") }
  }

  private static func loadEmojiAliases(_ resource: String) -> [String: [String]] {
    guard
      let url = Bundle.main.url(forResource: resource, withExtension: "json")
    else { fatalError("failed to load \(resource)") }
    do {
      return try JSONDecoder().decode(
        [String: [String]].self,
        from: Data(contentsOf: url)
      )
    } catch { fatalError("failed to load \(resource)") }
  }

  private struct EmojiListEntry: Decodable {
    let emoji: String
    let label: String
    let category: Int

    init(from decoder: Decoder) throws {
      var container = try decoder.unkeyedContainer()
      self.emoji = try container.decode(String.self)
      self.label = try container.decode(String.self)
      self.category = try container.decode(Int.self)
    }
  }
}
