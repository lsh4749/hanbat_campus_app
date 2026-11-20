import 'package:flutter/material.dart';

import '../club.dart';
import '../club_repository.dart';
import '../club_screen.dart';
import 'club_card.dart';

/// 홈 화면에 들어가는 "실시간 소모임 모집" 카드.
/// Firestore에서 지금 모집 중인 최신 글을 최대 3개 보여준다.
class ClubPreviewCard extends StatefulWidget {
  const ClubPreviewCard({super.key});

  @override
  State<ClubPreviewCard> createState() => _ClubPreviewCardState();
}

class _ClubPreviewCardState extends State<ClubPreviewCard> {
  // 빌드할 때마다 새 구독이 생기지 않도록 스트림을 한 번만 만든다.
  late final Stream<List<Club>> _stream =
      ClubRepository().watchRecruiting(limit: 3);

  static const _primary = Color(0xFF004098);

  void _openClubScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ClubScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _openClubScreen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _primary.withValues(alpha: 0.1),
                    child: const Icon(Icons.campaign, color: _primary),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      '실시간 소모임 모집',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const Text('전체보기', style: TextStyle(color: Colors.grey)),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 10),
              StreamBuilder<List<Club>>(
                stream: _stream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const _Message('모집글을 불러오지 못했어요.');
                  }
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }
                  final clubs = snapshot.data!;
                  if (clubs.isEmpty) {
                    return const _Message('지금 모집 중인 모임이 없어요. 첫 모임을 만들어보세요!');
                  }
                  return Column(
                    children: clubs.map((c) => _ClubRow(club: c)).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClubRow extends StatelessWidget {
  const _ClubRow({required this.club});

  final Club club;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 56, right: 8, top: 4, bottom: 4),
      child: Row(
        children: [
          ClubBadge(
            text: club.category,
            color: clubCategoryColor(club.category),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              club.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${club.currentMembers}/${club.maxMembers}명',
            style: const TextStyle(
              color: Colors.indigo,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 56, top: 2, bottom: 2),
      child: Text(text, style: const TextStyle(color: Colors.black54)),
    );
  }
}
