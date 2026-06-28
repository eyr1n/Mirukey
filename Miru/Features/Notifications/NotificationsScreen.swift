import APIKit
import MisskeyAPI
import SwiftUI

struct NotificationsScreen: View {
  @Environment(Session.self) private var session

  @State private var paginator = Paginator<MisskeyAPI.Notification>(limit: 10)

  var body: some View {
    ListStack {
      PaginatedList(paginator: paginator, fetch: fetchNotifications) {
        notification in
        VStack(alignment: .leading, spacing: 0) {
          NotificationRow(notification: notification)
          Divider()
        }
      }
    }
    .navigationTitle("Notifications")
    .refreshable {
      do {
        try await paginator.refresh(fetchNotifications)
      } catch {
        errorAlert(error)
      }
    }
  }

  private func fetchNotifications(_ limit: Int, _ untilId: String?) async throws
    -> [MisskeyAPI.Notification]
  {
    return try await session.apiKit.response(
      for: MisskeyAPI.NotificationsRequest(limit: limit, untilId: untilId)
    )
  }
}
