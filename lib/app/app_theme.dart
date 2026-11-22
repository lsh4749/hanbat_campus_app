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

/// 앱 전체 테마. 홈 화면(벤토 타일) 디자인을 기준으로 버튼·카드·칩·탭·입력칸 등
/// 기본 위젯 모양을 통일한다. 각 기능 화면이 Card, ChoiceChip, TabBar, FilledButton 같은
/// 기본 위젯을 쓰면 따로 꾸미지 않아도 이 모양으로 보인다.
///
/// 새 화면을 만들 때 참고:
/// - 색은 Colors.teal 같은 기본색 대신 AppColors를 쓰기
/// - 카드 모서리 20, 버튼 14, 칩은 완전히 둥글게
class AppTheme {
  AppTheme._();

  static const _radiusCard = 20.0;
  static const _radiusButton = 14.0;
  static const _surface = Color(0xFFF5F6F8); // 카드 등 연회색 면
  static const _fill = Color(0xFFF3F4F6); // 입력칸·칩 바탕
  static const _line = Color(0xFFE5E7EB); // 테두리·구분선

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.background,
    );
    final base = ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      useMaterial3: true,
    );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_radiusButton),
    );
    const buttonText = TextStyle(fontSize: 15, fontWeight: FontWeight.w700);

    return base.copyWith(
      // 글꼴: 따로 지정하지 않아도 안드로이드는 기본 한글 글꼴이 Noto Sans KR이고,
      // 웹(Flutter web)도 한글은 Noto Sans KR로 자동 대체해서 보여준다.
      // (google_fonts 패키지는 현재 Flutter 버전의 material_ui와 타입이 충돌해서 사용하지 않음)

      // 상단 바: 흰 바탕, 왼쪽 정렬 굵은 제목, 스크롤해도 색이 안 바뀜
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          color: AppColors.ink,
        ),
      ),

      // 카드: 그림자 없는 연회색 둥근 면 (홈 타일과 같은 느낌)
      cardTheme: CardThemeData(
        color: _surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusCard),
        ),
      ),

      // 칩(필터 버튼): 회색 알약, 선택되면 검은색 + 흰 글씨, 체크 표시 없음
      chipTheme: ChipThemeData(
        backgroundColor: _fill,
        selectedColor: AppColors.ink,
        disabledColor: _fill,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        labelStyle: const TextStyle(
          fontSize: 14,
          height: 1.3,
          fontWeight: FontWeight.w500,
          color: AppColors.inkSub,
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 14,
          height: 1.3,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(size: 18, color: AppColors.inkSub),
      ),

      // 탭: 남색 굵은 글씨 + 남색 밑줄
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.inkSub,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: _line,
        labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        unselectedLabelStyle:
            TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),

      // 버튼: 남색 꽉 찬 버튼(높이 48, 모서리 14)이 기본
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _line,
          disabledForegroundColor: AppColors.inkSub,
          minimumSize: const Size(0, 48),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 48),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: _line),
          minimumSize: const Size(0, 48),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          shape: buttonShape,
        ),
      ),

      // 떠 있는 + 버튼: 탭바와 같은 검은색
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),

      // 입력칸: 회색 바탕, 테두리 없음, 누르면 남색 테두리
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _fill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        labelStyle: const TextStyle(color: AppColors.inkSub),
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusButton),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusButton),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusButton),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),

      // 팝업 창: 흰 바탕, 모서리 24
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: AppColors.ink,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // 목록 한 줄
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.inkSub,
        titleTextStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        subtitleTextStyle:
            const TextStyle(fontSize: 13, color: AppColors.inkSub),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // 하단 알림 메시지: 검은 둥근 상자로 떠서 보임
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(fontSize: 14, color: Colors.white),
        actionTextColor: AppColors.accent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0xFFEEF0F3),
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
    );
  }
}
