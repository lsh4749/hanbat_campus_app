import 'package:flutter/material.dart';

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
// 오늘의 학식 + 원터치 리뷰. 누르면 학식·기숙사 식단 상세 화면(MealScreen)으로 이동.
// 데이터: assets/data/meals.json (tools/crawl_meals.py로 매주 갱신)
// 평일엔 학식 중식(백반), 주말·공휴일엔 지금 시간에 맞는 기숙사 식단을 보여준다.
// TODO: 리뷰를 Firestore에 저장할지 학식 담당과 정해서 _onReview에 연결.
// ===========================================================================
class MealTile extends StatefulWidget {
  const MealTile({super.key});

  @override
  State<MealTile> createState() => _MealTileState();
}

enum MealReview { good, soso, bad }

class _MealTileState extends State<MealTile> {
  MealReview? _picked;
  late final Future<WeeklyMeals> _future = MealRepository.instance.loadMeals();

  static const _labels = {
    MealReview.good: '맛있어요',
    MealReview.soso: '보통이에요',
    MealReview.bad: '아쉬워요',
  };

  void _onReview(MealReview review) {
    setState(() => _picked = _picked == review ? null : review);
  }

  @override
  Widget build(BuildContext context) {
    return BentoTile(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      semanticLabel: '학식 · 기숙사 식단 자세히 보기',
      onTap: () => _push(context, const MealScreen()),
      child: FutureBuilder<WeeklyMeals>(
        future: _future,
        builder: (context, snapshot) {
          final now = DateTime.now();
          final pick = snapshot.data?.todayPick(now);

          var title = '오늘의 학식';
          String menu;
          String sides;
          if (snapshot.hasError) {
            menu = '식단을 불러오지 못했어요';
            sides = '잠시 후 다시 확인해 주세요.';
          } else if (!snapshot.hasData) {
            menu = '불러오는 중…';
            sides = '';
          } else if (pick == null) {
            menu = '오늘은 학식이 없어요';
            sides = now.weekday >= DateTime.saturday
                ? '토·일·공휴일은 학생식당이 쉬어요.'
                : '아직 등록된 식단이 없어요.';
          } else {
            title = pick.source == MealSource.cafeteria
                ? '오늘의 학식 · ${pick.time.cafeteriaLabel}'
                : '오늘의 기숙사 식단 · ${pick.time.label}';
            menu = pick.menu.mainDish;
            sides = pick.menu.sides.take(3).join(' · ');
          }
          // 리뷰는 학식(백반)이 있을 때만
          final canReview = pick?.source == MealSource.cafeteria;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onPrimarySub)),
                  ),
                  const Text('전체 식단',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onPrimarySub)),
                  const Icon(Icons.chevron_right_rounded,
                      size: 18, color: AppColors.onPrimarySub),
                ],
              ),
              const SizedBox(height: 6),
              Text(menu,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      color: Colors.white)),
              if (sides.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(sides,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.onPrimaryBody)),
              ],
              if (canReview) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    for (final review in MealReview.values) ...[
                      if (review != MealReview.good) const SizedBox(width: 8),
                      Expanded(child: _reviewButton(review)),
                    ],
                  ],
                ),
                if (_picked != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    '"${_labels[_picked]}" 평가가 반영됐어요. 한 번 더 누르면 취소돼요.',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.onPrimaryBody),
                  ),
                ],
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _reviewButton(MealReview review) {
    final on = _picked == review;
    return Semantics(
      selected: on,
      child: TextButton(
        onPressed: () => _onReview(review),
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
