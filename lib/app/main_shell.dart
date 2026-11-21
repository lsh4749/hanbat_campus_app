import 'package:flutter/material.dart';

import '../building/building_screen.dart';
import '../club/club_screen.dart';
import '../home/home_screen.dart';
import '../home/more_screen.dart';
import '../schedule/schedule_screen.dart';
import 'app_theme.dart';

/// 하단 탭 번호. 홈 타일에서 특정 탭으로 이동할 때 사용한다.
class AppTab {
  AppTab._();
  static const home = 0;
  static const campus = 1;
  static const club = 2;
  static const schedule = 3;
  static const more = 4;
}

/// 앱의 뼈대: 화면 아래 떠 있는 탭바 + 탭별 화면.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = AppTab.home;

  void _select(int index) => setState(() => _index = index);

  static const _items = [
    _NavItem(Icons.home_rounded, '홈'),
    _NavItem(Icons.apartment_rounded, '캠퍼스'),
    _NavItem(Icons.groups_rounded, '소모임'),
    _NavItem(Icons.event_note_rounded, '일정'),
    _NavItem(Icons.more_horiz_rounded, '더보기'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack: 탭을 바꿔도 각 화면의 스크롤·입력 상태가 유지된다.
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(onSelectTab: _select),
          const BuildingScreen(),
          const ClubScreen(),
          const ScheduleScreen(),
          const MoreScreen(),
        ],
      ),
      bottomNavigationBar: _FloatingNavBar(
        items: _items,
        currentIndex: _index,
        onTap: _select,
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final selected = i == currentIndex;
              final color =
                  selected ? AppColors.accent : const Color(0xFFD1D5DB);
              return Expanded(
                child: Semantics(
                  selected: selected,
                  button: true,
                  label: '${item.label} 탭',
                  excludeSemantics: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => onTap(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(item.icon, color: color, size: 24),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
