import Testing

@testable import MFMParser

@Suite("SimpleParser")
struct SimpleParserTests {
  @Suite("text")
  struct TextTests {
    @Test("basic")
    func basic() {
      #expect(MFMParser.parseSimple("abc") == [TEXT("abc")])
    }

    @Test("ignore hashtag")
    func ignoreHashtag() {
      #expect(MFMParser.parseSimple("abc#abc") == [TEXT("abc#abc")])
    }

    @Test("keycap number sign")
    func keycapNumberSign() {
      #expect(MFMParser.parseSimple("abc#️⃣abc") == [TEXT("abc"), UNI_EMOJI("#️⃣"), TEXT("abc")])
    }
  }

  @Suite("emoji")
  struct EmojiTests {
    @Test("basic")
    func basic() {
      #expect(MFMParser.parseSimple(":foo:") == [EMOJI_CODE("foo")])
    }

    @Test("between texts")
    func betweenTexts() {
      #expect(MFMParser.parseSimple("foo:bar:baz") == [TEXT("foo:bar:baz")])
    }

    @Test("between texts 2")
    func betweenTexts2() {
      #expect(MFMParser.parseSimple("12:34:56") == [TEXT("12:34:56")])
    }

    @Test("between texts 3")
    func betweenTexts3() {
      #expect(MFMParser.parseSimple("あ:bar:い") == [TEXT("あ"), EMOJI_CODE("bar"), TEXT("い")])
    }

    @Test("Ignore Variation Selector preceded by Unicode Emoji")
    func ignoreVariationSelector() {
      #expect(MFMParser.parseSimple("\u{FE0F}") == [TEXT("\u{FE0F}")])
    }
  }

  @Test("disallow other syntaxes")
  func disallowOtherSyntaxes() {
    #expect(MFMParser.parseSimple("foo **bar** baz") == [TEXT("foo **bar** baz")])
  }
}

@Suite("FullParser - text")
struct FullParserTextTests {
  @Test("普通のテキストを入力すると1つのテキストノードが返される")
  func basic() {
    #expect(MFMParser.parse("abc") == [TEXT("abc")])
  }
}

@Suite("FullParser - quote")
struct QuoteTests {
  @Test("1行の引用ブロックを使用できる")
  func singleLine() {
    #expect(MFMParser.parse("> abc") == [QUOTE([TEXT("abc")])])
  }

  @Test("複数行の引用ブロックを使用できる")
  func multipleLines() {
    #expect(MFMParser.parse("\n> abc\n> 123\n") == [QUOTE([TEXT("abc\n123")])])
  }

  @Test("引用ブロックはブロックをネストできる")
  func nestBlock() {
    #expect(MFMParser.parse("\n> <center>\n> a\n> </center>\n") == [QUOTE([CENTER([TEXT("a")])])])
  }

  @Test("引用ブロックはインライン構文を含んだブロックをネストできる")
  func nestBlockWithInline() {
    let output: [MFMNode] = [
      QUOTE([
        CENTER([
          TEXT("I'm "),
          MENTION("ai", nil, "@ai"),
          TEXT(", An bot of misskey!"),
        ])
      ])
    ]
    #expect(MFMParser.parse("\n> <center>\n> I'm @ai, An bot of misskey!\n> </center>\n") == output)
  }

  @Test("複数行の引用ブロックでは空行を含めることができる")
  func emptyLineInside() {
    #expect(MFMParser.parse("\n> abc\n>\n> 123\n") == [QUOTE([TEXT("abc\n\n123")])])
  }

  @Test("1行の引用ブロックを空行にはできない")
  func cannotBeEmpty() {
    #expect(MFMParser.parse("> ") == [TEXT("> ")])
  }

  @Test("引用ブロックの後ろの空行は無視される")
  func trailingEmptyLineIgnored() {
    #expect(
      MFMParser.parse("\n> foo\n> bar\n\nhoge") == [QUOTE([TEXT("foo\nbar")]), TEXT("hoge")])
  }

  @Test("2つの引用行の間に空行がある場合は2つの引用ブロックが生成される")
  func twoQuotesSeparatedByEmptyLine() {
    let output: [MFMNode] = [QUOTE([TEXT("foo")]), QUOTE([TEXT("bar")]), TEXT("hoge")]
    #expect(MFMParser.parse("\n> foo\n\n> bar\n\nhoge") == output)
  }
}

@Suite("FullParser - search")
struct SearchTests {
  @Test("Search")
  func search() {
    let input = "MFM 書き方 123 Search"
    #expect(MFMParser.parse(input) == [SEARCH("MFM 書き方 123", input)])
  }

  @Test("[Search]")
  func bracketSearch() {
    let input = "MFM 書き方 123 [Search]"
    #expect(MFMParser.parse(input) == [SEARCH("MFM 書き方 123", input)])
  }

  @Test("search")
  func lowerSearch() {
    let input = "MFM 書き方 123 search"
    #expect(MFMParser.parse(input) == [SEARCH("MFM 書き方 123", input)])
  }

  @Test("[search]")
  func bracketLowerSearch() {
    let input = "MFM 書き方 123 [search]"
    #expect(MFMParser.parse(input) == [SEARCH("MFM 書き方 123", input)])
  }

