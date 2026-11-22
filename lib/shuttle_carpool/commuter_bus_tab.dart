import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'commuter_bus_data.dart';

/// 통학 임차버스 탭.
///
/// 등교버스는 평일 아침 한 번 운행하므로, 노선과 "내 정류장"을 고르면
/// 그 정류장 승차 시각까지 남은 시간을 보여준다.
/// 야간 하교버스는 시험·축제기간에만 24:00에 학교에서 한 번 출발한다.
class CommuterBusTab extends StatefulWidget {
  const CommuterBusTab({super.key});

  @override
  State<CommuterBusTab> createState() => _CommuterBusTabState();
}

class _CommuterBusTabState extends State<CommuterBusTab> {
  static const _routeKey = 'commuter_bus_route';
  static const _stopKeyPrefix = 'commuter_bus_stop_';

  final Future<CommuterBusInfo> _future = CommuterBusRepository.instance.load();

  bool _night = false;
  String? _routeId;
  String? _nightRouteId;

  /// 노선 id → 내 정류장 순번
  final Map<String, int> _myStops = {};

  SharedPreferences? _prefs;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _loadSaved();
    // 남은 시간이 저절로 줄어들도록 30초마다 다시 그린다.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final stops = <String, int>{};
    for (final key in prefs.getKeys()) {
      if (key.startsWith(_stopKeyPrefix)) {
        final v = prefs.getInt(key);
        if (v != null) stops[key.substring(_stopKeyPrefix.length)] = v;
      }
    }
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _routeId ??= prefs.getString(_routeKey);
      _myStops.addAll(stops);
    });
  }

  void _selectRoute(String id) {
    setState(() => _routeId = id);
    _prefs?.setString(_routeKey, id);
  }

  void _toggleMyStop(String routeId, int index) {
    setState(() {
      if (_myStops[routeId] == index) {
        _myStops.remove(routeId);
        _prefs?.remove('$_stopKeyPrefix$routeId');
      } else {
        _myStops[routeId] = index;
        _prefs?.setInt('$_stopKeyPrefix$routeId', index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CommuterBusInfo>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('임차버스 정보를 불러오지 못했어요.\n${snapshot.error}'));
        }
        final info = snapshot.data;
        if (info == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.wb_sunny_outlined),
                  label: Text('등교 (아침)'),
                ),
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.nightlight_outlined),
                  label: Text('야간 하교'),
                ),
              ],
              selected: {_night},
              onSelectionChanged: (s) => setState(() => _night = s.first),
            ),
            const SizedBox(height: 16),
            if (_night) ..._buildNight(context, info) else ..._buildMorning(context, info),
            const SizedBox(height: 16),
            Text(
              '출처: 한밭대학교 홈페이지 임차버스 안내 · ${info.updatedAt} 기준',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // 등교 (아침 1회)
  // --------------------------------------------------------------------------
  List<Widget> _buildMorning(BuildContext context, CommuterBusInfo info) {
    final routes = info.morningRoutes;
    if (routes.isEmpty) return const [Text('등록된 등교 노선이 없어요.')];

    final route = routes.firstWhere(
      (r) => r.id == _routeId,
      orElse: () => routes.first,
    );
    final myIndex = _myStops[route.id];
    final myStop = (myIndex != null && myIndex < route.stops.length)
        ? route.stops[myIndex]
        : null;

    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    final runsToday = now.weekday <= DateTime.friday;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final r in routes)
            ChoiceChip(
              label: Text(r.name),
              selected: r.id == route.id,
              onSelected: (_) => _selectRoute(r.id),
            ),
        ],
      ),
      const SizedBox(height: 8),
      Text(route.areas, style: textTheme.bodyMedium),
      const SizedBox(height: 12),
      _MorningStatusCard(
        route: route,
        myStop: myStop,
        arriveAt: info.arriveAt,
        now: now,
      ),
      const SizedBox(height: 20),
      Text(
        '정류장 · 승차 시각',
        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 4),
      Text(
        '타는 정류장을 누르면 내 정류장으로 저장돼요.',
        style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: 8),
      Card(
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            for (var i = 0; i < route.stops.length; i++)
              _StopTile(
                stop: route.stops[i],
                isMine: i == myIndex,
                isPast: runsToday &&
                    route.stops[i].minutes != null &&
                    route.stops[i].minutes! < nowMin,
                onTap: route.stops[i].time == null
                    ? null
                    : () => _toggleMyStop(route.id, i),
              ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _NoticeCard(lines: info.notices),
    ];
  }

  // --------------------------------------------------------------------------
  // 야간 하교 (시험·축제기간 24:00 1회)
  // --------------------------------------------------------------------------
  List<Widget> _buildNight(BuildContext context, CommuterBusInfo info) {
    final routes = info.nightRoutes;
    if (routes.isEmpty) return const [Text('등록된 야간 노선이 없어요.')];

    final route = routes.firstWhere(
      (r) => r.id == _nightRouteId,
      orElse: () => routes.first,
    );
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final r in routes)
            ChoiceChip(
              label: Text(r.name),
              selected: r.id == route.id,
              onSelected: (_) => setState(() => _nightRouteId = r.id),
            ),
        ],
      ),
      const SizedBox(height: 8),
      Text(route.areas, style: textTheme.bodyMedium),
      const SizedBox(height: 12),
      Card(
        margin: EdgeInsets.zero,
        color: colorScheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.nightlight_round, color: colorScheme.onSecondaryContainer),
                  const SizedBox(width: 8),
                  Text(
                    '야간 하교버스',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '학교에서 ${info.nightDepartAt} 출발',
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(info.nightNotice, style: textTheme.bodySmall),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
      Text(
        '하차 정류장 (순서대로)',
        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      Card(
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            for (var i = 0; i < route.stops.length; i++)
              ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 13,
                  backgroundColor: colorScheme.secondaryContainer,
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                title: Text(route.stops[i]),
              ),
          ],
        ),
      ),
    ];
  }
}

