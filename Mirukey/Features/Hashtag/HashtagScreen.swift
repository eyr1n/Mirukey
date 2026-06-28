import APIKit
import MisskeyAPI
import SwiftUI

struct HashtagScreen: View {
  @Environment(Session.self) private var session

  @State private var selectedFilter = HashtagNoteFilter.all
  @State private var allPaginator = Paginator<MisskeyAPI.Note>(limit: 10)
  @State private var filesPaginator = Paginator<MisskeyAPI.Note>(limit: 10)

  let tag: String

  var body: some View {
    ListStack {
      Picker("", selection: $selectedFilter) {
        ForEach(HashtagNoteFilter.allCases) { filter in
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
    }
    .navigationTitle("#\(tag)")
    .refreshable {
      do {
        try await paginator.refresh(fetchNotes)
      } catch {
        errorAlert(error)
      }
    }
  }

  private var paginator: Paginator<MisskeyAPI.Note> {
    switch selectedFilter {
    case .all: allPaginator
    case .files: filesPaginator
    }
  }

  private func fetchNotes(_ limit: Int, _ untilId: String?) async throws
    -> [MisskeyAPI.Note]
  {
    try await session.apiKit.response(
      for:
        MisskeyAPI.NotesSearchByTagRequest(
          withFiles: selectedFilter == .files,
          untilId: untilId,
          limit: limit,
          tag: tag
        )
    )
  }
}

enum HashtagNoteFilter: String, CaseIterable, Identifiable {
  case all
  case files

  var id: String { rawValue }

  var title: LocalizedStringKey {
    switch self {
    case .all: return "All"
    case .files: return "With Files"
    }
  }
}
