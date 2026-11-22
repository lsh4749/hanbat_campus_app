import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../app/widgets/page_header.dart';
import '../building/building_screen.dart';
import '../chat/chat_screen.dart';
import '../lost_found/lost_found_screen.dart';
import '../restaurant/restaurant_screen.dart';
import '../shuttle_carpool/shuttle_carpool_screen.dart';

/// 더보기 탭: 하단 탭에 없는 기능들로 가는 메뉴.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = <_MoreEntry>[
      _MoreEntry(Icons.directions_bus_rounded, '셔틀버스 · 카풀', AppColors.primary,
          () => const ShuttleCarpoolScreen()),
      _MoreEntry(Icons.restaurant_rounded, '대학가 맛집 · 메뉴 룰렛',
          AppColors.orangeSub, () => const RestaurantScreen()),
      _MoreEntry(Icons.search_rounded, '분실물 찾기', AppColors.redIcon,
          () => const LostFoundScreen()),
      _MoreEntry(Icons.apartment_rounded, '건물 및 주요 시설 안내', AppColors.blueInk,
          () => const BuildingScreen()),
      _MoreEntry(Icons.chat_bubble_outline_rounded, '실시간 익명 채팅',
          AppColors.greenSub, () => const ChatScreen()),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AppPageHeader(subtitle: '모든 기능 한눈에', title: '더보기'),
            Expanded(child: _buildList(entries)),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<_MoreEntry> entries) {
    return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final e = entries[i];
          return Material(
            color: const Color(0xFFF5F6F8),
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(e.icon, color: e.color),
              ),
              title: Text(e.title,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => e.builder()),
              ),
            ),
          );
        },
      );
  }
}

class _MoreEntry {
  final IconData icon;
  final String title;
  final Color color;
  final Widget Function() builder;
  const _MoreEntry(this.icon, this.title, this.color, this.builder);
}
