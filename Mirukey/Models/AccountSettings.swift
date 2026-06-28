import Foundation

struct AccountSettings: Codable {
  private static let recentEmojisLimit = 20

  var defaultVisibility: NoteVisibility = .public
  var recentEmojis: [String] = []

  mutating func addRecentEmoji(_ emoji: String) {
    recentEmojis = Array(
      ([emoji] + recentEmojis.filter { $0 != emoji }).prefix(
        Self.recentEmojisLimit
      )
    )
  }
}
