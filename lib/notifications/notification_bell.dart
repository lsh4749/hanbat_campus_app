import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import 'notification_center.dart';
import 'notification_screen.dart';

/// 홈 화면 오른쪽 위 종 버튼. 안 읽은 알림 개수를 빨간 배지로 보여준다.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final center = NotificationCenter.instance;
    return ListenableBuilder(
      listenable: center,
      builder: (context, _) {
        final count = center.unreadCount;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: count > 0 ? '알림 $count개' : '알림',
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFF3F4F6),
                foregroundColor: AppColors.ink,
                fixedSize: const Size(44, 44),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: Icon(count > 0
                  ? Icons.notifications_rounded
                  : Icons.notifications_none_rounded),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              ),
            ),
            if (count > 0)
              Positioned(
                right: 2,
                top: 2,
                child: IgnorePointer(
                  child: Container(
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      count > 9 ? '9+' : '$count',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          height: 1.1),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
