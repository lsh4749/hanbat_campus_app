import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// 건물 한 동 (assets/data/buildings.json)
class Building {
  const Building({
    required this.code,
    required this.name,
    required this.zone,
    required this.departments,
    required this.facilities,
  });

  /// 'N4', 'S2', 'D1' 같은 동 번호
  final String code;
  final String name;

  /// 'N' / 'S' / 'D'
  final String zone;

  /// 이 건물에 사무실이 있는 학과
  final List<String> departments;

  /// 층별 주요 시설 ('학생식당 · 편의점 (1층)' …)
  final List<String> facilities;

  /// 동 번호·이름·학과·시설 중 하나라도 검색어를 포함하면 true
  bool matches(String query) {
    final q = query.trim().toLowerCase().replaceAll(' ', '');
    if (q.isEmpty) return true;
    bool has(String s) => s.toLowerCase().replaceAll(' ', '').contains(q);
    return has(code) ||
        has(name) ||
        departments.any(has) ||
        facilities.any(has);
  }

  factory Building.fromJson(Map<String, dynamic> json) => Building(
        code: json['code'] as String? ?? '',
        name: json['name'] as String? ?? '',
        zone: json['zone'] as String? ?? '',
        departments: _strings(json['departments']),
        facilities: _strings(json['facilities']),
      );
}

class CampusBuildings {
  const CampusBuildings({required this.zones, required this.buildings});

  /// 'N' → 'N동 (공학 계열)'
  final Map<String, String> zones;
  final List<Building> buildings;

  factory CampusBuildings.fromJson(Map<String, dynamic> json) {
    final zones = <String, String>{};
    final rawZones = json['zones'];
    if (rawZones is Map) {
      rawZones.forEach((k, v) => zones[k.toString()] = v.toString());
    }
    return CampusBuildings(
      zones: zones,
      buildings: [
        for (final e in json['buildings'] as List? ?? const [])
          if (e is Map) Building.fromJson(Map<String, dynamic>.from(e)),
      ],
    );
  }
}

/// '평일' : '09:30 ~ 12:00, 13:00 ~ 20:30' 같은 한 줄 정보
class GymRow {
  const GymRow(this.label, this.text);

  final String label;
  final String text;

  factory GymRow.fromJson(Map<String, dynamic> json) => GymRow(
        json['label'] as String? ?? '',
        json['time'] as String? ?? json['text'] as String? ?? '',
      );
}

/// 헬스장 한 곳 (assets/data/gym.json)
class Gym {
  const Gym({
    required this.name,
    required this.location,
    required this.target,
    required this.isOpen,
    required this.notice,
    required this.hours,
    required this.fees,
    required this.howToJoin,
    required this.contact,
  });

  final String name;
  final String location;
  final String target;

  /// true: 운영 중, false: 운영 중단, null: 표시 안 함
  final bool? isOpen;
  final String notice;
  final List<GymRow> hours;
  final List<GymRow> fees;
  final String howToJoin;
  final String contact;

  factory Gym.fromJson(Map<String, dynamic> json) => Gym(
        name: json['name'] as String? ?? '',
        location: json['location'] as String? ?? '',
        target: json['target'] as String? ?? '',
        isOpen: json['isOpen'] as bool?,
        notice: json['notice'] as String? ?? '',
        hours: _rows(json['hours']),
        fees: _rows(json['fees']),
        howToJoin: json['howToJoin'] as String? ?? '',
        contact: json['contact'] as String? ?? '',
      );
}

/// 건물·헬스장 JSON을 읽어 둔다. 앱 실행 중 한 번만 읽는다.
class CampusRepository {
  CampusRepository._();
  static final instance = CampusRepository._();

  Future<CampusBuildings>? _buildings;
  Future<List<Gym>>? _gyms;

  Future<CampusBuildings> loadBuildings() => _buildings ??=
      _loadJson('assets/data/buildings.json').then(CampusBuildings.fromJson);

  Future<List<Gym>> loadGyms() => _gyms ??=
      _loadJson('assets/data/gym.json').then((json) => [
            for (final e in json['gyms'] as List? ?? const [])
              if (e is Map) Gym.fromJson(Map<String, dynamic>.from(e)),
          ]);

  static Future<Map<String, dynamic>> _loadJson(String path) async {
    final text = await rootBundle.loadString(path);
    return jsonDecode(text) as Map<String, dynamic>;
  }
}

List<String> _strings(Object? raw) =>
    raw is List ? [for (final e in raw) e.toString()] : <String>[];

List<GymRow> _rows(Object? raw) => raw is List
    ? [
        for (final e in raw)
          if (e is Map) GymRow.fromJson(Map<String, dynamic>.from(e)),
      ]
    : <GymRow>[];
