import 'package:cloud_firestore/cloud_firestore.dart';

/// 소모임 모집글 한 건을 나타내는 모델.
///
/// Firestore `clubs` 컬렉션 문서 구조:
/// - category: '운동' | '게임' | '스터디' | '자유'
/// - title, location, time, description: String
/// - creatorId: 작성자 uid (Firebase 익명 로그인)
/// - participants: 참여자 uid 목록 (작성자 포함)
/// - currentMembers: participants 길이와 항상 같게 유지 (보안 규칙에서 검사)
/// - maxMembers: 정원 (2~30)
/// - isClosedEarly: 모임장 조기 마감 여부
/// - createdAt: 서버 시간
class Club {
  static const List<String> categories = ['운동', '게임', '스터디', '자유'];

  final String id;
  final String category;
  final String title;
  final String location;
  final String time;
  final String description;
  final String creatorId;
  final List<String> participants;
  final int maxMembers;
  final bool isClosedEarly;
  final DateTime? createdAt;

  const Club({
    required this.id,
    required this.category,
    required this.title,
    required this.location,
    required this.time,
    required this.description,
    required this.creatorId,
    required this.participants,
    required this.maxMembers,
    required this.isClosedEarly,
    this.createdAt,
  });

  /// 인원 수는 참여자 목록 길이 하나로만 계산한다.
  int get currentMembers => participants.length;
  bool get isFull => currentMembers >= maxMembers;
  bool get isRecruiting => !isFull && !isClosedEarly;

  /// 정원의 50%를 넘게 모인 인기 모임 (홈 화면 불꽃 표시)
  bool get isHot => maxMembers > 0 && currentMembers / maxMembers > 0.5;

  String get statusLabel {
    if (isClosedEarly) return '조기 마감';
    if (isFull) return '모집 마감';
    return '모집중';
  }

  factory Club.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return Club(
      id: doc.id,
      category: data['category'] as String? ?? '자유',
      title: data['title'] as String? ?? '제목 없음',
      location: data['location'] as String? ?? '',
      time: data['time'] as String? ?? '',
      description: data['description'] as String? ?? '',
      creatorId: data['creatorId'] as String? ?? '',
      participants: List<String>.from(data['participants'] ?? const []),
      maxMembers: (data['maxMembers'] as num?)?.toInt() ?? 4,
      isClosedEarly: data['isClosedEarly'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
