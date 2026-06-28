import UIKit

extension UIWindow {
  static var keyWindow: UIWindow? {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .filter { $0.activationState == .foregroundActive }
      .compactMap(\.keyWindow)
      .first
  }
}

extension UIViewController {
  var topMostViewController: UIViewController {
    if let controller = presentedViewController {
      return controller.topMostViewController
    }
    if let controller = self as? UINavigationController {
      return controller.visibleViewController?.topMostViewController
        ?? controller
    }
    if let controller = self as? UITabBarController {
      return controller.selectedViewController?.topMostViewController
        ?? controller
    }
    return self
  }
}
