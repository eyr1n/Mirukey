import SwiftUI

struct EmojiButton: View {
  @State private var popoverPresented = false

  let name: String
  let url: URL?
  var count: Int? = nil
  var active = false
  var action: (() -> Void)? = nil

  var body: some View {
    Button {
      action?()
    } label: {
      HStack(spacing: Spacing.sm) {
        EmojiImage(
          url: url,
          alt: name
        )
        if let count {
          Text(String(count)).bold().font(.subheadline)
        }
      }
      .padding(.horizontal, Spacing.md)
      .padding(.vertical, Spacing.md)
      .background(backgroundColor)
      .clipShape(Capsule())
      .contentShape(Capsule())
      .onLongPressGesture {
        popoverPresented = true
      }
      .popover(isPresented: $popoverPresented) {
        Text(name)
          .font(.subheadline)
          .padding(.horizontal, Spacing.md)
          .padding(.vertical, Spacing.md)
          .presentationCompactAdaptation(.popover)
      }
    }
    .buttonStyle(.plain)
  }

  private var backgroundColor: Color {
    if action == nil {
      .clear
    } else {
      active
        ? Color.accentColor.opacity(0.2) : Color(.secondarySystemBackground)
    }
  }
}
