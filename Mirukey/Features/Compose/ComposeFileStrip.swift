import SwiftUI
import UIKit

struct ComposeFileStrip: View {
  @Binding var files: [SelectedComposeFile]
  let isSubmitting: Bool
  @State private var atStart = true
  @State private var atEnd = false

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(alignment: .top, spacing: Spacing.md) {
        ForEach(files, id: \.id) { file in
          let fileId = file.id
          ComposeFileThumbnail(
            file: file,
            onDelete: { files.removeAll { $0.id == fileId } },
            onToggleSensitive: {
              if let index = files.firstIndex(where: { $0.id == fileId }) {
                files[index].isSensitive.toggle()
              }
            },
            isSubmitting: isSubmitting
          )
        }
      }
      .padding(.vertical, Spacing.xs)
    }
    .onScrollGeometryChange(for: Bool.self) { geometry in
      geometry.contentOffset.x <= 1
    } action: { _, value in
      atStart = value
    }
    .onScrollGeometryChange(for: Bool.self) { geometry in
      geometry.contentOffset.x >= geometry.contentSize.width - geometry.containerSize.width - 1
    } action: { _, value in
      atEnd = value
    }
    .horizontalOverflowFade(atStart: atStart, atEnd: atEnd)
  }
}

private struct ComposeFileThumbnail: View {
  let file: SelectedComposeFile
  let onDelete: () -> Void
  let onToggleSensitive: () -> Void
  let isSubmitting: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: Spacing.md) {
      ZStack(alignment: .topTrailing) {
        preview
          .frame(width: NoteMediaSize.compact.width, height: NoteMediaSize.compact.height)
          .clipShape(RoundedRectangle(cornerRadius: Radius.md))
          .clipped()

        Button(action: onDelete) {
          Image(systemName: "xmark.circle.fill")
            .foregroundStyle(.white, .black.opacity(0.55))
            .font(.title3)
        }
        .padding(Spacing.md)
      }

      Toggle("Sensitive", isOn: Binding(get: { file.isSensitive }, set: { _ in onToggleSensitive() }))
        .font(.caption)
        .frame(width: NoteMediaSize.compact.width)
        .disabled(isSubmitting)
    }
  }

  @ViewBuilder
  private var preview: some View {
    if let image = file.preview {
      Image(uiImage: image)
        .resizable()
        .scaledToFill()
    } else {
      Color(.secondarySystemBackground)
        .overlay {
          VStack(spacing: Spacing.md) {
            Image(systemName: file.previewIcon)
              .font(.title2)
            Text(file.filename)
              .font(.caption2)
              .lineLimit(2)
              .multilineTextAlignment(.center)
              .padding(.horizontal, Spacing.sm)
          }
          .foregroundStyle(.secondary)
        }
    }
  }
}
