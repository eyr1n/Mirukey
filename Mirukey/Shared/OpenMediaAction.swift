import MediaViewer
import SwiftUI

struct OpenMediaAction {
  private let handler: (_ pages: [PreviewPage], _ index: Int) -> Void

  init(handler: @escaping (_ pages: [PreviewPage], _ index: Int) -> Void) {
    self.handler = handler
  }

  func callAsFunction(_ pages: [PreviewPage], _ index: Int) {
    handler(pages, index)
  }
}

private struct OpenMediaKey: EnvironmentKey {
  static let defaultValue = OpenMediaAction { _, _ in }
}

extension EnvironmentValues {
  var openMedia: OpenMediaAction {
    get { self[OpenMediaKey.self] }
    set { self[OpenMediaKey.self] = newValue }
  }
}
