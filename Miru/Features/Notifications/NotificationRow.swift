import MFMParser
import MFMRenderer
import MisskeyAPI
import SwiftUI

struct NotificationRow: View {
  let notification: MisskeyAPI.Notification

  var body: some View {
    switch notification {
    case .note(let payload): NoteNotificationRow(payload: payload)
    case .mention(let payload): MentionNotificationRow(payload: payload)
    case .reply(let payload): ReplyNotificationRow(payload: payload)
    case .renote(let payload): RenoteNotificationRow(payload: payload)
    case .quote(let payload): QuoteNotificationRow(payload: payload)
    case .reaction(let payload): ReactionNotificationRow(payload: payload)
    case .pollEnded(let payload): PollEndedNotificationRow(payload: payload)
    case .follow(let payload): FollowNotificationRow(payload: payload)
    case .receiveFollowRequest(let payload):
      ReceiveFollowRequestNotificationRow(payload: payload)
    case .followRequestAccepted(let payload):
      FollowRequestAcceptedNotificationRow(payload: payload)
    case .reactionGrouped(let payload):
      UnknownNotificationRow(payload: payload)
    case .renoteGrouped(let payload):
      UnknownNotificationRow(payload: payload)
    case .roleAssigned(let payload): UnknownNotificationRow(payload: payload)
    case .achievementEarned(let payload):
      UnknownNotificationRow(payload: payload)
    case .exportCompleted(let payload): UnknownNotificationRow(payload: payload)
    case .login(let payload): UnknownNotificationRow(payload: payload)
    case .sensitiveFlagAssigned(let payload):
      UnknownNotificationRow(payload: payload)
    case .createToken(let payload): UnknownNotificationRow(payload: payload)
    case .app(let payload): UnknownNotificationRow(payload: payload)
    case .test(let payload): UnknownNotificationRow(payload: payload)
    case .unknown(let payload): UnknownNotificationRow(payload: payload)
    }
  }
}

private struct NotificationUserAvatar: View {
  @Environment(AppRouter.self) private var router

  let user: MisskeyAPI.User
  let route: AppRoute

  var body: some View {
    Button {
      router.push(route: route)
    } label: {
      AvatarView(
        url: user.avatarUrl.flatMap { URL(string: $0) },
        size: 32
      )
    }
    .buttonStyle(.plain)
  }
}

private struct NotificationScaffold<Avatar: View, Title: View, Content: View>: View {
  @Environment(AppRouter.self) private var router

  @ViewBuilder let avatar: () -> Avatar
  @ViewBuilder let title: () -> Title
  let createdAt: Date
  var tapRoute: AppRoute? = nil
  @ViewBuilder let content: () -> Content

  var body: some View {
    HStack(alignment: .top, spacing: Spacing.md) {
      avatar()
      VStack(alignment: .leading, spacing: Spacing.md) {
        HStack(alignment: .top, spacing: Spacing.md) {
          title()
          Spacer()
          Text(createdAt.relativeString)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
        }
        content()
      }
    }
    .padding(.horizontal, Spacing.lg)
    .padding(.vertical, Spacing.md)
    .frame(maxWidth: .infinity, alignment: .leading)
    .contentShape(Rectangle())
    .onTapGesture {
      if let tapRoute { router.push(route: tapRoute) }
    }
  }
}

private struct UserNotificationRow<Content: View>: View {
  let user: MisskeyAPI.User
  let createdAt: Date
  var tapRoute: AppRoute? = nil
  @ViewBuilder let content: () -> Content

  var body: some View {
    NotificationScaffold(
      avatar: { NotificationUserAvatar(user: user, route: .profile(user.id)) },
      title: {
        MFMSimpleRenderer(
          nodes: MFMParser.parseSimple(user.displayName),
          emojis: user.emojis
        )
        .font(.subheadline)
        .bold()
        .lineLimit(1)
      },
      createdAt: createdAt,
      tapRoute: tapRoute,
      content: content
    )
  }
}

private struct NotificationAction: View {
  let text: LocalizedStringKey
  init(_ text: LocalizedStringKey) { self.text = text }

  var body: some View {
    Text(text).font(.subheadline)
  }
}

private struct NotificationNotePreview: View {
  let note: MisskeyAPI.Note

