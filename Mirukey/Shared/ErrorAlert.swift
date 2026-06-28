import UIKit

func errorAlert(_ error: Error) {
  let controller = UIAlertController(
    title: String(localized: "Error"),
    message: error.localizedDescription,
    preferredStyle: .alert
  )
  controller.addAction(
    UIAlertAction(title: String(localized: "OK"), style: .default)
  )
  UIWindow.keyWindow?.rootViewController?.topMostViewController.present(
    controller,
    animated: true
  )
}
