import UIKit

nonisolated final class MFMRemoteEmojiAttachment: NSTextAttachment {
  let urlString: String

  private static let transparentImage: UIImage = {
    let format = UIGraphicsImageRendererFormat.default()
    format.opaque = false
    return UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1), format: format).image { _ in }
  }()

  init(urlString: String, size: CGFloat, aspect: CGFloat, font: UIFont) {
    self.urlString = urlString
    super.init(data: nil, ofType: nil)
    image = Self.transparentImage
    let yOffset = font.descender + (font.lineHeight - size) / 2
    bounds = CGRect(x: 0, y: yOffset, width: size * aspect, height: size)
    accessibilityLabel = urlString
  }

  required init?(coder: NSCoder) {
    self.urlString = ""
    super.init(coder: coder)
  }

  override func image(
    forBounds imageBounds: CGRect, textContainer: NSTextContainer?, characterIndex charIndex: Int
  ) -> UIImage? {
    Self.transparentImage
  }

  override func attachmentBounds(
    for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect,
    glyphPosition position: CGPoint, characterIndex charIndex: Int
  ) -> CGRect {
    clampedBounds(forLineFragment: lineFrag)
  }

  private func clampedBounds(forLineFragment lineFrag: CGRect) -> CGRect {
    var rect = bounds
    let availableWidth = lineFrag.width
    guard availableWidth.isFinite, availableWidth > 0 else { return rect }
    rect.size.width = min(rect.width, availableWidth)
    return rect
  }
}
