import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_theme.dart';
import '../models/chat_models.dart';
import 'chat_avatar.dart';
import 'media_message_card.dart';
import 'reply_preview.dart';

/// 개별 메시지 행 위젯:
/// - 내 메시지(우측, 파랑) vs 상대 메시지(좌측, 회색)
/// - 연속 메시지 그룹핑 (프로필 아바타 & 모임 발신자 ID 1회만 표시)
/// - 텍스트/사진/동영상 렌더링
/// - 답장 프리뷰 표시 및 원본 점프 + 1초 하이라이트
/// - 길게 누르기(LongPress) 및 스와이프로 답장 대상 지정
/// - 읽음/읽지 않음 1줄 말줄임 표시
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.isGroup,
    required this.isFirstInGroup,
    required this.isLastInGroup,
    required this.showReadStatus,
    required this.isHighlighted,
    required this.onReply,
    required this.onTapReplyReference,
  });

  final ChatMessage message;
  final bool isMe;
  final bool isGroup;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final bool showReadStatus;
  final bool isHighlighted;
  final VoidCallback onReply;
  final ValueChanged<String> onTapReplyReference;

  static const double _avatarSize = 34;
  static const double _avatarGap = 8;

  void _triggerReply() {
    HapticFeedback.lightImpact();
    onReply();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxBubbleWidth = screenWidth * 0.70;

    return Dismissible(
      key: ValueKey('swipe_${message.id}'),
      direction:
          isMe ? DismissDirection.endToStart : DismissDirection.startToEnd,
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.18,
        DismissDirection.endToStart: 0.18,
      },
      confirmDismiss: (_) async {
        _triggerReply();
        return false;
      },
      background: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.blueBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.reply_rounded,
              size: 18,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        margin: EdgeInsets.only(
          top: isFirstInGroup ? 8 : 3,
          bottom: showReadStatus ? 6 : 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
        decoration: BoxDecoration(
          color: isHighlighted ? AppColors.blueBg : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // 모임(그룹) 채팅: 상대방 연속 메시지 중 첫 번째에만 발신자 ID 표시
            if (!isMe && isGroup && isFirstInGroup)
              Padding(
                padding: const EdgeInsets.only(
                  left: _avatarSize + _avatarGap + 4,
                  bottom: 4,
                ),
                child: Text(
                  message.senderName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            // 답장 원본 프리뷰 (답장 메시지인 경우)
            if (message.replyTo != null)
              Padding(
                padding: EdgeInsets.only(
                  left: isMe ? 0 : _avatarSize + _avatarGap,
                ),
                child: MessageReplyReference(
                  reply: message.replyTo!,
                  isMe: isMe,
                  maxWidth: maxBubbleWidth,
                  onTap: () => onTapReplyReference(message.replyTo!.messageId),
                ),
              ),
            // 본문 행 (프로필 아바타 + 말풍선/미디어)
            Row(
              mainAxisAlignment:
                  isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isMe) ...[
                  if (isLastInGroup)
                    ChatAvatar(
                      color: message.senderAvatarColor,
                      icon: Icons.person_rounded,
                      size: _avatarSize,
                    )
                  else
                    const SizedBox(width: _avatarSize),
                  const SizedBox(width: _avatarGap),
                ],
                GestureDetector(
                  onLongPress: _triggerReply,
                  child: _buildContent(maxBubbleWidth),
                ),
              ],
            ),
            // 읽음 / 읽지 않음 상태 (긴 목록은 1줄 말줄임 처리)
            if (showReadStatus)
              Padding(
                padding: EdgeInsets.only(
                  top: 4,
                  left: isMe ? 32 : _avatarSize + _avatarGap + 4,
                  right: isMe ? 4 : 32,
                ),
                child: Text(
                  message.readStatusText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: isMe ? TextAlign.right : TextAlign.left,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(double maxBubbleWidth) {
    if (message.type == ChatMessageType.image ||
        message.type == ChatMessageType.video) {
      return MediaMessageCard(
        message: message,
        maxWidth: maxBubbleWidth,
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxBubbleWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            fontSize: 14.5,
            height: 1.38,
            color: isMe ? Colors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }
}
