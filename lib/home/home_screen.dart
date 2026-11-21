import 'package:flutter/material.dart';
import '../building/building_screen.dart';
import '../shuttle_carpool/shuttle_carpool_screen.dart';
import '../lost_found/lost_found_screen.dart';
import '../restaurant/restaurant_screen.dart';
import '../club/club_screen.dart';
import '../club/widgets/club_preview_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('한밭 라이프', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      // 좌측 상단 [☰] 메뉴 클릭 시 열리는 사이드바
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF004098)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '한밭대학교 통합 맵',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '캠퍼스 생활의 모든 것',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              context,
              Icons.apartment,
              '1. 건물 및 주요 시설 안내',
              const BuildingScreen(),
            ),
            _buildDrawerItem(
              context,
              Icons.directions_bus,
              '2. 셔틀버스 & 택시 카풀',
              const ShuttleCarpoolScreen(),
            ),
            _buildDrawerItem(
              context,
              Icons.search,
              '3. 분실물 찾아주기',
              const LostFoundScreen(),
            ),
            _buildDrawerItem(
              context,
              Icons.restaurant,
              '4. 대학가 맛집 & 추천 룰렛',
              const RestaurantScreen(),
            ),
            _buildDrawerItem(
              context,
              Icons.groups,
              '5. 한밭 소모임 모집',
              const ClubScreen(),
            ),
          ],
        ),
      ),
      // 메인 대시보드 위젯 영역
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildDashboardCard(
            context,
            icon: Icons.directions_bus,
            title: '다음 셔틀버스 안내',
            subtitle: '정문 출발 14:20 (약 7분 전) • 터치하여 시간표 보기',
            targetScreen: const ShuttleCarpoolScreen(),
          ),
          const SizedBox(height: 12),
          _buildDashboardCard(
            context,
            icon: Icons.lunch_dining,
            title: '오늘의 학식 (중식)',
            subtitle: '제육덮밥 / 계란국 / 깍두기 • 터치하여 상세 보기',
            targetScreen: const BuildingScreen(),
          ),
          const SizedBox(height: 12),
          _buildDashboardCard(
            context,
            icon: Icons.casino,
            title: '오늘 뭐 먹지? 맛집 룰렛',
            subtitle: '결정장애 해결! 대학가 맛집 랜덤 추천받기',
            targetScreen: const RestaurantScreen(),
          ),
          const SizedBox(height: 12),
          // Firestore 실시간 데이터로 모집 중인 소모임을 보여주는 카드
          const ClubPreviewCard(),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    Widget screen,
  ) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF004098)),
      title: Text(title),
      onTap: () {
        Navigator.pop(context); // 사이드바 닫기
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      },
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget targetScreen,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF004098).withValues(alpha: 0.1),
          child: Icon(icon, color: const Color(0xFF004098)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => targetScreen));
        },
      ),
    );
  }
}