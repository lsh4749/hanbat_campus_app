import 'lost_found_item.dart';

/// Rules-based similarity score. Not a probability or proof of ownership.
class LostFoundMatch {
  const LostFoundMatch({
    required this.item,
    required this.score,
    required this.reasons,
    required this.timeDifference,
  });

  final LostFoundItem item;
  final int score;
  final List<String> reasons;
  final Duration timeDifference;
}

/// Finds opposite-type posts. It does not change Firestore data.
List<LostFoundMatch> findLostFoundMatches(
  LostFoundItem source,
  Iterable<LostFoundItem> allItems,
) {
  if (source.status != 'open' || source.eventTime == null) {
    return const <LostFoundMatch>[];
  }
  if (source.type != '분실물' && source.type != '습득물') {
    return const <LostFoundMatch>[];
  }

  final matches = <LostFoundMatch>[];

  for (final other in allItems) {
    if (other.id == source.id || other.type == source.type) continue;
    if (other.status != 'open' || other.eventTime == null) continue;
    if (other.category != source.category) continue;

    final lost = source.type == '분실물' ? source : other;
    final found = source.type == '습득물' ? source : other;
    if (lost.type != '분실물' || found.type != '습득물') continue;

    // 습득 시각 - 분실 시각 (음수이면 분실 전 습득)
    final delay = found.eventTime!.difference(lost.eventTime!);

    var score = 30; // Same category is required.
    final reasons = <String>['물품 종류 일치'];

    if (source.buildingCode.isNotEmpty &&
        source.buildingCode == other.buildingCode) {
      score += 50;
      reasons.add('같은 건물');
    }

    // 분실 30분 전 ~ 분실 3시간 후: +20점
    // 분실 3시간 초과 ~ 6시간 후: +10점
    // 그 외 시간: 추천 대상 제외
    if (delay >= const Duration(minutes: -30) &&
        delay <= const Duration(hours: 3)) {
      score += 20;
      reasons.add(delay.isNegative
          ? '분실 시각 30분 전 이내 습득'
          : '분실 후 3시간 이내 습득');
    } else if (delay > const Duration(hours: 3) &&
        delay <= const Duration(hours: 6)) {
      score += 10;
      reasons.add('분실 후 3시간 초과~6시간 이내 습득');
    } else {
      continue;
    }

    // A low score means too many coincidental matches.
    if (score < 90) continue;
    matches.add(LostFoundMatch(
      item: other,
      score: score,
      reasons: reasons,
      timeDifference: delay,
    ));
  }

  matches.sort((a, b) {
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) return byScore;
    // Break score ties by closeness to the reported lost time.
    return a.timeDifference.abs().compareTo(b.timeDifference.abs());
  });
  return matches;
}
