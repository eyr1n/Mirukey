import Foundation
import MisskeyAPI

enum NoteVisibility: String, Codable, CaseIterable, Identifiable {
  case `public`
  case home
  case followers
  case specified

  var id: String { rawValue }

  var title: String {
    switch self {
    case .public: return String(localized: "Public")
    case .home: return String(localized: "Home")
    case .followers: return String(localized: "Followers")
    case .specified: return String(localized: "Specified")
    }
  }

  var apiValue: MisskeyAPI.NotesCreateRequest.Visibility {
    switch self {
    case .public:
      return .public
    case .home:
      return .home
    case .followers:
      return .followers
    case .specified:
      return .specified
    }
  }

  init(apiValue: MisskeyAPI.NotesCreateRequest.Visibility) {
    self = NoteVisibility(rawValue: apiValue.rawValue) ?? .public
  }
}
