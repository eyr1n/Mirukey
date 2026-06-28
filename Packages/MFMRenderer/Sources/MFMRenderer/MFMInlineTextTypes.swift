import UIKit

struct MFMInlineStyle: OptionSet, Hashable {
  let rawValue: Int

  static let bold = MFMInlineStyle(rawValue: 1 << 0)
  static let italic = MFMInlineStyle(rawValue: 1 << 1)
  static let small = MFMInlineStyle(rawValue: 1 << 2)
  static let strike = MFMInlineStyle(rawValue: 1 << 3)
  static let inlineCode = MFMInlineStyle(rawValue: 1 << 4)
}

enum MFMFontFamily: String {
  case `default`
  case serif
  case monospaced
  case cursive
  case fantasy
  case emoji
  case math
}

struct MFMInlineToken {
  enum Kind {
    case text(String)
    case url(String, link: String)
    case mention(String)
    case hashtag(String)
    case emoji(String)
  }

  let kind: Kind
  let state: MFMInlineTextState

  var styles: MFMInlineStyle { state.styles }
  var fontFamily: MFMFontFamily { state.fontFamily }
  var fgColor: UIColor? { state.fgColor }
  var bgColor: UIColor? { state.bgColor }

  func replacingKind(_ kind: Kind) -> MFMInlineToken {
    MFMInlineToken(kind: kind, state: state)
  }
}

struct MFMInlineTextState {
  var styles: MFMInlineStyle = []
  var fontFamily: MFMFontFamily = .default
  var fgColor: UIColor? = nil
  var bgColor: UIColor? = nil

  func adding(_ style: MFMInlineStyle) -> MFMInlineTextState {
    var copy = self
    copy.styles.insert(style)
    return copy
  }
}

struct MFMInlineTextStyle {
  let uiFont: UIFont
  var emojiScale: CGFloat = 1
  var foregroundColor: UIColor = .label
  var foregroundColorKey: String = "primary"

  init(
    uiFont: UIFont,
    emojiScale: CGFloat = 1,
    foregroundColor: UIColor = .label,
    foregroundColorKey: String = "primary"
  ) {
    self.uiFont = uiFont
    self.emojiScale = emojiScale
    self.foregroundColor = foregroundColor
    self.foregroundColorKey = foregroundColorKey
  }

  func emojiSize(for font: UIFont) -> CGFloat {
    let base = (font.lineHeight * 0.84).rounded(.toNearestOrAwayFromZero)
    return (base * emojiScale).rounded(.toNearestOrAwayFromZero)
  }

  var resolvedEmojiSize: CGFloat { emojiSize(for: uiFont) }

  var styleKey: String {
    let descriptor = uiFont.fontDescriptor
    let traits = descriptor.symbolicTraits.rawValue
    let weight = uiFont.weightValue ?? 0

    let name = uiFont.fontName
    let pointSize = Int(uiFont.pointSize.rounded(.toNearestOrAwayFromZero))
    let lineHeight = Int(uiFont.lineHeight.rounded(.toNearestOrAwayFromZero))
    let emojiSize = Int(resolvedEmojiSize)

    let foregroundKey = foregroundColor.cacheKey(fallback: foregroundColorKey)
    return "\(name):\(pointSize):\(lineHeight):\(emojiSize):\(traits):\(String(format: "%.3f", weight)):\(foregroundKey)"
  }
}
