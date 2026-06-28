import SDWebImage
import UIKit

final class MFMInlineTextView: UIView {
  var onOpenURL: ((URL) -> Void)?
  var onOpenMFMLink: ((MFMLink) -> Void)?
  var onEmojiAspectLearned: ((String, CGFloat) -> Void)?

  var isInteractive = false {
    didSet { isUserInteractionEnabled = isInteractive }
  }

  var lineLimit: Int = 0 {
    didSet {
      guard lineLimit != oldValue else { return }
      textContainer.maximumNumberOfLines = lineLimit
      invalidateIntrinsicContentSize()
      setNeedsLayout()
      setNeedsDisplay()
    }
  }

  let textStorage = NSTextStorage()
  let layoutManager = NSLayoutManager()
  let textContainer = NSTextContainer()
  private var currentText: NSAttributedString?
  var emojiViews: [Int: SDAnimatedImageView] = [:]
  var highlightedRange: NSRange?
  var originalColor: UIColor?

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    isOpaque = false
    contentMode = .redraw
    textContainer.lineFragmentPadding = 0
    textContainer.lineBreakMode = .byTruncatingTail
    textContainer.maximumNumberOfLines = 0
    layoutManager.usesFontLeading = true
    layoutManager.addTextContainer(textContainer)
    textStorage.addLayoutManager(layoutManager)
    let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
    tap.cancelsTouchesInView = false
    tap.delegate = self
    addGestureRecognizer(tap)

    registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: Self, _) in
      view.setNeedsDisplay()
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func setAttributedText(_ text: NSAttributedString) {
    guard text !== currentText else { return }
    currentText = text
    textStorage.setAttributedString(text)
    clearEmojiViews()
    invalidateIntrinsicContentSize()
    setNeedsLayout()
    setNeedsDisplay()
  }

  func setContainerWidth(_ width: CGFloat) {
    if textContainer.size.width != width {
      textContainer.size = CGSize(width: width, height: .greatestFiniteMagnitude)
    }
  }

  func measure(width: CGFloat) -> CGSize {
    setContainerWidth(width)
    layoutManager.ensureLayout(for: textContainer)
    let used = layoutManager.usedRect(for: textContainer)
    return CGSize(width: min(ceil(used.width), width), height: ceil(used.height))
  }

  var fallbackWidth: CGFloat {
    window?.windowScene?.screen.bounds.width ?? 393
  }

  override var intrinsicContentSize: CGSize {
    let width = bounds.width > 0 ? bounds.width : fallbackWidth
    return measure(width: width)
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    setContainerWidth(bounds.width)
    updateEmojiOverlays()
  }

  override func draw(_ rect: CGRect) {
    setContainerWidth(bounds.width)
    let glyphRange = layoutManager.glyphRange(for: textContainer)
    layoutManager.drawBackground(forGlyphRange: glyphRange, at: .zero)
    layoutManager.drawGlyphs(forGlyphRange: glyphRange, at: .zero)
  }
}

extension MFMInlineTextView: UIGestureRecognizerDelegate {
  func gestureRecognizer(
    _ gestureRecognizer: UIGestureRecognizer,
    shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
  ) -> Bool {
    return !(otherGestureRecognizer is UITapGestureRecognizer)
  }
}
