import SwiftUI

struct ReactionStrip: View {
  let myReaction: String?
  let reactions: [Reaction]
  let onAdd: (String) -> Void
  let onRequestRemove: () -> Void

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: Spacing.md) {
        ForEach(reactions) { reaction in
          let isActive = myReaction == reaction.raw
          if reaction.isRemote {
            EmojiButton(
              name: reaction.name,
              url: reaction.url,
              count: reaction.count,
              active: isActive
            )
          } else {
            EmojiButton(
              name: reaction.name,
              url: reaction.url,
              count: reaction.count,
              active: isActive
            ) {
              if isActive {
                onRequestRemove()
              } else {
                onAdd(reaction.raw)
              }
            }
          }
        }
      }
    }
    .horizontalOverflowFadeTracking()
    .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
  }
}
