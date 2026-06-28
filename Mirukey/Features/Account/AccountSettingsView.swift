import MisskeyAPI
import SwiftUI

struct AccountSettingsView: View {
  @Environment(Session.self) private var session

  var body: some View {
    @Bindable var session = session

    List {
      Section("Post Settings") {
        Picker("Default Visibility", selection: $session.settings.defaultVisibility) {
          ForEach(NoteVisibility.allCases) { option in
            Text(option.title).tag(option)
          }
        }
      }
    }
    .navigationTitle("Account Settings")
  }
}
