import AVKit
import MediaViewer
import MediaViewerBuiltins
import MisskeyAPI
import SDWebImage
import SDWebImageSwiftUI
import SwiftUI
import UIKit

enum NoteMediaSize {
  static let compact = CGSize(width: 160, height: 120)
  static let standard = CGSize(width: 240, height: 180)
}

struct NoteMediaStrip: View {
  @Environment(\.openMedia) private var openMedia
  let files: [MisskeyAPI.DriveFile]?
  var thumbnailSize: CGSize = NoteMediaSize.standard

  private var previewableFiles: [MediaFile] {
    MediaFile.previewable(from: files)
  }

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: Spacing.md) {
        ForEach(Array(previewableFiles.enumerated()), id: \.element.id) {
          index,
          file in
          SensitiveMediaThumbnail(file: file, size: thumbnailSize) {
            openMedia(buildPages(from: previewableFiles), index)
          }
        }
      }
    }
    .horizontalOverflowFadeTracking()
    .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
  }

  private func buildPages(from files: [MediaFile]) -> [PreviewPage] {
    files.map { file in
      PreviewPage(
        id: UUID(),
        viewControllerProvider: {
          switch file.kind {
          case .image:
            return await AnimatedImagePreviewViewController.load(url: file.url)
          case .video, .audio:
            let player = AVPlayer(url: file.url)
            return PlayerPreviewItemViewController(player: player)
          }
        },
        thumbnailViewControllerProvider: {
          switch file.kind {
          case .image:
            return LoadingIndicatorViewController()
          case .video, .audio:
            return nil
          }
        },
        activityProvider: {
          UIActivityItemsConfiguration(objects: [file.url as NSURL])
        }
      )
    }
  }
}

private final class AnimatedImagePreviewViewController: UIViewController,
  UIScrollViewDelegate
{
  private let scrollView = UIScrollView()
  private let imageView = SDAnimatedImageView()
  private let doubleTapGesture = UITapGestureRecognizer()
  private let url: URL

  static func load(url: URL) async -> AnimatedImagePreviewViewController {
    let controller = AnimatedImagePreviewViewController(url: url)
    controller.loadViewIfNeeded()
    await controller.loadImage()
    return controller
  }

  private init(url: URL) {
    self.url = url
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError()
  }

  override func loadView() {
    view = scrollView
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    scrollView.delegate = self
    scrollView.showsVerticalScrollIndicator = false
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.contentInsetAdjustmentBehavior = .never

    imageView.backgroundColor = .clear
    imageView.contentMode = .scaleAspectFit
    imageView.isUserInteractionEnabled = true
    scrollView.addSubview(imageView)
    imageView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
      imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
      imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
      imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
      imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
      imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
    ])

    doubleTapGesture.addTarget(self, action: #selector(handleDoubleTapGesture))
    doubleTapGesture.numberOfTapsRequired = 2
    imageView.addGestureRecognizer(doubleTapGesture)

    scrollView.minimumZoomScale = 1.0
    scrollView.maximumZoomScale = 3.0
    scrollView.zoomScale = 1.0
  }

  private func loadImage() async {
    await withCheckedContinuation { continuation in
      imageView.sd_setImage(
        with: url,
        placeholderImage: nil,
        options: [.retryFailed, .matchAnimatedImageClass],
        context: [.animatedImageClass: SDAnimatedImage.self],
        progress: nil
      ) { _, _, _, _ in
        continuation.resume()
      }
    }
  }

  @objc private func handleDoubleTapGesture(
    _ gestureRecognizer: UITapGestureRecognizer
  ) {
    if scrollView.zoomScale == scrollView.minimumZoomScale {
      let tapPoint = gestureRecognizer.location(in: imageView)

      let newZoomScale = scrollView.maximumZoomScale
      let xSize = scrollView.bounds.size.width / newZoomScale
      let ySize = scrollView.bounds.size.height / newZoomScale
      let zoomRect = CGRect(
        x: tapPoint.x - xSize / 2,
        y: tapPoint.y - ySize / 2,
        width: xSize,
        height: ySize
      )

      scrollView.zoom(to: zoomRect, animated: true)
    } else {
      scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
    }
  }

  func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    imageView
  }
}

private final class LoadingIndicatorViewController: UIViewController {
  private let activityIndicator = UIActivityIndicatorView(style: .large)

  override func loadView() {
    let containerView = UIView()
    containerView.backgroundColor = .clear

    activityIndicator.color = .white
    activityIndicator.translatesAutoresizingMaskIntoConstraints = false
    containerView.addSubview(activityIndicator)
    NSLayoutConstraint.activate([
      activityIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
      activityIndicator.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
    ])

    view = containerView
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    activityIndicator.startAnimating()
  }
}

private struct SensitiveMediaThumbnail: View {
  let file: MediaFile
  let size: CGSize
  let onOpen: () -> Void
  @State private var revealed = false

  var body: some View {
    ZStack {
      WebImage(
        url: file.imageURL,
        options: [.retryFailed]
      ) { image in
        image.resizable()
      } placeholder: {
        mediaPlaceholder
      }
      .scaledToFill()
      .blur(radius: file.isSensitive && !revealed ? 18 : 0)

      if file.isSensitive && !revealed {
        Color.black.opacity(0.45)
        Image(systemName: "eye.slash")
          .font(.title3)
          .foregroundStyle(.white)
      }

    }
    .frame(width: size.width, height: size.height)
    .contentShape(RoundedRectangle(cornerRadius: Radius.md))
    .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    .overlay {
      RoundedRectangle(cornerRadius: Radius.md)
        .stroke(Color(.separator), lineWidth: 1)
    }
    .onTapGesture {
      if file.isSensitive && !revealed {
        revealed = true
      } else {
        onOpen()
      }
    }
  }

  private var mediaPlaceholder: some View {
    ZStack {
      Color.gray.opacity(0.2)
      Image(systemName: placeholderSystemImage)
        .font(.title2)
        .foregroundStyle(.secondary)
    }
  }

  private var placeholderSystemImage: String {
    switch file.kind {
    case .video:
      return "play.rectangle.fill"
    case .audio:
      return "waveform.circle.fill"
    case .image:
      return "photo"
    }
  }
}
