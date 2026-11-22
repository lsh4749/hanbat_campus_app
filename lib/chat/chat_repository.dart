import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../club/club.dart' show nicknameFor;
import 'chat_texts.dart';
import 'models/chat_models.dart';

/// # 익명/모임 채팅 Mock 데이터 저장소
/// - 추후 Firestore 연동 시 이 계층만 교체해야 함.
/// - 실제로는 Firestore에서 채팅방 목록, 메시지 목록, 읽음 처리, 고정 처리 등을 실시간 스트리밍으로 받아와야 할 것으로 보인다.
/// - 아니면 DB를 로컬에 캐싱하고, Firestore에서 변경이 있을 때만 업데이트하는 방식이 좋으려나?
/// - 내가 멍청해서 모르지... (실제로는 Firestore가 뭔지도모름, 폐급대학생)
class ChatRepository extends ChangeNotifier {
  ChatRepository._() {
    _rooms = _buildMockRooms();
  }

  static final ChatRepository instance = ChatRepository._();

  /// 현재 로그인한 내 익명 ID (Mock)
  /// 소모임·카풀과 같은 자동 익명 닉네임 (예: '용감한 너구리')
  /// 익명 로그인이 안 됐을 때만 예전 예시 이름을 쓴다.
  String get myUserId {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid == null ? '한밭_익명24' : nicknameFor(uid);
  }
  final Color myAvatarColor = AppColors.primary;

  late List<ChatRoom> _rooms;

  int _nextMessageSeq = 1000;

