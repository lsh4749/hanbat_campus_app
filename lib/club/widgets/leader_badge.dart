import 'package:flutter/material.dart';

/// 모임장 표시용 금색 왕관 아이콘.
/// 머티리얼 아이콘에는 왕관이 없어서 직접 그린다. (기기마다 모양이 다른 이모지 대신 사용)
class CrownIcon extends StatelessWidget {
  const CrownIcon({super.key, this.size = 16, this.color = crownGold});

  static const crownGold = Color(0xFFF2B705);

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.8),
      painter: _CrownPainter(color),
    );
  }
}

class _CrownPainter extends CustomPainter {
  _CrownPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final fill = Paint()..color = color;

    // 왕관 몸통: 뾰족한 봉우리 3개
    final body = Path()
      ..moveTo(w * 0.06, h * 0.30)
      ..lineTo(w * 0.30, h * 0.55)
      ..lineTo(w * 0.50, h * 0.12)
      ..lineTo(w * 0.70, h * 0.55)
      ..lineTo(w * 0.94, h * 0.30)
      ..lineTo(w * 0.84, h * 0.80)
      ..lineTo(w * 0.16, h * 0.80)
      ..close();
    canvas.drawPath(body, fill);

    // 아래 띠
    canvas.drawRRect(
      RRect.fromLTRBR(w * 0.16, h * 0.84, w * 0.84, h * 1.0,
          Radius.circular(h * 0.06)),
      fill,
    );

    // 봉우리 끝 구슬
    final r = w * 0.075;
    canvas.drawCircle(Offset(w * 0.06, h * 0.26), r, fill);
    canvas.drawCircle(Offset(w * 0.50, h * 0.08), r, fill);
    canvas.drawCircle(Offset(w * 0.94, h * 0.26), r, fill);
  }

  @override
  bool shouldRepaint(_CrownPainter old) => old.color != color;
}

/// 왕관 + '모임장' 글자 배지.
///
/// 소모임 카드뿐 아니라 채팅에서도 쓸 수 있다. (여창건님 참고)
/// 예) 채팅 메시지 보낸 사람 이름 옆에:
///   if (message.senderId == club.creatorId) const LeaderBadge()
/// 소모임 채팅방 id는 'club_<소모임 문서 id>' 형식이라, 방 id에서 소모임 id를 꺼내
/// clubs/<id> 문서의 creatorId와 비교하면 된다.
class LeaderBadge extends StatelessWidget {
  const LeaderBadge({super.key, this.compact = false});

  /// true면 왕관만 보여준다 (좁은 자리용)
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      // Semantics는 const로 만들 수 없어서 const를 붙이지 않는다.
      return Tooltip(
        message: '모임장',
        child: Semantics(label: '모임장', child: const CrownIcon(size: 16)),
      );
    }
    return Semantics(
      label: '모임장',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(5, 2, 7, 2),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4CC),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CrownIcon(size: 13),
            SizedBox(width: 3),
            Text(
              '모임장',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF8A6100),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
