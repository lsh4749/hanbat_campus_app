import '../chat_texts.dart';

/// 채팅 목록 상대 시간 및 채팅방 날짜/시간 구분선 포맷터.
class ChatTimeFormatter {
  ChatTimeFormatter._();

  /// 오전/오후 H:mm 형식 (예: 오후 3:46, 오전 9:05)
  static String formatAmPmTime(DateTime dateTime) {
    final isPm = dateTime.hour >= 12;
    final period = isPm ? ChatTexts.pm : ChatTexts.am;
    final hour12 = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$period $hour12:$minute';
  }

  /// 채팅방 목록 우측 상대 시간 포맷팅 규칙:
  /// - 오늘(하루 미만): 오후 3:46
  /// - 어제: 어제
  /// - 2일 ~ 6일 전: 2일 전 ~ 6일 전
  /// - 1주 ~ 3주 전: 1주일 전 ~ 3주일 전
  /// - 4주 이상(1달 이상): 1달 전 ~ N달 전 (년 단위 변환 없음)
  static String formatRelativeTime(DateTime dateTime, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final todayDate = DateTime(current.year, current.month, current.day);
    final targetDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final dayDiff = todayDate.difference(targetDate).inDays;

    if (dayDiff <= 0) {
      return formatAmPmTime(dateTime);
    }
    if (dayDiff == 1) {
      return ChatTexts.yesterday;
    }
    if (dayDiff <= 6) {
      return ChatTexts.daysAgo(dayDiff);
    }
    if (dayDiff < 28) {
      final weeks = dayDiff ~/ 7;
      return ChatTexts.weeksAgo(weeks);
    }

    // 4주(28일) 이상이면 년 단위로 변환하지 않고 계속 'N달 전'으로 표기
    var months =
        (current.year - dateTime.year) * 12 + (current.month - dateTime.month);
    if (current.day < dateTime.day) {
      months -= 1;
    }
    if (months < 1) {
      months = 1;
    }
    return ChatTexts.monthsAgo(months);
  }

  /// 채팅방 내부 날짜/시간 구분선 (예: 12월 5일 오후 9:16)
  static String formatDateDivider(DateTime dateTime) {
    return ChatTexts.dateDivider(
      dateTime.month,
      dateTime.day,
      formatAmPmTime(dateTime),
    );
  }

  /// 메시지 사이에 날짜/시간 구분선을 표시해야 하는지 판별:
  /// 첫 메시지이거나, 날짜가 바뀌었거나, 시간 간격이 30분 이상일 때 true.
  static bool shouldShowDateDivider(DateTime? previous, DateTime current) {
    if (previous == null) return true;
    final dateChanged = previous.year != current.year ||
        previous.month != current.month ||
        previous.day != current.day;
    if (dateChanged) return true;
    return current.difference(previous).inMinutes.abs() >= 30;
  }
}
