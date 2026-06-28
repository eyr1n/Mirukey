import MFMParser
import SwiftUI
import UIKit

struct MFMInlineRendererView: View {
  @Environment(\.openURL) private var openURL
  @Environment(\.mfmEmojiResolver) private var emojiResolver
  @Environment(\.mfmLinkHandler) private var linkHandler
  @Environment(\.font) private var font
  @Environment(\.fontResolutionContext) private var fontResolutionContext
  @Environment(\.multilineTextAlignment) private var multilineTextAlignment

  let tokens: [MFMInlineToken]
  let emojis: [String: String]?
  let emojiScale: CGFloat
  let color: Color
  let lineLimit: Int?

  @State private var aspects: [String: CGFloat] = [:]

  init(
    nodes: [MFMNode],
    emojis: [String: String]?,
    emojiScale: CGFloat,
    color: Color,
    lineLimit: Int?
  ) {
    self.tokens = MFMInlineTextBuilder.tokens(from: nodes)
    self.emojis = emojis
    self.emojiScale = emojiScale
    self.color = color
    self.lineLimit = lineLimit
  }

  var body: some View {
    let _ = aspects
    let builder = MFMInlineTextBuilder(
      tokens: tokens,
      emojis: emojis,
      globalResolver: { emojiResolver($0) },
      aspects: aspects,
      style: MFMInlineTextStyle(
        uiFont: resolvedUIFont,
        emojiScale: emojiScale,
        foregroundColor: UIColor(color),
        foregroundColorKey: String(describing: color)
      ),
      alignment: NSTextAlignment(multilineTextAlignment)
    )
    let key = builder.signature
    let string = MFMAttributedStringCache.shared.getOrBuild(key) {
      builder.makeAttributedString()
    }

    MFMInlineTextRepresentable(
      attributedText: string,
      sizeKey: key,
      lineLimit: lineLimit,
      isInteractive: builder.hasLinks,
      onOpenURL: { openURL($0) },
      onOpenMFMLink: { linkHandler($0) },
      onEmojiAspectLearned: learnAspect
    )
  }

  private func learnAspect(_ url: String, _ aspect: CGFloat) {
    Task { @MainActor in
      if aspects[url] == aspect { return }
      aspects[url] = aspect
    }
  }

  private var resolvedUIFont: UIFont {
    let resolved = (font ?? .body).resolve(in: fontResolutionContext)
    return resolved.ctFont.asUIFont
  }
}

extension NSTextAlignment {
  init(_ textAlignment: TextAlignment) {
    switch textAlignment {
    case .leading: self = .left
    case .center: self = .center
    case .trailing: self = .right
    }
  }
}
