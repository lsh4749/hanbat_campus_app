import 'package:flutter/material.dart';

import '../app_theme.dart';

/// 둥근 알약 모양 선택 버튼 (카테고리 필터, 날짜 선택 등).
///
/// 기본 ChoiceChip은 웹에서 한글 글꼴이 늦게 로딩되면 글자가 잘려 보이는 경우가 있어서,
/// 글자 크기에 맞춰 자연스럽게 늘어나는 버튼을 직접 만들었다.
class PillChip extends StatelessWidget {
  const PillChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedColor = AppColors.ink,
    this.selectedTextColor = Colors.white,
    this.leading,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;
  final Color selectedTextColor;

  /// 글자 앞에 붙는 작은 표시 (예: 카테고리 색 점)
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? selectedColor : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: 6)],
                  Text(
                    label,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.3,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? selectedTextColor : AppColors.inkSub,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
