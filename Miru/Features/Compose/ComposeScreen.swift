import APIKit
import Foundation
import MisskeyAPI
import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct ComposeScreen: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(Session.self) private var session

  @State private var text = ""
  @State private var visibility: NoteVisibility = .public
  @State private var cw = ""
  @State private var cwEnabled = false
  @State private var localOnly = false
  @State private var selectedPickerItems: [PhotosPickerItem] = []
  @State private var selectedFiles: [SelectedComposeFile] = []
  @State private var fileImporterPresented = false
  @State private var emojiPickerPresented = false
  @State private var pendingEmoji: String?
  @State private var insertionCapture: ComposeInsertionCapture?
  @State private var isSubmitting = false

  @FocusState private var textEditorFocused: Bool

  let context: ComposeContext
  var onPosted: ((MisskeyAPI.Note) -> Void)? = nil

  var body: some View {
    NavigationStack {
      Form {
        Section {
          if case .reply(let note) = context {
            VStack(alignment: .leading, spacing: 0) {
              CompactNote(note: note.displayNote)
                .padding(.vertical, Spacing.sm)
                .allowsHitTesting(false)
              DashedDivider()
                .padding(.vertical, Spacing.md)
              TextEditor(text: $text)
                .frame(minHeight: 120)
                .focused($textEditorFocused)
            }
            .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
          } else if case .quote(let note) = context {
            VStack(alignment: .leading, spacing: Spacing.md) {
              TextEditor(text: $text)
                .frame(minHeight: 140)
                .focused($textEditorFocused)
              CompactNote(note: note)
                .padding(Spacing.md)
                .contentShape(Rectangle())
                .overlay {
                  RoundedRectangle(cornerRadius: Radius.md)
                    .stroke(Color(.separator), lineWidth: 1)
                }
                .allowsHitTesting(false)
            }
            .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
          } else {
            TextEditor(text: $text)
              .frame(minHeight: 140)
              .focused($textEditorFocused)
          }

          composeTools

          if !selectedFiles.isEmpty {
            ComposeFileStrip(files: $selectedFiles, isSubmitting: isSubmitting)
          }
        }
        .disabled(isSubmitting)

        Section {
          Picker("Visibility", selection: $visibility) {
            ForEach(NoteVisibility.allCases) { option in
              Text(option.title).tag(option)
            }
          }
          Toggle("Local Only", isOn: $localOnly)
          Toggle("Content Warning", isOn: $cwEnabled)
          if cwEnabled {
            TextField("Warning Text", text: $cw)
          }
        }
        .disabled(isSubmitting)

      }
      .contentMargins(.top, 0, for: .scrollContent)
      .onAppear {
        switch context {
        case .new, .channel:
          visibility = session.settings.defaultVisibility
        case .reply(let note):
          visibility =
            NoteVisibility(rawValue: note.displayNote.visibility) ?? .public
          if note.displayNote.user.id != session.account.userId && text.isEmpty
          {
            text = "\(note.displayNote.user.acct) "
          }
        case .quote(let note):
          visibility =
            NoteVisibility(rawValue: note.displayNote.visibility) ?? .public
        case .edit(let note):
          text = note.text ?? ""
          cw = note.cw ?? ""
          cwEnabled = !(note.cw ?? "").isEmpty
          visibility = NoteVisibility(rawValue: note.visibility) ?? .public
          localOnly = note.localOnly ?? false
        }

        Task { @MainActor in
          try? await Task.sleep(for: .milliseconds(100))
          textEditorFocused = true
        }
      }
      .onChange(of: selectedPickerItems) {
        Task {
          await appendSelectedPickerItems()
        }
      }
      .fileImporter(
        isPresented: $fileImporterPresented,
        allowedContentTypes: [.item],
        allowsMultipleSelection: true
      ) { result in
        Task {
          await appendImportedFiles(result: result)
        }
      }
      .sheet(isPresented: $emojiPickerPresented) {
        EmojiPickerScreen { emoji in
          pendingEmoji = emoji
        }
      }
      .onChange(of: emojiPickerPresented) { _, isPresented in
        guard !isPresented, let emoji = pendingEmoji else { return }
        textEditorFocused = true
        Task { @MainActor in
          try? await Task.sleep(for: .milliseconds(150))
          insert(emoji)
          pendingEmoji = nil
        }
      }
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button {
            dismiss()
          } label: {
            Image(systemName: "xmark")
          }
          .accessibilityLabel("Cancel")
        }
        ToolbarItem(placement: .confirmationAction) {
          Button {
            Task {
              await submit()
            }
          } label: {
            submitButtonLabel
          }
          .buttonStyle(.borderedProminent)
          .buttonBorderShape(.capsule)
          .disabled(isSubmitting || !canSubmit)
        }
      }
    }
  }

  private var canSubmit: Bool {
    !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      || (!context.isEditing && !selectedFiles.isEmpty)
      || !context.existingEditFileIds.isEmpty
  }

  @ViewBuilder
  private var submitButtonLabel: some View {
    if isSubmitting {
      ProgressView()
        .progressViewStyle(.circular)
        .controlSize(.small)
        .tint(.white)
        .frame(width: 18, height: 18)
    } else {
      Image(systemName: "paperplane.fill")
        .font(.body.weight(.semibold))
        .frame(width: 18, height: 18)
    }
  }

  @ViewBuilder
  private var composeTools: some View {
    HStack(spacing: Spacing.lg) {
      Button {
        insertionCapture = captureInsertionPoint()
        emojiPickerPresented = true
      } label: {
        Image(systemName: "face.smiling")
      }
      if !context.isEditing {
        PhotosPicker(
          selection: $selectedPickerItems,
          maxSelectionCount: nil,
          matching: .any(of: [.images, .videos])
        ) {
          Image(systemName: "photo.on.rectangle")
        }
        Button {
          fileImporterPresented = true
        } label: {
          Image(systemName: "folder")
        }
      }
      Spacer()
    }
    .font(.title3)
    .foregroundStyle(.secondary)
    .buttonStyle(.plain)
    .disabled(isSubmitting)
  }

  private func submit() async {
    guard !isSubmitting else { return }
    isSubmitting = true
    do {
      let contentWarning = cwEnabled ? cw : nil
      let created: MisskeyAPI.Note
      if case .edit(let note) = context {
        created = try await session.apiKit.response(
          for:
            MisskeyAPI.NotesCreateRequest(
              visibility: visibility.apiValue,
              cw: contentWarning?.isEmpty == true ? nil : contentWarning,
              localOnly: localOnly,
              replyId: note.replyId,
              renoteId: note.isQuote ? note.renote?.id : nil,
              channelId: context.channelId,
              text: text.isEmpty ? nil : text,
              fileIds: context.existingEditFileIds.isEmpty
                ? nil : context.existingEditFileIds
            )
        ).createdNote
      } else {
        created = try await session.apiKit.response(
          for:
            MisskeyAPI.NotesCreateRequest(
              visibility: visibility.apiValue,
              cw: contentWarning?.isEmpty == true ? nil : contentWarning,
              localOnly: localOnly,
              replyId: context.replyId,
              renoteId: context.quoteId,
              channelId: context.channelId,
              text: text.isEmpty ? nil : text,
              fileIds: try await uploadedFileIds()
            )
        ).createdNote
      }
      isSubmitting = false
      onPosted?(created)
      dismiss()
    } catch {
      errorAlert(error)
      isSubmitting = false
    }
  }

  private func appendSelectedPickerItems() async {
    let loaded = await ComposeAttachmentLoader.loadPickerItems(
      selectedPickerItems
    )
    selectedFiles.append(contentsOf: loaded)
    selectedPickerItems = []
  }

  private func appendImportedFiles(result: Result<[URL], Error>) async {
    let loaded = await ComposeAttachmentLoader.loadImportedFiles(result: result)
    selectedFiles.append(contentsOf: loaded)
  }

  private func uploadedFileIds() async throws -> [String]? {
    var fileIds: [String] = []
    for file in selectedFiles {
      let uploaded = try await session.apiKit.response(
        for: MisskeyAPI.DriveFilesCreateRequest(
          name: file.filename,
          isSensitive: file.isSensitive,
          file: .init(
            data: file.data,
            filename: file.filename,
            mimeType: file.mimeType
          )
        )
      )
      fileIds.append(uploaded.id)
    }
    return fileIds.isEmpty ? nil : fileIds
  }

  private func captureInsertionPoint() -> ComposeInsertionCapture? {
    guard
      let window = UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .flatMap({ $0.windows })
        .first(where: { $0.isKeyWindow }),
      let textView = firstResponderTextView(in: window)
    else { return nil }
    return ComposeInsertionCapture(text: text, range: textView.selectedRange)
  }

  private func firstResponderTextView(in view: UIView) -> UITextView? {
    if let tv = view as? UITextView, tv.isFirstResponder { return tv }
    for sub in view.subviews {
      if let found = firstResponderTextView(in: sub) { return found }
    }
    return nil
  }

  private func insert(_ emoji: String) {
    guard
      let window = UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .flatMap({ $0.windows })
        .first(where: { $0.isKeyWindow }),
      let textView = firstResponderTextView(in: window)
    else {
      insertAtCapturedRange(emoji)
      return
    }
    if let capture = insertionCapture,
      capture.text == text,
      capture.range.location != NSNotFound,
      NSMaxRange(capture.range) <= (textView.text as NSString).length
    {
      textView.selectedRange = capture.range
    }
    textView.insertText(emoji)
    insertionCapture = nil
  }

  private func insertAtCapturedRange(_ emoji: String) {
    defer { insertionCapture = nil }
    let ns = text as NSString
    guard let capture = insertionCapture,
      capture.text == text,
      capture.range.location != NSNotFound,
      NSMaxRange(capture.range) <= ns.length
    else {
      text += emoji
      return
    }
    text = ns.replacingCharacters(in: capture.range, with: emoji)
  }
}

