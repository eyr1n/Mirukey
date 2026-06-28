import SwiftUI

struct ReactionFilterSelector: View {
  let reactions: [Reaction]
  let selectedType: String?
  let onSelect: (String) -> Void

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: Spacing.md) {
        ForEach(reactions) { reaction in
          EmojiButton(
            name: reaction.name,
            url: reaction.url,
            count: reaction.count,
            active: selectedType == reaction.raw
          ) {
            onSelect(reaction.raw)
          }
        }
      }
      .padding(.horizontal, Spacing.lg)
      .padding(.vertical, Spacing.md)
    }
    .horizontalOverflowFadeTracking()
    .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
  }
}
