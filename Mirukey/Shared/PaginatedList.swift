import SwiftUI

struct PaginatedList<Element: Identifiable, Row: View>: View
where Element.ID == String {
  let paginator: Paginator<Element>
  let fetch: Paginator<Element>.Fetch
  @ViewBuilder let row: (Element) -> Row

  var body: some View {
    ForEach(paginator.items) { element in
      row(element)
    }
    switch paginator.state {
    case .ready, .loading:
      LoadingListRow()
        .id(paginator.id)
        .onAppear { loadNext() }
    case .failed, .end:
      EmptyView()
    }
  }

  private func loadNext() {
    Task { try? await paginator.loadNext(fetch) }
  }
}
