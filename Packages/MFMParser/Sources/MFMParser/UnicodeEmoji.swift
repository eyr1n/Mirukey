import Foundation

//
// Unicode emoji detection.
//
// mfm.js detects Unicode emoji with a ~17KB vendored regex from
// `@misskey-dev/emoji-data` (a fixed Unicode snapshot). This port instead uses
// the platform's own grapheme segmentation + scalar properties: a deliberate
// deviation from a strict 1:1 port, kept lighter and self-updating with the OS's
// Unicode tables. The MFM-relevant cases (presentation emoji, VS16 sequences,
// skin tones, ZWJ sequences, flags, keycaps) all match; some text-default symbols
// that mfm.js treats as emoji only via its regex (e.g. a bare "☀") are not, which
// is invisible in rendering and absent from the test suite.
//

/// Whether a single grapheme cluster should be treated as a Unicode emoji.
func isEmojiCluster(_ cluster: String) -> Bool {
  let scalars = Array(cluster.unicodeScalars)
  guard let first = scalars.first else { return false }
  // Default emoji-presentation characters (most emoji) stand alone.
  if first.properties.isEmojiPresentation { return true }
  if scalars.count > 1 {
    // VS16 forces emoji presentation; otherwise a base emoji with a modifier,
    // ZWJ continuation, regional indicator, or keycap also forms an emoji.
    if scalars.contains(where: { $0 == "\u{FE0F}" }) { return true }
    if first.properties.isEmoji { return true }
  }
  return false
}

/// Parser matching one Unicode emoji grapheme cluster at the current index
/// (mfm.js's `unicodeEmoji` rule). A lone variation selector is not an emoji and
/// falls through to the text rule, matching mfm.js's behavior.
let unicodeEmojiParser = Parser { input, index, _ in
  guard index < input.length else { return failure() }
  let range = input.rangeOfComposedCharacterSequence(at: index)
  // Only match at a cluster boundary (e.g. not mid surrogate pair).
  guard range.location == index else { return failure() }
  let cluster = input.substring(with: range)
  guard isEmojiCluster(cluster) else { return failure() }
  return success(NSMaxRange(range), UNI_EMOJI(cluster))
}
