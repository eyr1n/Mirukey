import MFMParser
import SwiftUI
import UIKit

private enum Spacing {
  static let md: CGFloat = 8
}

struct MFMQuoteView: View {
  let children: [MFMNode]
  let emojis: [String: String]?
  let color: Color

  var body: some View {
    HStack(spacing: Spacing.md) {
      Rectangle()
        .fill(.tertiary)
        .frame(width: 4)
      MFMRenderer(
        nodes: children,
        emojis: emojis,
        color: color
      )
    }
    .padding(8)
    .fixedSize(horizontal: false, vertical: true)
  }
}

struct MFMCenterView: View {
  let children: [MFMNode]
  let emojis: [String: String]?
  let color: Color

  var body: some View {
    MFMRenderer(
      nodes: children,
      emojis: emojis,
      color: color
    )
    .multilineTextAlignment(.center)
    .frame(maxWidth: .infinity, alignment: .center)
  }
}

struct MFMBlockCodeView: View {
  let code: String
  let color: Color

  var body: some View {
    Text(code)
      .font(.system(.body, design: .monospaced))
      .foregroundStyle(color)
  }
}
