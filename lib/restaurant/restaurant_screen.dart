import 'package:flutter/material.dart';
import '../app/app_theme.dart';
import 'restaurant_model.dart';
import 'roulette_screen.dart';

/// 대학가 맛집 목록. 룰렛에서 음식 종류(String)를 arguments로 넘기면 그 종류만 보여준다.
class RestaurantScreen extends StatefulWidget {
  const RestaurantScreen({super.key});

  @override
  State<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen> {
  late final Future<List<Restaurant>> _future = Restaurant.load();
  String? _category; // null = 전체
  bool _argsRead = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsRead) return; // 최초 1회만
    _argsRead = true;
    // 룰렛에서 오면 String, 그냥 들어오면 null 이므로 String? 로 받는다.
    _category = ModalRoute.of(context)?.settings.arguments as String?;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_category == null ? '대학가 맛집' : '$_category 맛집'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RouletteScreen()),
            ),
            icon: const Icon(Icons.casino_rounded),
            label: const Text('추천 룰렛'),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _chip('전체', null),
                for (final c in foodCategories) _chip(c, c),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Restaurant>>(
              future: _future,
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(child: Text('맛집 데이터를 불러오지 못했어요'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = _category == null
                    ? snap.data!
                    : snap.data!.where((r) => r.category == _category).toList();
                if (list.isEmpty) {
                  return Center(child: Text('$_category 맛집이 아직 없어요'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _RestaurantCard(r: list[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String? value) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: _category == value,
          onSelected: (_) => setState(() => _category = value),
        ),
      );
}

class _RestaurantCard extends StatelessWidget {
  const _RestaurantCard({required this.r});
  final Restaurant r;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.orangeBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(r.name,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.orangeInk)),
            ),
            Text(r.category,
                style: const TextStyle(color: AppColors.orangeSub)),
          ]),
          const SizedBox(height: 6),
          Text('대표메뉴  ${r.menu}'),
          Text('영업시간  ${r.hours}'),
          if (r.address.isNotEmpty) Text(r.address),
        ],
      ),
    );
  }
}
