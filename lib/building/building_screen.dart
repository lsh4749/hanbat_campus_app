import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import 'building_data.dart';

/// 건물 및 주요 시설 안내 (더보기 탭에서 들어옴)
/// - 건물: 동 번호 · 건물 이름 · 학과 · 층별 시설 (검색, 구역 필터)
/// - 헬스장: 휘트니스센터 · 생활관 체력단련실 운영 정보
class BuildingScreen extends StatelessWidget {
  const BuildingScreen({super.key, this.initialTab = 0});

  /// 0: 건물, 1: 헬스장
  final int initialTab;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('건물 및 주요 시설 안내',
              style: TextStyle(fontWeight: FontWeight.w800)),
          bottom: const TabBar(tabs: [Tab(text: '건물'), Tab(text: '헬스장')]),
        ),
        body: const TabBarView(children: [_BuildingTab(), _GymTab()]),
      ),
    );
  }
}

const _boxColor = Color(0xFFF5F6F8);

// ===========================================================================
// 건물 탭
// ===========================================================================
class _BuildingTab extends StatefulWidget {
  const _BuildingTab();

  @override
  State<_BuildingTab> createState() => _BuildingTabState();
}

class _BuildingTabState extends State<_BuildingTab>
    with AutomaticKeepAliveClientMixin {
  late final Future<CampusBuildings> _future =
      CampusRepository.instance.loadBuildings();
  String _query = '';
  String? _zone; // null이면 전체

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<CampusBuildings>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('건물 정보를 불러오지 못했어요.\n${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        final shown = [
          for (final b in data.buildings)
            if ((_zone == null || b.zone == _zone) && b.matches(_query)) b,
        ];

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            TextField(
              onChanged: (v) => setState(() => _query = v),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: '건물 이름, 동 번호, 학과로 검색 (예: N4, 컴퓨터)',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: _boxColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _zoneChip('전체', null),
                for (final entry in data.zones.entries)
                  _zoneChip(entry.value, entry.key),
              ],
            ),
            const SizedBox(height: 14),
            if (shown.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text('검색 결과가 없어요.',
                      style: TextStyle(color: AppColors.inkSub)),
                ),
              )
            else
              for (final b in shown)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _BuildingCard(building: b),
                ),
          ],
        );
      },
    );
  }

  Widget _zoneChip(String label, String? zone) {
    final selected = _zone == zone;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: selected ? Colors.white : AppColors.ink,
      ),
      onSelected: (_) => setState(() => _zone = zone),
    );
  }
}

class _BuildingCard extends StatelessWidget {
  const _BuildingCard({required this.building});

  final Building building;

  @override
  Widget build(BuildContext context) {
    final b = building;
    final subtitle = b.departments.isNotEmpty
        ? b.departments.join(' · ')
        : (b.facilities.isNotEmpty ? b.facilities.first : '상세 정보 준비 중');

    return Material(
      color: _boxColor,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        // 펼쳤을 때 위아래로 생기는 선 없애기
        shape: const RoundedRectangleBorder(),
        collapsedShape: const RoundedRectangleBorder(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        leading: _CodeBadge(code: b.code, zone: b.zone),
        title: Text(b.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: AppColors.inkSub)),
        children: [
          if (b.departments.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final d in b.departments)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.blueBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(d,
                        style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.blueInk)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          if (b.facilities.isEmpty)
            const Text('층별 시설 정보가 아직 없어요.',
                style: TextStyle(fontSize: 13, color: AppColors.inkSub))
          else
            for (final f in b.facilities)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  ',
                        style: TextStyle(fontSize: 13, color: AppColors.inkSub)),
                    Expanded(
                      child: Text(f,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.ink)),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

/// 'N4' 같은 동 번호 배지. 구역마다 색이 다르다.
class _CodeBadge extends StatelessWidget {
  const _CodeBadge({required this.code, required this.zone});

  final String code;
  final String zone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (zone) {
      'N' => (AppColors.blueBg, AppColors.blueInk),
      'S' => (AppColors.orangeBg, AppColors.orangeInk),
      'D' => (AppColors.greenBg, AppColors.greenInk),
      _ => (Colors.white, AppColors.ink),
    };
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(code,
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w900, color: fg)),
    );
  }
}

// ===========================================================================
// 헬스장 탭
// ===========================================================================
class _GymTab extends StatefulWidget {
  const _GymTab();

  @override
  State<_GymTab> createState() => _GymTabState();
}

class _GymTabState extends State<_GymTab> {
  late final Future<List<Gym>> _future = CampusRepository.instance.loadGyms();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Gym>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('헬스장 정보를 불러오지 못했어요.\n${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final gyms = snapshot.data!;
        if (gyms.isEmpty) {
          return const Center(child: Text('등록된 헬스장 정보가 없어요.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: gyms.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _GymCard(gym: gyms[i]),
        );
      },
    );
  }
}

class _GymCard extends StatelessWidget {
  const _GymCard({required this.gym});

  final Gym gym;

  @override
  Widget build(BuildContext context) {
    final closed = gym.isOpen == false;
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.fitness_center_rounded,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(gym.name,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800)),
                    Text(gym.location,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.inkSub)),
                  ],
                ),
              ),
              if (gym.isOpen != null) _StatusBadge(open: gym.isOpen!),
            ],
          ),
          if (gym.notice.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: closed ? AppColors.redBg : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(gym.notice,
                  style: TextStyle(
                      fontSize: 13,
                      color: closed ? AppColors.redInk : AppColors.inkSub)),
            ),
          ],
          if (gym.target.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Row('이용 대상', gym.target),
          ],
          if (gym.hours.isNotEmpty) ...[
            const SizedBox(height: 8),
            const _Label('운영 시간'),
            for (final r in gym.hours) _Row(r.label, r.text),
          ],
          if (gym.fees.isNotEmpty) ...[
            const SizedBox(height: 8),
            const _Label('등록비'),
            for (final r in gym.fees) _Row(r.label, r.text),
          ],
          if (gym.howToJoin.isNotEmpty) ...[
            const SizedBox(height: 8),
            _Row('등록 방법', gym.howToJoin),
          ],
          if (gym.contact.isNotEmpty) _Row('문의', gym.contact),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.open});

  final bool open;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: open ? AppColors.greenBg : AppColors.redBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(open ? '운영 중' : '운영 중단',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: open ? AppColors.greenInk : AppColors.redIcon)),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.primary)),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.text);

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkSub)),
          ),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 13, color: AppColors.ink)),
          ),
        ],
      ),
    );
  }
}
