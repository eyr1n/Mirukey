import SDWebImageSwiftUI
import SwiftUI

struct AvatarView: View {
  let url: URL?
  let size: CGFloat

  var body: some View {
    ZStack {
      Color(.secondarySystemBackground)
      if let url {
        AnimatedImage(url: url)
          .resizable()
          .scaledToFill()
      }
    }
    .frame(width: size, height: size)
    .clipShape(Circle())
    .overlay {
      Circle()
        .stroke(Color(.separator), lineWidth: 1)
    }
  }
}
