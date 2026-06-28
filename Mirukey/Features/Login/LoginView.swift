import APIKit
import MisskeyAPI
import SwiftUI

struct LoginView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(SessionManager.self) private var accountManager

  @State private var serverURLText = ""
  @State private var isLoading = false

  private var serverURL: URL? {
    URL(string: "https://\(serverURLText)")
  }

  var body: some View {
    NavigationStack {
      Form {
        Section("Server URL") {
          HStack(spacing: Spacing.md) {
            Text("https://").foregroundStyle(.secondary)
            TextField("example.com", text: $serverURLText).keyboardType(.URL)
          }
        }

        Section {
          Button {
            Task {
              await startMiAuth()
            }
          } label: {
            HStack(spacing: Spacing.md) {
              Spacer()
              Text("Log in with MiAuth").bold()
              Spacer()
            }
          }
          .disabled(serverURL == nil || isLoading)
        }
      }
      .navigationTitle("Log In")
    }
  }

  private func startMiAuth() async {
    guard let serverURL else { return }
    isLoading = true
    do {
      let token = try await MiAuth.start(serverURL: serverURL)
      let apiKit = APIKit.Session(
        adapter: MisskeyAPI.SessionAdapter(
          baseURL: serverURL.appending(path: "api"),
          token: token
        )
      )
      let meta = try await apiKit.response(for: MisskeyAPI.MetaRequest())
      let me = try await apiKit.response(for: MisskeyAPI.MeRequest())
      accountManager.addAccount(
        account: Account(
          user: me,
          serverURL: URL(string: meta.uri)!,
          token: token
        )
      )
      dismiss()
    } catch {
      errorAlert(error)
    }
    isLoading = false
  }
}
