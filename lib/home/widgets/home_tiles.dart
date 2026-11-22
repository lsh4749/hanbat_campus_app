import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/app_theme.dart';
import '../../app/widgets/bento_tile.dart';
import '../../lost_found/lost_found_screen.dart';
import '../../meal/meal_data.dart';
import '../../meal/meal_screen.dart';
import '../../roulette/roulette_screen.dart';
import '../../shuttle_carpool/shuttle_carpool_screen.dart';
import 'roulette_wheel.dart';

void _push(BuildContext context, Widget screen) {
  Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}

// ===========================================================================
// 오늘의 식단 + 원터치 리뷰
// - 위쪽 [학식 | 기숙사] 버튼으로 같은 자리에서 식단을 바꿔 본다. 마지막 선택은 기억한다.
//   (처음엔 오늘 학식이 있으면 학식, 없으면 기숙사)
// - 누르면 고른 쪽 탭으로 식단 상세 화면(MealScreen)이 열린다.
// - 데이터: assets/data/meals.json (tools/crawl_meals.py로 갱신, 담당: 임경중)
// TODO: 리뷰를 Firestore에 저장할지 학식 담당과 정해서 _onReview에 연결.
// ===========================================================================
class MealTile extends StatefulWidget {
  const MealTile({super.key});

  @override
  State<MealTile> createState() => _MealTileState();
}

enum MealReview { good, soso, bad }

/// 타일에 그릴 내용 한 묶음
class _MealView {
  const _MealView({
    required this.label,
    required this.menu,
    this.sides = '',
    this.reviewKey,
  });

  final String label;
  final String menu;
  final String sides;

  /// 리뷰를 남길 수 있는 끼니면 '식당_날짜_끼니', 아니면 null
  final String? reviewKey;
}

class _MealTileState extends State<MealTile> {
  static const _prefKey = 'home_meal_source';

  // 학생식당 중식(백반) 운영 시간: assets/data/meal_info.json 기준 11:30 ~ 13:30
  static const _lunchEnd = (hour: 13, minute: 30);

  late final Future<WeeklyMeals> _future = MealRepository.instance.loadMeals();

  /// 사용자가 마지막으로 고른 식당 (한 번도 안 골랐으면 null → 자동)
  MealSource? _saved;

  /// 리뷰는 식당·날짜·끼니별로 따로 기억 (아직은 화면에서만, 저장 안 함)
  final Map<String, MealReview> _reviews = {};

  static const _labels = {
    MealReview.good: '맛있어요',
    MealReview.soso: '보통이에요',
    MealReview.bad: '아쉬워요',
  };

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      final v = prefs.getString(_prefKey);
      if (!mounted || v == null) return;
      setState(() => _saved =
          v == MealSource.dorm.name ? MealSource.dorm : MealSource.cafeteria);
    });
  }

  Future<void> _selectSource(MealSource source) async {
    setState(() => _saved = source);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, source.name);
  }

  void _onReview(String key, MealReview review) {
    setState(() {
      if (_reviews[key] == review) {
        _reviews.remove(key);
      } else {
        _reviews[key] = review;
      }
    });
  }

  MealSource _effectiveSource(WeeklyMeals? meals, DateTime now) {
    if (_saved != null) return _saved!;
    final hasLunch = meals?.cafeteriaOn(now)?[MealTime.lunch] != null;
    return hasLunch ? MealSource.cafeteria : MealSource.dorm;
  }

  _MealView _cafeteriaView(WeeklyMeals meals, DateTime now) {
    final lunch = meals.cafeteriaOn(now)?[MealTime.lunch];
    if (lunch == null) {
      return _MealView(
        label: '학생식당',
        menu: '오늘은 학식이 쉬어요',
        sides: now.weekday >= DateTime.saturday
            ? '토·일·공휴일 휴무 · 기숙사 식단을 확인해 보세요'
            : '아직 등록된 식단이 없어요',
      );
    }
    final end = DateTime(
        now.year, now.month, now.day, _lunchEnd.hour, _lunchEnd.minute);
    final ended = now.isAfter(end);
    return _MealView(
      label: ended ? '오늘의 학식 · 중식 · 운영 종료' : '오늘의 학식 · 중식',
      menu: lunch.mainDish,
      sides: lunch.sides.take(3).join(' · '),
      reviewKey: 'cafeteria_${dateKey(now)}_lunch',
    );
  }

  _MealView _dormView(WeeklyMeals meals, DateTime now) {
    final day = meals.dormOn(now);
    if (day == null || day.isEmpty) {
      return const _MealView(
        label: '기숙사',
        menu: '오늘 기숙사 식단이 없어요',
        sides: '아직 등록된 식단이 없어요',
      );
    }
    // 지금 시간에 맞는 끼니 (10시 전 아침, 15시 전 점심, 그 뒤 저녁)
    final preferred = now.hour < 10
        ? MealTime.breakfast
        : (now.hour < 15 ? MealTime.lunch : MealTime.dinner);
    for (final time in [preferred, ...MealTime.values]) {
      final menu = day[time];
      if (menu == null) continue;
      return _MealView(
        label: '오늘의 기숙사 식단 · ${time.label}',
        menu: menu.mainDish,
        sides: menu.sides.take(3).join(' · '),
        reviewKey: 'dorm_${dateKey(now)}_${time.name}',
      );
    }
    return const _MealView(label: '기숙사', menu: '오늘 기숙사 식단이 없어요');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WeeklyMeals>(
      future: _future,
      builder: (context, snapshot) {
        final now = DateTime.now();
        final meals = snapshot.data;
        final source = _effectiveSource(meals, now);

        final _MealView view;
        if (snapshot.hasError) {
          view = const _MealView(
              label: '오늘의 식단',
              menu: '식단을 불러오지 못했어요',
              sides: '잠시 후 다시 확인해 주세요.');
        } else if (meals == null) {
          view = const _MealView(label: '오늘의 식단', menu: '불러오는 중…');
        } else {
          view = source == MealSource.cafeteria
              ? _cafeteriaView(meals, now)
              : _dormView(meals, now);
        }
        final key = view.reviewKey;
        final picked = key == null ? null : _reviews[key];

        return BentoTile(
          color: AppColors.primary,
          padding: const EdgeInsets.fromLTRB(18, 14, 14, 16),
          semanticLabel: '식단 자세히 보기',
          onTap: () => _push(
            context,
            MealScreen(initialTab: source == MealSource.dorm ? 1 : 0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // [학식 | 기숙사] 전환 + 전체 식단
              Row(
                children: [
                  _SourceToggle(source: source, onChanged: _selectSource),
                  const Spacer(),
                  const Text('전체 식단',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onPrimarySub)),
                  const Icon(Icons.chevron_right_rounded,
                      size: 18, color: AppColors.onPrimarySub),
                ],
              ),
              const SizedBox(height: 10),
              Text(view.label,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onPrimarySub)),
              const SizedBox(height: 4),
              Text(view.menu,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      color: Colors.white)),
              if (view.sides.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(view.sides,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.onPrimaryBody)),
              ],
              if (key != null) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    for (final review in MealReview.values) ...[
                      if (review != MealReview.good) const SizedBox(width: 8),
                      Expanded(
                          child: _reviewButton(
                              review, picked == review, () => _onReview(key, review))),
                    ],
                  ],
                ),
                if (picked != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    '"${_labels[picked]}" 평가가 반영됐어요. 한 번 더 누르면 취소돼요.',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.onPrimaryBody),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _reviewButton(MealReview review, bool on, VoidCallback onTap) {
    return Semantics(
      selected: on,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          minimumSize: const Size.fromHeight(44),
          backgroundColor:
              on ? AppColors.accent : Colors.white.withValues(alpha: 0.14),
          foregroundColor: on ? AppColors.onAccent : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          padding: EdgeInsets.zero,
        ),
        child: Text(_labels[review]!),
      ),
    );
  }
}

