import APIKit
import MisskeyAPI
import SDWebImageSwiftUI
import SwiftUI

struct TimelineScreen: View {
  @Environment(Session.self) private var session

  @State private var paginator = Paginator<MisskeyAPI.Note>(limit: 10)
  @State private var composePresented = false

  var kind: TimelineKind

  var body: some View {
    ListStack {
      PaginatedList(paginator: paginator, fetch: fetchNotes) { note in
        VStack(spacing: 0) {
          NoteRow(
            note: note,
            onDeleted: { paginator.remove(id: $0) },
            onPosted: { paginator.prepend($0) }
          )
          Divider()
        }
      }
    }
    .navigationTitle(kind.title)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        NavigationLink(value: AppRoute.account) {
          if let url = session.avatarURL {
            AnimatedImage(url: url)
              .resizable()
              .aspectRatio(1, contentMode: .fill)
              .scaledToFill()
              .clipShape(Circle())
              .scaleEffect(2.squareRoot())
          }
        }
      }
    }
    .refreshable {
      do {
        try await paginator.refresh(fetchNotes)
      } catch {
        errorAlert(error)
      }
    }
    .overlay(alignment: .bottomTrailing) {
      Button {
        composePresented = true
      } label: {
        Image(systemName: "plus")
          .font(.system(size: 24))
          .frame(width: 48, height: 48)
      }
      .buttonStyle(.glassProminent)
      .buttonBorderShape(.circle)
      .padding(.trailing, 12)
      .padding(.bottom, 12)
    }
    .sheet(isPresented: $composePresented) {
      ComposeScreen(context: .new) { paginator.prepend($0) }
    }
  }

  private func fetchNotes(_ limit: Int, _ untilId: String?) async throws
    -> [MisskeyAPI.Note]
  {
    return switch kind {
    case .home:
      try await session.apiKit.response(
        for: MisskeyAPI.NotesTimelineRequest(limit: limit, untilId: untilId)
      )
    case .local:
      try await session.apiKit.response(
        for: MisskeyAPI.NotesLocalTimelineRequest(
          limit: limit,
          untilId: untilId
        )
      )
    case .global:
      try await session.apiKit.response(
        for: MisskeyAPI.NotesGlobalTimelineRequest(
          limit: limit,
          untilId: untilId
        )
      )
    }
  }
}

enum TimelineKind: String {
  case home
  case local
  case global

  var title: LocalizedStringKey {
    switch self {
    case .home: "Home"
    case .local: "Local"
    case .global: "Global"
    }
  }
}
