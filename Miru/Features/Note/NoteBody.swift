import MFMParser
import MFMRenderer
import MisskeyAPI
import SwiftUI

struct NoteBody: View {
  @State private var cwExpanded = false

  let note: MisskeyAPI.Note
  var style: NoteBodyStyle

  var body: some View {
    VStack(alignment: .leading, spacing: Spacing.md) {
      if let cw = note.cw {
        MFMRenderer(
          nodes: MFMParser.parse(cw),
          emojis: note.emojis
        )
        Button {
          withAnimation(.none) { cwExpanded.toggle() }
        } label: {
          Label(
            cwExpanded ? "Hide" : "Show More",
            systemImage: cwExpanded ? "eye.slash" : "eye"
          )
          .font(.subheadline)
        }
        .buttonStyle(.bordered)
      }

      if note.cw == nil || cwExpanded {
        if note.isHidden == true {
          Text(verbatim: "(\(String(localized: "Private")))")
            .foregroundStyle(.secondary)
        } else if let nodes = note.text.map({
          MFMParser.parse($0)
        }) {
          MFMRenderer(
            nodes: nodes,
            emojis: note.emojis
          )
          .modifier(
            MaxHeightFadeModifier(maxHeight: style == .detail ? nil : 160)
          )
        }
        if !MediaFile.previewable(from: note.files).isEmpty {
          NoteMediaStrip(
            files: note.files,
            thumbnailSize: style == .compact
              ? NoteMediaSize.compact : NoteMediaSize.standard
          )
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

enum NoteBodyStyle {
  case standard
  case detail
  case compact
}

private struct MaxHeightFadeModifier: ViewModifier {
  let maxHeight: CGFloat?

  @State private var contentHeight: CGFloat = 0

  func body(content: Content) -> some View {
    let isOverflowing = maxHeight != nil && contentHeight > maxHeight!
    let targetHeight = isOverflowing ? maxHeight! : nil

    content
      .background(
        GeometryReader { geometry in
          Color.clear
            .preference(key: ContentHeightKey.self, value: geometry.size.height)
        }
      )
      .onPreferenceChange(ContentHeightKey.self) { height in
        self.contentHeight = height
      }
      .frame(maxHeight: targetHeight, alignment: .top)
      .clipped()
      .mask {
        if isOverflowing {
          VStack(spacing: 0) {
            Color.black
            LinearGradient(
              gradient: Gradient(colors: [.black, .clear]),
              startPoint: .top,
              endPoint: .bottom
            )
            .frame(height: maxHeight.flatMap { $0 / 2 })
          }
        } else {
          Color.black
        }
      }
      .overlay(alignment: .bottom) {
        if isOverflowing {
          Text("Show more")
            .bold()
            .foregroundStyle(Color.accentColor)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
  }

  private struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
      value = max(value, nextValue())
    }
  }
}
