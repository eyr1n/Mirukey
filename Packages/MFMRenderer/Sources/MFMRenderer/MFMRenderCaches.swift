import UIKit

final class MFMAttributedStringCache {
  static let shared = MFMAttributedStringCache()
  private let cache: NSCache<NSString, NSAttributedString> = {
    let cache = NSCache<NSString, NSAttributedString>()
    cache.countLimit = 1024
    return cache
  }()

  func getOrBuild(_ key: String, _ build: () -> NSAttributedString) -> NSAttributedString {
    if let cached = cache.object(forKey: key as NSString) {
      return cached
    }
    let value = build()
    cache.setObject(value, forKey: key as NSString)
    return value
  }
}

final class MFMTextSizeCache {
  static let shared = MFMTextSizeCache()
  private let cache: NSCache<NSString, NSValue> = {
    let cache = NSCache<NSString, NSValue>()
    cache.countLimit = 2048
    return cache
  }()

  func get(key: String, width: CGFloat, lineLimit: Int) -> CGSize? {
    cache.object(forKey: compositeKey(key, width, lineLimit))?.cgSizeValue
  }

  func set(_ size: CGSize, key: String, width: CGFloat, lineLimit: Int) {
    cache.setObject(NSValue(cgSize: size), forKey: compositeKey(key, width, lineLimit))
  }

  private func compositeKey(_ key: String, _ width: CGFloat, _ lineLimit: Int) -> NSString {
    "\(key)|w\(Int(width.rounded()))|l\(lineLimit)" as NSString
  }
}
