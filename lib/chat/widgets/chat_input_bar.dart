import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../chat_texts.dart';
import '../models/chat_models.dart';
import 'reply_preview.dart';

/// Mock 미디어 첨부 프리셋 모델.
class MockMediaDraft {
  final ChatMessageType type;
  final String title;
  final String? duration;
  final Color accentColor;

  const MockMediaDraft({
    required this.type,
    required this.title,
    required this.accentColor,
    this.duration,
  });
}

/// 채팅방 하단 알약형 입력창 + 사진/동영상 첨부 + 전송 버튼.
class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.onSendText,
    required this.onSendMedia,
    this.replyingTo,
    this.onCancelReply,
  });

  final ValueChanged<String> onSendText;
  final ValueChanged<MockMediaDraft> onSendMedia;
  final ChatMessage? replyingTo;
  final VoidCallback? onCancelReply;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  bool _hasText = false;

  static const _mockMediaPresets = <MockMediaDraft>[
    MockMediaDraft(
      type: ChatMessageType.image,
      title: '한밭대 정문 캠퍼스 사진',
      accentColor: AppColors.primary,
    ),
    MockMediaDraft(
      type: ChatMessageType.image,
      title: '오늘 학식 메뉴 사진',
      accentColor: AppColors.fire,
    ),
    MockMediaDraft(
      type: ChatMessageType.video,
      title: '대운동장 풋살 하이라이트.mp4',
      duration: '0:18',
      accentColor: AppColors.greenSub,
    ),
    MockMediaDraft(
      type: ChatMessageType.video,
      title: '강의실 발표 리허설.mp4',
      duration: '1:05',
      accentColor: AppColors.blueInk,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleTextChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChange);
    _controller.dispose();
    super.dispose();
  }

  void _handleTextChange() {
    final next = _controller.text.trim().isNotEmpty;
    if (next != _hasText) {
      setState(() => _hasText = next);
    }
  }

  void _submitText() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSendText(text);
    _controller.clear();
  }

  void _openMediaSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  ChatTexts.attachSheetTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  ChatTexts.attachSheetSubtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.inkSub,
                  ),
                ),
                const SizedBox(height: 12),
                ..._mockMediaPresets.map((preset) {
                  final isVideo = preset.type == ChatMessageType.video;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: preset.accentColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isVideo
                            ? Icons.play_circle_outline_rounded
                            : Icons.photo_outlined,
                        color: preset.accentColor,
                      ),
                    ),
                    title: Text(
                      preset.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    subtitle: Text(
                      isVideo
                          ? ChatTexts.videoDurationLabel(preset.duration ?? '')
                          : ChatTexts.mediaPhoto,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.inkSub,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.send_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      widget.onSendMedia(preset);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.replyingTo != null)
              ReplyComposerBanner(
                target: widget.replyingTo!,
                onCancel: widget.onCancelReply ?? () {},
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 4, 6, 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _submitText(),
                        style: const TextStyle(
                          fontSize: 14.5,
                          color: AppColors.ink,
                        ),
                        decoration: const InputDecoration(
                          hintText: ChatTexts.inputHint,
                          hintStyle: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 14.5,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: _openMediaSheet,
                      tooltip: ChatTexts.tooltipAttachMedia,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 38,
                        minHeight: 38,
                      ),
                      icon: const Icon(
                        Icons.photo_outlined,
                        color: AppColors.inkSub,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Material(
                        color: _hasText
                            ? AppColors.primary
                            : const Color(0xFFD1D5DB),
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: _hasText ? _submitText : null,
                          child: const SizedBox(
                            width: 36,
                            height: 36,
                            child: Icon(
                              Icons.arrow_upward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
