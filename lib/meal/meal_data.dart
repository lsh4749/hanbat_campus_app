import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// 끼니. JSON 키(breakfast / lunch / dinner)와 이름이 같다.
enum MealTime {
  breakfast('아침', '조식'),
  lunch('점심', '중식'),
  dinner('저녁', '석식');

  const MealTime(this.label, this.cafeteriaLabel);

  /// 기숙사에서 쓰는 이름 (아침/점심/저녁)
  final String label;

  /// 학식에서 쓰는 이름 (조식/중식/석식)
  final String cafeteriaLabel;
}

/// 어디 식단인지
enum MealSource { cafeteria, dorm }

/// 한 끼 메뉴. 예) ['백미밥', '시금치된장국', '콩나물불고기', '간장순두부', ...]
class MealMenu {
  const MealMenu(this.items);

  final List<String> items;

  /// 홈 타일에 크게 보여줄 대표 메뉴.
  /// 첫 줄이 맨밥(백미밥·쌀밥 등)이면 건너뛰고, 그 뒤에 나오는 국·찌개도 건너뛴 다음 메뉴를 고른다.
  /// 첫 줄이 카레라이스·볶음밥·면처럼 밥이 아니면 그게 대표 메뉴다.
  String get mainDish => items.isEmpty ? '' : items[_mainIndex];

  /// 대표 메뉴와 맨밥을 뺀 나머지
  List<String> get sides => [
        for (var i = 0; i < items.length; i++)
          if (i != _mainIndex && !_isPlainRice(items[i])) items[i],
      ];

  int get _mainIndex {
    if (items.isEmpty || !_isPlainRice(items.first)) return 0;
    // 밥 다음 두 줄 안에 국·찌개가 있으면 그 다음 줄이 메인 반찬
    for (var i = 1; i < items.length && i <= 2; i++) {
      if (_isSoup(items[i])) return i + 1 < items.length ? i + 1 : i;
    }
    return items.length > 1 ? 1 : 0;
  }

  /// '생선까스/타르타르', '쌀밥&누룽지'처럼 붙은 부분을 떼고 본 이름만
  static String _base(String s) => s.split(RegExp(r'[/&*(]')).first.trim();

  static final _riceRe = RegExp(r'^[가-힣]{1,3}밥$');
  static const _notPlainRice = ['볶음', '비빔', '덮', '김밥', '주먹'];
  static final _soupRe = RegExp(r'(국|탕|찌개|국물|스프|수프|개장)$');

  static bool _isPlainRice(String s) {
    final base = _base(s);
    return _riceRe.hasMatch(base) && !_notPlainRice.any(base.contains);
  }

  static bool _isSoup(String s) => _soupRe.hasMatch(_base(s));
}

/// 하루치 식단 (끼니별 메뉴)
class DayMeals {
  const DayMeals(this.date, this.menus);

  final DateTime date;
  final Map<MealTime, MealMenu> menus;

  MealMenu? operator [](MealTime time) => menus[time];
  bool get isEmpty => menus.isEmpty;

  factory DayMeals.fromJson(DateTime date, Map<String, dynamic> json) {
    final menus = <MealTime, MealMenu>{};
    for (final time in MealTime.values) {
      final list = json[time.name];
      if (list is List && list.isNotEmpty) {
        menus[time] = MealMenu([for (final e in list) e.toString()]);
      }
    }
    return DayMeals(date, menus);
  }
}

/// 홈 타일에 보여줄 오늘의 한 끼
class TodayMeal {
  const TodayMeal(this.source, this.time, this.menu);

  final MealSource source;
  final MealTime time;
  final MealMenu menu;
}

/// assets/data/meals.json (tools/crawl_meals.py가 매주 만들어 줌)
class WeeklyMeals {
  const WeeklyMeals({
    required this.updatedAt,
    required this.cafeteria,
    required this.dorm,
  });

  final DateTime? updatedAt;

  /// 날짜('2026-11-23') → 하루 식단. 날짜순으로 정렬돼 있다.
  final Map<String, DayMeals> cafeteria;
  final Map<String, DayMeals> dorm;

  DayMeals? cafeteriaOn(DateTime day) => cafeteria[dateKey(day)];
  DayMeals? dormOn(DateTime day) => dorm[dateKey(day)];

  /// 오늘 보여줄 한 끼. 학식 중식이 있으면 그걸,
  /// 없으면(주말·공휴일) 지금 시간에 맞는 기숙사 식단을 고른다.
  TodayMeal? todayPick(DateTime now) {
    final lunch = cafeteriaOn(now)?[MealTime.lunch];
    if (lunch != null) {
      return TodayMeal(MealSource.cafeteria, MealTime.lunch, lunch);
    }
    final dormDay = dormOn(now);
    if (dormDay == null) return null;
    final preferred = now.hour < 10
        ? MealTime.breakfast
        : (now.hour < 15 ? MealTime.lunch : MealTime.dinner);
    for (final time in [preferred, ...MealTime.values]) {
      final menu = dormDay[time];
      if (menu != null) return TodayMeal(MealSource.dorm, time, menu);
    }
    return null;
  }