/// 남색 타일 위의 [학식 | 기숙사] 전환 버튼
class _SourceToggle extends StatelessWidget {
  const _SourceToggle({required this.source, required this.onChanged});

  final MealSource source;
  final ValueChanged<MealSource> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _option('학식', MealSource.cafeteria),
          _option('기숙사', MealSource.dorm),
        ],
      ),
    );
  }

  Widget _option(String label, MealSource value) {
    final on = source == value;
    return Semantics(
      selected: on,
      button: true,
      label: '$label 식단 보기',
      excludeSemantics: true,
      child: Material(
        color: on ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => onChanged(value),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 34),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.3,
                  fontWeight: on ? FontWeight.w800 : FontWeight.w600,
                  color: on ? AppColors.primary : AppColors.onPrimaryBody,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// 메뉴 추천 룰렛: 누르면 큰 룰렛 화면으로 이동 (룰렛 판이 Hero로 커지며 이어짐)
// ===========================================================================
class RouletteTile extends StatelessWidget {
  const RouletteTile({super.key});

  @override
  Widget build(BuildContext context) {
    return BentoTile(
      color: AppColors.orangeBg,
      semanticLabel: '메뉴 추천 룰렛 열기',
      onTap: () => _push(context, const RouletteScreen()),
      child: const Stack(
        // 룰렛이 위쪽 여백까지 살짝 올라가도록 잘라내지 않는다.
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -10,
            right: 4,
            child: Hero(
              tag: RouletteScreen.heroTag,
              child: RouletteWheel(size: 84),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Text('메뉴 추천 룰렛',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppColors.orangeInk)),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// 셔틀 · 카풀 (누르면 셔틀·카풀 화면, 카풀은 그 안의 탭에서 확인)
// TODO(김명재): 시간표 데이터로 다음 출발 시간을 계산해 연결.
// ===========================================================================
class ShuttleTile extends StatelessWidget {
  const ShuttleTile({super.key});

  @override
  Widget build(BuildContext context) {
    return BentoTile(
      color: AppColors.blueBg,
      semanticLabel: '셔틀버스와 카풀 보기',
      onTap: () => _push(context, const ShuttleCarpoolScreen()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const TileIconBox(
                  icon: Icons.directions_bus_rounded, color: AppColors.primary),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('셔틀 · 카풀',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.blueInk)),
              ),
            ],
          ),
          const Spacer(),
          const Text('7분 후',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                  color: AppColors.primary)),
          const Text('정문 14:20 · 카풀 보기 ›',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: AppColors.blueInk)),
        ],
      ),
    );
  }
}

// ===========================================================================
// 분실물 찾기
// ===========================================================================
class LostFoundTile extends StatelessWidget {
  const LostFoundTile({super.key});

  @override
  Widget build(BuildContext context) {
    return BentoTile(
      color: AppColors.redBg,
      semanticLabel: '분실물 찾기',
      onTap: () => _push(context, const LostFoundScreen()),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TileIconBox(icon: Icons.search_rounded, color: AppColors.redIcon),
          Spacer(),
          Text('분실물 찾기',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.redInk)),
          SizedBox(height: 2),
          Text('잃어버린 물건 확인',
              style: TextStyle(fontSize: 12, color: AppColors.redSub)),
        ],
      ),
    );
  }
}
