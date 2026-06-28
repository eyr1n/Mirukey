import MFMRenderer
import SwiftUI

struct AuthenticatedContentView: View {
  let session: Session

  var body: some View {
    AppTabView()
      .environment(session)
      .environment(
        \.mfmEmojiResolver,
        MFMEmojiResolver { session.emojiURL(name: $0) }
      )
      .task {
        try? await session.loadEmojis()
        try? await session.refreshProfile()
      }
  }
}
