import APIKit
import Foundation

@MainActor
@Observable
final class Paginator<Element: Identifiable>: Identifiable
where Element.ID == String {
  typealias Fetch = (_ limit: Int, _ untilId: String?) async throws -> [Element]

  enum State {
    case ready
    case loading
    case failed
    case end
  }

  private(set) var items: [Element] = []
  private(set) var state: State = .ready
  private(set) var id = 0
  private var generation = 0

  let limit: Int

  init(limit: Int) {
    self.limit = limit
  }

  func load(untilId: Element.ID? = nil, _ fetch: Fetch) async throws {
    generation &+= 1
    let token = generation
    state = .loading
    do {
      let loaded = try await fetch(limit, untilId)
      guard token == generation else { return }
      items = untilId == nil ? loaded : items + loaded
      state = loaded.isEmpty ? .end : .ready
      id &+= 1
    } catch {
      guard token == generation else { return }
      if error.isCancellation {
        state = .ready
        return
      }
      state = .failed
      id &+= 1
      throw error
    }
  }

  func refresh(_ fetch: Fetch) async throws {
    try await load(untilId: nil, fetch)
  }

  func loadNext(_ fetch: Fetch) async throws {
    guard state == .ready || state == .failed else { return }
    try await load(untilId: items.last?.id, fetch)
  }

  func remove(id: Element.ID) {
    items.removeAll { $0.id == id }
  }

  func prepend(_ item: Element) {
    items.insert(item, at: 0)
  }
}