  var body: some View {
    let target = note.renote ?? note
    if let text = target.text?.trimmingCharacters(in: .whitespacesAndNewlines),
      !text.isEmpty
    {
      MFMSimpleRenderer(
        nodes: MFMParser.parseSimple(text),
        emojis: target.emojis
      )
      .lineLimit(3)
      .font(.caption)
      .padding(.top, Spacing.xs)
    }
  }
}

struct ReplyNotificationRow: View {
  let payload: MisskeyAPI.Notification.Reply
  var body: some View { NoteRow(note: payload.note) }
}

struct MentionNotificationRow: View {
  let payload: MisskeyAPI.Notification.Mention
  var body: some View { NoteRow(note: payload.note) }
}

struct QuoteNotificationRow: View {
  let payload: MisskeyAPI.Notification.Quote
  var body: some View { NoteRow(note: payload.note) }
}

struct NoteNotificationRow: View {
  let payload: MisskeyAPI.Notification.Note
  var body: some View {
    UserNotificationRow(
      user: payload.user,
      createdAt: payload.createdAt,
      tapRoute: .note(payload.note.id)
    ) {
      NotificationAction("posted")
      NotificationNotePreview(note: payload.note)
    }
  }
}

struct RenoteNotificationRow: View {
  let payload: MisskeyAPI.Notification.Renote
  var body: some View {
    UserNotificationRow(
      user: payload.user,
      createdAt: payload.createdAt,
      tapRoute: .note(payload.note.id)
    ) {
      NotificationAction("renoted")
      NotificationNotePreview(note: payload.note)
    }
  }
}

struct PollEndedNotificationRow: View {
  let payload: MisskeyAPI.Notification.PollEnded
  var body: some View {
    UserNotificationRow(
      user: payload.user,
      createdAt: payload.createdAt,
      tapRoute: .note(payload.note.id)
    ) {
      NotificationAction("poll ended")
      NotificationNotePreview(note: payload.note)
    }
  }
}

struct ReactionNotificationRow: View {
  @Environment(Session.self) private var session
  let payload: MisskeyAPI.Notification.Reaction

  var body: some View {
    UserNotificationRow(
      user: payload.user,
      createdAt: payload.createdAt,
      tapRoute: .note(payload.note.id)
    ) {
      let reaction = Reaction(payload.reaction).resolvingURL(
        emojiURL: { session.emojiURL(name: $0) },
        noteEmojiURLs: payload.note.reactionEmojis
      )
      HStack(alignment: .center, spacing: Spacing.sm) {
        Text("reacted")
        EmojiImage(
          url: reaction.url,
          alt: reaction.name,
          height: 20
        )
      }
      .font(.subheadline)
      NotificationNotePreview(note: payload.note)
    }
  }
}

struct FollowNotificationRow: View {
  let payload: MisskeyAPI.Notification.Follow
  var body: some View {
    UserNotificationRow(
      user: payload.user,
      createdAt: payload.createdAt,
      tapRoute: .profile(payload.user.id)
    ) {
      NotificationAction("followed you")
    }
  }
}

struct ReceiveFollowRequestNotificationRow: View {
  let payload: MisskeyAPI.Notification.ReceiveFollowRequest
  var body: some View {
    UserNotificationRow(
      user: payload.user,
      createdAt: payload.createdAt,
      tapRoute: .profile(payload.user.id)
    ) {
      NotificationAction("requested to follow you")
    }
  }
}

struct FollowRequestAcceptedNotificationRow: View {
  let payload: MisskeyAPI.Notification.FollowRequestAccepted
  var body: some View {
    UserNotificationRow(
      user: payload.user,
      createdAt: payload.createdAt,
      tapRoute: .profile(payload.user.id)
    ) {
      NotificationAction("accepted your follow request")
    }
  }
}

struct UnknownNotificationRow: View {
  let payload: any MisskeyAPI.Notification.Payload
  var body: some View {
    NotificationScaffold(
      avatar: { AvatarView(url: nil, size: 32) },
      title: {
        Text(payload.type)
          .font(.subheadline.bold())
          .lineLimit(1)
      },
      createdAt: payload.createdAt,
      content: { EmptyView() }
    )
  }
}
