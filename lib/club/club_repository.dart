import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'club.dart';

/// 화면에 그대로 보여줄 수 있는 한국어 메시지를 담은 예외.
class ClubException implements Exception {
  final String message;
  const ClubException(this.message);

  @override
  String toString() => message;
}

/// 소모임 Firestore 접근을 한곳에 모은 클래스.
/// 화면(ClubScreen)과 홈 미리보기 카드가 같이 사용한다.
class ClubRepository {
  ClubRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _clubs =>
      _db.collection('clubs');

  /// 현재 기기의 익명 사용자 uid. 로그인에 실패했으면 null.
  String? get currentUid => _auth.currentUser?.uid;

  String _requireUid() {
    final uid = currentUid;
    if (uid == null) {
      throw const ClubException('사용자 정보를 불러오지 못했어요. 앱을 다시 실행해 주세요.');
    }
    return uid;
  }

  /// 전체 모집글 (최신순)
  Stream<List<Club>> watchAll() {
    return _clubs
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Club.fromDoc).toList());
  }

  /// 홈 화면용: 아직 모집 중인 최신 글 몇 개
  Stream<List<Club>> watchRecruiting({int limit = 3}) {
    return _clubs
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map((snap) => snap.docs
            .map(Club.fromDoc)
            .where((c) => c.isRecruiting)
            .take(limit)
            .toList());
  }

  Future<void> create({
    required String category,
    required String title,
    required String location,
    required String time,
    required String description,
    required int maxMembers,
  }) async {
    final uid = _requireUid();
    await _guard(() => _clubs.add({
          'category': category,
          'title': title,
          'location': location,
          'time': time,
          'description': description,
          'creatorId': uid,
          'participants': [uid],
          'currentMembers': 1,
          'maxMembers': maxMembers,
          'isClosedEarly': false,
          'createdAt': FieldValue.serverTimestamp(),
        }));
  }

  /// 참여하기. 트랜잭션으로 최신 인원을 다시 읽고 확인하므로
  /// 여러 명이 동시에 눌러도 정원을 넘지 않는다.
  Future<void> join(String clubId) async {
    final uid = _requireUid();
    final ref = _clubs.doc(clubId);
    await _guard(() => _db.runTransaction((tx) async {
          final snap = await tx.get(ref);
          if (!snap.exists) throw const ClubException('삭제된 모집글이에요.');
          final club = Club.fromDoc(snap);

          if (club.participants.contains(uid)) return;
          if (club.isClosedEarly) {
            throw const ClubException('모임장이 모집을 마감했어요.');
          }
          if (club.isFull) throw const ClubException('정원이 가득 찼어요.');

          final updated = [...club.participants, uid];
          tx.update(ref, {
            'participants': updated,
            'currentMembers': updated.length,
          });
        }));
  }

  /// 참여 취소. 모임장은 나갈 수 없고, 대신 글을 삭제한다.
  Future<void> leave(String clubId) async {
    final uid = _requireUid();
    final ref = _clubs.doc(clubId);
    await _guard(() => _db.runTransaction((tx) async {
          final snap = await tx.get(ref);
          if (!snap.exists) return;
          final club = Club.fromDoc(snap);

          if (club.creatorId == uid) {
            throw const ClubException('모임장은 나갈 수 없어요. 모집글을 삭제해 주세요.');
          }
          if (!club.participants.contains(uid)) return;

          final updated = club.participants.where((p) => p != uid).toList();
          tx.update(ref, {
            'participants': updated,
            'currentMembers': updated.length,
          });
        }));
  }

  Future<void> setClosedEarly(String clubId, bool closed) {
    return _guard(() => _clubs.doc(clubId).update({'isClosedEarly': closed}));
  }

  Future<void> delete(String clubId) {
    return _guard(() => _clubs.doc(clubId).delete());
  }

  /// Firestore 오류를 사용자에게 보여줄 메시지로 바꾼다.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ClubException {
      rethrow;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw const ClubException('권한이 없어요. (본인 글만 수정·삭제할 수 있어요)');
      }
      if (e.code == 'unavailable') {
        throw const ClubException('네트워크 연결을 확인해 주세요.');
      }
      throw ClubException('오류가 발생했어요: ${e.message ?? e.code}');
    }
  }
}