enum ComposeContext {
  case new
  case channel(String)
  case reply(MisskeyAPI.Note)
  case quote(MisskeyAPI.Note)
  case edit(MisskeyAPI.Note)
}

extension ComposeContext: Hashable {
  static func == (lhs: ComposeContext, rhs: ComposeContext) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

extension ComposeContext: Identifiable {
  var id: String {
    switch self {
    case .new: "new"
    case .channel(let channelId): "channel-\(channelId)"
    case .reply(let note): "reply-\(note.id)"
    case .quote(let note): "quote-\(note.id)"
    case .edit(let note): "edit-\(note.id)"
    }
  }
}

extension ComposeContext {
  var isEditing: Bool {
    if case .edit = self { return true }
    return false
  }

  var existingEditFileIds: [String] {
    if case .edit(let note) = self {
      return note.files?.map(\.id) ?? []
    }
    return []
  }

  var replyId: String? {
    if case .reply(let note) = self { return note.id }
    return nil
  }

  var quoteId: String? {
    if case .quote(let note) = self { return note.id }
    return nil
  }

  var channelId: String? {
    switch self {
    case .channel(let channelId):
      return channelId
    case .edit(let note):
      return note.channelId
    default:
      return nil
    }
  }
}

private struct ComposeInsertionCapture {
  let text: String
  let range: NSRange
}
