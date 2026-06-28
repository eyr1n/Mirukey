import SDWebImageSwiftUI
import SwiftUI

struct EmojiImage: View {
  @State private var aspect: CGFloat = 1

  let url: URL?
  let alt: String
  var height: CGFloat = 28

  var body: some View {
    if let url {
      AnimatedImage(url: url)
        .onSuccess { image, _, _ in
          let newAspect = image.size.width / image.size.height
          Task { @MainActor in
            if newAspect != aspect { aspect = newAspect }
          }
        }
        .resizable()
        .aspectRatio(aspect, contentMode: .fit)
        .frame(
          idealWidth: height * aspect,
          maxWidth: height * aspect,
          idealHeight: height,
          maxHeight: height
        )
    } else {
      Text(alt)
        .font(.system(size: height))
        .frame(height: height)
    }
  }
}
