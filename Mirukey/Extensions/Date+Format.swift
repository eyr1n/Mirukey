import Foundation

extension Date {
  var absoluteString: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .medium
    return formatter.string(from: self)
  }

  var relativeString: String {
    let ago = Int(Date().timeIntervalSince(self))
    switch ago {
    case 31_536_000...:
      return String(localized: "\(ago / 31_536_000) years ago")
    case 2_592_000...: return String(localized: "\(ago / 2_592_000) months ago")
    case 604_800...: return String(localized: "\(ago / 604_800) weeks ago")
    case 86_400...: return String(localized: "\(ago / 86_400) days ago")
    case 3_600...: return String(localized: "\(ago / 3_600) hours ago")
    case 60...: return String(localized: "\(ago / 60) min ago")
    case 10...: return String(localized: "\(ago) seconds ago")
    default: return String(localized: "Just now")
    }
  }
}
