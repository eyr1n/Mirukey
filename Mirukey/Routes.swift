import MFMRenderer
import SwiftUI

enum AppRoute: Identifiable, Hashable {
  case note(String)
  case profile(String)
  case hashtag(String)
  case account
  case accountSettings

  var id: String {
    switch self {
    case .note(let id): "note-\(id)"
    case .profile(let id): "profile-\(id)"
    case .hashtag(let tag): "hashtag-\(tag)"
    case .account: "account"
    case .accountSettings: "accountSettings"
    }
  }

  @ViewBuilder
  var content: some View {
    switch self {
    case .note(let id): NoteDetailScreen(noteId: id)
    case .profile(let id): ProfileScreen(userId: id)
    case .hashtag(let tag): HashtagScreen(tag: tag)
    case .account: AccountView()
    case .accountSettings: AccountSettingsView()
    }
  }
}

@MainActor
@Observable
final class AppRouter {
  fileprivate var path: [AppRoute] = []

  func push(route: AppRoute) {
    path.append(route)
  }

  func pop() {
    path.removeLast()
  }
}

struct AppNavigationStack<Content: View>: View {
  @State private var router = AppRouter()

  private let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    @Bindable var router = router

    NavigationStack(path: $router.path) {
      content
        .navigationDestination(for: AppRoute.self) { $0.content }
    }
    .environment(router)
    .environment(
      \.mfmLinkHandler,
      MFMLinkHandler {
        switch $0 {
        case .mention(let acct):
          router.push(route: .profile(acct))
        case .hashtag(let tag):
          router.push(route: .hashtag(tag))
        }
      }
    )
  }
}

private enum AppTab {
  case home
  case local
  case global
  case notifications
}

struct AppTabView: View {
  @Environment(Session.self) private var session

  @State private var tab: AppTab = .home

  var body: some View {
    TabView(selection: $tab) {
      Tab("Home", systemImage: "house", value: .home) {
        AppNavigationStack {
          TimelineScreen(kind: .home)
        }
      }
      Tab("Local", systemImage: "building", value: .local) {
        AppNavigationStack {
          TimelineScreen(kind: .local)
        }
      }
      Tab("Global", systemImage: "globe", value: .global) {
        AppNavigationStack {
          TimelineScreen(kind: .global)
        }
      }
      Tab("Notifications", systemImage: "bell", value: .notifications) {
        AppNavigationStack {
          NotificationsScreen()
        }
      }
      .badge(session.unreadNotificationCount)
    }
  }
}