  @Test("検索")
  func kensaku() {
    let input = "MFM 書き方 123 検索"
    #expect(MFMParser.parse(input) == [SEARCH("MFM 書き方 123", input)])
  }

  @Test("[検索]")
  func bracketKensaku() {
    let input = "MFM 書き方 123 [検索]"
    #expect(MFMParser.parse(input) == [SEARCH("MFM 書き方 123", input)])
  }

  @Test("ブロックの前後にあるテキストが正しく解釈される")
  func surroundingText() {
    let output: [MFMNode] = [
      TEXT("abc"),
      SEARCH("hoge piyo bebeyo", "hoge piyo bebeyo 検索"),
      TEXT("123"),
    ]
    #expect(MFMParser.parse("abc\nhoge piyo bebeyo 検索\n123") == output)
  }
}

@Suite("FullParser - code block")
struct CodeBlockTests {
  @Test("コードブロックを使用できる")
  func basic() {
    #expect(MFMParser.parse("```\nabc\n```") == [CODE_BLOCK("abc", nil)])
  }

  @Test("コードブロックには複数行のコードを入力できる")
  func multiline() {
    #expect(MFMParser.parse("```\na\nb\nc\n```") == [CODE_BLOCK("a\nb\nc", nil)])
  }

  @Test("コードブロックは言語を指定できる")
  func withLang() {
    #expect(MFMParser.parse("```js\nconst a = 1;\n```") == [CODE_BLOCK("const a = 1;", "js")])
  }

  @Test("ブロックの前後にあるテキストが正しく解釈される")
  func surroundingText() {
    let output: [MFMNode] = [TEXT("abc"), CODE_BLOCK("const abc = 1;", nil), TEXT("123")]
    #expect(MFMParser.parse("abc\n```\nconst abc = 1;\n```\n123") == output)
  }

  @Test("ignore internal marker")
  func ignoreInternalMarker() {
    #expect(MFMParser.parse("```\naaa```bbb\n```") == [CODE_BLOCK("aaa```bbb", nil)])
  }

  @Test("trim after line break")
  func trimAfterLineBreak() {
    #expect(MFMParser.parse("```\nfoo\n```\nbar") == [CODE_BLOCK("foo", nil), TEXT("bar")])
  }
}

@Suite("FullParser - mathBlock")
struct MathBlockTests {
  @Test("1行の数式ブロックを使用できる")
  func basic() {
    #expect(MFMParser.parse("\\[math1\\]") == [MATH_BLOCK("math1")])
  }

  @Test("ブロックの前後にあるテキストが正しく解釈される")
  func surroundingText() {
    #expect(MFMParser.parse("abc\n\\[math1\\]\n123") == [TEXT("abc"), MATH_BLOCK("math1"), TEXT("123")])
  }

  @Test("行末以外に閉じタグがある場合はマッチしない")
  func closeNotAtLineEnd() {
    #expect(MFMParser.parse("\\[aaa\\]after") == [TEXT("\\[aaa\\]after")])
  }

  @Test("行頭以外に開始タグがある場合はマッチしない")
  func openNotAtLineBegin() {
    #expect(MFMParser.parse("before\\[aaa\\]") == [TEXT("before\\[aaa\\]")])
  }
}

@Suite("FullParser - center")
struct CenterTests {
  @Test("single text")
  func singleText() {
    #expect(MFMParser.parse("<center>abc</center>") == [CENTER([TEXT("abc")])])
  }

  @Test("multiple text")
  func multipleText() {
    let output: [MFMNode] = [
      TEXT("before"),
      CENTER([TEXT("abc\n123\n\npiyo")]),
      TEXT("after"),
    ]
    #expect(MFMParser.parse("before\n<center>\nabc\n123\n\npiyo\n</center>\nafter") == output)
  }
}

@Suite("FullParser - emoji code")
struct EmojiCodeTests {
  @Test("basic")
  func basic() {
    #expect(MFMParser.parse(":abc:") == [EMOJI_CODE("abc")])
  }
}

@Suite("FullParser - unicode emoji")
struct UnicodeEmojiTests {
  @Test("basic")
  func basic() {
    #expect(MFMParser.parse("今起きた😇") == [TEXT("今起きた"), UNI_EMOJI("😇")])
  }

  @Test("keycap number sign")
  func keycapNumberSign() {
    #expect(MFMParser.parse("abc#️⃣123") == [TEXT("abc"), UNI_EMOJI("#️⃣"), TEXT("123")])
  }
}

@Suite("FullParser - big")
struct BigTests {
  @Test("basic")
  func basic() {
    #expect(MFMParser.parse("***abc***") == [FN("tada", MFMFnArgs([]), [TEXT("abc")])])
  }

  @Test("内容にはインライン構文を利用できる")
  func inlineInside() {
    let output: [MFMNode] = [
      FN("tada", MFMFnArgs([]), [TEXT("123"), BOLD([TEXT("abc")]), TEXT("123")])
    ]
    #expect(MFMParser.parse("***123**abc**123***") == output)
  }

