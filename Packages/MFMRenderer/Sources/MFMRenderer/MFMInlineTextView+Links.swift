import UIKit

extension MFMInlineTextView {
  override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    guard isInteractive else { return false }
    return linkAction(at: point) != nil
  }

  private func glyphIndex(at point: CGPoint) -> Int? {
    guard textStorage.length > 0 else { return nil }
    setContainerWidth(bounds.width)
    layoutManager.ensureLayout(for: textContainer)
    let index = layoutManager.glyphIndex(
      for: point,
      in: textContainer,
      fractionOfDistanceThroughGlyph: nil
    )
    guard index < layoutManager.numberOfGlyphs else { return nil }
    return index
  }

  func characterIndex(at point: CGPoint) -> Int? {
    guard let glyphIndex = glyphIndex(at: point) else { return nil }
    let charIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)
    guard charIndex < textStorage.length else { return nil }
    return charIndex
  }

  private enum LinkAction {
    case url(URL)
    case mfmLink(MFMLink)
  }

  private func linkAction(at point: CGPoint) -> LinkAction? {
    linkActionAndRange(at: point)?.action
  }

  private func linkActionAndRange(at point: CGPoint) -> (action: LinkAction, range: NSRange)? {
    guard let glyphIndex = glyphIndex(at: point) else { return nil }
    let glyphRect = layoutManager.boundingRect(
      forGlyphRange: NSRange(location: glyphIndex, length: 1),
      in: textContainer
    )
    guard glyphRect.contains(point) else { return nil }
    let charIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)
    guard charIndex < textStorage.length else { return nil }
    var effectiveRange = NSRange()
    guard let value = textStorage.attribute(.mfmLink, at: charIndex, effectiveRange: &effectiveRange) else {
      return nil
    }
    guard let action = Self.linkAction(from: value) else { return nil }
    return (action, effectiveRange)
  }

  private static func linkAction(from value: Any) -> LinkAction? {
    if let link = value as? MFMLink { return .mfmLink(link) }
    if let url = value as? URL { return .url(url) }
    if let string = value as? String, let url = URL(string: string) { return .url(url) }
    return nil
  }

  @objc func handleTap(_ gesture: UITapGestureRecognizer) {
    let location = gesture.location(in: self)

    guard isInteractive, let action = linkAction(at: location) else { return }
    switch action {
    case .url(let url):
      onOpenURL?(url)
    case .mfmLink(let link):
      onOpenMFMLink?(link)
    }
  }
}

extension MFMInlineTextView {
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesBegan(touches, with: event)
    guard let point = touches.first?.location(in: self) else { return }
    setLinkHighlight(at: point)
  }

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesEnded(touches, with: event)
    clearLinkHighlight()
  }

  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesCancelled(touches, with: event)
    clearLinkHighlight()
  }

  private func setLinkHighlight(at point: CGPoint) {
    guard let charIndex = characterIndex(at: point) else { return }
    var effectiveRange = NSRange()
    guard textStorage.attribute(.mfmLink, at: charIndex, effectiveRange: &effectiveRange) != nil else {
      return
    }

    if highlightedRange != nil { return }
    highlightedRange = effectiveRange

    let color = textStorage.attribute(.foregroundColor, at: charIndex, effectiveRange: nil) as? UIColor ?? UIColor.label
    originalColor = color

    let highlightedColor = color.withAlphaComponent(color.cgColor.alpha * 0.5)
    textStorage.addAttribute(.foregroundColor, value: highlightedColor, range: effectiveRange)
    setNeedsDisplay()
  }

  private func clearLinkHighlight() {
    guard let range = highlightedRange, let color = originalColor else { return }
    textStorage.addAttribute(.foregroundColor, value: color, range: range)
    highlightedRange = nil
    originalColor = nil
    setNeedsDisplay()
  }
}
