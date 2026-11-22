import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

/// 채팅방 및 사용자 원형 프로필 아바타.
class ChatAvatar extends StatelessWidget {
  const ChatAvatar({
    super.key,
    required this.color,
    this.icon = Icons.person_rounded,
    this.size = 44,
    this.showPinBadge = false,
  });

  final Color color;
  final IconData icon;
  final double size;
  final bool showPinBadge;

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Icon(
        icon,
        color: color,
        size: size * 0.52,
      ),
    );

    if (!showPinBadge) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.background, width: 1.8),
            ),
            child: const Icon(
              Icons.star_rounded,
              size: 11,
              color: AppColors.onAccent,
            ),
          ),
        ),
      ],
    );
  }
}
