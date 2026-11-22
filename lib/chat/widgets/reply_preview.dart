import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../chat_texts.dart';
import '../models/chat_models.dart';
import 'media_message_card.dart';

/// 답장 메시지 상단에 표시되는 원본 참조 프리뷰.
/// 탭하면 [onTap]이 호출되어 원본 메시지로 스크롤 및 하이라이트 이동한다.
class MessageReplyReference extends StatelessWidget {
  const MessageReplyReference({
    super.key,
    required this.reply,
    required this.isMe,
    required this.maxWidth,
    required this.onTap,
  });

  final ReplyReference reply;
  final bool isMe;
  final double maxWidth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isMedia = reply.type != ChatMessageType.text;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Text(
              ChatTexts.repliedNotice,
              style: TextStyle(
                fontSize: 11.5,
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: IntrinsicHeight(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 좌측 세로선 (|)
                  Container(
                    width: 3,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: isMedia
                        ? _MediaReplyPreview(reply: reply)
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              reply.textPreview,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                                height: 1.3,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
        ],
      ),
    );
  }
}

class _MediaReplyPreview extends StatelessWidget {
  const _MediaReplyPreview({required this.reply});

  final ReplyReference reply;

  @override
  Widget build(BuildContext context) {
    final label = reply.type == ChatMessageType.video
        ? ChatTexts.mediaVideo
        : ChatTexts.mediaPhoto;
    final detail = reply.mediaTitle ?? reply.textPreview;

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MediaMiniThumbnail(
            type: reply.type,
            mediaUrl: reply.mediaUrl,
            accentColor: reply.mediaAccentColor,
            size: 40,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkSub,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 하단 입력창 위에 표시되는 '답장 작성 중' 배너.
class ReplyComposerBanner extends StatelessWidget {
  const ReplyComposerBanner({
    super.key,
    required this.target,
    required this.onCancel,
  });

  final ChatMessage target;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final isMedia = target.type != ChatMessageType.text;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          if (isMedia) ...[
            MediaMiniThumbnail(
              type: target.type,
              mediaUrl: target.mediaUrl,
              accentColor: target.mediaAccentColor,
              size: 36,
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ChatTexts.replyingTo(target.senderName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  target.mediaTitle ?? target.summaryText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCancel,
            tooltip: ChatTexts.tooltipCancelReply,
            icon: const Icon(
              Icons.close_rounded,
              size: 20,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}
