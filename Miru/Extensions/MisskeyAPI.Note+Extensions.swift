import MisskeyAPI

extension MisskeyAPI.Note {
  var displayNote: MisskeyAPI.Note {
    if isPureRenote, let renote = renote {
      return renote
    }
    return self
  }

  var isPureRenote: Bool {
    renoteId != nil
      && replyId == nil
      && text == nil
      && cw == nil
      && (fileIds ?? []).isEmpty
      && poll == nil
  }

  var isQuote: Bool {
    renote != nil && !isPureRenote
  }

  func matches(id: String) -> Bool {
    self.id == id || displayNote.id == id
  }
}
