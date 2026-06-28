import MFMParser
import UIKit

struct MFMInlineTextBuilder {
  let style: MFMInlineTextStyle
  let alignment: NSTextAlignment

  private let tokens: [MFMInlineToken]
  let emojis: [String: String]?
  let globalResolver: (String) -> URL?
  let aspects: [String: CGFloat]

  init(
    nodes: [MFMNode],
    emojis: [String: String]?,
    globalResolver: @escaping (String) -> URL?,
    aspects: [String: CGFloat] = [:],
    style: MFMInlineTextStyle,
    alignment: NSTextAlignment = .left
  ) {
    self.init(
      tokens: Self.tokens(from: nodes),
      emojis: emojis,
      globalResolver: globalResolver,
      aspects: aspects,
      style: style,
      alignment: alignment
    )
  }

  init(
    tokens: [MFMInlineToken],
    emojis: [String: String]?,
    globalResolver: @escaping (String) -> URL?,
    aspects: [String: CGFloat] = [:],
    style: MFMInlineTextStyle,
    alignment: NSTextAlignment = .left
  ) {
    self.tokens = tokens
    self.emojis = emojis
    self.globalResolver = globalResolver
    self.aspects = aspects
    self.style = style
    self.alignment = alignment
  }

  static func tokens(from nodes: [MFMNode]) -> [MFMInlineToken] {
    var tokens: [MFMInlineToken] = []
    tokens.reserveCapacity(nodes.count)
    flatten(nodes: nodes, state: MFMInlineTextState(), into: &tokens)
    return tokens
  }

  private static func flatten(
    nodes: [MFMNode],
    state: MFMInlineTextState,
    into result: inout [MFMInlineToken]
  ) {
    func makeToken(
      _ kind: MFMInlineToken.Kind,
      state tokenState: MFMInlineTextState = state
    ) -> MFMInlineToken {
      MFMInlineToken(kind: kind, state: tokenState)
    }

    for node in nodes {
      switch node {
      case .text(let value):
        result.append(makeToken(.text(value)))
      case .unicodeEmoji(let value):
        result.append(makeToken(.text(value)))
      case .emojiCode(let name):
        result.append(makeToken(.emoji(name)))
      case .url(let url, _):
        result.append(makeToken(.url(url, link: url)))
      case .mention(_, _, let acct):
        result.append(makeToken(.mention(acct)))
      case .hashtag(let tag):
        result.append(makeToken(.hashtag(tag)))
      case .inlineCode(let code):
        result.append(makeToken(.text(code), state: state.adding(.inlineCode)))
      case .mathInline(let formula):
        result.append(makeToken(.text(formula)))
      case .bold(let children):
        flatten(nodes: children, state: state.adding(.bold), into: &result)
      case .italic(let children):
        flatten(nodes: children, state: state.adding(.italic), into: &result)
      case .small(let children):
        flatten(nodes: children, state: state.adding(.small), into: &result)
      case .strike(let children):
        flatten(nodes: children, state: state.adding(.strike), into: &result)
      case .quote(let children), .center(let children), .plain(let children):
        flatten(nodes: children, state: state, into: &result)

      case .link(_, let url, let children):
        var childTokens: [MFMInlineToken] = []
        childTokens.reserveCapacity(children.count)
        flatten(nodes: children, state: state, into: &childTokens)
        for token in childTokens {
          switch token.kind {
          case .text(let val), .url(let val, _), .mention(let val):
            result.append(token.replacingKind(.url(val, link: url)))
          case .hashtag(let tag):
            result.append(token.replacingKind(.url("#\(tag)", link: url)))
          case .emoji:
            result.append(token)
          }
        }

      case .fn(let name, let args, let children):
        let functionName = name.lowercased()
        if functionName == "unixtime",
          let value = children.first?.plainText,
          let seconds = Self.leadingInt(in: value)
        {
          result.append(makeToken(.text(Self.unixtimeText(seconds: seconds))))
          continue
        }
        flatten(
          nodes: children,
          state: fnState(name: functionName, args: args, from: state),
          into: &result
        )

      default:
        result.append(makeToken(.text(MFMParser.toString(node))))
      }
    }
  }