  /// 정렬 규칙이 반영된 채팅방 목록 반환.
  /// 1. 즐겨찾기(★)된 방이 최상단 고정 (가장 최근에 별을 누른 순)
  /// 2. 고정되지 않은 방은 최신 메시지 순
  List<ChatRoom> getRooms({bool unreadOnly = false}) {
    final filtered = unreadOnly
        ? _rooms.where((r) => r.hasUnread).toList()
        : List<ChatRoom>.from(_rooms);

    filtered.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      if (a.isPinned && b.isPinned) {
        final aPin = a.pinnedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bPin = b.pinnedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bPin.compareTo(aPin);
      }
      return b.lastMessageAt.compareTo(a.lastMessageAt);
    });
    return filtered;
  }

  int get totalUnreadRoomCount => _rooms.where((r) => r.hasUnread).length;

  ChatRoom? findRoomById(String roomId) {
    for (final room in _rooms) {
      if (room.id == roomId) return room;
    }
    return null;
  }

  /// 소모임 등 외부 화면에서 roomId/roomTitle로 바로 진입할 때 방을 조회하거나 생성.
  ChatRoom getOrCreateRoom({
    required String roomId,
    required String roomTitle,
    bool isGroup = true,
  }) {
    final existing = findRoomById(roomId);
    if (existing != null) return existing;

    final now = DateTime.now();
    final created = ChatRoom(
      id: roomId,
      title: roomTitle,
      isGroup: isGroup,
      avatarColor: AppColors.primary,
      avatarIcon: isGroup ? Icons.groups_rounded : Icons.person_rounded,
      messages: [
        ChatMessage(
          id: 'welcome_$roomId',
          senderId: 'id_leader',
          senderName: ChatTexts.defaultLeaderName,
          senderAvatarColor: AppColors.blueInk,
          type: ChatMessageType.text,
          text: ChatTexts.welcomeMessage(roomTitle),
          sentAt: now,
          readBy: const [],
        ),
      ],
    );
    _rooms.add(created);
    notifyListeners();
    return created;
  }

  /// 상단 고정(별표) 토글. 고정 시 현재 시각을 기록해 최신 고정 순으로 정렬.
  void togglePin(String roomId) {
    final idx = _rooms.indexWhere((r) => r.id == roomId);
    if (idx == -1) return;

    final current = _rooms[idx];
    final nextPinned = !current.isPinned;
    _rooms[idx] = current.copyWith(
      isPinned: nextPinned,
      pinnedAt: nextPinned ? DateTime.now() : null,
      clearPinnedAt: !nextPinned,
    );
    notifyListeners();
  }

  /// 채팅방 입장 시 읽음 처리.
  void markRoomAsRead(String roomId) {
    final idx = _rooms.indexWhere((r) => r.id == roomId);
    if (idx == -1) return;
    if (_rooms[idx].unreadCount == 0) return;

    _rooms[idx] = _rooms[idx].copyWith(unreadCount: 0);
    notifyListeners();
  }

  /// 새 메시지 전송 (텍스트 / 사진 / 동영상 + 선택적 답장 참조).
  ChatMessage sendMessage({
    required String roomId,
    required ChatMessageType type,
    required String text,
    ReplyReference? replyTo,
    String? mediaTitle,
    String? mediaDuration,
    Color? mediaAccentColor,
  }) {
    final idx = _rooms.indexWhere((r) => r.id == roomId);
    final now = DateTime.now();
    final message = ChatMessage(
      id: 'msg_${_nextMessageSeq++}',
      senderId: myUserId,
      senderName: myUserId,
      senderAvatarColor: myAvatarColor,
      type: type,
      text: text,
      mediaTitle: mediaTitle,
      mediaDuration: mediaDuration,
      mediaAccentColor: mediaAccentColor,
      sentAt: now,
      replyTo: replyTo,
      readBy: const [],
    );

    if (idx != -1) {
      final room = _rooms[idx];
      _rooms[idx] = room.copyWith(
        unreadCount: 0,
        messages: [...room.messages, message],
      );
      notifyListeners();
    }
    return message;
  }

  /// 모든 요구사항(1:1, 모임, 고정, 안 읽음, 연속 메시지, 텍스트/사진/동영상,
  /// 답장+원본 이동, 긴 읽음 목록, 오늘/어제/2일전/1주일전/26달전 시간 포맷)을
  /// 한눈에 테스트할 수 있는 Mock 데이터 구성.
  List<ChatRoom> _buildMockRooms() {
    final now = DateTime.now();
    final todayBase = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    );

    // 1) 고정된 모임 채팅방 (가장 최근 고정 + 안 읽음 + 모든 메시지 기능 집합)
    final futsalImgMsg = ChatMessage(
      id: 'f_m5',
      senderId: myUserId,
      senderName: myUserId,
      senderAvatarColor: myAvatarColor,
      type: ChatMessageType.image,
      text: '',
      mediaTitle: '대운동장 야간 조명 현장 사진',
      mediaAccentColor: const Color(0xFF16A34A),
      sentAt: todayBase.subtract(const Duration(minutes: 14)),
      readBy: const ['id_1', 'id_2', 'id_3'],
    );

    final futsalFirstMyMsg = ChatMessage(
      id: 'f_m3',
      senderId: myUserId,
      senderName: myUserId,
      senderAvatarColor: myAvatarColor,
      type: ChatMessageType.text,
      text: '저 10분 전에 정문 쪽에서 합류할게요! 공 챙겨가나요?',
      sentAt: todayBase.subtract(const Duration(minutes: 62)),
      readBy: const ['id_1', 'id_2'],
    );

    final futsalRoom = ChatRoom(
      id: 'club_futsal',
      title: '한밭대 저녁 풋살 번개 모임',
      isGroup: true,
      avatarColor: const Color(0xFF16A34A),
      avatarIcon: Icons.sports_soccer_rounded,
      unreadCount: 3,
      isPinned: true,
      pinnedAt: now.subtract(const Duration(minutes: 5)),
      messages: [
        // 연속 메시지 테스트 (id_1이 2개 연속 전송 -> 프로필 & 발신자 ID 1번만 표시)
        ChatMessage(
          id: 'f_m1',
          senderId: 'id_1',
          senderName: 'id_1',
          senderAvatarColor: const Color(0xFFEA580C),
          type: ChatMessageType.text,
          text: '다들 오늘 저녁 7시 대운동장 풋살 잊지 않으셨죠?',
          sentAt: todayBase.subtract(const Duration(minutes: 65)),
        ),
        ChatMessage(
          id: 'f_m2',
          senderId: 'id_1',
          senderName: 'id_1',
          senderAvatarColor: const Color(0xFFEA580C),
          type: ChatMessageType.text,
          text: '풋살화랑 물만 챙겨오시면 됩니다!',
          sentAt: todayBase.subtract(const Duration(minutes: 64)),
        ),
        futsalFirstMyMsg,
        // 텍스트 답장 메시지 (탭하면 f_m3으로 스크롤 + 하이라이트)
        ChatMessage(
          id: 'f_m4',
          senderId: 'id_2',
          senderName: 'id_2',
          senderAvatarColor: const Color(0xFF7C3AED),
          type: ChatMessageType.text,
          text: '네! 제가 풋살공 2개랑 조끼까지 다 챙겨놨어요 👍',
          sentAt: todayBase.subtract(const Duration(minutes: 58)),
          replyTo: ReplyReference.fromMessage(futsalFirstMyMsg),
        ),
        // 30분 이상 간격 -> 날짜/시간 구분선 자동 표시
        futsalImgMsg,
        // 사진에 대한 답장 (작은 썸네일 표시 + 탭 시 f_m5로 이동)
        ChatMessage(
          id: 'f_m6',
          senderId: 'id_3',
          senderName: 'id_3',
          senderAvatarColor: const Color(0xFF0284C7),
          type: ChatMessageType.text,
          text: '오 조명 엄청 밝네요! 벌써 뛰고 싶다',
          sentAt: todayBase.subtract(const Duration(minutes: 10)),
          replyTo: ReplyReference.fromMessage(futsalImgMsg),
        ),
        // 동영상 메시지 (중앙 재생 아이콘 오버레이)
        ChatMessage(
          id: 'f_m7',
          senderId: 'id_1',
          senderName: 'id_1',
          senderAvatarColor: const Color(0xFFEA580C),
          type: ChatMessageType.video,
          text: '',
          mediaTitle: '지난주 골 하이라이트.mp4',
          mediaDuration: '0:24',
          mediaAccentColor: const Color(0xFF0F766E),
          sentAt: todayBase.subtract(const Duration(minutes: 7)),
        ),
        // 내 메시지 + 긴 읽음 목록 (1줄 말줄임 ellipsis 테스트)
        ChatMessage(
          id: 'f_m8',
          senderId: myUserId,
          senderName: myUserId,
          senderAvatarColor: myAvatarColor,
          type: ChatMessageType.text,
          text: '좋아요! 그럼 7시 정각에 골대 앞에서 모여요!',
          sentAt: todayBase.subtract(const Duration(minutes: 3)),
          readBy: const ['id_1', 'id_2', 'id_3', 'id_4', 'id_5', 'id_6'],
        ),
      ],
    );

    // 2) 두 번째 고정된 1:1 채팅방 (어제 메시지 + 스케치 흐름 반영 + 읽지 않음 테스트)
    final yesterday = DateTime(now.year, now.month, now.day - 1, 21, 16);
    final dmMyGreeting = ChatMessage(
      id: 'd_m2',
      senderId: myUserId,
      senderName: myUserId,
      senderAvatarColor: myAvatarColor,
      type: ChatMessageType.text,
      text: '안녕?',
      sentAt: yesterday.subtract(const Duration(minutes: 45)),
      readBy: const ['익명_컴공23'],
    );

    final dmRoom = ChatRoom(
      id: 'dm_cs23',
      title: '익명_컴공23',
      isGroup: false,
      avatarColor: const Color(0xFF2563EB),
      avatarIcon: Icons.person_rounded,
      unreadCount: 0,
      isPinned: true,
      pinnedAt: now.subtract(const Duration(hours: 2)),
      messages: [
        ChatMessage(
          id: 'd_m1',
          senderId: '익명_컴공23',
          senderName: '익명_컴공23',
          senderAvatarColor: const Color(0xFF2563EB),
          type: ChatMessageType.text,
          text: '안녕?',
          sentAt: yesterday.subtract(const Duration(minutes: 48)),
        ),
        dmMyGreeting,
        ChatMessage(
          id: 'd_m3',
          senderId: '익명_컴공23',
          senderName: '익명_컴공23',
          senderAvatarColor: const Color(0xFF2563EB),
          type: ChatMessageType.text,
          text: '무슨 일이야?',
          sentAt: yesterday.subtract(const Duration(minutes: 44)),
          replyTo: ReplyReference.fromMessage(dmMyGreeting),
        ),
        // 30분 이상 경과 -> 날짜/시간 구분선 표시
        ChatMessage(
          id: 'd_m4',
          senderId: myUserId,
          senderName: myUserId,
          senderAvatarColor: myAvatarColor,
          type: ChatMessageType.text,
          text: '자료구조 과제 참고자료 사진 보내줄 수 있어?',
          sentAt: yesterday,
          readBy: const ['익명_컴공23'],
        ),
        // 연속 메시지 (사진 + 텍스트)
        ChatMessage(
          id: 'd_m5',
          senderId: '익명_컴공23',
          senderName: '익명_컴공23',
          senderAvatarColor: const Color(0xFF2563EB),
          type: ChatMessageType.image,
          text: '',
          mediaTitle: '자료구조 필기 정리 노트',
          mediaAccentColor: const Color(0xFF4F46E5),
          sentAt: yesterday.add(const Duration(minutes: 2)),
        ),
        ChatMessage(
          id: 'd_m6',
          senderId: '익명_컴공23',
          senderName: '익명_컴공23',
          senderAvatarColor: const Color(0xFF2563EB),
          type: ChatMessageType.text,
          text: '여기 정리본이야! 확인해 봐',
          sentAt: yesterday.add(const Duration(minutes: 3)),
        ),
        ChatMessage(
          id: 'd_m7',
          senderId: myUserId,
          senderName: myUserId,
          senderAvatarColor: myAvatarColor,
          type: ChatMessageType.text,
          text: '고마워!! 내일 커피 살게 ☕',
          sentAt: yesterday.add(const Duration(minutes: 5)),
          readBy: const [], // 읽지 않음 표시 테스트
        ),
      ],
    );

    // 3) 고정 안 됨 · 안 읽음 · 2일 전 (모임 채팅)
    final twoDaysAgo = DateTime(now.year, now.month, now.day - 2, 18, 20);
    final carpoolRoom = ChatRoom(
      id: 'club_carpool',
      title: '유성온천역 택시 카풀',
      isGroup: true,
      avatarColor: const Color(0xFFD97706),
      avatarIcon: Icons.local_taxi_rounded,
      unreadCount: 2,
      messages: [
        ChatMessage(
          id: 'c_m1',
          senderId: 'id_taxi1',
          senderName: 'id_taxi1',
          senderAvatarColor: const Color(0xFFD97706),
          type: ChatMessageType.text,
          text: '정문 버스정류장 앞에 도착했습니다!',
          sentAt: twoDaysAgo.subtract(const Duration(minutes: 4)),
        ),
        ChatMessage(
          id: 'c_m2',
          senderId: 'id_taxi2',
          senderName: 'id_taxi2',
          senderAvatarColor: const Color(0xFF059669),
          type: ChatMessageType.text,
          text: '저도 지금 나가는 중이에요 2분만 기다려주세요!',
          sentAt: twoDaysAgo,
        ),
      ],
    );

    // 4) 고정 안 됨 · 읽음 · 1주일 전 (모임 채팅)
    final oneWeekAgo = DateTime(now.year, now.month, now.day - 7, 15, 10);
    final studyRoom = ChatRoom(
      id: 'club_algo',
      title: 'N4동 알고리즘 스터디',
      isGroup: true,
      avatarColor: const Color(0xFF7C3AED),
      avatarIcon: Icons.code_rounded,
      unreadCount: 0,
      messages: [
        ChatMessage(
          id: 's_m1',
          senderId: 'id_algo1',
          senderName: 'id_algo1',
          senderAvatarColor: const Color(0xFF7C3AED),
          type: ChatMessageType.text,
          text: '이번 주 백준 실버 3문제 풀이 영상 공유드려요.',
          sentAt: oneWeekAgo.subtract(const Duration(minutes: 5)),
        ),
        ChatMessage(
          id: 's_m2',
          senderId: 'id_algo1',
          senderName: 'id_algo1',
          senderAvatarColor: const Color(0xFF7C3AED),
          type: ChatMessageType.video,
          text: '',
          mediaTitle: 'DP 점화식 풀이 설명.mp4',
          mediaDuration: '4:12',
          mediaAccentColor: const Color(0xFF6D28D9),
          sentAt: oneWeekAgo,
        ),
      ],
    );

    // 5) 고정 안 됨 · 안 읽음 · 3주일 전 (1:1 분실물 채팅)
    final threeWeeksAgo = DateTime(now.year, now.month, now.day - 21, 11, 30);
    final lostFoundRoom = ChatRoom(
      id: 'dm_lost',
      title: '익명_도서관습득자',
      isGroup: false,
      avatarColor: const Color(0xFFDC2626),
      avatarIcon: Icons.search_rounded,
      unreadCount: 1,
      messages: [
        ChatMessage(
          id: 'l_m1',
          senderId: '익명_도서관습득자',
          senderName: '익명_도서관습득자',
          senderAvatarColor: const Color(0xFFDC2626),
          type: ChatMessageType.text,
          text: '혹시 도서관 3층에서 에어팟 케이스 잃어버리신 분 맞으신가요?',
          sentAt: threeWeeksAgo,
        ),
      ],
    );

    // 6) 고정 안 됨 · 읽음 · 26달 전 (년 단위 변환 없이 '26달 전' 표시 테스트!)
    final twentySixMonthsAgo = DateTime(now.year - 2, now.month - 2, 10, 14, 0);
    final oldRoom = ChatRoom(
      id: 'club_ot_old',
      title: '신입생 OT 1조 단톡방',
      isGroup: true,
      avatarColor: const Color(0xFF64748B),
      avatarIcon: Icons.celebration_rounded,
      unreadCount: 0,
      messages: [
        ChatMessage(
          id: 'o_m1',
          senderId: 'id_ot_leader',
          senderName: 'id_ot_leader',
          senderAvatarColor: const Color(0xFF475569),
          type: ChatMessageType.text,
          text: '다들 OT 너무 즐거웠어요! 개강하고 학식 같이 먹어요 🙌',
          sentAt: twentySixMonthsAgo,
        ),
      ],
    );

    return [futsalRoom, dmRoom, carpoolRoom, studyRoom, lostFoundRoom, oldRoom];
  }
}
