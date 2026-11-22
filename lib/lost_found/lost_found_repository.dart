import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'lost_found_item.dart';

/// 등록 실패 원인을 화면에서 안내하기 위한 예외.
class LostFoundException implements Exception {
  const LostFoundException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// 분실물 화면에서 Firestore 코드를 직접 다루지 않도록 분리한 저장소.
class LostFoundRepository {
  LostFoundRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _items =>
      _db.collection('lost_items');

  String? get currentUid => _auth.currentUser?.uid;

  /// Firestore 게시물을 등록일 기준 최신순으로 실시간 구독.
  Stream<List<LostFoundItem>> watchAll() => _items
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(LostFoundItem.fromDoc).toList());

  Future<void> create({
    required String type,
    required String title,
    required String category,
    required String buildingCode,
    required String location,
    required DateTime eventTime,
    required String description,
  }) async {
    final uid = currentUid;
    if (uid == null) {
      throw const LostFoundException(
        '로그인 정보를 찾지 못했어요. 페이지를 새로고침한 뒤 다시 시도해 주세요.',
      );
    }
    if (type != '분실물' && type != '습득물') {
      throw const LostFoundException('등록 유형을 확인해 주세요.');
    }
    if (title.trim().isEmpty || description.trim().isEmpty ||
        buildingCode.trim().isEmpty || category.trim().isEmpty) {
      throw const LostFoundException('필수 입력값을 모두 입력해 주세요.');
    }
    if (eventTime.isAfter(DateTime.now())) {
      throw const LostFoundException('분실·습득 시간은 현재보다 늦을 수 없어요.');
    }

    try {
      await _items.add({
        'type': type,
        'title': title.trim(),
        'category': category,
        'buildingCode': buildingCode,
        'location': location,
        'eventTime': Timestamp.fromDate(eventTime),
        'description': description.trim(),
        'status': 'open',
        'authorId': uid,
        // 팀 알림 기능에서 사용하는 필드: title, authorId, createdAt.
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw const LostFoundException(
          '게시물 등록 권한이 없어요. Firebase 규칙과 익명 로그인 설정을 확인해 주세요.',
        );
      }
      if (e.code == 'unavailable') {
        throw const LostFoundException('네트워크 연결을 확인해 주세요.');
      }
      throw LostFoundException('Firebase 저장에 실패했어요: ${e.message ?? e.code}');
    }
  }
}
