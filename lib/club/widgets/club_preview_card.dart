import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../app/widgets/bento_tile.dart';
import '../club.dart';
import '../club_repository.dart';
import '../club_screen.dart';
import 'club_card.dart';

/// 홈 화면의 "실시간 소모임" 타일.
/// Firestore에서 지금 모집 중인 최신 글을 최대 2개 보여주고,
/// 정원의 50%를 넘은 모임은 제목 양옆에 불꽃을 붙여 인기 모임임을 강조한다.
class ClubPreviewCard extends StatefulWidget {
  const ClubPreviewCard({super.key, this.onOpen});

  /// 타일을 눌렀을 때 동작. 없으면 소모임 화면을 새로 연다.
  /// (메인 탭바에서는 '소모임' 탭으로 전환하도록 넘겨준다.)
  final VoidCallback? onOpen;

  @override
  State<ClubPreviewCard> createState() => _ClubPreviewCardState();
}

class _ClubPreviewCardState extends State<ClubPreviewCard> {
  // 빌드할 때마다 새 구독이 생기지 않도록 스트림을 한 번만 만든다.
  late final Stream<List<Club>> _stream =
      ClubRepository().watchRecruiting(limit: 2);

  void _open() {
    if (widget.onOpen != null) {
      widget.onOpen!();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ClubScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BentoTile(
      color: AppColors.greenBg,
      semanticLabel: '실시간 소모임 전체보기',
      onTap: _open,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text('실시간 소모임',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppColors.greenInk)),
              ),
              Text('전체보기',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.greenSub)),
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
                return const SizedBox(
                  height: 44,
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
                children: [
                  for (var i = 0; i < clubs.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    _ClubRow(club: clubs[i]),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ClubRow extends StatelessWidget {
  const _ClubRow({required this.club});

  final Club club;

  @override
  Widget build(BuildContext context) {
    final hot = club.isHot;
    return Semantics(
      label: hot ? '인기 모임' : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            ClubBadge(
              text: club.category,
              color: clubCategoryColor(club.category),
            ),
            const SizedBox(width: 10),
            // 제목이 길면 말줄임표로 줄이되, 양옆 불꽃은 항상 보이게 한다.
            Expanded(
              child: Row(
                children: [
                  if (hot) const _Fire(),
                  Flexible(
                    child: Text(
                      club.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: hot ? FontWeight.w700 : FontWeight.w500,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  if (hot) const _Fire(),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${club.currentMembers}/${club.maxMembers}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.greenSub,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Fire extends StatelessWidget {
  const _Fire();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 2),
      child: Icon(Icons.local_fire_department_rounded,
          size: 17, color: AppColors.fire),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text,
          style: const TextStyle(fontSize: 13, color: AppColors.inkSub)),
    );
  }
}
