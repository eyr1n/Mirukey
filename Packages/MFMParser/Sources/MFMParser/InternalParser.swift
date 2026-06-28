import Foundation

private func isAsciiAlnum(_ c: unichar) -> Bool {
  (c >= 0x30 && c <= 0x39) || (c >= 0x41 && c <= 0x5A) || (c >= 0x61 && c <= 0x7A)
}

private func trailingDotDashLength(_ s: String) -> Int {
  var n = 0
  for ch in s.reversed() {
    if ch == "." || ch == "-" { n += 1 } else { break }
  }
  return n
}

private func trailingDotCommaLength(_ s: String) -> Int {
  var n = 0
  for ch in s.reversed() {
    if ch == "." || ch == "," { n += 1 } else { break }
  }
  return n
}

private func startsWithDotDash(_ s: String) -> Bool {
  guard let first = s.first else { return false }
  return first == "." || first == "-"
}

private func isAllAsciiDigits(_ s: String) -> Bool {
  !s.isEmpty && s.utf16.allSatisfy { $0 >= 0x30 && $0 <= 0x39 }
}

private let space = regexp("[\u{20}\u{3000}\u{09}]")
private let alphaAndNum = regexp("[a-z0-9]", .caseInsensitive)

private func seqOrText(_ parsers: [Parser]) -> Parser {
  Parser { input, index, state in
    // TODO: typesafe implementation
    var accum: [Any] = []
    var latestIndex = index
    for parser in parsers {
      let result = parser.handler(input, latestIndex, state)
      if !result.success {
        if latestIndex == index {
          return failure()
        } else {
          return success(
            latestIndex,
            input.substring(with: NSRange(location: index, length: latestIndex - index)))
        }
      }
      accum.append(result.value)
      latestIndex = result.index
    }
    return success(latestIndex, accum)
  }
}

private let notLinkLabel = Parser { _, index, state in
  !state.linkLabel ? success(index, jsNull) : failure()
}

private let nestable = Parser { _, index, state in
  state.depth < state.nestLimit ? success(index, jsNull) : failure()
}

private func nest(_ parser: Parser, _ fallback: Parser? = nil) -> Parser {
  // nesting limited? -> No: specified parser, Yes: fallback parser (default = P.char)
  let inner = alt([
    seq(nestable, parser).select(1),
    fallback ?? char,
  ])
  return Parser { input, index, state in
    state.depth += 1
    let result = inner.handler(input, index, state)
    state.depth -= 1
    return result
  }
}

final class MFMLanguage: @unchecked Sendable {
  var fullParser: Parser!
  var simpleParser: Parser!
  var full: Parser!
  var simple: Parser!
  var inline: Parser!
  var quote: Parser!
  var codeBlock: Parser!
  var mathBlock: Parser!
  var centerTag: Parser!
  var big: Parser!
  var boldAsta: Parser!
  var boldTag: Parser!
  var boldUnder: Parser!
  var smallTag: Parser!
  var italicTag: Parser!
  var italicAsta: Parser!
  var italicUnder: Parser!
  var strikeTag: Parser!
  var strikeWave: Parser!
  var unicodeEmoji: Parser!
  var plainTag: Parser!
  var fn: Parser!
  var inlineCode: Parser!
  var mathInline: Parser!
  var mention: Parser!
  var hashtag: Parser!
  var emojiCode: Parser!
  var link: Parser!
  var url: Parser!
  var urlAlt: Parser!
  var search: Parser!
  var text: Parser!

