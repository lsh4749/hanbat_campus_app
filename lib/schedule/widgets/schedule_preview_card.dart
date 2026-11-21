import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../app/widgets/bento_tile.dart';
import '../academic_event.dart';
import '../schedule_screen.dart';

/// 홈 화면의 "학사 일정" 타일. 다가오는 일정 2개를 D-day와 함께 보여준다.
class SchedulePreviewCard extends StatefulWidget {
  const SchedulePreviewCard({super.key, this.onOpen});

  /// 타일을 눌렀을 때 동작. 없으면 일정 화면을 새로 연다.
  final VoidCallback? onOpen;

  @override
  State<SchedulePreviewCard> createState() => _SchedulePreviewCardState();
}

class _SchedulePreviewCardState extends State<SchedulePreviewCard> {
  late final Future<List<AcademicEvent>> _future =
      AcademicScheduleRepository.instance.loadUpcoming(limit: 2);

  void _open() {
    if (widget.onOpen != null) {
      widget.onOpen!();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScheduleScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BentoTile(
      color: AppColors.ink,
      padding: const EdgeInsets.all(16),
      semanticLabel: '학사 일정 전체보기',
      onTap: _open,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('학사 일정',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFD1D5DB))),
          const Spacer(),
          FutureBuilder<List<AcademicEvent>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const _Line(dDay: '!', title: '일정을 불러오지 못했어요');
              }
              if (!snapshot.hasData) return const SizedBox(height: 40);
              final events = snapshot.data!;
              if (events.isEmpty) {
                return const _Line(dDay: '-', title: '다가오는 일정 없음');
              }
              final now = DateTime.now();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < events.length; i++) ...[
                    if (i > 0) const SizedBox(height: 6),
                    _Line(
                      dDay: events[i].dDayLabel(now),
                      title: events[i].title,
                    ),
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

class _Line extends StatelessWidget {
  const _Line({required this.dDay, required this.title});

  final String dDay;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 48,
          child: Text(dDay,
              maxLines: 1,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppColors.accent)),
        ),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xFFF3F4F6)),
          ),
        ),
      ],
    );
  }
}
