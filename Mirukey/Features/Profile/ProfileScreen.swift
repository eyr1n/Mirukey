import APIKit
import MFMParser
import MFMRenderer
import MisskeyAPI
import SwiftUI

struct ProfileScreen: View {
  @Environment(Session.self) private var session
  @Environment(\.openURL) private var openURL
  @Environment(AppRouter.self) private var router

  @State private var profile: MisskeyAPI.User?
  @State private var selectedFilter = ProfileNoteFilter.notes

  @State private var notesPaginator = Paginator<MisskeyAPI.Note>(limit: 10)
  @State private var allPaginator = Paginator<MisskeyAPI.Note>(limit: 10)
  @State private var filesPaginator = Paginator<MisskeyAPI.Note>(limit: 10)

  let userId: String

  var body: some View {
    ListStack {
      if let profile {
        VStack(spacing: 0) {
          VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .top, spacing: Spacing.md) {
              AvatarView(
                url: profile.avatarUrl.flatMap { URL(string: $0) },
                size: 80
              )
              VStack(alignment: .leading, spacing: Spacing.md) {
                MFMSimpleRenderer(
                  nodes: MFMParser.parseSimple(profile.displayName),
                  emojis: profile.emojis
                )
                .font(.title2)
                .bold()
                Text(profile.acct).foregroundStyle(.secondary)
              }
            }
            if let description = profile.description, !description.isEmpty {
              MFMRenderer(
                nodes: MFMParser.parse(description),
                emojis: profile.emojis
              )
              .font(.subheadline)
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, Spacing.lg)
          .padding(.vertical, Spacing.md)
          Divider()
        }

        Picker("", selection: $selectedFilter) {
          ForEach(ProfileNoteFilter.allCases) { filter in
            Text(filter.title).tag(filter)
          }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)

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
      } else {
        LoadingListRow()
      }
    }
    .navigationTitle("Profile")
    .navigationBarTitleDisplayMode(.inline)
    .refreshable {
      do {
        try await refreshProfile()
        try await paginator.refresh(fetchNotes)
      } catch {
        errorAlert(error)
      }
    }
    .task {
      do {
        try await refreshProfile()
      } catch {
        errorAlert(error)
      }
    }
    .toolbar {
      if profile != nil {
        ToolbarItem(placement: .navigationBarTrailing) {
          Menu {
            if let browserURL {
              Button("Open in Browser", systemImage: "safari") {
                openURL(browserURL)
              }
            }
            if let remoteURL {
              Button("Open Remote", systemImage: "arrow.up.forward.square") {
                openURL(remoteURL)
              }
            }
          } label: {
            Image(systemName: "ellipsis")
          }
        }
      }
    }
  }

  private var paginator: Paginator<MisskeyAPI.Note> {
    switch selectedFilter {
    case .notes: notesPaginator
    case .all: allPaginator
    case .files: filesPaginator
    }
  }

  private var resolvedUserId: String? {
    if userId.hasPrefix("@") {
      profile?.id
    } else if userId == "me" {
      session.account.userId
    } else {
      userId
    }
  }

  private var browserURL: URL? {
    guard let profile else { return nil }
    return session.account.serverURL.appending(path: profile.acct)
  }

  private var remoteURL: URL? {
    guard let profile,
      let host = profile.host
    else { return nil }
    return URL(string: "https://\(host)/@\(profile.username)")
  }

  private func refreshProfile() async throws {
    let request: MisskeyAPI.UsersShowRequest
    if userId.hasPrefix("@") {
      let parts = userId.dropFirst().split(separator: "@")
      request = MisskeyAPI.UsersShowRequest(
        username: String(parts[0]),
        host: parts.count > 1 ? String(parts[1]) : nil
      )
    } else {
      request = MisskeyAPI.UsersShowRequest(userId: resolvedUserId)
    }
    profile = try await session.apiKit.response(for: request)
  }

  private func fetchNotes(_ limit: Int, _ untilId: String?) async throws
    -> [MisskeyAPI.Note]
  {
    guard let resolvedUserId else { return [] }
    return try await session.apiKit.response(
      for:
        MisskeyAPI.UsersNotesRequest(
          userId: resolvedUserId,
          withReplies: selectedFilter == .all,
          limit: limit,
          untilId: untilId,
          withFiles: selectedFilter == .files
        )
    )
  }
}

enum ProfileNoteFilter: String, CaseIterable, Identifiable {
  case notes
  case all
  case files

  var id: String { rawValue }

  var title: LocalizedStringKey {
    switch self {
    case .notes: return "Notes"
    case .all: return "All"
    case .files: return "With Files"
    }
  }
}
