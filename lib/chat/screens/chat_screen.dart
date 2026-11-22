import 'dart:async';

import 'package:flutter/material.dart';
//이게 왜 deprecated 되었는지 모르겠음. 일단은 경고 무시하고 사용함.

import '../../app/app_theme.dart';
import '../chat_repository.dart';
import '../chat_texts.dart';
import '../models/chat_models.dart';
import '../utils/time_formatter.dart';
import '../widgets/chat_avatar.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/message_bubble.dart';
import 'chat_repo_screen.dart';

/// 소모임 등 외부 화면의 주석 인터페이스(`ChatRoomScreen`)와도 호환되는 별칭.
typedef ChatRoomScreen = ChatScreen;

/// 화면 2: 개별 채팅방 화면.
///
/// - [room] 또는 [roomId]가 전달되면 해당 개별 채팅방을 표시한다.
/// - 파라미터 없이 `const ChatScreen()`으로 호출되면(예: 더보기 탭 / 알림함)
///   채팅방 목록([ChatRepoScreen])으로 자연스럽게 진입한다.
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key, this.room, this.roomId, this.roomTitle});

  final ChatRoom? room;
  final String? roomId;
  final String? roomTitle;

  @override
  Widget build(BuildContext context) {
    final targetId = room?.id ?? roomId;
    if (targetId == null) {
      return const ChatRepoScreen();
    }

    return _ChatRoomView(
      roomId: targetId,
      fallbackTitle: room?.title ?? roomTitle ?? ChatTexts.defaultRoomTitle,
    );
  }
}

class _ChatRoomView extends StatefulWidget {
  const _ChatRoomView({required this.roomId, required this.fallbackTitle});

  final String roomId;
  final String fallbackTitle;

  @override
  State<_ChatRoomView> createState() => _ChatRoomViewState();
}

class _ChatRoomViewState extends State<_ChatRoomView> {
  final _repo = ChatRepository.instance;
  final _scrollController = ScrollController();
  final Map<String, GlobalKey> _messageKeys = {};

  ChatMessage? _replyingTo;
  String? _highlightedMessageId;
  Timer? _highlightTimer;

  @override
  void initState() {
    super.initState();
    _repo.getOrCreateRoom(
      roomId: widget.roomId,
      roomTitle: widget.fallbackTitle,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _repo.markRoomAsRead(widget.roomId);
      _scrollToBottom(animated: false);
    });
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  GlobalKey _keyForMessage(String messageId) {
    return _messageKeys.putIfAbsent(messageId, GlobalKey.new);
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    final target = _scrollController.position.maxScrollExtent;
    if (animated) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(target);
    }
  }

  void _handleTogglePin(ChatRoom room) {
    final willPin = !room.isPinned;
    _repo.togglePin(room.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            willPin ? ChatTexts.snackPinned : ChatTexts.snackUnpinned,
          ),
          duration: const Duration(milliseconds: 1400),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _handleSelectReply(ChatMessage message) {
    setState(() => _replyingTo = message);
  }

  void _handleJumpToOriginal(String targetMessageId) {
    final targetContext = _messageKeys[targetMessageId]?.currentContext;
    if (targetContext == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(ChatTexts.snackOriginalNotFound),
            duration: Duration(milliseconds: 1400),
          ),
        );
      return;
    }

    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      alignment: 0.35,
    );

    _highlightTimer?.cancel();
    setState(() => _highlightedMessageId = targetMessageId);
    _highlightTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _highlightedMessageId = null);
      }
    });
  }

  void _handleSendText(String text) {
    final replyRef = _replyingTo == null
        ? null
        : ReplyReference.fromMessage(_replyingTo!);
    _repo.sendMessage(
      roomId: widget.roomId,
      type: ChatMessageType.text,
      text: text,
      replyTo: replyRef,
    );
    setState(() => _replyingTo = null);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _handleSendMedia(MockMediaDraft draft) {
    final replyRef = _replyingTo == null
        ? null
        : ReplyReference.fromMessage(_replyingTo!);
    _repo.sendMessage(
      roomId: widget.roomId,
      type: draft.type,
      text: '',
      replyTo: replyRef,
      mediaTitle: draft.title,
      mediaDuration: draft.duration,
      mediaAccentColor: draft.accentColor,
    );
    setState(() => _replyingTo = null);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _repo,
      builder: (context, _) {
        final room =
            _repo.findRoomById(widget.roomId) ??
            _repo.getOrCreateRoom(
              roomId: widget.roomId,
              roomTitle: widget.fallbackTitle,
            );
        final messages = room.messages;

        // 내가 보낸 가장 최근 메시지 인덱스 (읽음/읽지 않음 표시 기준)
        var lastMyMessageIndex = -1;
        for (var i = messages.length - 1; i >= 0; i--) {
          if (messages[i].senderId == _repo.myUserId) {
            lastMyMessageIndex = i;
            break;
          }
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0.5,
            leadingWidth: 44,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              tooltip: ChatTexts.tooltipBack,
              icon: const Icon(
                Icons.chevron_left_rounded,
                size: 30,
                color: AppColors.ink,
              ),
            ),
            titleSpacing: 4,
            title: Row(
              children: [
                ChatAvatar(
                  color: room.avatarColor,
                  icon: room.avatarIcon,
                  size: 34,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    room.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () => _handleTogglePin(room),
                tooltip:
                    room.isPinned ? ChatTexts.tooltipUnpin : ChatTexts.tooltipPin,
                icon: Icon(
                  room.isPinned
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 27,
                  color: room.isPinned ? AppColors.accent : AppColors.inkSub,
                ),
              ),
              const SizedBox(width: 4),
            ],
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  behavior: HitTestBehavior.translucent,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: List.generate(messages.length, (i) {
                        final msg = messages[i];
                        final prev = i > 0 ? messages[i - 1] : null;
                        final next = i < messages.length - 1
                            ? messages[i + 1]
                            : null;

                        final showDivider =
                            ChatTimeFormatter.shouldShowDateDivider(
                              prev?.sentAt,
                              msg.sentAt,
                            );
                        final nextHasDivider =
                            next != null &&
                            ChatTimeFormatter.shouldShowDateDivider(
                              msg.sentAt,
                              next.sentAt,
                            );

                        final sameSenderAsPrev =
                            prev != null &&
                            prev.senderId == msg.senderId &&
                            !showDivider;
                        final sameSenderAsNext =
                            next != null &&
                            next.senderId == msg.senderId &&
                            !nextHasDivider;

                        final isMe = msg.senderId == _repo.myUserId;

                        return Column(
                          key: _keyForMessage(msg.id),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (showDivider)
                              _DateDivider(
                                label: ChatTimeFormatter.formatDateDivider(
                                  msg.sentAt,
                                ),
                              ),
                            MessageBubble(
                              message: msg,
                              isMe: isMe,
                              isGroup: room.isGroup,
                              isFirstInGroup: !sameSenderAsPrev,
                              isLastInGroup: !sameSenderAsNext,
                              showReadStatus: isMe && i == lastMyMessageIndex,
                              isHighlighted: _highlightedMessageId == msg.id,
                              onReply: () => _handleSelectReply(msg),
                              onTapReplyReference: _handleJumpToOriginal,
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ),
              ChatInputBar(
                replyingTo: _replyingTo,
                onCancelReply: () => setState(() => _replyingTo = null),
                onSendText: _handleSendText,
                onSendMedia: _handleSendMedia,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.inkSub,
            ),
          ),
        ),
      ),
    );
  }
}
