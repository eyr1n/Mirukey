import Foundation
import MisskeyAPI

struct Account: Codable, Identifiable {
  let id: String
  let userId: String
  let username: String
  let host: String
  let serverURL: URL
  let token: String

  var name: String?
  var avatarURL: URL?
  var emojis: [String: String]

  init(user: MisskeyAPI.User, serverURL: URL, token: String) {
    let host = serverURL.host()!
    self.id = "@\(user.id)@\(host)"
    self.userId = user.id
    self.username = user.username
    self.host = host
    self.serverURL = serverURL
    self.token = token
    self.name = user.name
    self.avatarURL = user.avatarUrl.flatMap { URL(string: $0) }
    self.emojis = user.emojis
  }
}