  init() {
    var pendingParsers: [() -> Void] = []

    func lazy(_ fn: @escaping () -> Parser) -> Parser {
      let parser = Parser()
      pendingParsers.append { parser.handler = fn().handler }
      return parser
    }

    fullParser = lazy { self.full.many(0) }

    simpleParser = lazy { self.simple.many(0) }

    full = lazy {
      alt([
        // Regexp
        self.unicodeEmoji,
        // "<center>" block
        self.centerTag,
        // "<small>"
        self.smallTag,
        // "<plain>"
        self.plainTag,
        // "<b>"
        self.boldTag,
        // "<i>"
        self.italicTag,
        // "<s>"
        self.strikeTag,
        // "<http"
        self.urlAlt,
        // "***"
        self.big,
        // "**"
        self.boldAsta,
        // "*"
        self.italicAsta,
        // "__"
        self.boldUnder,
        // "_"
        self.italicUnder,
        // "```" block
        self.codeBlock,
        // "`"
        self.inlineCode,
        // ">" block
        self.quote,
        // "\\[" block
        self.mathBlock,
        // "\\("
        self.mathInline,
        // "~~"
        self.strikeWave,
        // "$[""
        self.fn,
        // "@"
        self.mention,
        // "#"
        self.hashtag,
        // ":"
        self.emojiCode,
        // "?[" or "["
        self.link,
        // http
        self.url,
        // block
        self.search,
        self.text,
      ])
    }

    simple = lazy {
      alt([
        self.unicodeEmoji,  // Regexp
        self.emojiCode,  // ":"
        self.plainTag,  // "<plain>" // to NOT parse emojiCode inside `<plain>`
        self.text,
      ])
    }

    inline = lazy {
      alt([
        // Regexp
        self.unicodeEmoji,
        // "<small>"
        self.smallTag,
        // "<plain>"
        self.plainTag,
        // "<b>"
        self.boldTag,
        // "<i>"
        self.italicTag,
        // "<s>"
        self.strikeTag,
        // <http
        self.urlAlt,
        // "***"
        self.big,
        // "**"
        self.boldAsta,
        // "*"
        self.italicAsta,
        // "__"
        self.boldUnder,
        // "_"
        self.italicUnder,
        // "`"
        self.inlineCode,
        // "\\("
        self.mathInline,
        // "~~"
        self.strikeWave,
        // "$[""
        self.fn,
        // "@"
        self.mention,
        // "#"
        self.hashtag,
        // ":"
        self.emojiCode,
        // "?[" or "["
        self.link,
        // http
        self.url,
        self.text,
      ])
    }

    quote = lazy {
      let lines = seq(
        str(">"),
        space.option(),
        seq(notMatch(newline), char).select(1).many(0).text()
      ).select(2).sep(newline, 1)
      let parser = seq(
        newline.option(),
        newline.option(),
        lineBegin,
        lines,
        newline.option(),
        newline.option()
      ).select(3)
      return Parser { input, index, state in
        // parse quote
        let result = parser.handler(input, index, state)
        if !result.success { return result }
        let contents = result.value as! [Any]
        let quoteIndex = result.index
        // disallow empty content if single line
        if contents.count == 1, (contents[0] as! String).isEmpty {
          return failure()
        }
        // parse inner content
        let contentParser = nest(self.fullParser).many(0)
        let joined = contents.map { $0 as! String }.joined(separator: "\n") as NSString
        let inner = contentParser.handler(joined, 0, state)
        if !inner.success { return inner }
        return success(quoteIndex, QUOTE(mergeText(inner.value as! [Any])))
      }
    }

    codeBlock = lazy {
      let mark = str("```")
      return seq(
        newline.option(),
        lineBegin,
        mark,
        seq(notMatch(newline), char).select(1).many(0),
        newline,
        seq(notMatch(seq(newline, mark, lineEnd)), char).select(1).many(1),
        newline,
        mark,
        lineEnd,
        newline.option()
      ).map { value in
        let result = value as! [Any]
        let lang = (result[3] as! [Any]).map { $0 as! String }.joined()
          .trimmingCharacters(in: .whitespacesAndNewlines)
        let code = (result[5] as! [Any]).map { $0 as! String }.joined()
        return CODE_BLOCK(code, lang.isEmpty ? nil : lang)
      }
    }

    mathBlock = lazy {
      let open = str("\\[")
      let close = str("\\]")
      return seq(
        newline.option(),
        lineBegin,
        open,
        newline.option(),
        seq(notMatch(seq(newline.option(), close)), char).select(1).many(1),
        newline.option(),
        close,
        lineEnd,
        newline.option()
      ).map { value in
        let result = value as! [Any]
        let formula = (result[4] as! [Any]).map { $0 as! String }.joined()
        return MATH_BLOCK(formula)
      }
    }

    centerTag = lazy {
      let open = str("<center>")
      let close = str("</center>")
      return seq(
        newline.option(),
        lineBegin,
        open,
        newline.option(),
        seq(notMatch(seq(newline.option(), close)), nest(self.inline)).select(1).many(1),
        newline.option(),
        close,
        lineEnd,
        newline.option()
      ).map { value in
        let result = value as! [Any]
        return CENTER(mergeText(result[4] as! [Any]))
      }
    }

    big = lazy {
      let mark = str("***")
      return seqOrText([
        mark,
        seq(notMatch(mark), nest(self.inline)).select(1).many(1),
        mark,
      ]).map { value in
        if let text = value as? String { return text }
        let result = value as! [Any]
        return FN("tada", MFMFnArgs([]), mergeText(result[1] as! [Any]))
      }
    }

    boldAsta = lazy {
      let mark = str("**")
      return seqOrText([
        mark,
        seq(notMatch(mark), nest(self.inline)).select(1).many(1),
        mark,
      ]).map { value in
        if let text = value as? String { return text }
        let result = value as! [Any]
        return BOLD(mergeText(result[1] as! [Any]))
      }
    }

    boldTag = lazy {
      let open = str("<b>")
      let close = str("</b>")
      return seqOrText([
        open,
        seq(notMatch(close), nest(self.inline)).select(1).many(1),
        close,
      ]).map { value in
        if let text = value as? String { return text }
        let result = value as! [Any]
        return BOLD(mergeText(result[1] as! [Any]))
      }
    }

    boldUnder = lazy {
      let mark = str("__")
      return seq(
        mark,
        alt([alphaAndNum, space]).many(1),
        mark
      ).map { value in
        let result = value as! [Any]
        return BOLD(mergeText(result[1] as! [Any]))
      }
    }

    smallTag = lazy {
      let open = str("<small>")
      let close = str("</small>")
      return seqOrText([
        open,
        seq(notMatch(close), nest(self.inline)).select(1).many(1),
        close,
      ]).map { value in
        if let text = value as? String { return text }
        let result = value as! [Any]
        return SMALL(mergeText(result[1] as! [Any]))
      }
    }

    italicTag = lazy {
      let open = str("<i>")
      let close = str("</i>")
      return seqOrText([
        open,
        seq(notMatch(close), nest(self.inline)).select(1).many(1),
        close,
      ]).map { value in
        if let text = value as? String { return text }
        let result = value as! [Any]
        return ITALIC(mergeText(result[1] as! [Any]))
      }
    }

    italicAsta = lazy {
      let mark = str("*")
      let parser = seq(mark, alt([alphaAndNum, space]).many(1), mark)
      return Parser { input, index, state in
        let result = parser.handler(input, index, state)
        if !result.success { return failure() }
        // check before
        if index > 0, isAsciiAlnum(input.character(at: index - 1)) { return failure() }
        let value = result.value as! [Any]
        return success(result.index, ITALIC(mergeText(value[1] as! [Any])))
      }
    }

    italicUnder = lazy {
      let mark = str("_")
      let parser = seq(mark, alt([alphaAndNum, space]).many(1), mark)
      return Parser { input, index, state in
        let result = parser.handler(input, index, state)
        if !result.success { return failure() }
        // check before
        if index > 0, isAsciiAlnum(input.character(at: index - 1)) { return failure() }
        let value = result.value as! [Any]
        return success(result.index, ITALIC(mergeText(value[1] as! [Any])))
      }
    }

    strikeTag = lazy {
      let open = str("<s>")
      let close = str("</s>")
      return seqOrText([
        open,
        seq(notMatch(close), nest(self.inline)).select(1).many(1),
        close,
      ]).map { value in
        if let text = value as? String { return text }
        let result = value as! [Any]
        return STRIKE(mergeText(result[1] as! [Any]))
      }
    }

    strikeWave = lazy {
      let mark = str("~~")
      return seqOrText([
        mark,
        seq(notMatch(alt([mark, newline])), nest(self.inline)).select(1).many(1),
        mark,
      ]).map { value in
        if let text = value as? String { return text }
        let result = value as! [Any]
        return STRIKE(mergeText(result[1] as! [Any]))
      }
    }

    unicodeEmoji = unicodeEmojiParser

    plainTag = lazy {
      let open = str("<plain>")
      let close = str("</plain>")
      return seq(
        open,
        newline.option(),
        seq(notMatch(seq(newline.option(), close)), char).select(1).many(1).text(),
        newline.option(),
        close
      ).select(2).map { value in
        PLAIN(value as! String)
      }
    }

    fn = lazy {
      let fnName = regexp("[a-z0-9_]+", .caseInsensitive)
      let arg: Parser = seq(
        regexp("[a-z0-9_]+", .caseInsensitive),
        seq(str("="), regexp("[a-z0-9_.-]+", .caseInsensitive)).select(1).option()
      ).map { value in
        let result = value as! [Any]
        let key = result[0] as! String
        let argValue: MFMFnArgs.Arg.Value = isNull(result[1]) ? .true : .string(result[1] as! String)
        return MFMFnArgs.Arg(key: key, value: argValue)
      }
      let args = seq(str("."), arg.sep(str(","), 1)).select(1).map { value -> Any in
        let parsed = value as! [Any]
        var result = MFMFnArgs([])
        for arg in parsed {
          result.set(arg as! MFMFnArgs.Arg)
        }
        return result
      }
      let fnClose = str("]")
      return seqOrText([
        str("$["),
        fnName,
        args.option(),
        str(" "),
        seq(notMatch(fnClose), nest(self.inline)).select(1).many(1),
        fnClose,
      ]).map { value in
        if let text = value as? String { return text }
        let result = value as! [Any]
        let name = result[1] as! String
        let fnArgs = isNull(result[2]) ? MFMFnArgs([]) : (result[2] as! MFMFnArgs)
        let content = result[4] as! [Any]
        return FN(name, fnArgs, mergeText(content))
      }
    }

    inlineCode = lazy {
      let mark = str("`")
      return seq(
        mark,
        seq(notMatch(alt([mark, str("\u{00B4}"), newline])), char).select(1).many(1),
        mark
      ).map { value in
        let result = value as! [Any]
        let code = (result[1] as! [Any]).map { $0 as! String }.joined()
        return INLINE_CODE(code)
      }
    }

    mathInline = lazy {
      let open = str("\\(")
      let close = str("\\)")
      return seq(
        open,
        seq(notMatch(alt([close, newline])), char).select(1).many(1),
        close
      ).map { value in
        let result = value as! [Any]
        let formula = (result[1] as! [Any]).map { $0 as! String }.joined()
        return MATH_INLINE(formula)
      }
    }

    mention = lazy {
      let parser = seq(
        notLinkLabel,
        str("@"),
        regexp("[a-z0-9_.-]+", .caseInsensitive),
        seq(str("@"), regexp("[a-z0-9_.-]+", .caseInsensitive)).select(1).option()
      )
      return Parser { input, index, state in
        let result = parser.handler(input, index, state)
        if !result.success { return failure() }
        // check before (not mention)
        if index > 0, isAsciiAlnum(input.character(at: index - 1)) { return failure() }
        var invalidMention = false
        let resultIndex = result.index
        let value = result.value as! [Any]
        let username = value[2] as! String
        let hostname: String? = isNull(value[3]) ? nil : (value[3] as! String)
        // remove [.-] of tail of hostname
        var modifiedHost = hostname
        if let hostname {
          let len = trailingDotDashLength(hostname)
          if len > 0 {
            let trimmed = String(hostname.dropLast(len))
            modifiedHost = trimmed
            if trimmed.isEmpty {
              // disallow invalid char only hostname
              invalidMention = true
              modifiedHost = nil
            }
          }
        }
        // remove [.-] of tail of username
        var modifiedName = username
        let nameLen = trailingDotDashLength(username)
        if nameLen > 0 {
          if modifiedHost == nil {
            modifiedName = String(username.dropLast(nameLen))
          } else {
            // cannnot to remove tail of username if exist hostname
            invalidMention = true
          }
        }
        // disallow [.-] of head of username
        if modifiedName.isEmpty || startsWithDotDash(modifiedName) {
          invalidMention = true
        }
        // disallow [.-] of head of hostname
        if let modifiedHost, startsWithDotDash(modifiedHost) {
          invalidMention = true
        }
        // generate a text if mention is invalid
        if invalidMention {
          return success(
            resultIndex,
            input.substring(with: NSRange(location: index, length: resultIndex - index)))
        }
        let acct =
          modifiedHost != nil ? "@\(modifiedName)@\(modifiedHost!)" : "@\(modifiedName)"
        return success(
          index + (acct as NSString).length,
          MENTION(modifiedName, modifiedHost, acct))
      }
    }

    hashtag = lazy {
      let mark = str("#")
      let hashTagChar = seq(
        notMatch(
          alt([
            regexp("[ \u{3000}\t.,!?'\"#:/\\[\\]【】()「」（）<>]"),
            space,
            newline,
          ])),
        char
      ).select(1)
      var innerItem: Parser!
      innerItem = lazy {
        alt([
          seq(str("("), nest(innerItem, hashTagChar).many(0), str(")")),
          seq(str("["), nest(innerItem, hashTagChar).many(0), str("]")),
          seq(str("「"), nest(innerItem, hashTagChar).many(0), str("」")),
          seq(str("（"), nest(innerItem, hashTagChar).many(0), str("）")),
          hashTagChar,
        ])
      }
      let parser = seq(
        notLinkLabel,
        mark,
        innerItem.many(1).text()
      ).select(2)
      return Parser { input, index, state in
        let result = parser.handler(input, index, state)
        if !result.success { return failure() }
        // check before
        if index > 0, isAsciiAlnum(input.character(at: index - 1)) { return failure() }
        let value = result.value as! String
        // disallow number only
        if isAllAsciiDigits(value) { return failure() }
        return success(result.index, HASHTAG(value))
      }
    }

    emojiCode = lazy {
      let side = notMatch(regexp("[a-z0-9]", .caseInsensitive))
      let mark = str(":")
      return seq(
        alt([lineBegin, side]),
        mark,
        regexp("[a-z0-9_+-]+", .caseInsensitive),
        mark,
        alt([lineEnd, side])
      ).select(2).map { value in
        EMOJI_CODE(value as! String)
      }
    }

    link = lazy {
      let labelInline = Parser { input, index, state in
        state.linkLabel = true
        let result = self.inline.handler(input, index, state)
        state.linkLabel = false
        return result
      }
      let closeLabel = str("]")
      let parser = seq(
        notLinkLabel,
        alt([str("?["), str("[")]),
        seq(notMatch(alt([closeLabel, newline])), nest(labelInline)).select(1).many(1),
        closeLabel,
        str("("),
        alt([self.urlAlt, self.url]),
        str(")")
      )
      return Parser { input, index, state in
        let result = parser.handler(input, index, state)
        if !result.success { return failure() }
        let value = result.value as! [Any]
        let prefix = value[1] as! String
        let label = value[2] as! [Any]
        let silent = (prefix == "?[")
        guard let urlNode = value[5] as? MFMNode, case .url(let urlString, _) = urlNode else {
          return failure()
        }
        return success(
          result.index, LINK(silent, urlString, mergeText(label)))
      }
    }

    url = lazy {
      let urlChar = regexp("[.,a-z0-9_/:%#@$&?!~=+-]", .caseInsensitive)
      var innerItem: Parser!
      innerItem = lazy {
        alt([
          seq(str("("), nest(innerItem, urlChar).many(0), str(")")),
          seq(str("["), nest(innerItem, urlChar).many(0), str("]")),
          urlChar,
        ])
      }
      let parser = seq(
        notLinkLabel,
        regexp("https?://"),
        innerItem.many(1).text()
      )
      return Parser { input, index, state in
        let result = parser.handler(input, index, state)
        if !result.success { return failure() }
        let resultIndex = result.index
        var modifiedIndex = resultIndex
        let value = result.value as! [Any]
        let schema = value[1] as! String
        var content = value[2] as! String
        // remove the ".," at the right end
        let trail = trailingDotCommaLength(content)
        if trail > 0 {
          modifiedIndex -= trail
          content = String(content.dropLast(trail))
          if content.isEmpty {
            return success(
              resultIndex,
              input.substring(with: NSRange(location: index, length: resultIndex - index)))
          }
        }
        return success(modifiedIndex, N_URL(schema + content, false))
      }
    }

    urlAlt = lazy {
      let open = str("<")
      let close = str(">")
      let parser = seq(
        notLinkLabel,
        open,
        regexp("https?://"),
        seq(notMatch(alt([close, space])), char).select(1).many(1),
        close
      ).text()
      return Parser { input, index, state in
        let result = parser.handler(input, index, state)
        if !result.success { return failure() }
        let full = result.value as! NSString
        let text = full.substring(with: NSRange(location: 1, length: full.length - 2))
        return success(result.index, N_URL(text, true))
      }
    }

    search = lazy {
      let button = alt([
        regexp("\\[(検索|search)\\]", .caseInsensitive),
        regexp("(検索|search)", .caseInsensitive),
      ])
      return seq(
        newline.option(),
        lineBegin,
        seq(
          notMatch(
            alt([
              newline,
              seq(space, button, lineEnd),
            ])),
          char
        ).select(1).many(1),
        space,
        button,
        lineEnd,
        newline.option()
      ).map { value in
        let result = value as! [Any]
        let query = (result[2] as! [Any]).map { $0 as! String }.joined()
        let spaceStr = result[3] as! String
        let buttonStr = result[4] as! String
        return SEARCH(query, "\(query)\(spaceStr)\(buttonStr)")
      }
    }

    text = char

    while let resolve = pendingParsers.popLast() {
      resolve()
    }
  }
}

let language = MFMLanguage()
