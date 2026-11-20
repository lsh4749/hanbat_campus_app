import 'package:flutter/material.dart';

import '../club.dart';

Color clubCategoryColor(String category) {
  switch (category) {
    case '운동':
      return Colors.green;
    case '게임':
      return Colors.deepPurple;
    case '스터디':
      return Colors.blue;
    case '자유':
      return Colors.orange;
    default:
      return Colors.grey;
  }
}

/// 작은 색상 배지 (카테고리, 모집 상태 표시에 사용)
class ClubBadge extends StatelessWidget {
  const ClubBadge({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// 소모임 목록의 카드 한 장. 버튼 동작은 화면에서 콜백으로 받는다.
class ClubCard extends StatelessWidget {
  const ClubCard({
    super.key,
    required this.club,
    required this.uid,
    required this.onJoin,
    required this.onLeave,
    required this.onToggleClose,
    required this.onDelete,
    required this.onOpenChat,
  });

  final Club club;
  final String? uid;
  final VoidCallback onJoin;
  final VoidCallback onLeave;
  final ValueChanged<bool> onToggleClose;
  final VoidCallback onDelete;
  final VoidCallback onOpenChat;

  bool get _isCreator => uid != null && club.creatorId == uid;
  bool get _isJoined => uid != null && club.participants.contains(uid);

  @override
  Widget build(BuildContext context) {
    final closed = !club.isRecruiting;
    final statusColor = closed ? Colors.red : Colors.indigo;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 배지 + 작성자 삭제 버튼
            Row(
              children: [
                ClubBadge(
                  text: club.category,
                  color: clubCategoryColor(club.category),
                ),
                const SizedBox(width: 8),
                ClubBadge(
                  text:
                      '${club.statusLabel} (${club.currentMembers}/${club.maxMembers}명)',
                  color: statusColor,
                ),
                const Spacer(),
                if (_isCreator)
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 20, color: Colors.redAccent),
                    tooltip: '내 모집글 삭제',
                    onPressed: onDelete,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              club.title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // 장소·일시: 길어지면 다음 줄로 넘어가도록 Wrap 사용
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _InfoChip(icon: Icons.location_on_outlined, text: club.location),
                _InfoChip(icon: Icons.access_time, text: club.time),
              ],
            ),

            if (club.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                club.description,
                style: const TextStyle(color: Colors.black54, fontSize: 14),
              ),
            ],
            const SizedBox(height: 12),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    if (_isCreator) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '내가 모집 중인 모임 · 조기 마감',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                Switch(value: club.isClosedEarly, onChanged: onToggleClose),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onOpenChat,
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('모임 채팅방 입장'),
            ),
          ),
        ],
      );
    }

    if (_isJoined) {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
              onPressed: onLeave,
              icon: const Icon(Icons.exit_to_app, size: 18),
              label: const Text('참여 취소'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: FilledButton.icon(
              onPressed: onOpenChat,
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('채팅 참여하기'),
            ),
          ),
        ],
      );
    }

    final canJoin = club.isRecruiting && uid != null;
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: canJoin ? onJoin : null,
        icon: Icon(club.isRecruiting ? Icons.person_add : Icons.block),
        label: Text(club.isRecruiting ? '함께 참여하기' : '모집이 마감되었습니다'),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(color: Colors.black87, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
