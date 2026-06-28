import Foundation
import MisskeyAPI

struct MediaFile: Identifiable {
  enum Kind {
    case image
    case video
    case audio
  }

  let id: String
  let url: URL
  let thumbnailURL: URL?
  let kind: Kind
  let isSensitive: Bool

  init?(driveFile: MisskeyAPI.DriveFile) {
    guard
      let url = URL(string: driveFile.url),
      let scheme = url.scheme?.lowercased(),
      scheme == "http" || scheme == "https"
    else {
      return nil
    }

    let kind: Kind
    let type = driveFile.type.lowercased()
    if type.hasPrefix("image/") {
      kind = .image
    } else if type.hasPrefix("video/") {
      kind = .video
    } else if type.hasPrefix("audio/") {
      kind = .audio
    } else {
      return nil
    }

    self.id = driveFile.id
    self.url = url
    self.thumbnailURL = driveFile.thumbnailUrl.flatMap { value in
      URL(string: value)
    }
    self.kind = kind
    self.isSensitive = driveFile.isSensitive
  }

  var imageURL: URL {
    thumbnailURL ?? url
  }

  static func previewable(from driveFiles: [MisskeyAPI.DriveFile]?) -> [MediaFile] {
    (driveFiles ?? []).compactMap(MediaFile.init(driveFile:))
  }
}
