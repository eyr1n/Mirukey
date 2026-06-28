import MFMParser
import MFMRenderer
import MisskeyAPI
import SwiftUI

struct NoteRow: View {
  @Environment(AppRouter.self) private var router

  var note: MisskeyAPI.Note
  var showPreHeader: Bool = true
  var onDeleted: ((String) -> Void)? = nil
  var onPosted: ((MisskeyAPI.Note) -> Void)? = nil

  var body: some View {
    VStack(alignment: .leading, spacing: Spacing.md) {
      if showPreHeader {
        NotePreHeader(note: note)
      }
      HStack(alignment: .top, spacing: Spacing.md) {
        Button {
          router.push(route: .profile(note.displayNote.user.id))
        } label: {
          AvatarView(
            url: note.displayNote.user.avatarUrl.flatMap { URL(string: $0) },
            size: 48
          )
        }
        .buttonStyle(.plain)
        VStack(alignment: .leading, spacing: 0) {
          VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 0) {
              HStack(alignment: .top, spacing: Spacing.md) {
                MFMSimpleRenderer(
                  nodes: MFMParser.parseSimple(
                    note.displayNote.user.displayName
                  ),
                  emojis: note.displayNote.user.emojis,
                )
                .font(.subheadline)
                .bold()
                .lineLimit(1)
                Spacer()
                NoteMeta(
                  note: note.displayNote,
                  timestamp: note.displayNote.createdAt.relativeString
                )
              }
              Text(note.displayNote.user.acct)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            NoteBody(note: note.displayNote, style: .standard)
              .font(.subheadline)

            if note.displayNote.isQuote, let quoted = note.displayNote.renote {
              CompactNote(note: quoted)
                .padding(Spacing.md)
                .contentShape(Rectangle())
                .onTapGesture {
                  router.push(route: .note(quoted.id))
                }
                .overlay {
                  RoundedRectangle(cornerRadius: Radius.md)
                    .stroke(Color(.separator), lineWidth: 1)
                }
            }
          }
          NoteActions(
            note: note,
            onDeleted: onDeleted,
            onPosted: onPosted
          )
        }
      }
    }
    .padding(.horizontal, Spacing.lg)
    .padding(.top, Spacing.md)
    .contentShape(Rectangle())
    .frame(maxWidth: .infinity, alignment: .leading)
    .onTapGesture {
      router.push(route: .note(note.id))
    }
  }
}