  @Test("内容は改行できる")
  func lineBreaks() {
    let output: [MFMNode] = [
      FN("tada", MFMFnArgs([]), [TEXT("123\n"), BOLD([TEXT("abc")]), TEXT("\n123")])
    ]
    #expect(MFMParser.parse("***123\n**abc**\n123***") == output)
  }
}

@Suite("FullParser - bold tag")
struct BoldTagTests {
  @Test("basic")
  func basic() {
    #expect(MFMParser.parse("<b>abc</b>") == [BOLD([TEXT("abc")])])
  }

  @Test("inline syntax allowed inside")
  func inlineInside() {
    let output: [MFMNode] = [BOLD([TEXT("123"), STRIKE([TEXT("abc")]), TEXT("123")])]
    #expect(MFMParser.parse("<b>123~~abc~~123</b>") == output)
  }

  @Test("line breaks")
  func lineBreaks() {
    let output: [MFMNode] = [BOLD([TEXT("123\n"), STRIKE([TEXT("abc")]), TEXT("\n123")])]
    #expect(MFMParser.parse("<b>123\n~~abc~~\n123</b>") == output)
  }
}

@Suite("FullParser - bold")
struct BoldTests {
  @Test("basic")
  func basic() {
    #expect(MFMParser.parse("**abc**") == [BOLD([TEXT("abc")])])
  }

  @Test("内容にはインライン構文を利用できる")
  func inlineInside() {
    let output: [MFMNode] = [BOLD([TEXT("123"), STRIKE([TEXT("abc")]), TEXT("123")])]
    #expect(MFMParser.parse("**123~~abc~~123**") == output)
  }

  @Test("内容は改行できる")
  func lineBreaks() {
    let output: [MFMNode] = [BOLD([TEXT("123\n"), STRIKE([TEXT("abc")]), TEXT("\n123")])]
    #expect(MFMParser.parse("**123\n~~abc~~\n123**") == output)
  }
}

@Suite("FullParser - small")
struct SmallTests {
  @Test("basic")
  func basic() {
    #expect(MFMParser.parse("<small>abc</small>") == [SMALL([TEXT("abc")])])
  }

  @Test("内容にはインライン構文を利用できる")
  func inlineInside() {
    let output: [MFMNode] = [SMALL([TEXT("abc"), BOLD([TEXT("123")]), TEXT("abc")])]
    #expect(MFMParser.parse("<small>abc**123**abc</small>") == output)
  }

  @Test("内容は改行できる")
  func lineBreaks() {
    let output: [MFMNode] = [SMALL([TEXT("abc\n"), BOLD([TEXT("123")]), TEXT("\nabc")])]
    #expect(MFMParser.parse("<small>abc\n**123**\nabc</small>") == output)
  }
}

@Suite("FullParser - italic tag")
struct ItalicTagTests {
  @Test("basic")
  func basic() {
    #expect(MFMParser.parse("<i>abc</i>") == [ITALIC([TEXT("abc")])])
  }

  @Test("内容にはインライン構文を利用できる")
  func inlineInside() {
    let output: [MFMNode] = [ITALIC([TEXT("abc"), BOLD([TEXT("123")]), TEXT("abc")])]
    #expect(MFMParser.parse("<i>abc**123**abc</i>") == output)
  }

  @Test("内容は改行できる")
  func lineBreaks() {
    let output: [MFMNode] = [ITALIC([TEXT("abc\n"), BOLD([TEXT("123")]), TEXT("\nabc")])]
    #expect(MFMParser.parse("<i>abc\n**123**\nabc</i>") == output)
  }
}

@Suite("FullParser - italic alt 1")
struct ItalicAlt1Tests {
  @Test("basic")
  func basic() {
    #expect(MFMParser.parse("*abc*") == [ITALIC([TEXT("abc")])])
  }

  @Test("basic 2")
  func basic2() {
    let output: [MFMNode] = [TEXT("before "), ITALIC([TEXT("abc")]), TEXT(" after")]
    #expect(MFMParser.parse("before *abc* after") == output)
  }

  @Test("ignore a italic syntax if the before char is neither a space nor an LF nor [^a-z0-9]i")
  func ignoreWithBadBefore() {
    #expect(MFMParser.parse("before*abc*after") == [TEXT("before*abc*after")])
    let output: [MFMNode] = [TEXT("あいう"), ITALIC([TEXT("abc")]), TEXT("えお")]
    #expect(MFMParser.parse("あいう*abc*えお") == output)
  }
}

@Suite("FullParser - italic alt 2")
struct ItalicAlt2Tests {
  @Test("basic")
  func basic() {
    #expect(MFMParser.parse("_abc_") == [ITALIC([TEXT("abc")])])
  }

  @Test("basic 2")
  func basic2() {
    let output: [MFMNode] = [TEXT("before "), ITALIC([TEXT("abc")]), TEXT(" after")]
    #expect(MFMParser.parse("before _abc_ after") == output)
  }

  @Test("ignore a italic syntax if the before char is neither a space nor an LF nor [^a-z0-9]i")
  func ignoreWithBadBefore() {
    #expect(MFMParser.parse("before_abc_after") == [TEXT("before_abc_after")])
    let output: [MFMNode] = [TEXT("あいう"), ITALIC([TEXT("abc")]), TEXT("えお")]
    #expect(MFMParser.parse("あいう_abc_えお") == output)
  }
}

