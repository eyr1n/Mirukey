import Foundation

struct FullParserOpts {
  var nestLimit: Int?
}

func fullParser(_ input: String, _ opts: FullParserOpts) -> [MFMNode] {
  let state = State(
    trace: false,
    linkLabel: false,
    nestLimit: opts.nestLimit ?? 20,
    depth: 0)
  let result = language.fullParser.handler(input as NSString, 0, state)
  if !result.success { fatalError("Unexpected parse error") }
  return mergeText(result.value as! [Any])
}

func simpleParser(_ input: String) -> [MFMNode] {
  let state = State(nestLimit: Int.max)  // reliable infinite
  let result = language.simpleParser.handler(input as NSString, 0, state)
  if !result.success { fatalError("Unexpected parse error") }
  return mergeText(result.value as! [Any])
}
