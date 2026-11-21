import 'package:flutter/material.dart';

/// 홈 화면 벤토 그리드의 타일 한 칸.
/// 둥근 색 배경 + 누르면 물결 효과. 내용은 child로 넣는다.
class BentoTile extends StatelessWidget {
  const BentoTile({
    super.key,
    required this.color,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.padding = const EdgeInsets.all(18),
  });

  final Color color;
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// 타일 왼쪽 위의 흰 아이콘 상자
class TileIconBox extends StatelessWidget {
  const TileIconBox({super.key, required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}