@Suite("FullParser - strike")
struct StrikeTests {
  @Test("strike tag basic")
  func tagBasic() {
    #expect(MFMParser.parse("<s>foo</s>") == [STRIKE([TEXT("foo")])])
  }

  @Test("strike basic")
  func basic() {
    #expect(MFMParser.parse("~~foo~~") == [STRIKE([TEXT("foo")])])
  }
}

@Suite("FullParser - inlineCode")
struct InlineCodeTests {
  @Test("basic")
  func basic() {
    #expect(MFMParser.parse("`var x = \"Strawberry Pasta\";`") == [INLINE_CODE("var x = \"Strawberry Pasta\";")])
  }

  @Test("disallow line break")
  func disallowLineBreak() {
    #expect(MFMParser.parse("`foo\nbar`") == [TEXT("`foo\nbar`")])
  }

  @Test("disallow ´")
  func disallowAcute() {
    #expect(MFMParser.parse("`foo´bar`") == [TEXT("`foo´bar`")])
  }
}

@Suite("FullParser - mathInline")
struct MathInlineTests {
  @Test("basic")
  func basic() {
    let input = "\\(x = {-b \\pm \\sqrt{b^2-4ac} \\over 2a}\\)"
    #expect(MFMParser.parse(input) == [MATH_INLINE("x = {-b \\pm \\sqrt{b^2-4ac} \\over 2a}")])
  }
}

@Suite("FullParser - mention")
struct MentionTests {
  @Test("basic")
  func basic() {
    #expect(MFMParser.parse("@abc") == [MENTION("abc", nil, "@abc")])
  }

  @Test("basic 2")
  func basic2() {
    #expect(MFMParser.parse("before @abc after") == [TEXT("before "), MENTION("abc", nil, "@abc"), TEXT(" after")])
  }

  @Test("basic remote")
  func basicRemote() {
    #expect(MFMParser.parse("@abc@misskey.io") == [MENTION("abc", "misskey.io", "@abc@misskey.io")])
  }

  @Test("basic remote 2")
  func basicRemote2() {
    let output: [MFMNode] = [
      TEXT("before "), MENTION("abc", "misskey.io", "@abc@misskey.io"), TEXT(" after"),
    ]
    #expect(MFMParser.parse("before @abc@misskey.io after") == output)
  }

  @Test("basic remote 3")
  func basicRemote3() {
    let output: [MFMNode] = [
      TEXT("before\n"), MENTION("abc", "misskey.io", "@abc@misskey.io"), TEXT("\nafter"),
    ]
    #expect(MFMParser.parse("before\n@abc@misskey.io\nafter") == output)
  }

  @Test("ignore format of mail address")
  func ignoreMailAddress() {
    #expect(MFMParser.parse("abc@example.com") == [TEXT("abc@example.com")])
  }

  @Test("detect as a mention if the before char is [^a-z0-9]i")
  func detectWithNonAlnumBefore() {
    #expect(MFMParser.parse("あいう@abc") == [TEXT("あいう"), MENTION("abc", nil, "@abc")])
  }

  @Test("invalid char only username")
  func invalidCharOnlyUsername() {
    #expect(MFMParser.parse("@-") == [TEXT("@-")])
  }

  @Test("invalid char only hostname")
  func invalidCharOnlyHostname() {
    #expect(MFMParser.parse("@abc@.") == [TEXT("@abc@.")])
  }

  @Test("allow \"-\" in username")
  func allowDashInUsername() {
    #expect(MFMParser.parse("@abc-d") == [MENTION("abc-d", nil, "@abc-d")])
  }

  @Test("allow \".\" in username")
  func allowDotInUsername() {
    #expect(
      MFMParser.parse("@bsky.brid.gy@bsky.brid.gy")
        == [MENTION("bsky.brid.gy", "bsky.brid.gy", "@bsky.brid.gy@bsky.brid.gy")])
  }

  @Test("disallow \"-\" in head of username")
  func disallowDashHeadUsername() {
    #expect(MFMParser.parse("@-abc") == [TEXT("@-abc")])
  }

  @Test("disallow \"-\" in tail of username")
  func disallowDashTailUsername() {
    #expect(MFMParser.parse("@abc-") == [MENTION("abc", nil, "@abc"), TEXT("-")])
  }

  @Test("disallow \".\" in head of username")
  func disallowDotHeadUsername() {
    #expect(MFMParser.parse("@.abc") == [TEXT("@.abc")])
  }

  @Test("disallow \".\" in tail of username")
  func disallowDotTailUsername() {
    #expect(MFMParser.parse("@abc.") == [MENTION("abc", nil, "@abc"), TEXT(".")])
  }

  @Test("disallow \".\" in head of hostname")
  func disallowDotHeadHostname() {
    #expect(MFMParser.parse("@abc@.aaa") == [TEXT("@abc@.aaa")])
  }

  @Test("disallow \".\" in tail of hostname")
  func disallowDotTailHostname() {
    #expect(MFMParser.parse("@abc@aaa.") == [MENTION("abc", "aaa", "@abc@aaa"), TEXT(".")])
  }

  @Test("disallow \"-\" in head of hostname")
  func disallowDashHeadHostname() {
    #expect(MFMParser.parse("@abc@-aaa") == [TEXT("@abc@-aaa")])
  }

  @Test("disallow \"-\" in tail of hostname")
  func disallowDashTailHostname() {
    #expect(MFMParser.parse("@abc@aaa-") == [MENTION("abc", "aaa", "@abc@aaa"), TEXT("-")])
  }
}

