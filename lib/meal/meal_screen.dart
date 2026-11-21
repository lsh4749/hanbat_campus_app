import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../schedule/academic_event.dart' show formatShortDate;
import 'meal_data.dart';

/// 학식 · 기숙사 식단 상세 화면. 홈의 '오늘의 학식' 타일을 누르면 열린다.
/// - 학생식당 탭: 날짜별 백반 + 운영 정보 + 단품 메뉴
/// - 기숙사 탭: 날짜별 아침·점심·저녁 + 운영 시간
class MealScreen extends StatefulWidget {
  const MealScreen({super.key, this.initialTab = 0});

  /// 0: 학생식당, 1: 기숙사
  final int initialTab;

  @override
  State<MealScreen> createState() => _MealScreenState();
}

class _MealScreenState extends State<MealScreen> {
  late final Future<_ScreenData> _future = _load();

  static Future<_ScreenData> _load() async {
    final repo = MealRepository.instance;
    return _ScreenData(await repo.loadMeals(), await repo.loadInfo());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('학식 · 기숙사 식단',
              style: TextStyle(fontWeight: FontWeight.w800)),
          bottom: const TabBar(
            tabs: [Tab(text: '학생식당'), Tab(text: '기숙사')],
          ),
        ),
        body: FutureBuilder<_ScreenData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                  child: Text('식단을 불러오지 못했어요.\n${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data!;
            return TabBarView(
              children: [
                _MealTab(
                  days: data.meals.cafeteria.values.toList(),
                  info: data.info.cafeteria,
                  source: MealSource.cafeteria,
                  updatedAt: data.meals.updatedAt,
                ),
                _MealTab(
                  days: data.meals.dorm.values.toList(),
                  info: data.info.dorm,
                  source: MealSource.dorm,
                  updatedAt: data.meals.updatedAt,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ScreenData {
  const _ScreenData(this.meals, this.info);
  final WeeklyMeals meals;
  final MealInfo info;
}

// ===========================================================================
// 탭 하나 (학생식당 / 기숙사 공통)
// ===========================================================================
class _MealTab extends StatefulWidget {
  const _MealTab({
    required this.days,
    required this.info,
    required this.source,
    required this.updatedAt,
  });

  final List<DayMeals> days;
  final MealPlaceInfo info;
  final MealSource source;
  final DateTime? updatedAt;

  @override
  State<_MealTab> createState() => _MealTabState();
}

class _MealTabState extends State<_MealTab>
    with AutomaticKeepAliveClientMixin {
  late final List<DayMeals> _week;
  DayMeals? _selected;

  @override
  bool get wantKeepAlive => true; // 탭을 오가도 고른 날짜 유지

  @override
  void initState() {
    super.initState();
    _week = _weekToShow(widget.days);
    final todayKey = dateKey(DateTime.now());
    // 오늘, 없으면 가장 가까운 다음 날, 그것도 없으면 마지막 날
    for (final d in _week) {
      if (dateKey(d.date).compareTo(todayKey) >= 0) {
        _selected = d;
        break;
      }
    }
    _selected ??= _week.isEmpty ? null : _week.last;
  }

  /// 오늘(주말이면 다음 식단이 있는 날)이 속한 주의 식단만 보여준다.
  static List<DayMeals> _weekToShow(List<DayMeals> all) {
    if (all.isEmpty) return [];
    final todayKey = dateKey(DateTime.now());
    final anchor = all.firstWhere(
      (d) => dateKey(d.date).compareTo(todayKey) >= 0,
      orElse: () => all.last,
    );
    final monday =
        anchor.date.subtract(Duration(days: anchor.date.weekday - 1));
    final nextMonday = monday.add(const Duration(days: 7));
    return [
      for (final d in all)
        if (!d.date.isBefore(monday) && d.date.isBefore(nextMonday)) d,
    ];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isCafeteria = widget.source == MealSource.cafeteria;
    final selected = _selected;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (selected == null)
          _EmptyBox(
            isCafeteria
                ? '등록된 학식 식단이 없어요.\n토·일·공휴일과 방학에는 식단이 없을 수 있어요.'
                : '등록된 기숙사 식단이 없어요.',
          )
        else ...[
          _DayPicker(
            days: _week,
            selected: selected,
            onSelected: (d) => setState(() => _selected = d),
          ),
          const SizedBox(height: 14),
          if (selected.isEmpty)
            const _EmptyBox('이 날은 식단 정보가 없어요.')
          else
            for (final time in MealTime.values)
              if (selected[time] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _MenuCard(
                    title: isCafeteria
                        ? '${time.cafeteriaLabel} · 백반'
                        : time.label,
                    menu: selected[time]!,
                    highlight: isCafeteria || selected.menus.length == 1,
                  ),
                ),
        ],
        const SizedBox(height: 8),
        _InfoBox(info: widget.info),
        if (widget.info.singleMenu.isNotEmpty) ...[
          const SizedBox(height: 24),
          const _SectionTitle('단품 메뉴', subtitle: '운영시간 안에는 언제든 주문할 수 있어요'),
          const SizedBox(height: 10),
          for (final category in widget.info.singleMenu)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SingleMenuBox(category: category),
            ),
        ],
        const SizedBox(height: 12),
        Text(
          [
            '출처: ${isCafeteria ? '한밭대 홈페이지 금주의식단·학생식당' : '한밭대 학생생활관 식단표'}',
            if (widget.updatedAt != null)
              '식단 업데이트: ${formatShortDate(widget.updatedAt!)}',
          ].join('\n'),
          style: const TextStyle(fontSize: 12, color: AppColors.inkSub),
        ),
      ],
    );
  }
}

// ===========================================================================
// 작은 위젯들
// ===========================================================================
const _boxColor = Color(0xFFF5F6F8);

class _DayPicker extends StatelessWidget {
  const _DayPicker({
    required this.days,
    required this.selected,
    required this.onSelected,
  });

  final List<DayMeals> days;
  final DayMeals selected;
  final ValueChanged<DayMeals> onSelected;

  @override
  Widget build(BuildContext context) {
    final todayKey = dateKey(DateTime.now());
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final d in days)
          ChoiceChip(
            label: Text(dateKey(d.date) == todayKey
                ? '오늘 ${formatShortDate(d.date)}'
                : formatShortDate(d.date)),
            selected: identical(d, selected),
            onSelected: (_) => onSelected(d),
            showCheckmark: false,
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              color: identical(d, selected) ? Colors.white : AppColors.ink,
            ),
          ),
      ],
    );
  }
}

