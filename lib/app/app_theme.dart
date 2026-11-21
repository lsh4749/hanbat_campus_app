import 'package:flutter/material.dart';

/// 앱 전체에서 쓰는 색상. 새 화면을 만들 때도 여기 색을 쓰면 디자인이 통일돼요.
class AppColors {
  AppColors._();

  // 기본
  static const primary = Color(0xFF004098); // 한밭대 남색
  static const ink = Color(0xFF111827); // 본문 글씨, 탭바 배경
  static const inkSub = Color(0xFF4B5563); // 보조 글씨
  static const accent = Color(0xFFFFD54F); // 강조 노랑 (D-day, 선택된 탭)
  static const background = Color(0xFFFFFFFF);

  // 남색 타일 위 글씨
  static const onPrimarySub = Color(0xFFC7D7F2);
  static const onPrimaryBody = Color(0xFFDCE6F7);
  static const onAccent = Color(0xFF002A66);

  // 기능별 타일 색 (배경 / 진한 글씨 / 보조 글씨)
  static const orangeBg = Color(0xFFFFF1E6);
  static const orangeInk = Color(0xFF7C2D12);
  static const orangeSub = Color(0xFF9A3412);

  static const blueBg = Color(0xFFE8F1FF);
  static const blueInk = Color(0xFF1E3A8A);

  static const greenBg = Color(0xFFEAF7EE);
  static const greenInk = Color(0xFF14532D);
  static const greenSub = Color(0xFF166534);

  static const redBg = Color(0xFFFDECEC);
  static const redInk = Color(0xFF7F1D1D);
  static const redSub = Color(0xFF991B1B);
  static const redIcon = Color(0xFFB91C1C);

  static const fire = Color(0xFFF97316);
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
      ),
      scaffoldBackgroundColor: AppColors.background,
      useMaterial3: true,
    );
    return base.copyWith(
      // 글꼴: 따로 지정하지 않아도 안드로이드는 기본 한글 글꼴이 Noto Sans KR이고,
      // 웹(Flutter web)도 한글은 Noto Sans KR로 자동 대체해서 보여준다.
      // (google_fonts 패키지는 현재 Flutter 버전의 material_ui와 타입이 충돌해서 사용하지 않음)
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
    );
  }
}
