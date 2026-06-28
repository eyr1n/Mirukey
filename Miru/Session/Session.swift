import APIKit
import MisskeyAPI
import SwiftUI

@Observable
final class Session {
  let account: Account
  let apiKit: APIKit.Session
  private(set) var emojis: [String: MisskeyAPI.EmojiSimple] = [:]
  var unreadNotificationCount: Int = 0

  var name: String?
  var avatarURL: URL?

  var settings: AccountSettings {
    didSet {
      UserDefaults.standard.set(
        try? JSONEncoder().encode(settings),
        forKey: "accountSettings.\(account.id)"
      )
    }
  }

  init(account: Account) {
    self.account = account
    self.apiKit = APIKit.Session(
      adapter: MisskeyAPI.SessionAdapter(
        baseURL: account.serverURL.appending(path: "api"),
        token: account.token
      )
    )
    self.settings =
      UserDefaults.standard.data(forKey: "accountSettings.\(account.id)")
      .flatMap { try? JSONDecoder().decode(AccountSettings.self, from: $0) }
      ?? AccountSettings()
    self.name = account.name
    self.avatarURL = account.avatarURL
  }

  func loadEmojis() async throws {
    emojis = Dictionary(
      try await apiKit.response(for: MisskeyAPI.EmojisRequest()).emojis.map {
        ($0.name, $0)
      },
      uniquingKeysWith: { _, new in new }
    )
  }

  func refreshProfile() async throws {
    let me = try await apiKit.response(for: MisskeyAPI.MeRequest())
    name = me.name
    avatarURL = me.avatarUrl.flatMap(URL.init(string:))
    unreadNotificationCount = me.unreadNotificationsCount ?? 0
  }

  func emojiURL(name: String) -> URL? {
    emojis[name].flatMap { URL(string: $0.url) }
  }
}
