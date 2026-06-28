import APIKit
import Foundation

extension APIKit.Session: @retroactive @unchecked Sendable {}

extension MisskeyAPI {
  public final class SessionAdapter: URLSessionAdapter {
    private let baseURL: URL
    private let token: String?

    public init(baseURL: URL, token: String? = nil) {
      self.baseURL = baseURL
      self.token = token
      super.init(configuration: .default)
    }

    public override func createTask(
      with URLRequest: URLRequest,
      handler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) -> SessionTask {
      var URLRequest = URLRequest

      let original = URLComponents(
        url: URLRequest.url!,
        resolvingAgainstBaseURL: false
      )!
      var replaced = URLComponents(
        url: baseURL.appending(path: original.path),
        resolvingAgainstBaseURL: false
      )!
      replaced.query = original.query

      URLRequest.url = replaced.url!
      if let token {
        URLRequest.setValue(
          "Bearer \(token)",
          forHTTPHeaderField: "Authorization"
        )
      }

      return super.createTask(with: URLRequest, handler: handler)
    }
  }
}
