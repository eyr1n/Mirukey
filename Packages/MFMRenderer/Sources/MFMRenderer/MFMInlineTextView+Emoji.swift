import SDWebImage
import UIKit

extension MFMInlineTextView {
  func clearEmojiViews() {
    for view in emojiViews.values {
      view.removeFromSuperview()
    }
    emojiViews.removeAll()
  }

  func updateEmojiOverlays() {
    guard bounds.width > 0, textStorage.length > 0 else {
      clearEmojiViews()
      return
    }
    layoutManager.ensureLayout(for: textContainer)
    let fullRange = NSRange(location: 0, length: textStorage.length)
    let laidOutGlyphs = layoutManager.glyphRange(for: textContainer)
    var activeLocations = Set<Int>()

    textStorage.enumerateAttribute(.attachment, in: fullRange, options: []) { value, range, _ in
      guard let attachment = value as? MFMRemoteEmojiAttachment else { return }
      let glyphRange = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
      guard glyphRange.length > 0 else { return }
      let glyphIndex = glyphRange.location
      guard glyphIndex >= laidOutGlyphs.location, glyphIndex < NSMaxRange(laidOutGlyphs) else {
        return
      }
      let truncated = layoutManager.truncatedGlyphRange(inLineFragmentForGlyphAt: glyphIndex)
      if truncated.location != NSNotFound, glyphIndex >= truncated.location { return }
      let rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
      guard rect.width > 0, rect.height > 0 else { return }
      activeLocations.insert(range.location)

      let imageView: SDAnimatedImageView
      if let existing = emojiViews[range.location] {
        imageView = existing
      } else {
        imageView = SDAnimatedImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = false
        imageView.clipsToBounds = true
        addSubview(imageView)
        emojiViews[range.location] = imageView
      }
      imageView.frame = rect.integral
      loadEmoji(attachment, into: imageView)
    }

    for (location, view) in emojiViews where !activeLocations.contains(location) {
      view.sd_cancelCurrentImageLoad()
      view.image = nil
      view.removeFromSuperview()
      emojiViews.removeValue(forKey: location)
    }
  }

  private func loadEmoji(
    _ attachment: MFMRemoteEmojiAttachment,
    into imageView: SDAnimatedImageView
  ) {
    let urlString = attachment.urlString
    guard let url = URL(string: urlString) else { return }

    let report: (UIImage?) -> Void = { [weak self] image in
      guard let self, let image else { return }
      self.onEmojiAspectLearned?(urlString, image.size.width / image.size.height)
    }

    if imageView.sd_currentImageURL == url, let image = imageView.image {
      report(image)
      return
    }

    imageView.sd_setImage(
      with: url,
      placeholderImage: nil,
      options: [.retryFailed, .matchAnimatedImageClass],
      context: [.animatedImageClass: SDAnimatedImage.self],
      progress: nil,
      completed: { image, _, _, _ in report(image) }
    )
  }
}
