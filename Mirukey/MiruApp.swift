import MediaViewer
import SwiftUI
import UIKit

@main
struct MiruApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  var body: some Scene {
    WindowGroup {
      ContentView()
        .onOpenURL(prefersInApp: true)
        .environment(
          \.openMedia,
          OpenMediaAction { pages, index in
            let controller = PreviewController()
            controller.previewPages = pages
            controller.currentPreviewItemIndex = index
            UIWindow.keyWindow?.rootViewController?.topMostViewController
              .present(controller, animated: true)
          }
        )
    }
  }
}
