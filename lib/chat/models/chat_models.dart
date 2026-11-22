import 'package:flutter/material.dart';

import '../chat_texts.dart';

/// 지원하는 채팅 메시지 타입.
enum ChatMessageType {
  text,
  image,
  video,
}

/// 답장 대상 원본 메시지 요약 정보.
class ReplyReference {
  final String messageId;
  final String senderId;
  final String senderName;
  final ChatMessageType type;
  final String textPreview;
  final String? mediaUrl;
  final String? mediaTitle;
  final Color? mediaAccentColor;

  const ReplyReference({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    required this.type,
    required this.textPreview,
    this.mediaUrl,
    this.mediaTitle,
    this.mediaAccentColor,
  });

  factory ReplyReference.fromMessage(ChatMessage message) {
    final preview = switch (message.type) {
      ChatMessageType.text => message.text,
      ChatMessageType.image =>
        message.text.isNotEmpty ? message.text : ChatTexts.mediaPhoto,
      ChatMessageType.video =>
        message.text.isNotEmpty ? message.text : ChatTexts.mediaVideo,
    };
    return ReplyReference(
      messageId: message.id,
      senderId: message.senderId,
      senderName: message.senderName,
      type: message.type,
      textPreview: preview,
      mediaUrl: message.mediaUrl,
      mediaTitle: message.mediaTitle,
      mediaAccentColor: message.mediaAccentColor,
    );
  }
}

/// 개별 채팅 메시지 모델.
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final Color senderAvatarColor;
  final ChatMessageType type;
  final String text;
  final String? mediaUrl;
  final String? mediaTitle;
  final String? mediaDuration;
  final Color? mediaAccentColor;
  final DateTime sentAt;
  final ReplyReference? replyTo;
  final List<String> readBy;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderAvatarColor,
    required this.type,
    required this.text,
    required this.sentAt,
    this.mediaUrl,
    this.mediaTitle,
    this.mediaDuration,
    this.mediaAccentColor,
    this.replyTo,
    this.readBy = const [],
  });

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    Color? senderAvatarColor,
    ChatMessageType? type,
    String? text,
    String? mediaUrl,
    String? mediaTitle,
    String? mediaDuration,
    Color? mediaAccentColor,
    DateTime? sentAt,
    ReplyReference? replyTo,
    List<String>? readBy,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatarColor: senderAvatarColor ?? this.senderAvatarColor,
      type: type ?? this.type,
      text: text ?? this.text,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaTitle: mediaTitle ?? this.mediaTitle,
      mediaDuration: mediaDuration ?? this.mediaDuration,
      mediaAccentColor: mediaAccentColor ?? this.mediaAccentColor,
      sentAt: sentAt ?? this.sentAt,
      replyTo: replyTo ?? this.replyTo,
      readBy: readBy ?? this.readBy,
    );
  }

  /// 채팅 목록 미리보기 문구.
  String get summaryText {
    return switch (type) {
      ChatMessageType.text => text,
      ChatMessageType.image => ChatTexts.photoSummary(text),
      ChatMessageType.video => ChatTexts.videoSummary(text),
    };
  }

  /// 읽음 상태 표시 문자열.
  String get readStatusText {
    if (readBy.isEmpty) return ChatTexts.unreadStatus;
    return readBy.map(ChatTexts.readByUser).join(', ');
  }
}

/// 채팅방 모델 (1:1 또는 모임 그룹 채팅).
class ChatRoom {
  final String id;
  final String title;
  final bool isGroup;
  final Color avatarColor;
  final IconData avatarIcon;
  final int unreadCount;
  final bool isPinned;
  final DateTime? pinnedAt;
  final List<ChatMessage> messages;

  const ChatRoom({
    required this.id,
    required this.title,
    required this.isGroup,
    required this.avatarColor,
    required this.avatarIcon,
    required this.messages,
    this.unreadCount = 0,
    this.isPinned = false,
    this.pinnedAt,
  });

  bool get hasUnread => unreadCount > 0;

  ChatMessage? get lastMessage => messages.isEmpty ? null : messages.last;

  String get lastMessagePreview =>
      lastMessage?.summaryText ?? ChatTexts.noMessagesYet;

  DateTime get lastMessageAt =>
      lastMessage?.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  ChatRoom copyWith({
    String? id,
    String? title,
    bool? isGroup,
    Color? avatarColor,
    IconData? avatarIcon,
    int? unreadCount,
    bool? isPinned,
    DateTime? pinnedAt,
    bool clearPinnedAt = false,
    List<ChatMessage>? messages,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      title: title ?? this.title,
      isGroup: isGroup ?? this.isGroup,
      avatarColor: avatarColor ?? this.avatarColor,
      avatarIcon: avatarIcon ?? this.avatarIcon,
      unreadCount: unreadCount ?? this.unreadCount,
      isPinned: isPinned ?? this.isPinned,
      pinnedAt: clearPinnedAt ? null : (pinnedAt ?? this.pinnedAt),
      messages: messages ?? this.messages,
    );
  }
}