@Suite("FullParser - hashtag")
struct HashtagTests {
  @Test("basic")
  func basic() {
    #expect(MFMParser.parse("#abc") == [HASHTAG("abc")])
  }

  @Test("basic 2")
  func basic2() {
    #expect(MFMParser.parse("before #abc after") == [TEXT("before "), HASHTAG("abc"), TEXT(" after")])
  }

  @Test("with keycap number sign")
  func withKeycapNumberSign() {
    #expect(MFMParser.parse("#️⃣abc123 #abc") == [UNI_EMOJI("#️⃣"), TEXT("abc123 "), HASHTAG("abc")])
  }

  @Test("with keycap number sign 2")
  func withKeycapNumberSign2() {
    #expect(MFMParser.parse("abc\n#️⃣abc") == [TEXT("abc\n"), UNI_EMOJI("#️⃣"), TEXT("abc")])
  }

  @Test("ignore a hashtag if the before char is neither a space nor an LF nor [^a-z0-9]i")
  func ignoreWithBadBefore() {
    #expect(MFMParser.parse("abc#abc") == [TEXT("abc#abc")])
    #expect(MFMParser.parse("あいう#abc") == [TEXT("あいう"), HASHTAG("abc")])
  }

  @Test("ignore comma and period")
  func ignoreCommaPeriod() {
    let output: [MFMNode] = [
      TEXT("Foo "), HASHTAG("bar"), TEXT(", baz "), HASHTAG("piyo"), TEXT("."),
    ]
    #expect(MFMParser.parse("Foo #bar, baz #piyo.") == output)
  }

  @Test("ignore exclamation mark")
  func ignoreExclamation() {
    #expect(MFMParser.parse("#Foo!") == [HASHTAG("Foo"), TEXT("!")])
  }

  @Test("ignore colon")
  func ignoreColon() {
    #expect(MFMParser.parse("#Foo:") == [HASHTAG("Foo"), TEXT(":")])
  }

  @Test("ignore single quote")
  func ignoreSingleQuote() {
    #expect(MFMParser.parse("#Foo'") == [HASHTAG("Foo"), TEXT("'")])
  }

  @Test("ignore double quote")
  func ignoreDoubleQuote() {
    #expect(MFMParser.parse("#Foo\"") == [HASHTAG("Foo"), TEXT("\"")])
  }

  @Test("ignore square bracket")
  func ignoreSquareBracket() {
    #expect(MFMParser.parse("#Foo]") == [HASHTAG("Foo"), TEXT("]")])
  }

  @Test("ignore slash")
  func ignoreSlash() {
    #expect(MFMParser.parse("#foo/bar") == [HASHTAG("foo"), TEXT("/bar")])
  }

  @Test("ignore angle bracket")
  func ignoreAngleBracket() {
    #expect(MFMParser.parse("#foo<bar>") == [HASHTAG("foo"), TEXT("<bar>")])
  }

  @Test("allow including number")
  func allowNumber() {
    #expect(MFMParser.parse("#foo123") == [HASHTAG("foo123")])
  }

  @Test("with brackets ()")
  func withParens() {
    #expect(MFMParser.parse("(#foo)") == [TEXT("("), HASHTAG("foo"), TEXT(")")])
  }

  @Test("with brackets 「」")
  func withCornerBrackets() {
    #expect(MFMParser.parse("「#foo」") == [TEXT("「"), HASHTAG("foo"), TEXT("」")])
  }

  @Test("with mixed brackets")
  func withMixedBrackets() {
    #expect(MFMParser.parse("「#foo(bar)」") == [TEXT("「"), HASHTAG("foo(bar)"), TEXT("」")])
  }

  @Test("with brackets () (space before)")
  func withParensSpaceBefore() {
    #expect(MFMParser.parse("(bar #foo)") == [TEXT("(bar "), HASHTAG("foo"), TEXT(")")])
  }

  @Test("with brackets 「」 (space before)")
  func withCornerBracketsSpaceBefore() {
    #expect(MFMParser.parse("「bar #foo」") == [TEXT("「bar "), HASHTAG("foo"), TEXT("」")])
  }

  @Test("disallow number only")
  func disallowNumberOnly() {
    #expect(MFMParser.parse("#123") == [TEXT("#123")])
  }

  @Test("disallow number only (with brackets)")
  func disallowNumberOnlyWithBrackets() {
    #expect(MFMParser.parse("(#123)") == [TEXT("(#123)")])
  }
}

@Suite("FullParser - url")
struct UrlTests {
  @Test("basic")
  func basic() {
    #expect(MFMParser.parse("https://misskey.io/@ai") == [N_URL("https://misskey.io/@ai")])
  }

