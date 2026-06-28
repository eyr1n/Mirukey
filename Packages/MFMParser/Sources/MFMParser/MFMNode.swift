import Foundation

public struct MFMFnArgs: Equatable, Sendable {
  public struct Arg: Hashable, Sendable {
    public enum Value: Hashable, Sendable {
      case string(String)
      case `true`
    }

    public let key: String
    public let value: Value
  }

  private(set) var args: [Arg] = []

  init(_ args: [Arg]) {
    for arg in args {
      set(arg)
    }
  }

  mutating func set(_ arg: Arg) {
    if let index = args.firstIndex(where: { $0.key == arg.key }) {
      args[index] = arg
    } else {
      args.append(arg)
    }
  }

  public subscript(_ key: String) -> Arg.Value? {
    args.first { $0.key == key }?.value
  }

  public static func == (lhs: MFMFnArgs, rhs: MFMFnArgs) -> Bool {
    Set(lhs.args) == Set(rhs.args)
  }
}

public enum MFMNode: Equatable, Sendable {
  case quote([MFMNode])
  case search(query: String, content: String)
  case blockCode(code: String, lang: String?)
  case mathBlock(formula: String)
  case center([MFMNode])

  case unicodeEmoji(String)
  case emojiCode(name: String)
  case bold([MFMNode])
  case small([MFMNode])
  case italic([MFMNode])
  case strike([MFMNode])
  case inlineCode(code: String)
  case mathInline(formula: String)
  case mention(username: String, host: String?, acct: String)
  case hashtag(String)
  case url(url: String, brackets: Bool)
  case link(silent: Bool, url: String, children: [MFMNode])
  case fn(name: String, args: MFMFnArgs, children: [MFMNode])
  case plain([MFMNode])
  case text(String)

  public var isBlock: Bool {
    switch self {
    case .quote, .search, .blockCode, .mathBlock, .center:
      return true
    default:
      return false
    }
  }

  public var children: [MFMNode]? {
    switch self {
    case .quote(let c), .center(let c), .bold(let c), .small(let c),
      .italic(let c), .strike(let c), .plain(let c):
      return c
    case .link(_, _, let c), .fn(_, _, let c):
      return c
    default:
      return nil
    }
  }
}

func QUOTE(_ children: [MFMNode]) -> MFMNode { .quote(children) }

func SEARCH(_ query: String, _ content: String) -> MFMNode {
  .search(query: query, content: content)
}

func CODE_BLOCK(_ code: String, _ lang: String?) -> MFMNode {
  .blockCode(code: code, lang: lang)
}

func MATH_BLOCK(_ formula: String) -> MFMNode { .mathBlock(formula: formula) }

func CENTER(_ children: [MFMNode]) -> MFMNode { .center(children) }

func UNI_EMOJI(_ value: String) -> MFMNode { .unicodeEmoji(value) }

func EMOJI_CODE(_ name: String) -> MFMNode { .emojiCode(name: name) }

func BOLD(_ children: [MFMNode]) -> MFMNode { .bold(children) }

func SMALL(_ children: [MFMNode]) -> MFMNode { .small(children) }

func ITALIC(_ children: [MFMNode]) -> MFMNode { .italic(children) }

func STRIKE(_ children: [MFMNode]) -> MFMNode { .strike(children) }

func INLINE_CODE(_ code: String) -> MFMNode { .inlineCode(code: code) }

func MATH_INLINE(_ formula: String) -> MFMNode { .mathInline(formula: formula) }

func MENTION(_ username: String, _ host: String?, _ acct: String) -> MFMNode {
  .mention(username: username, host: host, acct: acct)
}

func HASHTAG(_ value: String) -> MFMNode { .hashtag(value) }

func N_URL(_ value: String, _ brackets: Bool = false) -> MFMNode {
  .url(url: value, brackets: brackets)
}

func LINK(_ silent: Bool, _ url: String, _ children: [MFMNode]) -> MFMNode {
  .link(silent: silent, url: url, children: children)
}

func FN(_ name: String, _ args: MFMFnArgs, _ children: [MFMNode]) -> MFMNode {
  .fn(name: name, args: args, children: children)
}

func PLAIN(_ text: String) -> MFMNode { .plain([.text(text)]) }

func TEXT(_ value: String) -> MFMNode { .text(value) }
