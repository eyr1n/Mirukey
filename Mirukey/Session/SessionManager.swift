import APIKit
import Foundation
import KeychainAccess
import MisskeyAPI
import SwiftUI

@MainActor
@Observable
final class SessionManager {
  private static let keychain = Keychain()
    .accessibility(.afterFirstUnlockThisDeviceOnly)
  @AppStorage("currentAccountID") private static var currentAccountID: String?

  private(set) var accounts: [Account]

  var currentAccount: Account? {
    didSet {
      Self.currentAccountID = currentAccount?.id
      session = currentAccount.map(Session.init)
    }
  }

  private(set) var session: Session?

  init() {
    accounts = Self.keychain.allKeys()
      .compactMap { key in
        Self.keychain[data: key].flatMap {
          try? JSONDecoder().decode(Account.self, from: $0)
        }
      }
      .sorted { $0.id < $1.id }
    let current =
      accounts.first { $0.id == Self.currentAccountID } ?? accounts.first

    currentAccount = current
    session = current.map(Session.init)
  }

  func addAccount(account: Account) {
    accounts.removeAll { $0.id == account.id }
    accounts.append(account)
    accounts.sort { $0.id < $1.id }
    Self.save(account: account)
    currentAccount = account
  }

  func switchAccount(account: Account) {
    guard account.id != currentAccount?.id else { return }
    currentAccount = account
  }

  func removeAccount(account: Account) {
    accounts.removeAll { $0.id == account.id }
    try? Self.keychain.remove(account.id)
    if currentAccount?.id == account.id {
      currentAccount = accounts.first
    }
  }

  private static func save(account: Account) {
    guard let data = try? JSONEncoder().encode(account) else { return }
    keychain[data: account.id] = data
  }
}