  @Test("with other texts")
  func withOtherTexts() {
    let output: [MFMNode] = [
      TEXT("official instance: "), N_URL("https://misskey.io/@ai"), TEXT("."),
    ]
    #expect(MFMParser.parse("official instance: https://misskey.io/@ai.") == output)
  }

  @Test("ignore trailing period")
  func ignoreTrailingPeriod() {
    #expect(MFMParser.parse("https://misskey.io/@ai.") == [N_URL("https://misskey.io/@ai"), TEXT(".")])
  }

  @Test("disallow period only")
  func disallowPeriodOnly() {
    #expect(MFMParser.parse("https://.") == [TEXT("https://.")])
  }

  @Test("ignore trailing periods")
  func ignoreTrailingPeriods() {
    #expect(MFMParser.parse("https://misskey.io/@ai...") == [N_URL("https://misskey.io/@ai"), TEXT("...")])
  }

  @Test("with comma")
  func withComma() {
    #expect(
      MFMParser.parse("https://example.com/foo?bar=a,b") == [N_URL("https://example.com/foo?bar=a,b")])
  }

  @Test("ignore trailing comma")
  func ignoreTrailingComma() {
    #expect(
      MFMParser.parse("https://example.com/foo, bar") == [N_URL("https://example.com/foo"), TEXT(", bar")])
  }

  @Test("with brackets")
  func withBrackets() {
    #expect(
      MFMParser.parse("https://example.com/foo(bar)") == [N_URL("https://example.com/foo(bar)")])
  }

  @Test("ignore parent brackets")
  func ignoreParentBrackets() {
    let output: [MFMNode] = [TEXT("("), N_URL("https://example.com/foo"), TEXT(")")]
    #expect(MFMParser.parse("(https://example.com/foo)") == output)
  }

  @Test("ignore parent brackets (2)")
  func ignoreParentBrackets2() {
    let output: [MFMNode] = [TEXT("(foo "), N_URL("https://example.com/foo"), TEXT(")")]
    #expect(MFMParser.parse("(foo https://example.com/foo)") == output)
  }

  @Test("ignore parent brackets with internal brackets")
  func ignoreParentBracketsWithInternal() {
    let output: [MFMNode] = [TEXT("("), N_URL("https://example.com/foo(bar)"), TEXT(")")]
    #expect(MFMParser.parse("(https://example.com/foo(bar))") == output)
  }

  @Test("ignore parent []")
  func ignoreParentSquareBrackets() {
    let output: [MFMNode] = [TEXT("foo ["), N_URL("https://example.com/foo"), TEXT("] bar")]
    #expect(MFMParser.parse("foo [https://example.com/foo] bar") == output)
  }

  @Test("ignore non-ascii characters contained url without angle brackets")
  func ignoreNonAsciiWithoutAngle() {
    #expect(MFMParser.parse("https://大石泉すき.example.com") == [TEXT("https://大石泉すき.example.com")])
  }

  @Test("match non-ascii characters contained url with angle brackets")
  func matchNonAsciiWithAngle() {
    #expect(
      MFMParser.parse("<https://大石泉すき.example.com>") == [N_URL("https://大石泉すき.example.com", true)])
  }

  @Test("prevent xss")
  func preventXss() {
    #expect(MFMParser.parse("javascript:foo") == [TEXT("javascript:foo")])
  }
}

@Suite("FullParser - link")
struct LinkTests {
  @Test("basic")
  func basic() {
    let output: [MFMNode] = [
      LINK(false, "https://misskey.io/@ai", [TEXT("official instance")]), TEXT("."),
    ]
    #expect(MFMParser.parse("[official instance](https://misskey.io/@ai).") == output)
  }

  @Test("silent flag")
  func silentFlag() {
    let output: [MFMNode] = [
      LINK(true, "https://misskey.io/@ai", [TEXT("official instance")]), TEXT("."),
    ]
    #expect(MFMParser.parse("?[official instance](https://misskey.io/@ai).") == output)
  }

  @Test("with angle brackets url")
  func withAngleBracketsUrl() {
    let output: [MFMNode] = [
      LINK(false, "https://misskey.io/@ai", [TEXT("official instance")]), TEXT("."),
    ]
    #expect(MFMParser.parse("[official instance](<https://misskey.io/@ai>).") == output)
  }

  @Test("prevent xss")
  func preventXss() {
    #expect(MFMParser.parse("[click here](javascript:foo)") == [TEXT("[click here](javascript:foo)")])
  }

  @Test("cannot nest a url in a link label - basic")
  func cannotNestUrlBasic() {
    let output: [MFMNode] = [
      TEXT("official instance: "),
      LINK(false, "https://misskey.io/@ai", [TEXT("https://misskey.io/@ai")]),
      TEXT("."),
    ]
    #expect(MFMParser.parse("official instance: [https://misskey.io/@ai](https://misskey.io/@ai).") == output)
  }

