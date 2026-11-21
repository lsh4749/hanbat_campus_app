import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../club/club.dart';
import '../schedule/academic_event.dart';

enum NotificationType { club, lostFound, chat, schedule }

/// 알림 한 건
class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;

  /// 관련 문서/방 id (소모임 id, 채팅방 id 등)
  final String? refId;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.refId,
  });
}

/// 앱 안 알림함. 홈 화면 종 버튼과 알림 화면이 이 객체를 바라본다.
///
/// 알림이 생기는 경우
/// 1. 새 소모임 글 (다른 사람이 올린 글, 최근 3일)       → Firestore `clubs`
/// 2. 새 분실물 글 (다른 사람이 올린 글, 최근 3일)       → Firestore [lostFoundCollection]
/// 3. 나에게 온 새 채팅                                  → 채팅 기능에서 [addChatMessage] 호출
/// 4. 내가 알림을 켠 학사 일정의 하루 전 / 당일          → 일정 화면 종 버튼
///
/// ※ 앱이 켜져 있을 때 알림함에 쌓이는 방식이에요. 앱이 꺼져 있을 때 휴대폰
///   상단에 뜨는 푸시 알림은 FCM(Firebase Cloud Messaging) 설정이 추가로 필요해요.
class NotificationCenter extends ChangeNotifier {
  NotificationCenter._();
  static final NotificationCenter instance = NotificationCenter._();

  /// TODO(권수웅): 분실물 게시판의 Firestore 컬렉션 이름이 정해지면 맞춰 주세요.
  /// 문서에 createdAt(Timestamp), title(또는 itemName), authorId 필드가 있으면 알림이 떠요.
  static const lostFoundCollection = 'lost_items';

  static const _kLastReadMs = 'notif_last_read_ms';
  static const _kReadSchedule = 'notif_read_schedule_ids';
  static const _kAlarms = 'schedule_alarm_keys';
  static const _recentDays = 3;

  final List<AppNotification> _club = [];
  final List<AppNotification> _lostFound = [];
  final List<AppNotification> _chat = [];
  final List<AppNotification> _schedule = [];

  SharedPreferences? _prefs;
  DateTime _lastReadAt = DateTime.fromMillisecondsSinceEpoch(0);
  Set<String> _readScheduleIds = {};
  Set<String> _alarmKeys = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _clubSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _lostSub;
  bool _started = false;

  /// 최신순 전체 알림
  List<AppNotification> get items {
    final all = [..._club, ..._lostFound, ..._chat, ..._schedule];
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all;
  }

  int get unreadCount => items.where(isUnread).length;

  bool isUnread(AppNotification n) {
    if (n.type == NotificationType.schedule) {
      return !_readScheduleIds.contains(n.id);
    }
    return n.createdAt.isAfter(_lastReadAt);
  }

  /// 앱 시작 시 한 번 호출 (main.dart)
  Future<void> start() async {
    if (_started) return;
    _started = true;

    _prefs = await SharedPreferences.getInstance();
    final lastMs = _prefs!.getInt(_kLastReadMs);
    if (lastMs == null) {
      // 처음 설치한 경우: 예전 글이 전부 '안 읽음'으로 쌓이지 않게 지금을 기준으로 삼는다.
      _lastReadAt = DateTime.now();
      await _prefs!.setInt(_kLastReadMs, _lastReadAt.millisecondsSinceEpoch);
    } else {
      _lastReadAt = DateTime.fromMillisecondsSinceEpoch(lastMs);
    }
    _readScheduleIds = (_prefs!.getStringList(_kReadSchedule) ?? []).toSet();
    _alarmKeys = (_prefs!.getStringList(_kAlarms) ?? []).toSet();

    _listenClubs();
    _listenLostFound();
    await refreshSchedule();
  }

  /// 알림함을 열었을 때: 지금까지 온 알림을 모두 읽음 처리
  Future<void> markAllRead() async {
    _lastReadAt = DateTime.now();
    _readScheduleIds.addAll(_schedule.map((n) => n.id));
    notifyListeners();
    await _prefs?.setInt(_kLastReadMs, _lastReadAt.millisecondsSinceEpoch);
    await _prefs?.setStringList(_kReadSchedule, _readScheduleIds.toList());
  }

  // ---------------------------------------------------------------- 소모임
  Timestamp get _since => Timestamp.fromDate(
      DateTime.now().subtract(const Duration(days: _recentDays)));

