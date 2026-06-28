import Flow
import MisskeyAPI
import SwiftUI

struct EmojiPickerScreen: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(Session.self) private var session

  @State private var query = ""

  let onSelect: (String) -> Void

  var body: some View {
    NavigationStack {
      ScrollView {
        HFlow(
          horizontalAlignment: .leading,
          verticalAlignment: .center,
          horizontalSpacing: Spacing.md,
          verticalSpacing: Spacing.md
        ) {
          ForEach(filteredEmojis, id: \.self) { key in
            let reaction = Reaction(key).resolvingURL(
              emojiURL: { session.emojiURL(name: $0) }
            )
            EmojiButton(name: reaction.name, url: reaction.url) {
              onSelect(key)
              session.settings.addRecentEmoji(key)
              dismiss()
            }
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
      }
      .searchable(
        text: $query,
        placement: .navigationBarDrawer(displayMode: .always),
        prompt: "Search Emojis"
      )
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button {
            dismiss()
          } label: {
            Image(systemName: "xmark")
          }
        }
      }
    }
    .presentationDetents([.medium, .large])
  }

  private var customEmojis: [MisskeyAPI.EmojiSimple] {
    session.emojis.values
      .filter { !$0.name.contains(":") && !$0.name.contains("@") }
      .sorted { $0.name < $1.name }
  }

  private var filteredEmojis: [String] {
    EmojiSearchFilter.filter(
      customEmojis: customEmojis,
      unicodeEmojis: UnicodeEmojiData.entries,
      recentEmojis: session.settings.recentEmojis,
      query: query,
    )
  }
}
