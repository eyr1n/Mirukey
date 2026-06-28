import SwiftUI

struct DashedDivider: View {
  var body: some View {
    GeometryReader { proxy in
      Path { path in
        path.move(to: CGPoint(x: 0, y: 0.5))
        path.addLine(to: CGPoint(x: proxy.size.width, y: 0.5))
      }
      .stroke(Color(.separator), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
    }
    .frame(height: 1)
  }
}
