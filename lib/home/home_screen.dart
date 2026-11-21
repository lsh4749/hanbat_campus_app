import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../app/main_shell.dart';
import '../club/widgets/club_preview_card.dart';
import '../notifications/notification_bell.dart';
import '../schedule/widgets/schedule_preview_card.dart';
import 'widgets/home_tiles.dart';

/// 메인 홈: 벤토 그리드.
///
/// ┌──────────── 학식 + 원터치 리뷰 ────────────┐
/// │  메뉴 룰렛  │  셔틀 · 카풀                  │
/// ├──────────── 실시간 소모임 ─────────────────┤
/// │  학사 일정  │  분실물 찾기                  │
///
/// 각 타일은 담당 기능 폴더(또는 home/widgets/home_tiles.dart)에 있어요.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onSelectTab});

  /// 하단 탭 전환 (MainShell에서 넘겨줌). 없으면 각 타일이 화면을 새로 연다.
  final ValueChanged<int>? onSelectTab;

  static const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateText =
        '${_weekdays[now.weekday - 1]}요일, ${now.month}월 ${now.day}일';

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 0, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dateText,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.inkSub)),
                        const SizedBox(height: 2),
                        const Text('한밭 라이프',
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.8,
                                color: AppColors.primary)),
                      ],
                    ),
                  ),
                  // 새 소모임·분실물·채팅, 일정 하루 전 알림
                  const NotificationBell(),
                ],
              ),
            ),

            const MealTile(),
            const SizedBox(height: 10),
            const _TileRow(
              height: 140,
              left: RouletteTile(),
              right: ShuttleTile(),
            ),
            const SizedBox(height: 10),
            ClubPreviewCard(
              onOpen: onSelectTab == null
                  ? null
                  : () => onSelectTab!(AppTab.club),
            ),
            const SizedBox(height: 10),
            _TileRow(
              height: 124,
              left: SchedulePreviewCard(
                onOpen: onSelectTab == null
                    ? null
                    : () => onSelectTab!(AppTab.schedule),
              ),
              right: const LostFoundTile(),
            ),
          ],
        ),
      ),
    );
  }
}

/// 같은 높이의 타일 두 개를 나란히 놓는 줄
class _TileRow extends StatelessWidget {
  const _TileRow({
    required this.height,
    required this.left,
    required this.right,
  });

  final double height;
  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    // 글자 크기를 키운 기기에서도 내용이 잘리지 않도록 높이를 같이 늘린다.
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.4);
    return SizedBox(
      height: height * scale,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          const SizedBox(width: 10),
          Expanded(child: right),
        ],
      ),
    );
  }
}
