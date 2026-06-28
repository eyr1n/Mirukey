import APIKit
import AuthenticationServices
import Foundation
import MisskeyAPI
import UIKit

enum MiAuth {
  private static let appName = "Mirukey"
  private static let appScheme = "mirukey"
  private static let permissions = [
    "read:account",
    "read:notifications",
    "read:notes",
    "write:notes",
    "write:reactions",
    "write:following",
    "write:drive",
  ]

  private static let presentationContextProvider =
    PresentationContextProvider()

  static func start(serverURL: URL) async throws -> String {
    let sessionID = UUID().uuidString.lowercased()
    var components = URLComponents(
      url:
        serverURL
        .appending(path: "miauth")
        .appending(path: sessionID),
      resolvingAgainstBaseURL: false
    )
    components?.queryItems = [
      URLQueryItem(name: "name", value: appName),
      URLQueryItem(name: "callback", value: "\(appScheme)://miauth"),
      URLQueryItem(
        name: "permission",
        value: permissions.joined(separator: ",")
      ),
    ]
    guard let url = components?.url else { throw URLError(.badURL) }

    try await authenticate(url: url)
    return try await check(serverURL: serverURL, sessionID: sessionID)
  }

  private static func authenticate(url: URL) async throws {
    try await withCheckedThrowingContinuation {
      (continuation: CheckedContinuation<Void, Error>) in
      let session = ASWebAuthenticationSession(
        url: url,
        callbackURLScheme: appScheme
      ) { callbackURL, error in
        if let error {
          continuation.resume(throwing: error)
        } else {
          continuation.resume()
        }
      }
      session.presentationContextProvider = presentationContextProvider
      session.start()
    }
  }

  private static func check(serverURL: URL, sessionID: String) async throws
    -> String
  {
    let session = APIKit.Session(
      adapter: MisskeyAPI.SessionAdapter(
        baseURL: serverURL.appending(path: "api")
      )
    )
    let result = try await session.response(
      for: MisskeyAPI.MiAuthCheckRequest(sessionID: sessionID)
    )
    guard result.ok, let token = result.token else {
      throw ASWebAuthenticationSessionError(.canceledLogin)
    }
    return token
  }
}

private final class PresentationContextProvider: NSObject,
  ASWebAuthenticationPresentationContextProviding
{
  func presentationAnchor(for session: ASWebAuthenticationSession)
    -> ASPresentationAnchor
  {
    UIWindow.keyWindow!
  }
}
