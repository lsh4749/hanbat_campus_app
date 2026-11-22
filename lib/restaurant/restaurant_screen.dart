import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../app/widgets/page_header.dart';
import '../app/widgets/pill_chip.dart';
import '../home/widgets/roulette_wheel.dart';
import '../roulette/roulette_screen.dart';
import 'restaurant_model.dart';

/// 대학가 맛집 목록. 룰렛에서 음식 종류(String)를 arguments로 넘기면 그 종류만 보여준다.
///
/// 룰렛은 홈 화면과 같은 것(lib/roulette/roulette_screen.dart) 하나만 쓴다.
/// - 홈 룰렛 → 맛집 화면: RouteSettings.arguments 로 음식 종류를 받는다.
/// - 맛집 화면의 룰렛 버튼 → RouletteScreen(pickOnly: true) 가 뽑힌 종류를 돌려준다.
class RestaurantScreen extends StatefulWidget {
  const RestaurantScreen({super.key});

  @override
  State<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen> {
  late final Future<List<Restaurant>> _future = Restaurant.load();
  String? _category; // null = 전체
  bool _argsRead = false;

  /// 필터 칸은 룰렛 칸과 같은 목록을 쓴다 (룰렛 결과가 항상 필터에 있도록)
  static const _categories = RouletteScreen.categories;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsRead) return; // 최초 1회만
    _argsRead = true;
    // 룰렛에서 오면 String, 그냥 들어오면 null 이므로 String? 로 받는다.
    _category = ModalRoute.of(context)?.settings.arguments as String?;
  }

  Future<void> _openRoulette() async {
    final picked = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const RouletteScreen(pickOnly: true)),
    );
    if (picked != null && mounted) setState(() => _category = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 (홈·소모임과 같은 스타일)
            AppPageHeader(
              subtitle: '오늘 뭐 먹지?',
              title: _category == null ? '대학가 맛집' : '$_category 맛집',
            ),

            // 룰렛 바로가기 (홈 룰렛과 같은 판)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Material(
                color: AppColors.orangeBg,
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _openRoulette,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    child: Row(
                      children: [
                        const RouletteWheel(size: 52),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('메뉴 추천 룰렛',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.orangeInk)),
                              Text('돌려서 나온 음식 종류로 맛집을 골라드려요',
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.orangeSub)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.orangeInk),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 음식 종류 필터
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  PillChip(
                    label: '전체',
                    selected: _category == null,
                    onTap: () => setState(() => _category = null),
                  ),
                  for (final c in _categories) ...[
                    const SizedBox(width: 8),
                    PillChip(
                      label: c,
                      selected: _category == c,
                      onTap: () => setState(() => _category = c),
                    ),
                  ],
                ],
              ),
            ),

            Expanded(
              child: FutureBuilder<List<Restaurant>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return const _Message('맛집 데이터를 불러오지 못했어요');
                  }
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final list = _category == null
                      ? snap.data!
                      : snap.data!
                          .where((r) => r.category == _category)
                          .toList();
                  if (list.isEmpty) {
                    return _Message('$_category 맛집이 아직 없어요\n다른 종류를 골라보세요');
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _RestaurantCard(r: list[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  const _RestaurantCard({required this.r});
  final Restaurant r;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.orangeBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(r.category,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.orangeSub)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(r.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoLine(icon: Icons.restaurant_menu_rounded, text: r.menu),
                const SizedBox(height: 4),
                _InfoLine(icon: Icons.access_time_rounded, text: r.hours),
                if (r.address.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _InfoLine(icon: Icons.location_on_outlined, text: r.address),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.inkSub),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: const TextStyle(fontSize: 13.5, color: AppColors.ink)),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(text,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 15, color: AppColors.inkSub, height: 1.5)),
    );
  }
}
