import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../club.dart';
import 'leader_badge.dart';

/// 카테고리 진한 색 (글자, 배지용)
Color clubCategoryColor(String category) {
  switch (category) {
    case '운동':
      return const Color(0xFF15803D);
    case '게임':
      return const Color(0xFF6D28D9);
    case '스터디':
      return const Color(0xFF1D4ED8);
    case '공모전':
      return const Color(0xFF0F766E);
    case '자유':
      return const Color(0xFFC2410C);
    default:
      return Colors.blueGrey;
  }
}

/// 카테고리 연한 배경색 (홈 벤토 타일과 같은 톤)
Color clubCategoryTint(String category) {
  switch (category) {
    case '운동':
      return AppColors.greenBg;
    case '게임':
      return const Color(0xFFF3EEFF);
    case '스터디':
      return AppColors.blueBg;
    case '공모전':
      return const Color(0xFFE3F5F2);
    case '자유':
      return AppColors.orangeBg;
    default:
      return const Color(0xFFF3F4F6);
  }
}

/// 작은 색상 배지 (카테고리, 모집 상태 표시에 사용)
class ClubBadge extends StatelessWidget {
  const ClubBadge({
    super.key,
    required this.text,
    required this.color,
    this.background,
  });

  final String text;
  final Color color;

  /// 없으면 [color]를 연하게 깐다.
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
          height: 1.3,
        ),
      ),
    );
  }
}

/// 소모임 목록의 카드 한 장 (홈 화면 벤토 타일 스타일).
/// 버튼 동작은 화면에서 콜백으로 받는다.
class ClubCard extends StatelessWidget {
  const ClubCard({
    super.key,
    required this.club,
    required this.uid,
    required this.onJoin,
    required this.onLeave,
    required this.onToggleClose,
    required this.onDelete,
    required this.onEdit,
    required this.onOpenChat,
  });

  final Club club;
  final String? uid;
  final VoidCallback onJoin;
  final VoidCallback onLeave;
  final ValueChanged<bool> onToggleClose;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onOpenChat;

  bool get _isCreator => uid != null && club.creatorId == uid;
  bool get _isJoined => uid != null && club.participants.contains(uid);

