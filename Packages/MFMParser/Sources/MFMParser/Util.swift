import Foundation

func mergeText(_ nodes: [Any]) -> [MFMNode] {
  var dest: [MFMNode] = []
  var storedChars: [String] = []

  /**
   * Generate a text node from the stored chars, And push it.
  */
  func generateText() {
    if !storedChars.isEmpty {
      dest.append(.text(storedChars.joined()))
      storedChars.removeAll()
    }
  }

  var flatten: [Any] = []
  for node in nodes {
    if let nested = node as? [Any] {
      flatten.append(contentsOf: nested)
    } else {
      flatten.append(node)
    }
  }

  for node in flatten {
    if let string = node as? String {
      // Store the char.
      storedChars.append(string)
    } else if let mfm = node as? MFMNode, case .text(let text) = mfm {
      storedChars.append(text)
    } else if let mfm = node as? MFMNode {
      generateText()
      dest.append(mfm)
    }
  }
  generateText()

  return dest
}

func stringifyNode(_ node: MFMNode) -> String {
  switch node {
  // block
  case .quote(let children):
    return stringifyTree(children)
      .components(separatedBy: "\n")
      .map { "> \($0)" }
      .joined(separator: "\n")
  case .search(_, let content):
    return content
  case .blockCode(let code, let lang):
    return "```\(lang ?? "")\n\(code)\n```"
  case .mathBlock(let formula):
    return "\\[\n\(formula)\n\\]"
  case .center(let children):
    return "<center>\n\(stringifyTree(children))\n</center>"
  // inline
  case .emojiCode(let name):
    return ":\(name):"
  case .unicodeEmoji(let emoji):
    return emoji
  case .bold(let children):
    return "**\(stringifyTree(children))**"
  case .small(let children):
    return "<small>\(stringifyTree(children))</small>"
  case .italic(let children):
    return "<i>\(stringifyTree(children))</i>"
  case .strike(let children):
    return "~~\(stringifyTree(children))~~"
  case .inlineCode(let code):
    return "`\(code)`"
  case .mathInline(let formula):
    return "\\(\(formula)\\)"
  case .mention(_, _, let acct):
    return acct
  case .hashtag(let hashtag):
    return "#\(hashtag)"
  case .url(let url, let brackets):
    return brackets ? "<\(url)>" : url
  case .link(let silent, let url, let children):
    let prefix = silent ? "?" : ""
    return "\(prefix)[\(stringifyTree(children))](\(url))"
  case .fn(let name, let fnArgs, let children):
    let argFields = fnArgs.args.map { arg -> String in
      switch arg.value {
      case .true: return arg.key
      case .string(let value): return "\(arg.key)=\(value)"
      }
    }
    let argsString = argFields.isEmpty ? "" : "." + argFields.joined(separator: ",")
    return "$[\(name)\(argsString) \(stringifyTree(children))]"
  case .plain(let children):
    return "<plain>\n\(stringifyTree(children))\n</plain>"
  case .text(let text):
    return text
  }
}

private enum StringifyState {
  case none
  case inline
  case block
}

func stringifyTree(_ nodes: [MFMNode]) -> String {
  var dest: [MFMNode] = []
  var state: StringifyState = .none

  for node in nodes {
    // 文脈に合わせて改行を追加する。
    // none -> inline   : No
    // none -> block    : No
    // inline -> inline : No
    // inline -> block  : Yes
    // block -> inline  : Yes
    // block -> block   : Yes

    var pushLf = true
    if node.isBlock {
      if state == .none { pushLf = false }
      state = .block
    } else {
      if state == .none || state == .inline { pushLf = false }
      state = .inline
    }
    if pushLf {
      dest.append(.text("\n"))
    }
    dest.append(node)
  }

  return dest.map { stringifyNode($0) }.joined()
}

func inspectOne(_ node: MFMNode, _ action: (MFMNode) -> Void) {
  action(node)
  if let children = node.children {
    for child in children {
      inspectOne(child, action)
    }
  }
}
