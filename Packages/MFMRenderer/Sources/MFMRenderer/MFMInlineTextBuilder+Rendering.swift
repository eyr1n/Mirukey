import MFMParser
import UIKit

extension MFMInlineTextBuilder {
  func attributedToken(
    _ token: MFMInlineToken,
    paragraphStyle: NSParagraphStyle
  ) -> NSAttributedString {
    switch token.kind {
    case .text(let value):
      return textString(value, token: token, paragraphStyle: paragraphStyle)

    case .url(let value, let link):
      guard let url = URL(string: link) else {
        return textString(value, token: token, paragraphStyle: paragraphStyle)
      }

      return textString(
        value,
        link: url,
        token: token,
        paragraphStyle: paragraphStyle
      )

    case .mention(let value):
      return textString(
        value,
        mfmLink: .mention(acct: value),
        token: token,
        paragraphStyle: paragraphStyle
      )

    case .hashtag(let value):
      return textString(
        "#\(value)",
        mfmLink: .hashtag(tag: value),
        token: token,
        paragraphStyle: paragraphStyle
      )

    case .emoji(let name):
      guard let url = resolveEmojiURL(name) else {
        return textString(":\(name):", token: token, paragraphStyle: paragraphStyle)
      }

      return emojiAttachment(
        urlString: url.absoluteString,
        token: token,
        paragraphStyle: paragraphStyle
      )
    }
  }

  func textString(
    _ value: String,
    link: URL? = nil,
    mfmLink: MFMLink? = nil,
    token: MFMInlineToken,
    paragraphStyle: NSParagraphStyle
  ) -> NSAttributedString {
    let font: UIFont
    let styles = token.styles

    if styles.contains(.inlineCode) {
      let baseFont = resolveFont(
        baseFont: style.uiFont,
        styles: styles,
        fontFamily: .monospaced
      )
      let monospacedFont = UIFont.monospacedSystemFont(ofSize: baseFont.pointSize, weight: .regular)
      var traits = monospacedFont.fontDescriptor.symbolicTraits
      if styles.contains(.bold) {
        traits.insert(.traitBold)
      }
      if styles.contains(.italic) {
        traits.insert(.traitItalic)
      }
      if let descriptor = monospacedFont.fontDescriptor.withSymbolicTraits(traits) {
        font = UIFont(descriptor: descriptor, size: monospacedFont.pointSize)
      } else {
        font = monospacedFont
      }
    } else {
      font = resolveFont(
        baseFont: style.uiFont,
        styles: styles,
        fontFamily: token.fontFamily
      )
    }

    var attributes: [NSAttributedString.Key: Any] = [
      .font: font,
      .paragraphStyle: paragraphStyle
    ]

    let baseColor = token.fgColor ?? style.foregroundColor
    attributes[.foregroundColor] = baseColor

    if let bg = token.bgColor {
      attributes[.backgroundColor] = bg
    }

    if let link {
      attributes[.mfmLink] = link
      if token.fgColor == nil {
        attributes[.foregroundColor] = UIColor.systemBlue
      }
    } else if let mfmLink {
      attributes[.mfmLink] = mfmLink
      if token.fgColor == nil {
        switch mfmLink {
        case .mention:
          attributes[.foregroundColor] = UIColor.systemBlue
        case .hashtag:
          attributes[.foregroundColor] = UIColor.systemOrange
        }
      }
    }

    if styles.contains(.strike) {
      attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
    }

    return NSAttributedString(string: value, attributes: attributes)
  }

  func emojiAttachment(
    urlString: String,
    token: MFMInlineToken,
    paragraphStyle: NSParagraphStyle
  ) -> NSAttributedString {
    let font = resolveFont(
      baseFont: style.uiFont,
      styles: token.styles,
      fontFamily: token.fontFamily
    )
    let attachment = MFMRemoteEmojiAttachment(
      urlString: urlString,
      size: style.emojiSize(for: font),
      aspect: aspects[urlString] ?? 1,
      font: font
    )

    let string = NSMutableAttributedString(attachment: attachment)

    var attributes: [NSAttributedString.Key: Any] = [
      .font: font,
      .paragraphStyle: paragraphStyle
    ]

    if let bg = token.bgColor {
      attributes[.backgroundColor] = bg
    }

    string.addAttributes(attributes, range: NSRange(location: 0, length: string.length))

    return string
  }

  func resolveEmojiURL(_ name: String) -> URL? {
    emojis?[name].flatMap(URL.init(string:)) ?? globalResolver(name)
  }
}

extension NSAttributedString.Key {
  static let mfmLink = NSAttributedString.Key("MFMLink")
}

extension MFMFnArgs {
  func stringValue(for key: String) -> String? {
    guard case .string(let value) = self[key] else { return nil }
    return value
  }
}

extension MFMNode {
  var plainText: String? {
    switch self {
    case .text(let value), .unicodeEmoji(let value):
      return value
    case .plain(let children):
      return children.compactMap(\.plainText).joined()
    default:
      return nil
    }
  }
}

extension UIFont {
  var weightValue: CGFloat? {
    guard
      let traits = fontDescriptor.object(forKey: .traits)
        as? [UIFontDescriptor.TraitKey: Any]
    else {
      return nil
    }

    return traits[.weight] as? CGFloat
  }
}

extension UIColor {
  convenience init?(hex: String) {
    var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

    var rgb: UInt64 = 0
    guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

    let r, g, b, a: CGFloat
    let length = hexSanitized.count

    if length == 3 {
      r = CGFloat((rgb & 0xF00) >> 8) / 15.0
      g = CGFloat((rgb & 0x0F0) >> 4) / 15.0
      b = CGFloat(rgb & 0x00F) / 15.0
      a = 1.0
    } else if length == 6 {
      r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
      g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
      b = CGFloat(rgb & 0x0000FF) / 255.0
      a = 1.0
    } else if length == 8 {
      r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
      g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
      b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
      a = CGFloat(rgb & 0x000000FF) / 255.0
    } else {
      return nil
    }

    self.init(red: r, green: g, blue: b, alpha: a)
  }

  var hexString: String {
    var r: CGFloat = 0
    var g: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0
    guard getRed(&r, green: &g, blue: &b, alpha: &a) else { return "" }
    return String(format: "%02X%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255), Int(a * 255))
  }

  func cacheKey(fallback: String) -> String {
    let hex = hexString
    return hex.isEmpty ? fallback : hex
  }
}
