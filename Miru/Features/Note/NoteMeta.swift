import MFMRenderer
import SwiftUI
import MisskeyAPI

struct NoteMeta: View {
  var note: MisskeyAPI.Note
  var timestamp: String

  private var visibilityIcon: String? {
    switch note.visibility {
    case "home": "house"
    case "followers": "lock"
    case "specified": "envelope"
    default: nil
    }
  }

  var body: some View {
    HStack(spacing: Spacing.sm) {
      Text(timestamp)
      if let icon = visibilityIcon {
        Image(systemName: icon)
      }
      if note.localOnly == true {
        Image(systemName: "antenna.radiowaves.left.and.right.slash")
      }
    }
    .font(.caption)
    .foregroundStyle(.secondary)
  }
}
