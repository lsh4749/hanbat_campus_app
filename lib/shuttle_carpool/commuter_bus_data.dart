import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// 등교버스 정류장 하나. [time]이 null이면 학교 안 하차 지점이다.
class MorningStop {
  const MorningStop({required this.name, required this.time});

  final String name;

  /// '07:52' 같은 승차 시각
  final String? time;

  /// 자정부터 센 분. 시각이 없으면 null.
  int? get minutes => parseMinutes(time);

  factory MorningStop.fromJson(Map<String, dynamic> json) => MorningStop(
        name: json['name'] as String? ?? '',
        time: json['time'] as String?,
      );
}

/// 등교버스 노선 하나 (1호차 ~ 5호차). 아침에 한 번 운행한다.
class MorningRoute {
  const MorningRoute({
    required this.id,
    required this.name,
    required this.areas,
    required this.stops,
  });

  final String id;
  final String name;
  final String areas;
  final List<MorningStop> stops;

  /// 첫 정류장 출발 시각
  String? get firstTime =>
      stops.map((s) => s.time).firstWhere((t) => t != null, orElse: () => null);

  factory MorningRoute.fromJson(Map<String, dynamic> json) => MorningRoute(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        areas: json['areas'] as String? ?? '',
        stops: [
          for (final e in json['stops'] as List? ?? const [])
            if (e is Map) MorningStop.fromJson(Map<String, dynamic>.from(e)),
        ],
      );
}

/// 야간 하교버스 노선 하나. 정류장 시각 없이 학교에서 한 번 출발한다.
class NightRoute {
  const NightRoute({
    required this.id,
    required this.name,
    required this.areas,
    required this.stops,
  });

  final String id;
  final String name;
  final String areas;
  final List<String> stops;

  factory NightRoute.fromJson(Map<String, dynamic> json) => NightRoute(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        areas: json['areas'] as String? ?? '',
        stops: [
          for (final e in json['stops'] as List? ?? const []) e.toString(),
        ],
      );
}

/// assets/data/commuter_bus.json 전체
class CommuterBusInfo {
  const CommuterBusInfo({
    required this.updatedAt,
    required this.source,
    required this.notices,
    required this.arriveAt,
    required this.morningRoutes,
    required this.nightDepartAt,
    required this.nightNotice,
    required this.nightRoutes,
  });

  final String updatedAt;
  final String source;
  final List<String> notices;

  /// 등교버스 학교 도착 기준 시각 ('08:30')
  final String arriveAt;
  final List<MorningRoute> morningRoutes;

  /// 야간 하교버스 학교 출발 시각 ('24:00')
  final String nightDepartAt;
  final String nightNotice;
  final List<NightRoute> nightRoutes;

  factory CommuterBusInfo.fromJson(Map<String, dynamic> json) {
    final morning = _map(json['morning']);
    final night = _map(json['night']);
    return CommuterBusInfo(
      updatedAt: json['updatedAt'] as String? ?? '',
      source: json['source'] as String? ?? '',
      notices: [
        for (final e in json['notices'] as List? ?? const []) e.toString(),
      ],
      arriveAt: morning['arriveAt'] as String? ?? '08:30',
      morningRoutes: [
        for (final e in morning['routes'] as List? ?? const [])
          if (e is Map) MorningRoute.fromJson(Map<String, dynamic>.from(e)),
      ],
      nightDepartAt: night['departAt'] as String? ?? '24:00',
      nightNotice: night['notice'] as String? ?? '',
      nightRoutes: [
        for (final e in night['routes'] as List? ?? const [])
          if (e is Map) NightRoute.fromJson(Map<String, dynamic>.from(e)),
      ],
    );
  }
}

/// 임차버스 JSON을 읽어 둔다. 앱 실행 중 한 번만 읽는다.
class CommuterBusRepository {
  CommuterBusRepository._();
  static final instance = CommuterBusRepository._();

  Future<CommuterBusInfo>? _info;

  Future<CommuterBusInfo> load() => _info ??= rootBundle
      .loadString('assets/data/commuter_bus.json')
      .then((text) => CommuterBusInfo.fromJson(
          jsonDecode(text) as Map<String, dynamic>));
}

/// '07:52' → 472. 형식이 틀리면 null.
int? parseMinutes(String? hhmm) {
  if (hhmm == null) return null;
  final parts = hhmm.split(':');
  if (parts.length != 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return h * 60 + m;
}

Map<String, dynamic> _map(Object? raw) =>
    raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