  factory WeeklyMeals.fromJson(Map<String, dynamic> json) {
    return WeeklyMeals(
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      cafeteria: _days(json['cafeteria']),
      dorm: _days(json['dorm']),
    );
  }

  static Map<String, DayMeals> _days(Object? raw) {
    if (raw is! Map) return {};
    final keys = [for (final k in raw.keys) k.toString()]..sort();
    final result = <String, DayMeals>{};
    for (final key in keys) {
      final date = DateTime.tryParse(key);
      final value = raw[key];
      if (date == null || value is! Map) continue;
      final day = DayMeals.fromJson(date, Map<String, dynamic>.from(value));
      if (!day.isEmpty) result[key] = day;
    }
    return result;
  }
}

// ---------------------------------------------------------------------------
// assets/data/meal_info.json : 운영시간·가격·단품메뉴 (직접 작성한 정보)
// ---------------------------------------------------------------------------

/// '중식(백반)' : '11:30 ~ 13:30' 같은 한 줄 정보
class LabeledText {
  const LabeledText(this.label, this.text);

  final String label;
  final String text;

  factory LabeledText.fromJson(Map<String, dynamic> json) => LabeledText(
        json['label'] as String? ?? '',
        json['time'] as String? ?? json['text'] as String? ?? '',
      );
}

class SingleMenuItem {
  const SingleMenuItem({required this.name, this.price, this.priceText});

  final String name;
  final int? price;
  final String? priceText;

  /// '4,500원' 또는 priceText('5줄 3,500원 · 7줄 4,700원 …')
  String get priceLabel => priceText ?? (price == null ? '' : formatWon(price!));

  factory SingleMenuItem.fromJson(Map<String, dynamic> json) => SingleMenuItem(
        name: json['name'] as String? ?? '',
        price: (json['price'] as num?)?.toInt(),
        priceText: json['priceText'] as String?,
      );
}

class SingleMenuCategory {
  const SingleMenuCategory(this.name, this.items);

  final String name;
  final List<SingleMenuItem> items;

  factory SingleMenuCategory.fromJson(Map<String, dynamic> json) =>
      SingleMenuCategory(
        json['category'] as String? ?? '',
        _list(json['items'], SingleMenuItem.fromJson),
      );
}

/// 식당 한 곳의 고정 정보 (학생식당 / 생활관 식당)
class MealPlaceInfo {
  const MealPlaceInfo({
    required this.name,
    required this.place,
    required this.notice,
    required this.hours,
    required this.prices,
    required this.singleMenu,
    required this.source,
  });

  final String name;
  final String place;
  final String notice;
  final List<LabeledText> hours;
  final List<LabeledText> prices;
  final List<SingleMenuCategory> singleMenu;
  final String source;

  factory MealPlaceInfo.fromJson(Map<String, dynamic> json) => MealPlaceInfo(
        name: json['name'] as String? ?? '',
        place: json['place'] as String? ?? '',
        notice: json['notice'] as String? ?? '',
        hours: _list(json['hours'], LabeledText.fromJson),
        prices: _list(
          json['prices'],
          (p) => LabeledText(
            p['label'] as String? ?? '',
            formatWon((p['price'] as num? ?? 0).toInt()),
          ),
        ),
        singleMenu: _list(json['singleMenu'], SingleMenuCategory.fromJson),
        source: json['source'] as String? ?? '',
      );
}

class MealInfo {
  const MealInfo({required this.cafeteria, required this.dorm});

  final MealPlaceInfo cafeteria;
  final MealPlaceInfo dorm;

  factory MealInfo.fromJson(Map<String, dynamic> json) => MealInfo(
        cafeteria: MealPlaceInfo.fromJson(
            Map<String, dynamic>.from(json['cafeteria'] as Map)),
        dorm: MealPlaceInfo.fromJson(
            Map<String, dynamic>.from(json['dorm'] as Map)),
      );
}

// ---------------------------------------------------------------------------
// 불러오기
// ---------------------------------------------------------------------------

/// 식단 JSON을 읽어 둔다. 앱 실행 중 한 번만 읽는다.
class MealRepository {
  MealRepository._();
  static final instance = MealRepository._();

  static const _mealsPath = 'assets/data/meals.json';
  static const _infoPath = 'assets/data/meal_info.json';

  Future<WeeklyMeals>? _meals;
  Future<MealInfo>? _info;

  Future<WeeklyMeals> loadMeals() =>
      _meals ??= _loadJson(_mealsPath).then(WeeklyMeals.fromJson);

  Future<MealInfo> loadInfo() =>
      _info ??= _loadJson(_infoPath).then(MealInfo.fromJson);

  static Future<Map<String, dynamic>> _loadJson(String path) async {
    final text = await rootBundle.loadString(path);
    return jsonDecode(text) as Map<String, dynamic>;
  }
}

// ---------------------------------------------------------------------------
// 도우미
// ---------------------------------------------------------------------------

/// DateTime → '2026-11-23'
String dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// 4500 → '4,500원'
String formatWon(int won) {
  final digits = won.toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return '$buf원';
}

List<T> _list<T>(Object? raw, T Function(Map<String, dynamic>) fromJson) {
  if (raw is! List) return [];
  return [
    for (final e in raw)
      if (e is Map) fromJson(Map<String, dynamic>.from(e)),
  ];
}
