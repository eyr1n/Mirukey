import MFMParser
import SwiftUI
import UIKit

enum MFMRenderElement {
  case inline([MFMNode])
  case block(MFMNode)
}

public struct MFMRenderer: View {
  private let emojiScale: CGFloat = 2

  @Environment(\.multilineTextAlignment) private var multilineTextAlignment

  let elements: [MFMRenderElement]
  var emojis: [String: String]? = nil
  let color: Color

  public init(
    nodes: [MFMNode],
    emojis: [String: String]? = nil,
    color: Color = .primary
  ) {
    self.elements = Self.groupNodes(nodes)
    self.emojis = emojis
    self.color = color
  }

  private var stackAlignment: HorizontalAlignment {
    switch multilineTextAlignment {
    case .center: return .center
    case .trailing: return .trailing
    case .leading: return .leading
    }
  }

  public var body: some View {
    VStack(alignment: stackAlignment, spacing: 0) {
      ForEach(0..<elements.count, id: \.self) { index in
        switch elements[index] {
        case .inline(let inlineNodes):
          renderInline(inlineNodes)
        case .block(let blockNode):
          renderBlock(blockNode)
        }
      }
    }
  }

  private static func groupNodes(_ nodes: [MFMNode]) -> [MFMRenderElement] {
    var elements: [MFMRenderElement] = []
    elements.reserveCapacity(nodes.count)
    var currentInline: [MFMNode] = []

    for node in nodes {
      if node.isBlock {
        if !currentInline.isEmpty {
          elements.append(.inline(currentInline))
          currentInline = []
        }
        elements.append(.block(node))
      } else {
        currentInline.append(node)
      }
    }

    if !currentInline.isEmpty {
      elements.append(.inline(currentInline))
    }

    return elements
  }

  @ViewBuilder
  private func renderInline(_ inlineNodes: [MFMNode]) -> some View {
    MFMInlineRendererView(
      nodes: inlineNodes,
      emojis: emojis,
      emojiScale: emojiScale,
      color: color,
      lineLimit: nil
    )
  }

  @ViewBuilder
  private func renderBlock(_ node: MFMNode) -> some View {
    switch node {
    case .quote(let children):
      MFMQuoteView(
        children: children,
        emojis: emojis,
        color: color
      )
    case .center(let children):
      MFMCenterView(
        children: children,
        emojis: emojis,
        color: color
      )
    case .blockCode(let code, _):
      MFMBlockCodeView(code: code, color: color)
    case .search(_, let content):
      renderInline([.text(content)])
    case .mathBlock(let formula):
      renderInline([.text(formula)])
    default:
      renderInline([node])
    }
  }
}
