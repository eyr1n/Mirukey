import SwiftUI

struct ContentView: View {
  @State private var sessionManager = SessionManager()

  var body: some View {
    Group {
      if let session = sessionManager.session {
        AuthenticatedContentView(session: session)
          .id(session.account.id)
      } else {
        LoginView()
      }
    }
    .environment(sessionManager)
  }
}
