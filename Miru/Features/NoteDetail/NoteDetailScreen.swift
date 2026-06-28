import APIKit
import MFMParser
import MFMRenderer
import MisskeyAPI
import SwiftUI

struct NoteDetailScreen: View {
  @Environment(AppRouter.self) private var router
  @Environment(Session.self) private var session

  @State private var detailNote: MisskeyAPI.Note?
  @State private var selectedTab: NoteDetailTab = .replies
  @State private var selectedReaction: String?

  @State private var repliesPaginator = Paginator<MisskeyAPI.Note>(limit: 10)
  @State private var renotesPaginator = Paginator<MisskeyAPI.Note>(limit: 10)
  @State private var reactionPaginators:
    [String: Paginator<MisskeyAPI.NoteReaction>] = [:]

  let noteId: String

  var body: some View {
    ListStack {
      if let note = detailNote {
        VStack(spacing: 0) {
          VStack(alignment: .leading, spacing: Spacing.md) {
            NotePreHeader(note: note)
            VStack(alignment: .leading, spacing: 0) {
              VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(alignment: .center, spacing: Spacing.md) {
                  Button {
                    router.push(route: .profile(note.displayNote.user.id))
                  } label: {
                    AvatarView(
                      url: note.displayNote.user.avatarUrl.flatMap {
                        URL(string: $0)
                      },
                      size: 48
                    )
                  }
                  .buttonStyle(.plain)

                  VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top, spacing: Spacing.md) {
                      MFMSimpleRenderer(
                        nodes: MFMParser.parseSimple(
                          note.displayNote.user.displayName
                        ),
                        emojis: note.displayNote.user.emojis
                      )
                      .font(.subheadline)
                      .bold()
                      .lineLimit(1)
                      Spacer(minLength: 0)
                    }
                    Text(note.displayNote.user.acct)
                      .font(.caption)
                      .foregroundStyle(.secondary)
                      .lineLimit(1)
                  }
                }
                NoteBody(note: note.displayNote, style: .detail)
                if note.displayNote.isQuote,
                  let note = note.displayNote.renote
                {
                  CompactNote(note: note)
                    .padding(Spacing.md)
                    .contentShape(Rectangle())
                    .onTapGesture {
                      router.push(route: .note(note.id))
                    }
                    .overlay {
                      RoundedRectangle(cornerRadius: Radius.md)
                        .stroke(Color(.separator), lineWidth: 1)
                    }
                }
                NoteMeta(
                  note: note.displayNote,
                  timestamp: note.displayNote.createdAt.absoluteString
                )
              }
              NoteActions(
                note: note,
                onDeleted: { _ in router.pop() },
              )
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, Spacing.lg)
          .padding(.top, Spacing.md)
          Divider()
        }
      } else {
        LoadingListRow()
      }

      Picker("", selection: $selectedTab) {
        ForEach(NoteDetailTab.allCases) { tab in
          Text(tab.title).tag(tab)
        }
      }
      .pickerStyle(.segmented)
      .padding(.horizontal, Spacing.lg)
      .padding(.vertical, Spacing.md)

      switch selectedTab {
      case .replies:
        PaginatedList(paginator: repliesPaginator, fetch: fetchReplies) {
          reply in
          VStack(spacing: 0) {
            NoteRow(
              note: reply,
              showPreHeader: false,
              onDeleted: { repliesPaginator.remove(id: $0) }
            )
            Divider()
          }
        }
      case .renotes:
        PaginatedList(paginator: renotesPaginator, fetch: fetchRenotes) {
          renote in
          VStack(spacing: 0) {
            NoteDetailUserRow(user: renote.user) {
              router.push(route: .profile(renote.user.id))
            }
            Divider()
          }
        }
      case .reactions:
        ReactionFilterSelector(
          reactions: resolvedReactions,
          selectedType: selectedReaction,
          onSelect: { selectedReaction = $0 }
        )
        if let selectedReaction,
          let paginator = reactionPaginators[selectedReaction]
        {
          PaginatedList(
            paginator: paginator,
            fetch: fetchReactionUsers(type: selectedReaction)
          ) { reaction in
            VStack(spacing: 0) {
              NoteDetailUserRow(user: reaction.user) {
                router.push(route: .profile(reaction.user.id))
              }
              Divider()
            }
          }
        }
      }
    }
    .navigationTitle("Note")
    .navigationBarTitleDisplayMode(.inline)
    .refreshable {
      do {
        try await refreshDetail()
        try await repliesPaginator.refresh(fetchReplies)
        try await renotesPaginator.refresh(fetchRenotes)
        if let selectedReaction,
          let paginator = reactionPaginators[selectedReaction]
        {
          try await paginator.refresh(
            fetchReactionUsers(type: selectedReaction)
          )
        }
      } catch {
        errorAlert(error)
      }
    }
    .task(id: noteId) {
      do {
        try await refreshDetail()
      } catch {
        errorAlert(error)
      }
    }
  }

  private var displayNoteId: String? {
    detailNote?.displayNote.id
  }

  private var resolvedReactions: [Reaction] {
    guard let note = detailNote?.displayNote else { return [] }
    return Reaction.sorted(
      from: note.reactions,
      emojiURL: { session.emojiURL(name: $0) },
      noteEmojiURLs: note.reactionEmojis
    )
  }

  private func refreshDetail() async throws {
    detailNote = try await session.apiKit
      .response(for: MisskeyAPI.NotesShowRequest(noteId: noteId))
    reactionPaginators = Dictionary(
      uniqueKeysWithValues: resolvedReactions.map {
        ($0.raw, Paginator<MisskeyAPI.NoteReaction>(limit: 10))
      }
    )
    selectedReaction = nil
  }

  private func fetchReplies(_ limit: Int, _ untilId: String?) async throws
    -> [MisskeyAPI.Note]
  {
    guard let noteId = displayNoteId else { return [] }
    return try await session.apiKit.response(
      for: MisskeyAPI.NotesChildrenRequest(
        noteId: noteId,
        limit: limit,
        untilId: untilId
      )
    )
  }

  private func fetchRenotes(_ limit: Int, _ untilId: String?) async throws
    -> [MisskeyAPI.Note]
  {
    guard let noteId = displayNoteId else { return [] }
    return try await session.apiKit.response(
      for: MisskeyAPI.NotesRenotesRequest(
        noteId: noteId,
        limit: limit,
        untilId: untilId
      )
    )
  }

  private func fetchReactionUsers(
    type: String
  ) -> Paginator<MisskeyAPI.NoteReaction>.Fetch {
    { limit, untilId in
      guard let noteId = displayNoteId else { return [] }
      return try await session.apiKit.response(
        for:
          MisskeyAPI.NotesReactionsRequest(
            noteId: noteId,
            type: type,
            limit: limit,
            untilId: untilId
          )
      )
    }
  }
}

private enum NoteDetailTab: String, CaseIterable, Identifiable {
  case replies
  case renotes
  case reactions

  var id: String { rawValue }

  var title: LocalizedStringKey {
    switch self {
    case .replies: return "Replies"
    case .renotes: return "Renotes"
    case .reactions: return "Reactions"
    }
  }
}