  private static func fnState(
    name: String,
    args: MFMFnArgs,
    from state: MFMInlineTextState
  ) -> MFMInlineTextState {
    var next = state
    switch name {
    case "font":
      if args["serif"] != nil {
        next.fontFamily = .serif
      } else if args["monospace"] != nil {
        next.fontFamily = .monospaced
      } else if args["cursive"] != nil {
        next.fontFamily = .cursive
      } else if args["fantasy"] != nil {
        next.fontFamily = .fantasy
      } else if args["emoji"] != nil {
        next.fontFamily = .emoji
      } else if args["math"] != nil {
        next.fontFamily = .math
      } else if args["sans-serif"] != nil {
        next.fontFamily = .default
      }
    case "fg":
      if let hex = args.stringValue(for: "color"), let color = UIColor(hex: hex) {
        next.fgColor = color
      }
    case "bg":
      if let hex = args.stringValue(for: "color"), let color = UIColor(hex: hex) {
        next.bgColor = color
      }
    default:
      break
    }
    return next
  }

  private static func unixtimeText(seconds: Int) -> String {
    let date = Date(timeIntervalSince1970: TimeInterval(seconds))
    return "\(unixtimeAbsoluteFormatter.string(from: date)) (\(unixtimeRelativeFormatter.localizedString(for: date, relativeTo: Date())))"
  }

  private static func leadingInt(in value: String) -> Int? {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let range = trimmed.range(of: #"^-?\d+"#, options: .regularExpression) else { return nil }
    return Int(String(trimmed[range]))
  }

  private static let unixtimeAbsoluteFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale.current
    formatter.setLocalizedDateFormatFromTemplate("yyyyMMddHHmmss")
    return formatter
  }()

  private static let unixtimeRelativeFormatter: RelativeDateTimeFormatter = {
    let formatter = RelativeDateTimeFormatter()
    formatter.locale = Locale.current
    formatter.unitsStyle = .full
    return formatter
  }()

  var hasLinks: Bool {
    tokens.contains { token in
      switch token.kind {
      case .url(_, let link): return URL(string: link) != nil
      case .mention, .hashtag: return true
      default: return false
      }
    }
  }

  var signature: String {
    var key = "s:\(style.styleKey):\(alignment.rawValue)"
    key.reserveCapacity(key.count + tokens.count * 48)

    for token in tokens {
      switch token.kind {
      case .text(let value):
        key.append("\u{1}")
        appendTokenContext(token, to: &key)
        key.append(value)

      case .url(let value, let link):
        key.append("\u{2}")
        appendTokenContext(token, to: &key)
        key.append(value)
        key.append("|")
        key.append(link)

      case .mention(let value):
        key.append("\u{3}")
        appendTokenContext(token, to: &key)
        key.append(value)

      case .hashtag(let value):
        key.append("\u{6}")
        appendTokenContext(token, to: &key)
        key.append(value)

      case .emoji(let name):
        if let url = resolveEmojiURL(name)?.absoluteString {
          key.append("\u{4}")
          appendTokenContext(token, to: &key)
          key.append(url)
          key.append("#")
          key.append(Self.aspectKey(aspects[url]))
        } else {
          key.append("\u{5}")
          appendTokenContext(token, to: &key)
          key.append(name)
        }
      }
    }

    return key
  }

  func makeAttributedString() -> NSAttributedString {
    let result = NSMutableAttributedString()
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = alignment

    for token in tokens {
      result.append(attributedToken(token, paragraphStyle: paragraphStyle))
    }

    return result
  }

  static func aspectKey(_ aspect: CGFloat?) -> String {
    String(format: "%.2f", aspect ?? 1)
  }

  private func appendTokenContext(_ token: MFMInlineToken, to key: inout String) {
    key.append(String(token.styles.rawValue))
    key.append(":")
    key.append(token.fontFamily.rawValue)
    key.append(":")
    if let fgColor = token.fgColor {
      key.append(fgColor.hexString)
    }
    key.append(":")
    if let bgColor = token.bgColor {
      key.append(bgColor.hexString)
    }
  }
}
