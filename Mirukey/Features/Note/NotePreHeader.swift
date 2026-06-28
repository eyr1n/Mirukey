import MFMParser
import MFMRenderer
import SwiftUI
import MisskeyAPI

struct NotePreHeader: View {
  @Environment(AppRouter.self) private var router

  var note: MisskeyAPI.Note

  var body: some View {
    if note.isPureRenote {
      HStack(spacing: Spacing.md) {
        Image(systemName: "repeat")
          .foregroundStyle(.secondary)
        MFMSimpleRenderer(
          nodes: MFMParser.parseSimple(
            String(localized: "\(note.user.displayName) renoted")
          ),
          emojis: note.user.emojis,
          color: .secondary
        )
        .lineLimit(1)
        Spacer()
        NoteMeta(
          note: note,
          timestamp: note.createdAt.relativeString
        )
      }
      .font(.caption)
    }

    if let channel = note.displayNote.channel {
      HStack(spacing: Spacing.md) {
        Image(systemName: "tv")
        Text(channel.name)
          .lineLimit(1)
      }
      .font(.caption)
      .foregroundStyle(.secondary)
    }

    if let reply = note.displayNote.reply {
      VStack(alignment: .leading, spacing: Spacing.md) {
        CompactNote(note: reply)
          .contentShape(Rectangle())
          .onTapGesture {
            router.push(route: .note(reply.id))
          }
        DashedDivider()
      }
    }
  }
}
