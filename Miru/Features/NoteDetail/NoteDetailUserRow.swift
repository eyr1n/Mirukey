import MFMParser
import MFMRenderer
import MisskeyAPI
import SwiftUI

struct NoteDetailUserRow: View {
  let user: MisskeyAPI.User
  let onAvatarTap: () -> Void

  var body: some View {
    HStack(alignment: .top, spacing: Spacing.md) {
      Button(action: onAvatarTap) {
        AvatarView(url: user.avatarUrl.flatMap { URL(string: $0) }, size: 32)
      }
      .buttonStyle(.plain)
      VStack(alignment: .leading, spacing: 0) {
        MFMSimpleRenderer(
          nodes: MFMParser.parseSimple(user.displayName),
          emojis: user.emojis
        )
        .font(.subheadline)
        .bold()
        .lineLimit(1)
        Text(user.acct)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
    }
    .padding(.horizontal, Spacing.lg)
    .padding(.vertical, Spacing.md)
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
