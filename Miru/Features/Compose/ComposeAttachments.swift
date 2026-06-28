import Foundation
import Photos
import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct SelectedComposeFile: Identifiable {
  let id = UUID()
  let data: Data
  let preview: UIImage?
  let filename: String
  let mimeType: String
  var isSensitive = false

  var previewIcon: String {
    if mimeType.hasPrefix("video/") { return "film" }
    if mimeType.hasPrefix("audio/") { return "music.note" }
    return "doc"
  }
}

enum ComposeAttachmentLoader {
  static func loadPickerItems(_ items: [PhotosPickerItem]) async -> [SelectedComposeFile] {
    var loaded: [SelectedComposeFile] = []
    for item in items {
      guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
      let contentType = item.supportedContentTypes.first
      let mimeType = contentType?.preferredMIMEType ?? "application/octet-stream"
      let filename = filename(for: item, contentType: contentType, index: loaded.count + 1)
      let preview: UIImage? = mimeType.hasPrefix("image/") ? UIImage(data: data) : nil
      loaded.append(
        SelectedComposeFile(data: data, preview: preview, filename: filename, mimeType: mimeType))
    }
    return loaded
  }

  static func loadImportedFiles(result: Result<[URL], Error>) async -> [SelectedComposeFile] {
    guard case .success(let urls) = result else { return [] }
    var loaded: [SelectedComposeFile] = []
    for url in urls {
      guard url.startAccessingSecurityScopedResource() else { continue }
      let data = try? Data(contentsOf: url)
      url.stopAccessingSecurityScopedResource()
      guard let data else { continue }
      let utType = UTType(filenameExtension: url.pathExtension)
      let mimeType = utType?.preferredMIMEType ?? "application/octet-stream"
      let preview: UIImage? = mimeType.hasPrefix("image/") ? UIImage(data: data) : nil
      let filename = sanitizedFilename(url.lastPathComponent) ?? "file-\(loaded.count + 1)"
      loaded.append(
        SelectedComposeFile(
          data: data, preview: preview, filename: filename, mimeType: mimeType))
    }
    return loaded
  }

  private static func filename(
    for item: PhotosPickerItem,
    contentType: UTType?,
    index: Int
  ) -> String {
    if let filename = originalFilename(for: item) {
      return filename
    }
    let ext = contentType?.preferredFilenameExtension ?? "bin"
    return "file-\(index).\(ext)"
  }

  private static func originalFilename(for item: PhotosPickerItem) -> String? {
    guard let itemIdentifier = item.itemIdentifier else { return nil }
    let fetchResult = PHAsset.fetchAssets(
      withLocalIdentifiers: [itemIdentifier],
      options: nil
    )
    guard let asset = fetchResult.firstObject else { return nil }
    let resources = PHAssetResource.assetResources(for: asset)
    let resource =
      resources.first { resource in
        switch asset.mediaType {
        case .image:
          return resource.type == .photo || resource.type == .fullSizePhoto
        case .video:
          return resource.type == .video || resource.type == .fullSizeVideo
        case .audio:
          return resource.type == .audio
        default:
          return false
        }
      } ?? resources.first
    return sanitizedFilename(resource?.originalFilename)
  }

  private static func sanitizedFilename(_ filename: String?) -> String? {
    guard let filename else { return nil }
    let sanitized = filename
      .components(separatedBy: CharacterSet(charactersIn: "/\\:"))
      .joined(separator: "-")
      .trimmingCharacters(in: .whitespacesAndNewlines)
    return sanitized.isEmpty ? nil : sanitized
  }
}
