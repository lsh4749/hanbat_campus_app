import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 무지개 8칸 룰렛 판. [angle](라디안)만큼 원판이 시계 방향으로 돌아가고,
/// 위쪽 바늘은 고정. [labels]를 주면 각 칸에 글자를 쓴다 (8개).
class RouletteWheel extends StatelessWidget {
  const RouletteWheel({
    super.key,
    this.size = 92,
    this.angle = 0,
    this.labels,
  });

  final double size;
  final double angle;
  final List<String>? labels;

  /// 칸 개수 (색상 수와 같음)
  static const int segmentCount = 8;

  static const colors = [
    Color(0xFFF4D94A), // 노랑
    Color(0xFFFFA247), // 주황
    Color(0xFFF5474A), // 빨강
    Color(0xFFFF5FC4), // 분홍
    Color(0xFF9B6DD3), // 보라
    Color(0xFF42B5EA), // 파랑
    Color(0xFF3FB09E), // 청록
    Color(0xFF6CC46B), // 초록
  ];

  // 칸 색 위에서 잘 읽히는 글자색 (밝은 칸은 진한 글씨, 진한 칸은 흰 글씨)
  static const _labelColors = [
    Color(0xFF1F2937),
    Color(0xFF1F2937),
    Colors.white,
    Color(0xFF1F2937),
    Colors.white,
    Color(0xFF1F2937),
    Color(0xFF1F2937),
    Color(0xFF1F2937),
  ];

  /// [angle]만큼 돌았을 때 바늘이 가리키는 칸 번호
  static int indexAt(double angle) {
    const sweep = 2 * math.pi / segmentCount;
    final turned = (-angle) % (2 * math.pi); // 0 ~ 2π
    return (turned / sweep).round() % segmentCount;
  }

  /// [index]번 칸이 바늘 아래 오도록 하는 회전 각도 (+[extraTurns]바퀴)
  static double angleFor(int index, {int extraTurns = 0, double jitter = 0}) {
    const sweep = 2 * math.pi / segmentCount;
    return extraTurns * 2 * math.pi - index * sweep + jitter;
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _RoulettePainter(angle, labels),
      ),
    );
  }
}

class _RoulettePainter extends CustomPainter {
  _RoulettePainter(this.angle, this.labels);

  final double angle;
  final List<String>? labels;

  static const _outline = Color(0xFF1F2937);

  @override
  void paint(Canvas canvas, Size size) {
    // 100x100 기준 좌표로 그린 뒤 실제 크기에 맞게 늘린다.
    final s = size.width / 100;
    canvas.scale(s);
    const center = Offset(50, 54);

    // 바깥 흰 링
    canvas.drawCircle(center, 43, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      43,
      Paint()
        ..color = _outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // 회전하는 칸들 (+ 글자)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    const sweep = 2 * math.pi / RouletteWheel.segmentCount;
    final rect = Rect.fromCircle(center: Offset.zero, radius: 34);
    for (var i = 0; i < RouletteWheel.segmentCount; i++) {
      final start = -math.pi / 2 - sweep / 2 + i * sweep;
      canvas.drawArc(
          rect, start, sweep, true, Paint()..color = RouletteWheel.colors[i]);

      final text = labels != null && i < labels!.length ? labels![i] : null;
      if (text != null) {
        canvas.save();
        canvas.rotate(i * sweep); // 칸 중심 방향으로 회전 (위쪽 기준)
        final tp = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              fontSize: 6,
              fontWeight: FontWeight.w800,
              color: RouletteWheel._labelColors[i],
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )..layout(maxWidth: 20);
        tp.paint(canvas, Offset(-tp.width / 2, -24 - tp.height / 2));
        canvas.restore();
      }
    }
    canvas.restore();

    // 가운데 흰 원
    canvas.drawCircle(center, 10, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      10,
      Paint()
        ..color = _outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // 위쪽 바늘 (고정)
    final pointer = Path()
      ..moveTo(37, 6)
      ..lineTo(63, 6)
      ..lineTo(50, 25)
      ..close();
    canvas.drawPath(pointer, Paint()..color = Colors.white);
    canvas.drawPath(
      pointer,
      Paint()
        ..color = _outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_RoulettePainter old) =>
      old.angle != angle || old.labels != labels;
}
