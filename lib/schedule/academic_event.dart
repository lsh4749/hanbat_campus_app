import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// 학사일정 한 건 (assets/data/academic_schedule.json)
class AcademicEvent {
  final String title;
  final DateTime start;
  final DateTime end; // 하루짜리 일정이면 start와 같음
  final String type;

  const AcademicEvent({
    required this.title,
    required this.start,
    required this.end,
    required this.type,
  });

  factory AcademicEvent.fromJson(Map<String, dynamic> json) {
    final start = DateTime.parse(json['start'] as String);
    final endText = json['end'] as String?;
    return AcademicEvent(
      title: json['title'] as String,
      start: start,
      end: endText == null ? start : DateTime.parse(endText),
      type: json['type'] as String? ?? 'event',
    );
  }

  bool get isSingleDay => _dateOnly(start) == _dateOnly(end);

  bool isOngoing(DateTime now) {
    final today = _dateOnly(now);
    return !today.isBefore(_dateOnly(start)) && !today.isAfter(_dateOnly(end));
  }

  bool isPast(DateTime now) => _dateOnly(now).isAfter(_dateOnly(end));

  /// 'D-3', 'D-Day', '진행중', '종료'
  String dDayLabel(DateTime now) {
    if (isPast(now)) return '종료';
    if (isOngoing(now)) return isSingleDay ? 'D-Day' : '진행중';
    final days = _dateOnly(start).difference(_dateOnly(now)).inDays;
    return 'D-$days';
  }

  /// '12.14(월)' 또는 '12.14(월) ~ 12.18(금)'
  String get periodLabel {
    if (isSingleDay) return formatShortDate(start);
    return '${formatShortDate(start)} ~ ${formatShortDate(end)}';
  }

  String get typeLabel => _typeInfo[type]?.label ?? '일정';
  Color get typeColor => _typeInfo[type]?.color ?? Colors.blueGrey;
  IconData get typeIcon => _typeInfo[type]?.icon ?? Icons.event;

  static const Map<String, _TypeInfo> _typeInfo = {
    'exam': _TypeInfo('시험', Colors.red, Icons.edit_note),
    'course': _TypeInfo('수강', Colors.indigo, Icons.menu_book),
    'tuition': _TypeInfo('등록금', Colors.teal, Icons.payments_outlined),
    'vacation': _TypeInfo('방학', Colors.orange, Icons.beach_access),
    'event': _TypeInfo('행사', Color(0xFF004098), Icons.celebration_outlined),
  };
}

class _TypeInfo {
  final String label;
  final Color color;
  final IconData icon;
  const _TypeInfo(this.label, this.color, this.icon);
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

String formatShortDate(DateTime d) =>
    '${d.month}.${d.day}(${_weekdays[d.weekday - 1]})';

/// JSON을 읽어 시작일 순으로 정렬해 돌려준다. 앱 실행 중 한 번만 읽는다.
class AcademicScheduleRepository {
  AcademicScheduleRepository._();
  static final instance = AcademicScheduleRepository._();

  static const _assetPath = 'assets/data/academic_schedule.json';
  Future<List<AcademicEvent>>? _cache;

  Future<List<AcademicEvent>> loadAll() {
    return _cache ??= _load();
  }

  /// 아직 끝나지 않은 일정 중 가까운 순으로 [limit]개
  Future<List<AcademicEvent>> loadUpcoming({int limit = 3}) async {
    final now = DateTime.now();
    final all = await loadAll();
    return all.where((e) => !e.isPast(now)).take(limit).toList();
  }

  Future<List<AcademicEvent>> _load() async {
    final text = await rootBundle.loadString(_assetPath);
    final json = jsonDecode(text) as Map<String, dynamic>;
    final events = (json['events'] as List)
        .map((e) => AcademicEvent.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    return events;
  }
}
