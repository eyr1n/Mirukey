import Foundation

//
// Parsimmon-like stateful parser combinators
//

let jsNull = NSNull()

func isNull(_ value: Any) -> Bool { value is NSNull }

struct ParseResult {
  let success: Bool
  let index: Int
  let value: Any
}

final class State {
  var trace: Bool
  var linkLabel: Bool
  var nestLimit: Int
  var depth: Int

  init(trace: Bool = false, linkLabel: Bool = false, nestLimit: Int, depth: Int = 0) {
    self.trace = trace
    self.linkLabel = linkLabel
    self.nestLimit = nestLimit
    self.depth = depth
  }
}

typealias ParserHandler = (NSString, Int, State) -> ParseResult

func success(_ index: Int, _ value: Any) -> ParseResult {
  ParseResult(success: true, index: index, value: value)
}

func failure() -> ParseResult {
  ParseResult(success: false, index: 0, value: jsNull)
}

final class Parser: @unchecked Sendable {
  var name: String?
  var handler: ParserHandler!

  init() {}

  init(_ handler: @escaping ParserHandler, name: String? = nil) {
    self.name = name
    self.handler = { [weak self] input, index, state in
      if state.trace, let self, let name = self.name {
        let pos = "\(index)".rightPadded(6)
        print("\(pos)enter \(name)")
        let result = handler(input, index, state)
        if result.success {
          print("\("\(index):\(result.index)".rightPadded(6))match \(name)")
        } else {
          print("\("\(index)".rightPadded(6))fail \(name)")
        }
        return result
      }
      return handler(input, index, state)
    }
  }

  func map(_ fn: @escaping (Any) -> Any) -> Parser {
    Parser { input, index, state in
      let result = self.handler(input, index, state)
      if !result.success { return result }
      return success(result.index, fn(result.value))
    }
  }

  func text() -> Parser {
    Parser { input, index, state in
      let result = self.handler(input, index, state)
      if !result.success { return result }
      let text = input.substring(with: NSRange(location: index, length: result.index - index))
      return success(result.index, text)
    }
  }

  func many(_ min: Int) -> Parser {
    Parser { input, index, state in
      var latestIndex = index
      var accum: [Any] = []
      while latestIndex < input.length {
        let result = self.handler(input, latestIndex, state)
        if !result.success { break }
        latestIndex = result.index
        accum.append(result.value)
      }
      if accum.count < min { return failure() }
      return success(latestIndex, accum)
    }
  }

  func sep(_ separator: Parser, _ min: Int) -> Parser {
    precondition(min >= 1, "\"min\" must be a value greater than or equal to 1.")
    return seq(self, seq(separator, self).select(1).many(min - 1)).map { value in
      let result = value as! [Any]
      return [result[0]] + (result[1] as! [Any])
    }
  }

  func select(_ key: Int) -> Parser {
    map { ($0 as! [Any])[key] }
  }

  func option() -> Parser {
    alt([self, succeeded(jsNull)])
  }
}

func str(_ value: String) -> Parser {
  let needle = value as NSString
  return Parser { input, index, _ in
    if (input.length - index) < needle.length { return failure() }
    if input.substring(with: NSRange(location: index, length: needle.length)) != value {
      return failure()
    }
    return success(index + needle.length, value)
  }
}

func regexp(_ pattern: String, _ options: NSRegularExpression.Options = []) -> Parser {
  regexp(try! NSRegularExpression(pattern: pattern, options: options))
}

func regexp(_ re: NSRegularExpression) -> Parser {
  Parser { input, index, _ in
    let range = NSRange(location: index, length: input.length - index)
    guard
      let match = re.firstMatch(in: input as String, options: [.anchored], range: range)
    else {
      return failure()
    }
    let text = input.substring(with: match.range)
    return success(NSMaxRange(match.range), text)
  }
}

func seq(_ parsers: Parser...) -> Parser {
  seq(parsers)
}

func seq(_ parsers: [Parser]) -> Parser {
  Parser { input, index, state in
    var latestIndex = index
    var accum: [Any] = []
    for parser in parsers {
      let result = parser.handler(input, latestIndex, state)
      if !result.success { return result }
      latestIndex = result.index
      accum.append(result.value)
    }
    return success(latestIndex, accum)
  }
}

func alt(_ parsers: [Parser]) -> Parser {
  Parser { input, index, state in
    for parser in parsers {
      let result = parser.handler(input, index, state)
      if result.success { return result }
    }
    return failure()
  }
}

func succeeded(_ value: Any) -> Parser {
  Parser { _, index, _ in success(index, value) }
}

func notMatch(_ parser: Parser) -> Parser {
  Parser { input, index, state in
    let result = parser.handler(input, index, state)
    return !result.success ? success(index, jsNull) : failure()
  }
}

let cr = str("\r")
let lf = str("\n")
let crlf = str("\r\n")
let newline = alt([crlf, cr, lf])

let char = Parser { input, index, _ in
  if (input.length - index) < 1 { return failure() }
  let value = input.substring(with: NSRange(location: index, length: 1))
  return success(index + 1, value)
}

let lineBegin = Parser { input, index, state in
  if index == 0 { return success(index, jsNull) }
  if cr.handler(input, index - 1, state).success { return success(index, jsNull) }
  if lf.handler(input, index - 1, state).success { return success(index, jsNull) }
  return failure()
}

let lineEnd = Parser { input, index, state in
  if index == input.length { return success(index, jsNull) }
  if cr.handler(input, index, state).success { return success(index, jsNull) }
  if lf.handler(input, index, state).success { return success(index, jsNull) }
  return failure()
}

extension String {
  fileprivate func rightPadded(_ width: Int) -> String {
    count >= width ? self : self + String(repeating: " ", count: width - count)
  }
}
