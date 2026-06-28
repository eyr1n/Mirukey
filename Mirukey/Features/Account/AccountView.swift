import MFMParser
import MFMRenderer
import SwiftUI

struct AccountView: View {
  @Environment(SessionManager.self) private var sessionManager
  @Environment(Session.self) private var session

  @State private var loginPresented = false
  @State private var logoutPresented = false

  var body: some View {
    List {
      Section {
        ForEach(sessionManager.accounts) { account in
          Button {
            sessionManager.switchAccount(account: account)
          } label: {
            HStack(spacing: Spacing.md) {
              AvatarView(
                url: account.avatarURL,
                size: 48
              )

              VStack(alignment: .leading, spacing: Spacing.md) {
                if let name = account.name {
                  MFMSimpleRenderer(
                    nodes: MFMParser.parseSimple(name),
                    emojis: account.emojis
                  )
                  .bold()
                  .lineLimit(1)
                } else {
                  Text(account.username)
                    .bold()
                    .lineLimit(1)
                }
                Text(verbatim: "@\(account.username)@\(account.host)")
                  .font(.subheadline)
                  .foregroundStyle(.secondary)
                  .lineLimit(1)
              }

              if account.id == session.account.id {
                Spacer()
                Image(systemName: "checkmark").foregroundStyle(.accent)
              }
            }
          }
          .tint(.primary)
        }
        Button {
          loginPresented = true
        } label: {
          Label("Add Account", systemImage: "plus.circle.fill")
        }
      }

      Section {
        NavigationLink(value: AppRoute.profile("me")) {
          Label("Profile", systemImage: "person.crop.circle")
            .foregroundStyle(.primary)
        }
        NavigationLink(value: AppRoute.accountSettings) {
          Label("Account Settings", systemImage: "gearshape")
            .foregroundStyle(.primary)
        }
      }

      Section {
        Button(role: .destructive) {
          logoutPresented = true
        } label: {
          Label("Log Out", systemImage: "rectangle.portrait.and.arrow.forward")
            .foregroundStyle(.red)
        }
      }
    }
    .navigationTitle("Account")
    .sheet(isPresented: $loginPresented) {
      LoginView()
    }
    .alert("Log Out?", isPresented: $logoutPresented) {
      Button("Log Out", role: .destructive) {
        sessionManager.removeAccount(account: session.account)
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      let acct = "\(session.account.username)@\(session.account.host)"
      Text("Logging out from @\(acct).")
    }
  }
}
