

import MisskeyAPI

extension MisskeyAPI.User {
  var displayName: String {
    name ?? username
  }

  var acct: String {
    host.map { "@\(username)@\($0)" } ?? "@\(username)"
  }
}