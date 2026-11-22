import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../chat_repository.dart';
import '../chat_texts.dart';
import '../models/chat_models.dart';
import '../utils/time_formatter.dart';
import '../widgets/chat_avatar.dart';
import 'chat_screen.dart';

enum _ChatFilter { all, unread }

/// 화면 1: 채팅방 목록 화면 (진입점).
class ChatRepoScreen extends StatefulWidget {
  const ChatRepoScreen({super.key});

  @override
  State<ChatRepoScreen> createState() => _ChatRepoScreenState();
}

class _ChatRepoScreenState extends State<ChatRepoScreen> {
  final _repo = ChatRepository.instance;
  _ChatFilter _filter = _ChatFilter.all;

  void _openRoom(ChatRoom room) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatScreen(room: room)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: Navigator.canPop(context) ? 0 : 20,
        title: const Text(
          ChatTexts.repoTitle,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: _repo,
        builder: (context, _) {
          final rooms = _repo.getRooms(
            unreadOnly: _filter == _ChatFilter.unread,
          );
          final unreadCount = _repo.totalUnreadRoomCount;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 필터 칩 영역: [전체] [읽지 않음]
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                child: Row(
                  children: [
                    _FilterPill(
                      label: ChatTexts.filterAll,
                      selected: _filter == _ChatFilter.all,
                      onTap: () => setState(() => _filter = _ChatFilter.all),
                    ),
                    const SizedBox(width: 8),
                    _FilterPill(
                      label: ChatTexts.filterUnread,
                      badgeCount: unreadCount,
                      selected: _filter == _ChatFilter.unread,
                      onTap: () => setState(() => _filter = _ChatFilter.unread),
                    ),
                  ],
                ),
              ),
              // 내 프로필 영역 (리스트 최상단 고정 · 터치 시 동작 없음)
              _MyProfileHeader(
                myId: _repo.myUserId,
                avatarColor: _repo.myAvatarColor,
              ),
              const Divider(
                height: 1,
                thickness: 1,
                indent: 20,
                endIndent: 20,
                color: Color(0xFFF3F4F6),
              ),
              // 채팅방 목록
              Expanded(
                child: rooms.isEmpty
                    ? _EmptyRoomState(
                        isUnreadFilter: _filter == _ChatFilter.unread,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemCount: rooms.length,
                        separatorBuilder: (_, _) => const Divider(
                          height: 1,
                          thickness: 1,
                          indent: 78,
                          endIndent: 20,
                          color: Color(0xFFF3F4F6),
                        ),
                        itemBuilder: (context, index) {
                          final room = rooms[index];
                          return _ChatRoomTile(
                            room: room,
                            onTap: () => _openRoom(room),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.ink : const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? Colors.white : AppColors.inkSub,
                ),
              ),
              if (badgeCount > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.accent : AppColors.blueBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: selected ? AppColors.onAccent : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 리스트 최상단 고정 내 프로필 영역 (단순 표시용 · 터치 동작 없음).
class _MyProfileHeader extends StatelessWidget {
  const _MyProfileHeader({required this.myId, required this.avatarColor});

  final String myId;
  final Color avatarColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 16, 14),
      child: Row(
        children: [
          ChatAvatar(color: avatarColor, icon: Icons.person_rounded, size: 48),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              myId,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            ChatTexts.meLabel,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.inkSub,
            ),
          ),
          const SizedBox(width: 2),
          const Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: Color(0xFF9CA3AF),
          ),
        ],
      ),
    );
  }
}

class _ChatRoomTile extends StatelessWidget {
  const _ChatRoomTile({required this.room, required this.onTap});

  final ChatRoom room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final relativeTime = ChatTimeFormatter.formatRelativeTime(
      room.lastMessageAt,
    );
    final unread = room.hasUnread;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            ChatAvatar(
              color: room.avatarColor,
              icon: room.avatarIcon,
              size: 48,
              showPinBadge: room.isPinned,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          room.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: unread
                                ? FontWeight.w800
                                : FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      if (unread) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    room.lastMessagePreview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                      color: unread ? AppColors.ink : AppColors.inkSub,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  relativeTime,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                    color: unread ? AppColors.primary : AppColors.inkSub,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Color(0xFF9CA3AF),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRoomState extends StatelessWidget {
  const _EmptyRoomState({required this.isUnreadFilter});

  final bool isUnreadFilter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isUnreadFilter
                  ? Icons.mark_chat_read_outlined
                  : Icons.chat_bubble_outline_rounded,
              size: 48,
              color: const Color(0xFFD1D5DB),
            ),
            const SizedBox(height: 12),
            Text(
              isUnreadFilter
                  ? ChatTexts.emptyUnreadTitle
                  : ChatTexts.emptyRoomTitle,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isUnreadFilter
                  ? ChatTexts.emptyUnreadSubtitle
                  : ChatTexts.emptyRoomSubtitle,
              style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ),
    );
  }
}
