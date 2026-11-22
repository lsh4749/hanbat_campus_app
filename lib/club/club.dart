import 'package:cloud_firestore/cloud_firestore.dart';

/// 소모임 모집글 한 건을 나타내는 모델.
///
/// Firestore `clubs` 컬렉션 문서 구조:
/// - category: '운동' | '게임' | '스터디' | '공모전' | '자유'
/// - title, location, description: String
/// - meetAt: 모임 일시 (Timestamp). 이 시간이 지나면 자동으로 '모임 종료'
/// - time: 화면 표시용 일시 문자열 (예전 글 호환용, meetAt이 없으면 이걸 보여줌)
/// - creatorId: 작성자 uid (Firebase 익명 로그인)
/// - creatorNickname: 작성자 익명 닉네임 (예: '용감한 너구리')
/// - participants: 참여자 uid 목록 (작성자 포함)
/// - currentMembers: participants 길이와 항상 같게 유지 (보안 규칙에서 검사)
/// - maxMembers: 정원 (2~30)
/// - isClosedEarly: 모임장 조기 마감 여부
/// - createdAt, updatedAt: 서버 시간
class Club {
  static const List<String> categories = ['운동', '게임', '스터디', '공모전', '자유'];

  final String id;
  final String category;
  final String title;
  final String location;
  final String time;
  final DateTime? meetAt;
  final String description;
  final String creatorId;
  final String creatorNickname;
  final List<String> participants;
  final int maxMembers;
  final bool isClosedEarly;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Club({
    required this.id,
    required this.category,
    required this.title,
    required this.location,
    required this.time,
    required this.description,
    required this.creatorId,
    required this.creatorNickname,
    required this.participants,
    required this.maxMembers,
    required this.isClosedEarly,
    this.meetAt,
    this.createdAt,
    this.updatedAt,
  });

  /// 인원 수는 참여자 목록 길이 하나로만 계산한다.
  int get currentMembers => participants.length;
  bool get isFull => currentMembers >= maxMembers;

  /// 모임 시간이 지났는지 (meetAt이 없는 예전 글은 종료되지 않음)
  bool get isExpired => meetAt != null && DateTime.now().isAfter(meetAt!);

  bool get isRecruiting => !isFull && !isClosedEarly && !isExpired;

  /// 정원의 50%를 넘게 모인 인기 모임 (홈 화면 불꽃 표시)
  bool get isHot => maxMembers > 0 && currentMembers / maxMembers > 0.5;

  /// 한 번이라도 수정됐는지 (작성 후 1분 넘게 지나서 바뀐 경우만 표시)
  bool get isEdited =>
      updatedAt != null &&
      createdAt != null &&
      updatedAt!.difference(createdAt!).inMinutes >= 1;

  String get statusLabel {
    if (isExpired) return '모임 종료';
    if (isClosedEarly) return '조기 마감';
    if (isFull) return '모집 마감';
    return '모집중';
  }

  /// 화면에 보여줄 일시. meetAt이 있으면 '오늘 19:00', '11.24(화) 19:00' 형식
  String get timeLabel => meetAt == null ? time : formatMeetAt(meetAt!);

  factory Club.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return Club(
      id: doc.id,
      category: data['category'] as String? ?? '자유',
      title: data['title'] as String? ?? '제목 없음',
      location: data['location'] as String? ?? '',
      time: data['time'] as String? ?? '',
      meetAt: (data['meetAt'] as Timestamp?)?.toDate(),
      description: data['description'] as String? ?? '',
      creatorId: data['creatorId'] as String? ?? '',
      creatorNickname: data['creatorNickname'] as String? ?? '익명',
      participants: List<String>.from(data['participants'] ?? const []),
      maxMembers: (data['maxMembers'] as num?)?.toInt() ?? 4,
      isClosedEarly: data['isClosedEarly'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

/// '오늘 19:00' / '내일 07:30' / '11.24(화) 19:00'
String formatMeetAt(DateTime t) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(t.year, t.month, t.day);
  final diff = day.difference(today).inDays;
  final hm =
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  if (diff == 0) return '오늘 $hm';
  if (diff == 1) return '내일 $hm';
  if (diff == 2) return '모레 $hm';
  return '${t.month}.${t.day}(${_weekdays[t.weekday - 1]}) $hm';
}

/// uid로 항상 같은 익명 닉네임을 만든다. (예: '용감한 너구리')
/// 같은 기기(같은 uid)는 앱을 다시 켜도 같은 닉네임이 나온다.
String nicknameFor(String uid) {
  const adjectives = [
    '용감한', '졸린', '배고픈', '신난', '수줍은', '부지런한', '느긋한', '씩씩한',
    '똑똑한', '다정한', '엉뚱한', '활발한', '조용한', '반짝이는', '행복한', '든든한',
  ];
  const nouns = [
    '너구리', '고양이', '펭귄', '다람쥐', '수달', '부엉이', '여우', '판다',
    '토끼', '거북이', '햄스터', '참새', '고슴도치', '돌고래', '코알라', '한밭이',
  ];
  // 간단한 문자열 해시 (기기·실행마다 결과가 같도록 직접 계산)
  var hash = 0;
  for (final code in uid.codeUnits) {
    hash = (hash * 31 + code) & 0x7fffffff;
  }
  final adjective = adjectives[hash % adjectives.length];
  final noun = nouns[(hash ~/ adjectives.length) % nouns.length];
  return '$adjective $noun';
}
