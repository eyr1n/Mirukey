import SwiftUI

struct ListStack<Content: View>: View {
  private let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    List {
      content
        .listRowInsets(.init())
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .buttonStyle(.bordered)
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .environment(\.defaultMinListRowHeight, 0)
  }
}