/// 등교버스 상단 안내 카드: 내 정류장까지 남은 시간 또는 첫 출발·도착 시각
class _MorningStatusCard extends StatelessWidget {
  const _MorningStatusCard({
    required this.route,
    required this.myStop,
    required this.arriveAt,
    required this.now,
  });

  final MorningRoute route;
  final MorningStop? myStop;
  final String arriveAt;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final (headline, detail) = _message();

    return Card(
      margin: EdgeInsets.zero,
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.departure_board, color: colorScheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    myStop == null
                        ? '${route.name} 등교버스'
                        : '${route.name} · ${myStop!.name}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              headline,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              detail,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  (String, String) _message() {
    const holidayHint = '공휴일·방학 운행 여부는 학교 공지를 확인해 주세요.';
    final weekend = now.weekday > DateTime.friday;
    final nextDay = (weekend || now.weekday == DateTime.friday) ? '월요일' : '내일';

    final stop = myStop;
    final stopMin = stop?.minutes;
    if (stop == null || stopMin == null) {
      final first = route.firstTime ?? '-';
      return (
        '첫 정류장 $first 출발 · 학교 $arriveAt 도착',
        weekend
            ? '주말에는 운행하지 않아요. 정류장을 누르면 남은 시간을 알려드려요.'
            : '정류장을 누르면 내 정류장 승차까지 남은 시간을 알려드려요. $holidayHint',
      );
    }

    if (weekend) {
      return ('주말에는 운행하지 않아요', '다음 운행: 월요일 ${stop.time} 승차 · $holidayHint');
    }

    final diff = stopMin - (now.hour * 60 + now.minute);
    if (diff > 0) {
      return ('${stop.time} 승차 · ${_duration(diff)} 남음', '학교 $arriveAt 도착 예정 · $holidayHint');
    }
    if (diff == 0) {
      return ('지금 도착할 시간이에요', '${stop.time} 승차 · 정류장에서 기다려 주세요.');
    }
    return ('오늘 버스는 이미 지나갔어요', '다음 운행: $nextDay ${stop.time} 승차 · $holidayHint');
  }

  static String _duration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '$m분';
    if (m == 0) return '$h시간';
    return '$h시간 $m분';
  }
}

class _StopTile extends StatelessWidget {
  const _StopTile({
    required this.stop,
    required this.isMine,
    required this.isPast,
    required this.onTap,
  });

  final MorningStop stop;
  final bool isMine;
  final bool isPast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final muted = isPast && !isMine;
    final color = muted ? colorScheme.outline : null;

    return ListTile(
      dense: true,
      onTap: onTap,
      selected: isMine,
      selectedTileColor: colorScheme.primaryContainer.withAlpha(90),
      leading: SizedBox(
        width: 48,
        child: Text(
          stop.time ?? '하차',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: stop.time == null ? colorScheme.outline : color,
          ),
        ),
      ),
      title: Text(stop.name, style: TextStyle(color: color)),
      trailing: isMine
          ? Icon(Icons.star_rounded, color: colorScheme.primary)
          : (onTap == null ? null : Icon(Icons.star_border_rounded, color: colorScheme.outline)),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.bodySmall;

    return Card(
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 14, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(child: Text(line, style: style)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
