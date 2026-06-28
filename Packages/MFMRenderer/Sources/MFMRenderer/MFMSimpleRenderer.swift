import MFMParser
import SwiftUI
import UIKit

public struct MFMSimpleRenderer: View {
  @Environment(\.lineLimit) private var lineLimit

  private let emojiScale: CGFloat = 1

  let nodes: [MFMNode]
  var emojis: [String: String]?
  let color: Color

  public init(
    nodes: [MFMNode],
    emojis: [String: String]? = nil,
    color: Color = .primary
  ) {
    self.nodes = nodes
    self.emojis = emojis
    self.color = color
  }

  public var body: some View {
    MFMInlineRendererView(
      nodes: nodes,
      emojis: emojis,
      emojiScale: emojiScale,
      color: color,
      lineLimit: lineLimit
    )
  }
}
