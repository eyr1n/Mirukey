import SwiftUI

extension View {

  func horizontalOverflowFade(atStart: Bool, atEnd: Bool) -> some View {
    mask(
      LinearGradient(
        stops: [
          .init(color: atStart ? .black : .clear, location: 0),
          .init(color: .black, location: atStart ? 0 : 0.04),
          .init(color: .black, location: atEnd ? 1 : 0.88),
          .init(color: atEnd ? .black : .clear, location: 1),
        ],
        startPoint: .leading,
        endPoint: .trailing
      )
    )
  }

  func horizontalOverflowFadeTracking() -> some View {
    modifier(HorizontalOverflowFadeTracking())
  }
}

private struct HorizontalOverflowFadeTracking: ViewModifier {
  @State private var atStart = true
  @State private var atEnd = false

  func body(content: Content) -> some View {
    content
      .onScrollGeometryChange(for: Bool.self) { geometry in
        geometry.contentOffset.x <= 1
      } action: { _, value in
        atStart = value
      }
      .onScrollGeometryChange(for: Bool.self) { geometry in
        geometry.contentOffset.x >= geometry.contentSize.width
          - geometry.containerSize.width - 1
      } action: { _, value in
        atEnd = value
      }
      .horizontalOverflowFade(atStart: atStart, atEnd: atEnd)
  }
}
