import 'dart:math';
import 'package:flutter/material.dart';
import '../app/app_theme.dart';
import 'restaurant_model.dart';
import 'restaurant_screen.dart';

/// 음식 종류 추천 룰렛. 결과 종류를 arguments(String)로 담아 맛집 목록으로 보낸다.
class RouletteScreen extends StatefulWidget {
  const RouletteScreen({super.key});

  @override
  State<RouletteScreen> createState() => _RouletteScreenState();
}

class _RouletteScreenState extends State<RouletteScreen>
    with SingleTickerProviderStateMixin {
  static const _colors = [
    Color(0xFFFFD54F), Color(0xFF90CAF9), Color(0xFFA5D6A7),
    Color(0xFFFFAB91), Color(0xFFCE93D8), Color(0xFF80DEEA),
  ];
  final _rand = Random();
  late final AnimationController _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 4000));
  double _angle = 0; // 현재 회전각(rad)
  bool _spinning = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _spin() async {
    if (_spinning) return;
    setState(() => _spinning = true);

    final n = foodCategories.length;
    final slice = 2 * pi / n;
    final idx = _rand.nextInt(n);
    // idx번 칸의 중앙이 맨 위 화살표에 오도록 하는 최종 각도
    final stop = (-(idx * slice + slice / 2)) % (2 * pi);
    final delta = (stop - _angle) % (2 * pi);
    final from = _angle;
    final to = from + 2 * pi * 5 + delta; // 5바퀴 + 정지 위치

    final anim = Tween<double>(begin: from, end: to)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    anim.addListener(() => setState(() => _angle = anim.value));
    _ctrl.reset();
    await _ctrl.forward();
    _angle = to % (2 * pi);

    if (!mounted) return;
    setState(() => _spinning = false);
    _showResult(foodCategories[idx]);
  }

  void _showResult(String picked) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('오늘의 메뉴'),
        content: Text('$picked 당첨! 🎉',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('다시 돌리기')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx); // 다이얼로그 닫기
              // 룰렛 화면을 필터된 맛집 화면으로 교체. 음식 종류를 arguments로 전달.
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  settings: RouteSettings(arguments: picked),
                  builder: (_) => const RestaurantScreen(),
                ),
              );
            },
            child: Text('$picked 맛집 보기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('추천 룰렛')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_drop_down_rounded,
                size: 48, color: AppColors.primary),
            SizedBox(
              width: 300,
              height: 300,
              child: CustomPaint(
                painter: _WheelPainter(
                    labels: foodCategories, colors: _colors, angle: _angle),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _spinning ? null : _spin,
              child: Text(_spinning ? '돌아가는 중...' : '돌리기'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter(
      {required this.labels, required this.colors, required this.angle});
  final List<String> labels;
  final List<Color> colors;
  final double angle;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: c, radius: radius);
    final n = labels.length;
    final slice = 2 * pi / n;

    for (var i = 0; i < n; i++) {
      // 0번 칸은 회전각 0일 때 맨 위(-90°)에서 시작
      final start = -pi / 2 + angle + i * slice;
      canvas.drawArc(rect, start, slice, true,
          Paint()..color = colors[i % colors.length]);
      canvas.drawArc(
          rect,
          start,
          slice,
          true,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = Colors.white);

      final mid = start + slice / 2;
      final pos = c + Offset(cos(mid), sin(mid)) * (radius * 0.65);
      final tp = TextPainter(
        text: TextSpan(
            text: labels[i],
            style: const TextStyle(
                color: AppColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_WheelPainter old) => old.angle != angle;
}
