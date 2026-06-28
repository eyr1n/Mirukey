import SwiftUI

struct LoadingListRow: View {
  var body: some View {
    HStack {
      Spacer()
      ActivityIndicator()
      Spacer()
    }
    .frame(minHeight: 48)
  }
}