  @override
  Widget build(BuildContext context) {
    final ended = club.isExpired;
    final ink = clubCategoryColor(club.category);
    final tint = ended ? const Color(0xFFF3F4F6) : clubCategoryTint(club.category);
    final hot = club.isHot && club.isRecruiting;

    // 한 화면에 2~3개가 보이도록 정보를 촘촘하게 배치한 카드
    return Opacity(
      opacity: ended ? 0.6 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1줄: 배지 + (내 글) 수정/삭제
            SizedBox(
              height: 30,
              child: Row(
                children: [
                  ClubBadge(
                    text: club.category,
                    color: ended ? AppColors.inkSub : ink,
                    background: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  _StatusBadge(club: club),
                  const Spacer(),
                  if (_isCreator) ...[
                    _SmallIconButton(
                      icon: Icons.edit_outlined,
                      color: AppColors.inkSub,
                      tooltip: '내 모집글 수정',
                      onPressed: onEdit,
                    ),
                    _SmallIconButton(
                      icon: Icons.delete_outline,
                      color: const Color(0xFFDC2626),
                      tooltip: '내 모집글 삭제',
                      onPressed: onDelete,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 4),

            // 2줄: 제목 (인기 모임은 양옆 불꽃)
            Row(
              children: [
                if (hot) const _Fire(),
                Flexible(
                  child: Text(
                    club.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                if (hot) const _Fire(),
              ],
            ),
            const SizedBox(height: 4),

            // 3줄: 모임장 · 시간 · 장소
            Row(
              children: [
                const LeaderBadge(compact: true),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '${club.creatorNickname}${_isCreator ? '(나)' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink),
                  ),
                ),
                const _Dot(),
                const Icon(Icons.access_time_rounded,
                    size: 14, color: AppColors.inkSub),
                const SizedBox(width: 3),
                Text(club.timeLabel,
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.inkSub)),
                const _Dot(),
                const Icon(Icons.location_on_outlined,
                    size: 14, color: AppColors.inkSub),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    club.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.inkSub),
                  ),
                ),
              ],
            ),

            // 상세 설명은 한 줄만 (전체 내용은 수정 창에서 확인)
            if (club.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                club.isEdited
                    ? '${club.description} · 수정됨'
                    : club.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: AppColors.inkSub),
              ),
            ],
            const SizedBox(height: 10),

            // 4줄: 인원 막대 + 버튼
            Row(
              children: [
                Expanded(child: _MemberBar(club: club, color: ink)),
                const SizedBox(width: 10),
                ..._buildActions(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActions() {
    final chatButton = _CompactButton(
      label: '채팅',
      icon: Icons.chat_bubble_outline_rounded,
      filled: true,
      onPressed: onOpenChat,
    );

    if (_isCreator) {
      return [
        _CompactButton(
          label: club.isClosedEarly ? '모집 재개' : '조기 마감',
          onPressed: () => onToggleClose(!club.isClosedEarly),
        ),
        const SizedBox(width: 6),
        chatButton,
      ];
    }
    if (_isJoined) {
      return [
        _CompactButton(
          label: '참여 취소',
          textColor: const Color(0xFFDC2626),
          onPressed: onLeave,
        ),
        const SizedBox(width: 6),
        chatButton,
      ];
    }
    final canJoin = club.isRecruiting && uid != null;
    return [
      _CompactButton(
        label: club.isRecruiting
            ? '참여하기'
            : (club.isExpired ? '종료됨' : '마감됨'),
        icon: club.isRecruiting ? Icons.person_add_alt_1_rounded : null,
        filled: true,
        onPressed: canJoin ? onJoin : null,
      ),
    ];
  }
}

/// 카드 안의 작은 버튼 (높이 36). filled면 남색, 아니면 흰 바탕.
class _CompactButton extends StatelessWidget {
  const _CompactButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.filled = false,
    this.textColor = AppColors.ink,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool filled;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      backgroundColor: filled ? AppColors.primary : Colors.white,
      foregroundColor: filled ? Colors.white : textColor,
      disabledBackgroundColor: const Color(0xFFE5E7EB),
      disabledForegroundColor: AppColors.inkSub,
      minimumSize: const Size(0, 36),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      tapTargetSize: MaterialTapTargetSize.padded,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
    );
    if (icon == null) {
      return FilledButton(onPressed: onPressed, style: style, child: Text(label));
    }
    return FilledButton.icon(
      onPressed: onPressed,
      style: style,
      icon: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}

/// 카드 오른쪽 위 작은 아이콘 버튼 (수정/삭제)
class _SmallIconButton extends StatelessWidget {
  const _SmallIconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 19),
      color: color,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 30),
      onPressed: onPressed,
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 5),
      child: Text('·',
          style: TextStyle(fontSize: 12.5, color: AppColors.inkSub)),
    );
  }
}

/// 모집중 / 마감 / 종료 배지
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.club});

  final Club club;

  @override
  Widget build(BuildContext context) {
    if (club.isRecruiting) {
      return const ClubBadge(
        text: '모집중',
        color: Colors.white,
        background: AppColors.primary,
      );
    }
    return ClubBadge(
      text: club.statusLabel,
      color: AppColors.inkSub,
      background: Colors.white,
    );
  }
}

/// 참여 인원 막대 (예: 6/10명)
class _MemberBar extends StatelessWidget {
  const _MemberBar({required this.club, required this.color});

  final Club club;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = club.maxMembers == 0
        ? 0.0
        : (club.currentMembers / club.maxMembers).clamp(0.0, 1.0);
    return Row(
      children: [
        const Icon(Icons.groups_rounded, size: 16, color: AppColors.inkSub),
        const SizedBox(width: 5),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: const Color(0xFFEEF2F6),
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${club.currentMembers}/${club.maxMembers}',
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w800, color: color),
        ),
      ],
    );
  }
}

class _Fire extends StatelessWidget {
  const _Fire();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 2),
      child: Icon(Icons.local_fire_department_rounded,
          size: 17, color: AppColors.fire),
    );
  }
}
