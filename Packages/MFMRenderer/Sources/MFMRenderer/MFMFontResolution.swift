import CoreText
import UIKit

extension MFMInlineTextBuilder {
  func resolveFont(
    baseFont: UIFont,
    styles: MFMInlineStyle,
    fontFamily: MFMFontFamily
  ) -> UIFont {
    var font = baseFont
    var traits = font.fontDescriptor.symbolicTraits
    if styles.contains(.bold) {
      traits.insert(.traitBold)
    }
    if styles.contains(.italic) {
      traits.insert(.traitItalic)
    }

    let size = baseFont.pointSize
    var descriptor = font.fontDescriptor

    switch fontFamily {
    case .default:
      break
    case .serif:
      if let designDescriptor = descriptor.withDesign(.serif) {
        descriptor = designDescriptor
      }
    case .monospaced:
      if let designDescriptor = descriptor.withDesign(.monospaced) {
        descriptor = designDescriptor
      }
    case .cursive:
      if let named = Self.namedFont(["SnellRoundhand"], size: size, traits: traits) {
        font = named
        if styles.contains(.small) {
          font = font.withSize(font.pointSize * 5 / 6)
        }
        return font
      } else if let designDescriptor = descriptor.withDesign(.rounded) {
        descriptor = designDescriptor
      }
    case .fantasy:
      if let named = Self.namedFont(["Papyrus", "Copperplate"], size: size, traits: traits) {
        font = named
        if styles.contains(.small) {
          font = font.withSize(font.pointSize * 5 / 6)
        }
        return font
      }
    case .emoji:
      if let named = Self.namedFont(["AppleColorEmoji"], size: size, traits: traits) {
        return named
      }
    case .math:
      if let named = Self.namedFont(["TimesNewRomanPSMT"], size: size, traits: traits) {
        font = named
        if styles.contains(.small) {
          font = font.withSize(font.pointSize * 5 / 6)
        }
        return font
      } else if let designDescriptor = descriptor.withDesign(.serif) {
        descriptor = designDescriptor
      }
    }

    if let traitsDescriptor = descriptor.withSymbolicTraits(traits) {
      font = UIFont(descriptor: traitsDescriptor, size: size)
    } else {
      font = UIFont(descriptor: descriptor, size: size)
    }

    if styles.contains(.small) {
      font = font.withSize(font.pointSize * 5 / 6)
    }
    return font
  }

  static func namedFont(
    _ names: [String],
    size: CGFloat,
    traits: UIFontDescriptor.SymbolicTraits
  ) -> UIFont? {
    for name in names {
      guard let base = UIFont(name: name, size: size) else { continue }
      guard let descriptor = base.fontDescriptor.withSymbolicTraits(traits) else {
        return base
      }
      return UIFont(descriptor: descriptor, size: size)
    }
    return nil
  }
}

extension CTFont {
  var asUIFont: UIFont {
    let size = CTFontGetSize(self)
    let traits = CTFontGetSymbolicTraits(self)
    let weight: UIFont.Weight = traits.contains(.traitBold) ? .bold : .regular
    return UIFont.systemFont(ofSize: size, weight: weight)
  }
}
