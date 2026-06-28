import SwiftUI
import UIKit

struct ActivityIndicator: UIViewRepresentable {
  func makeUIView(context: Context) -> UIActivityIndicatorView {
    UIActivityIndicatorView(style: .medium)
  }

  func updateUIView(_ uiView: UIActivityIndicatorView, context: Context) {
    uiView.startAnimating()
  }
}