  @Test("cannot nest a url in a link label - nested")
  func cannotNestUrlNested() {
    let output: [MFMNode] = [
      TEXT("official instance: "),
      LINK(false, "https://misskey.io/@ai", [
        TEXT("https://misskey.io/@ai"),
        BOLD([TEXT("https://misskey.io/@ai")]),
      ]),
      TEXT("."),
    ]
    #expect(
      MFMParser.parse("official instance: [https://misskey.io/@ai**https://misskey.io/@ai**](https://misskey.io/@ai).")
        == output)
  }

  @Test("cannot nest a link in a link label - basic")
  func cannotNestLinkBasic() {
    let output: [MFMNode] = [
      TEXT("official instance: "),
      LINK(false, "https://misskey.io/@ai", [TEXT("[https://misskey.io/@ai")]),
      TEXT("]("),
      N_URL("https://misskey.io/@ai"),
      TEXT(")."),
    ]
    #expect(
      MFMParser.parse("official instance: [[https://misskey.io/@ai](https://misskey.io/@ai)](https://misskey.io/@ai).")
        == output)
  }

  @Test("cannot nest a link in a link label - nested")
  func cannotNestLinkNested() {
    let output: [MFMNode] = [
      TEXT("official instance: "),
      LINK(false, "https://misskey.io/@ai", [
        BOLD([TEXT("[https://misskey.io/@ai](https://misskey.io/@ai)")])
      ]),
      TEXT("."),
    ]
    #expect(
      MFMParser.parse(
        "official instance: [**[https://misskey.io/@ai](https://misskey.io/@ai)**](https://misskey.io/@ai).")
        == output)
  }

  @Test("cannot nest a mention in a link label - basic")
  func cannotNestMentionBasic() {
    let output: [MFMNode] = [LINK(false, "https://example.com", [TEXT("@example")])]
    #expect(MFMParser.parse("[@example](https://example.com)") == output)
  }

  @Test("cannot nest a mention in a link label - nested")
  func cannotNestMentionNested() {
    let output: [MFMNode] = [
      LINK(false, "https://example.com", [TEXT("@example"), BOLD([TEXT("@example")])])
    ]
    #expect(MFMParser.parse("[@example**@example**](https://example.com)") == output)
  }

  @Test("with brackets")
  func withBrackets() {
    let output: [MFMNode] = [LINK(false, "https://example.com/foo(bar)", [TEXT("foo")])]
    #expect(MFMParser.parse("[foo](https://example.com/foo(bar))") == output)
  }

  @Test("with parent brackets")
  func withParentBrackets() {
    let output: [MFMNode] = [
      TEXT("("), LINK(false, "https://example.com/foo(bar)", [TEXT("foo")]), TEXT(")"),
    ]
    #expect(MFMParser.parse("([foo](https://example.com/foo(bar)))") == output)
  }

  @Test("with brackets before")
  func withBracketsBefore() {
    let output: [MFMNode] = [
      TEXT("[test] foo "), LINK(false, "https://example.com", [TEXT("bar")]),
    ]
    #expect(MFMParser.parse("[test] foo [bar](https://example.com)") == output)
  }

  @Test("bad url in url part")
  func badUrlInUrlPart() {
    #expect(MFMParser.parse("[test](http://..)") == [TEXT("[test](http://..)")])
  }
}

@Suite("FullParser - fn")
struct FnTests {
  @Test("basic")
  func basic() {
    #expect(MFMParser.parse("$[tada abc]") == [FN("tada", MFMFnArgs([]), [TEXT("abc")])])
  }

  @Test("with a string argument")
  func withStringArg() {
    #expect(MFMParser.parse("$[spin.speed=1.1s a]") == [FN("spin", MFMFnArgs([MFMFnArgs.Arg(key: "speed", value: .string("1.1s"))]), [TEXT("a")])])
  }

  @Test("with a string argument 2")
  func withStringArg2() {
    #expect(MFMParser.parse("$[position.x=-3 a]") == [FN("position", MFMFnArgs([MFMFnArgs.Arg(key: "x", value: .string("-3"))]), [TEXT("a")])])
  }

  @Test("invalid fn name")
  func invalidFnName() {
    #expect(MFMParser.parse("$[関数 text]") == [TEXT("$[関数 text]")])
  }

  @Test("nest")
  func nest() {
    let output: [MFMNode] = [
      FN("spin", MFMFnArgs([MFMFnArgs.Arg(key: "speed", value: .string("1.1s"))]), [FN("shake", MFMFnArgs([]), [TEXT("a")])])
    ]
    #expect(MFMParser.parse("$[spin.speed=1.1s $[shake a]]") == output)
  }
}

@Suite("FullParser - plain")
struct PlainTests {
  @Test("multiple line")
  func multipleLine() {
    let output: [MFMNode] = [TEXT("a\n"), PLAIN("**Hello**\nworld"), TEXT("\nb")]
    #expect(MFMParser.parse("a\n<plain>\n**Hello**\nworld\n</plain>\nb") == output)
  }

  @Test("single line")
  func singleLine() {
    let output: [MFMNode] = [TEXT("a\n"), PLAIN("**Hello** world"), TEXT("\nb")]
    #expect(MFMParser.parse("a\n<plain>**Hello** world</plain>\nb") == output)
  }
}

