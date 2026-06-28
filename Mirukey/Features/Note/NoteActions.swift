import APIKit
import MisskeyAPI
import SwiftUI
import UIKit

struct NoteActions: View {
  @Environment(Session.self) private var session
  @Environment(\.openURL) private var openURL

  @State private var reactionPickerPresented = false
  @State private var removeReactionConfirmPresented = false
  @State private var deleteConfirmPresented = false
  @State private var unrenoteConfirmPresented = false
  @State private var editConfirmPresented = false

  @State private var composeContext: ComposeContext?
  @State private var pendingEditOriginalId: String?
  @State private var pendingEditedNote: MisskeyAPI.Note?

  @State private var myReaction: String?

  var note: MisskeyAPI.Note
  var onDeleted: ((String) -> Void)?
  var onPosted: ((MisskeyAPI.Note) -> Void)?

  init(
    note: MisskeyAPI.Note,
    onDeleted: ((String) -> Void)? = nil,
    onPosted: ((MisskeyAPI.Note) -> Void)? = nil
  ) {
    self.note = note
    self.onDeleted = onDeleted
    self.onPosted = onPosted
    _myReaction = State(initialValue: note.displayNote.myReaction)
  }

  private var displayNote: MisskeyAPI.Note {
    note.displayNote
  }

  private var displayReactions: [String: Int] {
    var counts = displayNote.reactions
    let serverReaction = displayNote.myReaction
    guard myReaction != serverReaction else { return counts }
    if let serverReaction {
      let next = (counts[serverReaction] ?? 0) - 1
      counts[serverReaction] = next > 0 ? next : nil
    }
    if let myReaction {
      counts[myReaction] = (counts[myReaction] ?? 0) + 1
    }
    return counts
  }

  var body: some View {
    if !displayReactions.isEmpty {
      ReactionStrip(
        myReaction: myReaction,
        reactions: resolvedReactions,
        onAdd: { reaction in Task { await addReaction(reaction) } },
        onRequestRemove: { removeReactionConfirmPresented = true }
      )
      .padding(.top, Spacing.md)
    }
    toolbar
      .sheet(isPresented: $reactionPickerPresented) {
        EmojiPickerScreen { reaction in
          reactionPickerPresented = false
          Task {
            await addReaction(reaction)
          }
        }
      }
      .alert("Remove reaction?", isPresented: $removeReactionConfirmPresented) {
        Button("Delete", role: .destructive) {
          Task { await removeCurrentReaction() }
        }
        Button("Cancel", role: .cancel) {}
      }
      .alert("Delete this note?", isPresented: $deleteConfirmPresented) {
        Button("Delete", role: .destructive) {
          Task { await deleteNote() }
        }
        Button("Cancel", role: .cancel) {}
      }
      .alert("Undo this renote?", isPresented: $unrenoteConfirmPresented) {
        Button("Unrenote", role: .destructive) {
          Task { await unrenote() }
        }
        Button("Cancel", role: .cancel) {}
      }
      .alert(
        "Delete and edit this note again?",
        isPresented: $editConfirmPresented
      ) {
        Button("Delete & Edit", role: .destructive) {
          Task { await deleteThenEdit() }
        }
        Button("Cancel", role: .cancel) {}
      }
      .sheet(item: $composeContext, onDismiss: applyPendingEdit) { ctx in
        ComposeScreen(context: ctx) { posted in
          switch ctx {

          case .edit:
            pendingEditedNote = posted

          case .quote, .reply:
            onPosted?(posted)
          default:
            break
          }
        }
      }
      .onChange(of: displayNote.id) { myReaction = displayNote.myReaction }
      .onChange(of: displayNote.myReaction) {
        myReaction = displayNote.myReaction
      }
  }

  private var isRenoteDisabled: Bool {
    displayNote.visibility == "specified"
      || (displayNote.visibility == "followers"
        && displayNote.user.id != session.account.userId)
  }

  private var resolvedReactions: [Reaction] {
    Reaction.sorted(
      from: displayReactions,
      emojiURL: { session.emojiURL(name: $0) },
      noteEmojiURLs: displayNote.reactionEmojis
    )
  }

