import MFMParser
import MFMRenderer
import MisskeyAPI
import SwiftUI

struct CompactNote: View {
  let note: MisskeyAPI.Note

  var body: some View {
    VStack(alignment: .leading, spacing: Spacing.md) {
      HStack(alignment: .center, spacing: Spacing.md) {
        AvatarView(url: note.user.avatarUrl.flatMap {URL(string: $0)}, size: 28)
        VStack(alignment: .leading, spacing: 0) {
          HStack(alignment: .top, spacing: Spacing.md) {
            MFMSimpleRenderer(
              nodes: MFMParser.parseSimple(note.user.displayName),
              emojis: note.user.emojis
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
        }
      }
      NoteBody(
        note: note,
        style: .compact
      ).font(.subheadline)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