/// 한 끼 카드: 대표 메뉴를 크게, 나머지는 작은 칩으로
class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.title,
    required this.menu,
    this.highlight = false,
  });

  final String title;
  final MealMenu menu;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final bg = highlight ? AppColors.primary : AppColors.blueBg;
    final titleColor = highlight ? AppColors.onPrimarySub : AppColors.blueInk;
    final mainColor = highlight ? Colors.white : AppColors.ink;
    final chipBg =
        highlight ? Colors.white.withValues(alpha: 0.14) : Colors.white;
    final chipText = highlight ? AppColors.onPrimaryBody : AppColors.inkSub;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: titleColor)),
          const SizedBox(height: 6),
          Text(menu.mainDish,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: mainColor)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final item in menu.items)
                if (item != menu.mainDish)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: chipBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(item,
                        style: TextStyle(fontSize: 13, color: chipText)),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 위치 · 운영시간 · 가격 · 안내
class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.info});

  final MealPlaceInfo info;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _boxColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.place_outlined,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text('${info.name} · ${info.place}',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          if (info.hours.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final row in info.hours) _InfoRow(row),
          ],
          if (info.prices.isNotEmpty) ...[
            const SizedBox(height: 6),
            for (final row in info.prices) _InfoRow(row),
          ],
          if (info.notice.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(info.notice,
                style: const TextStyle(fontSize: 12.5, color: AppColors.inkSub)),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.row);

  final LabeledText row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(row.label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkSub)),
          ),
          Expanded(
            child: Text(row.text,
                style: const TextStyle(fontSize: 13, color: AppColors.ink)),
          ),
        ],
      ),
    );
  }
}

class _SingleMenuBox extends StatelessWidget {
  const _SingleMenuBox({required this.category});

  final SingleMenuCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.orangeBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(category.name,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.orangeInk)),
          const SizedBox(height: 8),
          for (final item in category.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(item.name,
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.ink)),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(item.priceLabel,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.orangeSub)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          if (subtitle != null)
            Text(subtitle!,
                style: const TextStyle(fontSize: 12.5, color: AppColors.inkSub)),
        ],
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: _boxColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: AppColors.inkSub)),
    );
  }
}