  private var toolbar: some View {
    HStack(spacing: Spacing.lg) {
      HStack(spacing: 0) {
        Button {
          handleCompose(.reply(displayNote))
        } label: {
          Image(systemName: "arrowshape.turn.up.left")
            .frame(width: 42, height: 42)
        }
        if displayNote.repliesCount > 0 {
          Text(displayNote.repliesCount.formatted())
            .font(.subheadline)
        }
      }

      HStack(spacing: 0) {
        Menu {
          Button("Renote", systemImage: "repeat") { Task { await renote() } }
          Button("Quote", systemImage: "quote.bubble") {
            handleCompose(.quote(displayNote))
          }
        } label: {
          Image(systemName: "repeat")
            .frame(width: 42, height: 42)
        }.disabled(isRenoteDisabled)
        if displayNote.renoteCount > 0 {
          Text(displayNote.renoteCount.formatted())
            .font(.subheadline)
        }
      }

      Button {
        if myReaction != nil {
          removeReactionConfirmPresented = true
        } else {
          reactionPickerPresented = true
        }
      } label: {
        Image(systemName: myReaction == nil ? "plus" : "minus")
          .frame(width: 42, height: 42)
      }

      Menu {
        if let noteText = displayNote.text, !noteText.isEmpty {
          Button("Copy content", systemImage: "doc.on.doc") {
            UIPasteboard.general.string = noteText
          }
        }
        if let noteURL {
          Button("Copy link", systemImage: "link") {
            UIPasteboard.general.url = noteURL
          }
          Button("Open in browser", systemImage: "safari") {
            openURL(noteURL)
          }
        }
        if let remoteNoteURL {
          Button("Show on remote", systemImage: "arrow.up.forward.square") {
            openURL(remoteNoteURL)
          }
        }
        if let noteURL {
          ShareLink("Share", item: noteURL)
        }
        if canEditDisplayNote || canDeleteCurrentNote || canUnrenoteCurrentNote
        {
          Divider()
          if canEditDisplayNote {
            Button("Delete and edit", systemImage: "pencil") {
              editConfirmPresented = true
            }
          }
          if canDeleteCurrentNote {
            Button("Delete", systemImage: "trash", role: .destructive) {
              deleteConfirmPresented = true
            }
            .tint(.red)
          }
          if canUnrenoteCurrentNote {
            Button("Unrenote", systemImage: "repeat", role: .destructive) {
              unrenoteConfirmPresented = true
            }
            .tint(.red)
          }
        }
      } label: {
        Image(systemName: "ellipsis")
          .frame(width: 42, height: 42)
      }
    }
    .buttonStyle(.plain)
    .foregroundStyle(.secondary)
  }

  private func handleCompose(_ context: ComposeContext) {
    if case .edit(let original) = context {
      pendingEditOriginalId = original.id
    }
    composeContext = context
  }

  private func applyPendingEdit() {
    guard let originalId = pendingEditOriginalId else { return }
    pendingEditOriginalId = nil
    onDeleted?(originalId)
    if let edited = pendingEditedNote {
      onPosted?(edited)
      pendingEditedNote = nil
    }
  }

  private var noteURL: URL? {
    session.account.serverURL.appending(path: "notes").appending(
      path: displayNote.id
    )
  }

  private var remoteNoteURL: URL? {
    let remote =
      displayNote.uri.flatMap(URL.init(string:))
      ?? displayNote.url.flatMap(URL.init(string:))
    guard let remote else { return nil }
    if let noteURL, remote.absoluteString == noteURL.absoluteString {
      return nil
    }
    return remote
  }

  private var canEditDisplayNote: Bool {
    displayNote.user.id == session.account.userId
      && displayNote.id == note.id
  }

  private var canDeleteCurrentNote: Bool {
    note.user.id == session.account.userId && !note.isPureRenote
  }

  private var canUnrenoteCurrentNote: Bool {
    note.user.id == session.account.userId && note.isPureRenote
  }

  private func addReaction(_ reaction: String) async {
    let previous = myReaction
    myReaction = reaction
    do {
      _ = try await session.apiKit.response(
        for:
          MisskeyAPI.NotesReactionsCreateRequest(
            noteId: displayNote.id,
            reaction: reaction
          )
      )
    } catch {
      myReaction = previous
      errorAlert(error)
    }
  }

  private func removeCurrentReaction() async {
    guard myReaction != nil else { return }
    let previous = myReaction
    myReaction = nil
    do {
      _ = try await session.apiKit.response(
        for: MisskeyAPI.NotesReactionsDeleteRequest(noteId: displayNote.id)
      )
    } catch {
      myReaction = previous
      errorAlert(error)
    }
  }

  private func renote() async {
    do {
      let created = try await session.apiKit.response(
        for: MisskeyAPI.NotesCreateRequest(renoteId: displayNote.id)
      ).createdNote
      onPosted?(created)
    } catch {
      errorAlert(error)
    }
  }

  private func unrenote() async {
    do {
      _ = try await session.apiKit.response(
        for: MisskeyAPI.NotesUnrenoteRequest(noteId: note.displayNote.id)
      )
      onDeleted?(note.id)
    } catch {
      errorAlert(error)
    }
  }

  private func deleteNote() async {
    do {
      _ = try await session.apiKit.response(
        for: MisskeyAPI.NotesDeleteRequest(noteId: note.id)
      )
      onDeleted?(note.id)
    } catch {
      errorAlert(error)
    }
  }

  private func deleteThenEdit() async {
    let editingNote = displayNote
    do {
      _ = try await session.apiKit.response(
        for: MisskeyAPI.NotesDeleteRequest(noteId: editingNote.id)
      )

      handleCompose(.edit(editingNote))
    } catch {
      errorAlert(error)
    }
  }
}
