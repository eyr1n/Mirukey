import SDWebImage
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication
      .LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    SDImageCodersManager.shared.addCoder(SDImageAWebPCoder.shared)
    SDWebImageDownloader.shared.setValue(
      "image/webp,image/apng,image/*,*/*;q=0.8",
      forHTTPHeaderField: "Accept"
    )
    SDImageCache.shared.config.maxMemoryCost = 128 * 1024 * 1024
    SDImageCache.shared.config.maxDiskSize = 256 * 1024 * 1024
    return true
  }
}
