import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../home/widgets/roulette_wheel.dart';
import '../restaurant/restaurant_screen.dart';

/// 메뉴 추천 룰렛 화면.
/// [돌리기]를 누르면 룰렛이 돌고, 멈춘 칸의 음식 종류로 맛집 화면으로 이동한다.
///
/// 맛집 화면(RestaurantScreen, 4번 김연수 담당)에는 뽑힌 종류를
/// RouteSettings.arguments 로 넘긴다. 맛집 화면에서 받는 방법:
///   final category = ModalRoute.of(context)?.settings.arguments as String?;
///   // 예: '중식' → 중식 맛집만 필터링해서 보여주기
class RouletteScreen extends StatefulWidget {
  const RouletteScreen({super.key});

  /// 홈 타일 → 룰렛 화면 전환 시 룰렛 판이 커지며 이어지는 Hero 태그
  static const heroTag = 'menu-roulette-wheel';

  /// 맛집 화면으로 넘길 때 쓰는 경로 이름
  static const restaurantRouteName = '/restaurant';

  /// 룰렛 칸 (위쪽부터 시계 방향, 색 순서와 같음: 노랑 주황 빨강 분홍 보라 파랑 청록 초록)
  static const categories = ['한식', '중식', '일식', '양식', '분식', '치킨', '고기', '국밥'];

  @override
  State<RouletteScreen> createState() => _RouletteScreenState();
}

class _RouletteScreenState extends State<RouletteScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );
  late final Animation<double> _curve =
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart);

  final _random = math.Random();
  double _from = 0;
  double _to = 0;
  String? _result;
  bool _spinning = false;

  double get _angle => _from + (_to - _from) * _curve.value;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _spin() async {
    if (_spinning) return;
    const count = RouletteWheel.segmentCount;
    final target = _random.nextInt(count);
    // 칸 안에서 멈추는 위치를 조금씩 다르게 (칸 경계에는 멈추지 않도록 ±15°)
    final jitter = (_random.nextDouble() - 0.5) * (math.pi / 6);

    setState(() {
      _spinning = true;
      _result = null;
      _from = _angle % (2 * math.pi);
      // 지금 위치에서 최소 5바퀴 이상 돈 뒤 target 칸에서 멈추게 계산
      var to = RouletteWheel.angleFor(target, jitter: jitter);
      while (to < _from + 5 * 2 * math.pi) {
        to += 2 * math.pi;
      }
      _to = to;
    });

    await _controller.forward(from: 0);
    if (!mounted) return;

    final picked = RouletteScreen.categories[RouletteWheel.indexAt(_to)];
    setState(() {
      _spinning = false;
      _result = picked;
    });

    // 결과를 잠깐 보여준 뒤 맛집 화면으로 이동
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted && _result == picked) _openRestaurants(picked);
  }

  void _openRestaurants(String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        settings: RouteSettings(
          name: RouletteScreen.restaurantRouteName,
          arguments: category,
        ),
        builder: (_) => const RestaurantScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wheelSize = math.min(width - 48, 340.0);

    return Scaffold(
      backgroundColor: AppColors.orangeBg,
      appBar: AppBar(
        backgroundColor: AppColors.orangeBg,
        title: const Text('메뉴 추천 룰렛',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            const Text('오늘 뭐 먹지?',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.orangeInk)),
            const SizedBox(height: 4),
            const Text('룰렛이 멈춘 음식으로 맛집을 찾아드려요',
                style: TextStyle(fontSize: 14, color: AppColors.orangeSub)),
            const Spacer(),
            Hero(
              tag: RouletteScreen.heroTag,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => RouletteWheel(
                  size: wheelSize,
                  angle: _angle,
                  labels: RouletteScreen.categories,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 64,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _result == null
                    ? const SizedBox.shrink()
                    : Semantics(
                        liveRegion: true,
                        child: Text(
                          '오늘은 $_result 어때요?',
                          key: ValueKey(_result),
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink),
                        ),
                      ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: _spinning ? null : _spin,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.orangeInk,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                        textStyle: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                      child: Text(_spinning
                          ? '돌아가는 중...'
                          : (_result == null ? '룰렛 돌리기' : '다시 돌리기')),
                    ),
                  ),
                  if (_result != null && !_spinning) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _openRestaurants(_result!),
                      child: Text('$_result 맛집 보러가기 ›',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.orangeInk)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
