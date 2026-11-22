import 'package:flutter/material.dart';

import '../app_theme.dart';

/// 홈·소모임 화면과 같은 큰 제목 헤더.
///
///   작은 회색 설명
///   큰 남색 제목                    [오른쪽 버튼]
///
/// 이전 화면이 있으면(다른 화면에서 열린 경우) 왼쪽에 뒤로 가기 버튼이 자동으로 붙는다.
/// 사용 예)
///   AppPageHeader(subtitle: '오늘 뭐 먹지?', title: '대학가 맛집')
class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;

  /// 오른쪽 끝에 놓을 위젯 (예: 검색 버튼, 알림 버튼)
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(canPop ? 8 : 20, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (canPop)
            IconButton(
              tooltip: '뒤로',
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.maybePop(context),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subtitle != null) ...[
                  Text(subtitle!,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.inkSub)),
                  const SizedBox(height: 2),
                ],
                Text(title,
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                        height: 1.2,
                        color: AppColors.primary)),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

/// 헤더 오른쪽에 놓는 회색 둥근 아이콘 버튼 (검색 등)
class AppHeaderIconButton extends StatelessWidget {
  const AppHeaderIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xFFF3F4F6),
        foregroundColor: AppColors.ink,
        fixedSize: const Size(44, 44),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: Icon(icon),
      onPressed: onPressed,
    );
  }
}