@Suite("FullParser - nesting limit")
struct NestingLimitTests {
  @Test("quote - basic")
  func quoteBasic() {
    let output: [MFMNode] = [QUOTE([QUOTE([TEXT("> abc")])])]
    #expect(MFMParser.parse(">>> abc", nestLimit: 2) == output)
  }

  @Test("quote - basic 2")
  func quoteBasic2() {
    let output: [MFMNode] = [QUOTE([QUOTE([TEXT("**abc**")])])]
    #expect(MFMParser.parse(">> **abc**", nestLimit: 2) == output)
  }

  @Test("big")
  func big() {
    let output: [MFMNode] = [BOLD([BOLD([TEXT("***abc***")])])]
    #expect(MFMParser.parse("<b><b>***abc***</b></b>", nestLimit: 2) == output)
  }

  @Test("bold - basic")
  func boldBasic() {
    let output: [MFMNode] = [ITALIC([ITALIC([TEXT("**abc**")])])]
    #expect(MFMParser.parse("<i><i>**abc**</i></i>", nestLimit: 2) == output)
  }

  @Test("bold - tag")
  func boldTag() {
    let output: [MFMNode] = [ITALIC([ITALIC([TEXT("<b>abc</b>")])])]
    #expect(MFMParser.parse("<i><i><b>abc</b></i></i>", nestLimit: 2) == output)
  }

  @Test("small")
  func small() {
    let output: [MFMNode] = [ITALIC([ITALIC([TEXT("<small>abc</small>")])])]
    #expect(MFMParser.parse("<i><i><small>abc</small></i></i>", nestLimit: 2) == output)
  }

  @Test("italic")
  func italic() {
    let output: [MFMNode] = [BOLD([BOLD([TEXT("<i>abc</i>")])])]
    #expect(MFMParser.parse("<b><b><i>abc</i></b></b>", nestLimit: 2) == output)
  }

  @Test("strike - basic")
  func strikeBasic() {
    let output: [MFMNode] = [BOLD([BOLD([TEXT("~~abc~~")])])]
    #expect(MFMParser.parse("<b><b>~~abc~~</b></b>", nestLimit: 2) == output)
  }

  @Test("strike - tag")
  func strikeTag() {
    let output: [MFMNode] = [BOLD([BOLD([TEXT("<s>abc</s>")])])]
    #expect(MFMParser.parse("<b><b><s>abc</s></b></b>", nestLimit: 2) == output)
  }

  @Test("hashtag - basic")
  func hashtagBasic() {
    #expect(MFMParser.parse("<b>#abc(xyz)</b>", nestLimit: 2) == [BOLD([HASHTAG("abc(xyz)")])])
    let output: [MFMNode] = [BOLD([HASHTAG("abc"), TEXT("(x(y)z)")])]
    #expect(MFMParser.parse("<b>#abc(x(y)z)</b>", nestLimit: 2) == output)
  }

  @Test("hashtag - outside ()")
  func hashtagOutsideParens() {
    #expect(MFMParser.parse("(#abc)") == [TEXT("("), HASHTAG("abc"), TEXT(")")])
  }

  @Test("hashtag - outside []")
  func hashtagOutsideSquare() {
    #expect(MFMParser.parse("[#abc]") == [TEXT("["), HASHTAG("abc"), TEXT("]")])
  }

  @Test("hashtag - outside 「」")
  func hashtagOutsideCorner() {
    #expect(MFMParser.parse("「#abc」") == [TEXT("「"), HASHTAG("abc"), TEXT("」")])
  }

  @Test("hashtag - outside （）")
  func hashtagOutsideFullwidth() {
    #expect(MFMParser.parse("（#abc）") == [TEXT("（"), HASHTAG("abc"), TEXT("）")])
  }

  @Test("url")
  func url() {
    #expect(
      MFMParser.parse("<b>https://example.com/abc(xyz)</b>", nestLimit: 2)
        == [BOLD([N_URL("https://example.com/abc(xyz)")])])
    let output: [MFMNode] = [BOLD([N_URL("https://example.com/abc"), TEXT("(x(y)z)")])]
    #expect(MFMParser.parse("<b>https://example.com/abc(x(y)z)</b>", nestLimit: 2) == output)
  }

  @Test("fn")
  func fn() {
    let output: [MFMNode] = [BOLD([BOLD([TEXT("$[a b]")])])]
    #expect(MFMParser.parse("<b><b>$[a b]</b></b>", nestLimit: 2) == output)
  }
}

@Suite("FullParser - composite")
struct CompositeTests {
  @Test("composite")
  func composite() {
    let input =
      "before\n<center>\nHello $[tada everynyan! 🎉]\n\nI'm @ai, A bot of misskey!\n\nhttps://github.com/syuilo/ai\n</center>\nafter"
    let output: [MFMNode] = [
      TEXT("before"),
      CENTER([
        TEXT("Hello "),
        FN("tada", MFMFnArgs([]), [TEXT("everynyan! "), UNI_EMOJI("🎉")]),
        TEXT("\n\nI'm "),
        MENTION("ai", nil, "@ai"),
        TEXT(", A bot of misskey!\n\n"),
        N_URL("https://github.com/syuilo/ai"),
      ]),
      TEXT("after"),
    ]
    #expect(MFMParser.parse(input) == output)
  }
}
