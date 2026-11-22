/// `lib/chat/` 화면 및 위젯에서 사용하는 UI 텍스트 모음.
class ChatTexts {
  ChatTexts._();

  // 채팅방 목록 (ChatRepoScreen)
  static const repoTitle = '익명 메시지';
  static const filterAll = '전체';
  static const filterUnread = '읽지 않음';
  static const meLabel = '나';
  static const emptyUnreadTitle = '읽지 않은 메시지가 없어요';
  static const emptyUnreadSubtitle = '모든 익명 메시지를 확인했습니다.';
  static const emptyRoomTitle = '아직 채팅방이 없어요';
  static const emptyRoomSubtitle = '소모임이나 게시글에서 새로운 대화를 시작해 보세요.';
  static const noMessagesYet = '아직 대화가 없습니다.';

  // 개별 채팅방 (ChatScreen)
  static const defaultRoomTitle = '익명 채팅방';
  static const tooltipBack = '뒤로가기';
  static const tooltipPin = '상단 고정';
  static const tooltipUnpin = '상단 고정 해제';
  static const snackPinned = '채팅방을 상단에 고정했어요.';
  static const snackUnpinned = '상단 고정을 해제했어요.';
  static const snackOriginalNotFound = '원본 메시지를 찾을 수 없어요.';
  static const defaultLeaderName = '모임장';

  static String welcomeMessage(String roomTitle) =>
      '$roomTitle 채팅방에 오신 걸 환영해요!';

  // 말풍선 · 답장 · 읽음 상태
  static const repliedNotice = '답장을 보냈어요.';
  static const tooltipCancelReply = '답장 취소';
  static const unreadStatus = '읽지 않음';

  static String replyingTo(String senderName) => '$senderName님에게 답장';
  static String readByUser(String userId) => '$userId님이 읽음';

  // 미디어 (사진 · 동영상)
  static const mediaPhoto = '사진';
  static const mediaVideo = '동영상';
  static const sentPhoto = '사진을 보냈습니다.';
  static const sentVideo = '동영상을 보냈습니다.';
  static const previewPhotoFallback = '사진 미리보기 (Mock)';
  static const previewVideoFallback = '동영상 미리보기 (Mock)';

  static String photoSummary(String caption) =>
      caption.isNotEmpty ? '$mediaPhoto · $caption' : sentPhoto;
  static String videoSummary(String caption) =>
      caption.isNotEmpty ? '$mediaVideo · $caption' : sentVideo;
  static String videoDurationLabel(String duration) =>
      '$mediaVideo · $duration';

  // 하단 입력창 & 첨부 시트
  static const inputHint = '메시지 보내기..';
  static const tooltipAttachMedia = '사진 · 동영상 첨부';
  static const attachSheetTitle = '사진 · 동영상 보내기 (Mock)';
  static const attachSheetSubtitle = '테스트용 사진 또는 동영상을 선택해 바로 전송할 수 있어요.';

  // 시간 포맷
  static const am = '오전';
  static const pm = '오후';
  static const yesterday = '어제';

  static String daysAgo(int days) => '$days일 전';
  static String weeksAgo(int weeks) => '$weeks주 전';
  static String monthsAgo(int months) => '$months달 전';
  static String dateDivider(int month, int day, String time) =>
      '$month월 $day일 $time';
}
