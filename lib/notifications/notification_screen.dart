import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../chat/chat_screen.dart';
import '../club/club_screen.dart';
import '../lost_found/lost_found_screen.dart';
import '../schedule/schedule_screen.dart';
import 'notification_center.dart';

/// 알림함 화면. 열면 모든 알림을 읽음 처리하고, 이번에 새로 온 알림은 강조해서 보여준다.
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _center = NotificationCenter.instance;
  late final Set<String> _newIds;

  @override
  void initState() {
    super.initState();
    _newIds = _center.items.where(_center.isUnread).map((n) => n.id).toSet();
    _center.markAllRead();
  }

  void _open(AppNotification n) {
    final Widget screen = switch (n.type) {
      NotificationType.club => const ClubScreen(),
      NotificationType.clubJoin => const ClubScreen(),
      NotificationType.lostFound => const LostFoundScreen(),
      NotificationType.chat => const ChatScreen(),
      NotificationType.schedule => const ScheduleScreen(),
    };
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알림', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListenableBuilder(
        listenable: _center,
        builder: (context, _) {
          final items = _center.items;
          if (items.isEmpty) return const _EmptyState();
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _NotificationTile(
              notification: items[i],
              isNew: _newIds.contains(items[i].id),
              onTap: () => _open(items[i]),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.isNew,
    required this.onTap,
  });

  final AppNotification notification;
  final bool isNew;
  final VoidCallback onTap;

  static (IconData, Color, Color) _style(NotificationType type) {
    return switch (type) {
      NotificationType.club =>
        (Icons.groups_rounded, AppColors.greenSub, AppColors.greenBg),
      NotificationType.clubJoin =>
        (Icons.person_add_alt_1_rounded, AppColors.greenSub, AppColors.greenBg),
      NotificationType.lostFound =>
        (Icons.search_rounded, AppColors.redIcon, AppColors.redBg),
      NotificationType.chat =>
        (Icons.chat_bubble_rounded, AppColors.primary, AppColors.blueBg),
      NotificationType.schedule =>
        (Icons.event_note_rounded, AppColors.ink, const Color(0xFFFFF7D6)),
    };
  }

  static String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return '방금';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }

  @override
  Widget build(BuildContext context) {
    final (icon, fg, bg) = _style(notification.type);
    final timeText = notification.type == NotificationType.schedule
        ? '오늘'
        : _timeAgo(notification.createdAt);

    return Material(
      color: isNew ? const Color(0xFFEFF4FC) : const Color(0xFFF5F6F8),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: fg, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(notification.title,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink)),
                        ),
                        Text(timeText,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.inkSub)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(notification.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.inkSub)),
                  ],
                ),
              ),
              if (isNew) ...[
                const SizedBox(width: 8),
                Semantics(
                  label: '새 알림',
                  child: Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none_rounded,
                size: 56, color: Color(0xFF9CA3AF)),
            SizedBox(height: 12),
            Text('새 알림이 없어요',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink)),
            SizedBox(height: 6),
            Text(
              '새 소모임·분실물 글, 나에게 온 채팅이 여기에 모여요.\n'
              '일정 탭에서 종 버튼을 누르면 하루 전에 알려드려요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.inkSub, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
