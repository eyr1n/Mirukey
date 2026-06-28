import Testing

@testable import MFMParser

@Suite("API - toString")
struct ToStringTests {
  @Test("basic")
  func basic() {
    let input =
      "before\n<center>\nHello $[tada everynyan! 🎉]\n\nI'm @ai, A bot of misskey!\n\nhttps://github.com/syuilo/ai\n</center>\nafter"
    #expect(MFMParser.toString(MFMParser.parse(input)) == input)
  }

  @Test("single node")
  func singleNode() {
    #expect(MFMParser.toString(MFMParser.parse("$[tada Hello]")[0]) == "$[tada Hello]")
  }

  @Test("quote")
  func quote() {
    #expect(MFMParser.toString(MFMParser.parse("\n> abc\n> \n> 123\n")) == "> abc\n> \n> 123")
  }

  @Test("search")
  func search() {
    let input = "MFM 書き方 123 Search"
    #expect(MFMParser.toString(MFMParser.parse(input)) == input)
  }

  @Test("block code")
  func blockCode() {
    let input = "```\nabc\n```"
    #expect(MFMParser.toString(MFMParser.parse(input)) == input)
  }

  @Test("math block")
  func mathBlock() {
    let input = "\\[\ny = 2x + 1\n\\]"
    #expect(MFMParser.toString(MFMParser.parse(input)) == input)
  }

  @Test("center")
  func center() {
    let input = "<center>\nabc\n</center>"
    #expect(MFMParser.toString(MFMParser.parse(input)) == input)
  }

  // @Test("center (single line)")
  // func centerSingleLine() {
  //   let input = "<center>abc</center>"
  //   #expect(MFMParser.toString(MFMParser.parse(input)) == input)
  // }

  @Test("emoji code")
  func emojiCode() {
    let input = ":abc:"
    #expect(MFMParser.toString(MFMParser.parse(input)) == input)
  }

  @Test("unicode emoji")
  func unicodeEmoji() {
    let input = "今起きた😇"
    #expect(MFMParser.toString(MFMParser.parse(input)) == input)
  }

  @Test("big")
  func big() {
    #expect(MFMParser.toString(MFMParser.parse("***abc***")) == "$[tada abc]")
  }

  @Test("bold")
  func bold() {
    let input = "**abc**"
    #expect(MFMParser.toString(MFMParser.parse(input)) == input)
  }

  // @Test("bold tag")
  // func boldTag() {
  //   let input = "<b>abc</b>"
  //   #expect(MFMParser.toString(MFMParser.parse(input)) == input)
  // }

  @Test("small")
  func small() {
    let input = "<small>abc</small>"
    #expect(MFMParser.toString(MFMParser.parse(input)) == input)
  }

  // @Test("italic")
  // func italic() {
  //   let input = "*abc*"
  //   #expect(MFMParser.toString(MFMParser.parse(input)) == input)
  // }

  @Test("italic tag")
  func italicTag() {
    let input = "<i>abc</i>"
    #expect(MFMParser.toString(MFMParser.parse(input)) == input)
  }

  @Test("strike")
  func strike() {
    let input = "~~foo~~"
    #expect(MFMParser.toString(MFMParser.parse(input)) == input)
  }

  // @Test("strike tag")
  // func strikeTag() {
  //   let input = "<s>foo</s>"
  //   #expect(MFMParser.toString(MFMParser.parse(input)) == input)
  // }

  @Test("inline code")
  func inlineCode() {
    let input = "AiScript: `#abc = 2`"
    #expect(MFMParser.toString(MFMParser.parse(input)) == "AiScript: `#abc = 2`")
  }

  @Test("math inline")
  func mathInline() {
    let input = "\\(y = 2x + 3\\)"
    #expect(MFMParser.toString(MFMParser.parse(input)) == "\\(y = 2x + 3\\)")
  }

  @Test("hashtag")
  func hashtag() {
    let input = "a #misskey b"
    #expect(MFMParser.toString(MFMParser.parse(input)) == "a #misskey b")
  }

  @Test("link")
  func link() {
    let input = "[Ai](https://github.com/syuilo/ai)"
    #expect(MFMParser.toString(MFMParser.parse(input)) == "[Ai](https://github.com/syuilo/ai)")
  }

  @Test("silent link")
  func silentLink() {
    let input = "?[Ai](https://github.com/syuilo/ai)"
    #expect(MFMParser.toString(MFMParser.parse(input)) == "?[Ai](https://github.com/syuilo/ai)")
  }

  @Test("fn")
  func fn() {
    let input = "$[tada Hello]"
    #expect(MFMParser.toString(MFMParser.parse(input)) == "$[tada Hello]")
  }

  @Test("fn with arguments")
  func fnWithArguments() {
    let input = "$[spin.speed=1s,alternate Hello]"
    #expect(MFMParser.toString(MFMParser.parse(input)) == "$[spin.speed=1s,alternate Hello]")
  }

  @Test("plain")
  func plain() {
    let input = "a\n<plain>\nHello\nworld\n</plain>\nb"
    #expect(MFMParser.toString(MFMParser.parse(input)) == "a\n<plain>\nHello\nworld\n</plain>\nb")
  }

  @Test("1 line plain")
  func oneLinePlain() {
    let input = "a\n<plain>Hello</plain>\nb"
    #expect(MFMParser.toString(MFMParser.parse(input)) == "a\n<plain>\nHello\n</plain>\nb")
  }

  @Test("preserve url brackets")
  func preserveUrlBrackets() {
    let input1 = "https://github.com/syuilo/ai"
    #expect(MFMParser.toString(MFMParser.parse(input1)) == input1)

    let input2 = "<https://github.com/syuilo/ai>"
    #expect(MFMParser.toString(MFMParser.parse(input2)) == input2)
  }
}

@Suite("API - inspect")
struct InspectTests {
  @Test("visits all text nodes")
  func visitsAllText() {
    let nodes = MFMParser.parse("good morning $[tada everynyan!]")
    var texts: [String] = []
    MFMParser.inspect(nodes) { node in
      if case .text(let t) = node { texts.append(t) }
    }
    #expect(texts == ["good morning ", "everynyan!"])
  }

  @Test("visits text nodes of a single subtree")
  func visitsSingleSubtree() {
    let nodes = MFMParser.parse("good morning $[tada everyone!]")
    var texts: [String] = []
    MFMParser.inspect(nodes[1]) { node in
      if case .text(let t) = node { texts.append(t) }
    }
    #expect(texts == ["everyone!"])
  }
}

@Suite("API - extract")
struct ExtractTests {
  @Test("basic")
  func basic() {
    let nodes = MFMParser.parse("@hoge @piyo @bebeyo")
    let expected: [MFMNode] = [
      MENTION("hoge", nil, "@hoge"),
      MENTION("piyo", nil, "@piyo"),
      MENTION("bebeyo", nil, "@bebeyo"),
    ]
    let extracted = MFMParser.extract(nodes) { if case .mention = $0 { return true } else { return false } }
    #expect(extracted == expected)
  }

  @Test("nested")
  func nested() {
    let nodes = MFMParser.parse("abc:hoge:$[tada 123 @hoge :foo:]:piyo:")
    let expected: [MFMNode] = [EMOJI_CODE("hoge"), EMOJI_CODE("foo"), EMOJI_CODE("piyo")]
    let extracted = MFMParser.extract(nodes) {
      if case .emojiCode = $0 { return true } else { return false }
    }
    #expect(extracted == expected)
  }
}
