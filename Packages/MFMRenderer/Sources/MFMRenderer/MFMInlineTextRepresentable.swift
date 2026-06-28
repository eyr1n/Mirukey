import SwiftUI
import UIKit

struct MFMInlineTextRepresentable: UIViewRepresentable {
  let attributedText: NSAttributedString
  let sizeKey: String
  let lineLimit: Int?
  let isInteractive: Bool
  let onOpenURL: (URL) -> Void
  let onOpenMFMLink: (MFMLink) -> Void
  let onEmojiAspectLearned: (String, CGFloat) -> Void

  func makeUIView(context: Context) -> MFMInlineTextView {
    let view = MFMInlineTextView()
    view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    view.setContentHuggingPriority(.defaultLow, for: .horizontal)
    view.setContentCompressionResistancePriority(.required, for: .vertical)
    return view
  }

  func updateUIView(_ view: MFMInlineTextView, context: Context) {
    view.onOpenURL = onOpenURL
    view.onOpenMFMLink = onOpenMFMLink
    view.onEmojiAspectLearned = onEmojiAspectLearned
    view.isInteractive = isInteractive
    view.lineLimit = lineLimit ?? 0
    view.setAttributedText(attributedText)
  }

  func sizeThatFits(_ proposal: ProposedViewSize, uiView: MFMInlineTextView, context: Context)
    -> CGSize?
  {
    let width = proposal.width?.isFinite == true ? proposal.width! : uiView.fallbackWidth
    let limit = lineLimit ?? 0
    if let cached = MFMTextSizeCache.shared.get(key: sizeKey, width: width, lineLimit: limit) {
      return cached
    }
    let result = uiView.measure(width: width)
    MFMTextSizeCache.shared.set(result, key: sizeKey, width: width, lineLimit: limit)
    return result
  }
}