  void _listenClubs() {
    _clubSub = FirebaseFirestore.instance
        .collection('clubs')
        .where('createdAt', isGreaterThan: _since)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .listen((snap) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      _club
        ..clear()
        ..addAll(snap.docs
            .map(Club.fromDoc)
            .where((c) => c.createdAt != null && c.creatorId != uid)
            .map((c) => AppNotification(
                  id: 'club_${c.id}',
                  type: NotificationType.club,
                  title: '새 소모임이 올라왔어요',
                  body: '[${c.category}] ${c.title}',
                  createdAt: c.createdAt!,
                  refId: c.id,
                )));
      notifyListeners();
    }, onError: (Object e) => debugPrint('소모임 알림 구독 실패: $e'));
  }

  // ---------------------------------------------------------------- 분실물
  void _listenLostFound() {
    _lostSub = FirebaseFirestore.instance
        .collection(lostFoundCollection)
        .where('createdAt', isGreaterThan: _since)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .listen((snap) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      _lostFound
        ..clear()
        ..addAll(snap.docs.where((d) {
          final data = d.data();
          return data['createdAt'] is Timestamp && data['authorId'] != uid;
        }).map((d) {
          final data = d.data();
          final name = (data['title'] ?? data['itemName'] ?? '물건').toString();
          return AppNotification(
            id: 'lost_${d.id}',
            type: NotificationType.lostFound,
            title: '새 분실물 글이 올라왔어요',
            body: name,
            createdAt: (data['createdAt'] as Timestamp).toDate(),
            refId: d.id,
          );
        }));
      notifyListeners();
    }, onError: (Object e) => debugPrint('분실물 알림 구독 실패: $e'));
  }

  // ---------------------------------------------------------------- 채팅
  /// TODO(여창건): 나에게 새 메시지가 왔을 때(내가 보낸 메시지가 아닐 때) 호출해 주세요.
  /// 예) NotificationCenter.instance.addChatMessage(
  ///       roomId: 'club_abc', roomTitle: '풋살 모임', message: '7시에 정문에서 봬요');
  void addChatMessage({
    required String roomId,
    required String roomTitle,
    required String message,
  }) {
    final now = DateTime.now();
    _chat.insert(
      0,
      AppNotification(
        id: 'chat_${roomId}_${now.microsecondsSinceEpoch}',
        type: NotificationType.chat,
        title: '$roomTitle · 새 메시지',
        body: message,
        createdAt: now,
        refId: roomId,
      ),
    );
    if (_chat.length > 30) _chat.removeLast();
    notifyListeners();
  }

  // ---------------------------------------------------------------- 학사 일정
  static String alarmKey(AcademicEvent e) =>
      '${e.title}|${e.start.toIso8601String()}';

  bool isAlarmOn(AcademicEvent e) => _alarmKeys.contains(alarmKey(e));

  /// 일정 알림 켜기/끄기. 켜면 true를 돌려준다.
  Future<bool> toggleAlarm(AcademicEvent e) async {
    final key = alarmKey(e);
    final on = !_alarmKeys.contains(key);
    if (on) {
      _alarmKeys.add(key);
    } else {
      _alarmKeys.remove(key);
    }
    await _prefs?.setStringList(_kAlarms, _alarmKeys.toList());
    await refreshSchedule();
    return on;
  }

  /// 알림 켠 일정 중 내일 시작(하루 전 알림) / 오늘 시작(당일 알림)인 것을 알림함에 넣는다.
  Future<void> refreshSchedule() async {
    final List<AcademicEvent> events;
    try {
      events = await AcademicScheduleRepository.instance.loadAll();
    } catch (e) {
      debugPrint('일정 알림 계산 실패: $e');
      return;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dayTag = '${today.year}${today.month}${today.day}';

    _schedule.clear();
    for (final e in events) {
      if (!isAlarmOn(e)) continue;
      final start = DateTime(e.start.year, e.start.month, e.start.day);
      final String title;
      if (start == tomorrow) {
        title = '내일 일정이 있어요';
      } else if (start == today) {
        title = '오늘 일정이에요';
      } else {
        continue;
      }
      _schedule.add(AppNotification(
        // 날짜를 id에 넣어서 하루 전 알림과 당일 알림을 따로 읽음 처리한다.
        id: 'sched_${alarmKey(e)}_$dayTag',
        type: NotificationType.schedule,
        title: title,
        body: '${e.title} · ${e.periodLabel}',
        createdAt: today,
      ));
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _clubSub?.cancel();
    _lostSub?.cancel();
    super.dispose();
  }
}
