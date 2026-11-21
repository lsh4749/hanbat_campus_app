import 'package:flutter/material.dart';

import '../notifications/notification_center.dart';
import 'academic_event.dart';

/// 전체 학사일정 화면. 월별로 묶어서 보여주고, 지난 일정은 흐리게 표시한다.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late final Future<List<AcademicEvent>> _future =
      AcademicScheduleRepository.instance.loadAll();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('학교 주요 일정',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<AcademicEvent>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('일정을 불러오지 못했어요.\n${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final events = snapshot.data!;
          if (events.isEmpty) {
            return const Center(child: Text('등록된 일정이 없어요.'));
          }

          final now = DateTime.now();
          final children = <Widget>[];
          String? currentMonth;
          for (final e in events) {
            final month = '${e.start.year}년 ${e.start.month}월';
            if (month != currentMonth) {
              currentMonth = month;
              children.add(Padding(
                padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                child: Text(
                  month,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ));
            }
            children.add(_EventTile(event: e, now: now));
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: children,
          );
        },
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event, required this.now});

  final AcademicEvent event;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final past = event.isPast(now);
    final highlight = event.isOngoing(now);
    return Opacity(
      opacity: past ? 0.45 : 1,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: highlight ? 3 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: highlight
              ? BorderSide(color: event.typeColor, width: 1.5)
              : BorderSide.none,
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: event.typeColor.withValues(alpha: 0.12),
            child: Icon(event.typeIcon, color: event.typeColor, size: 20),
          ),
          title: Text(event.title,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('${event.typeLabel} · ${event.periodLabel}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DDayBadge(label: event.dDayLabel(now), color: event.typeColor),
              if (!past) _AlarmButton(event: event),
            ],
          ),
        ),
      ),
    );
  }
}

/// 일정 알림 켜기/끄기 버튼. 켜 두면 시작 하루 전(그리고 당일)에 알림함으로 알려준다.
class _AlarmButton extends StatelessWidget {
  const _AlarmButton({required this.event});

  final AcademicEvent event;

  @override
  Widget build(BuildContext context) {
    final center = NotificationCenter.instance;
    return ListenableBuilder(
      listenable: center,
      builder: (context, _) {
        final on = center.isAlarmOn(event);
        return IconButton(
          tooltip: on ? '알림 끄기' : '하루 전에 알림 받기',
          isSelected: on,
          icon: const Icon(Icons.notifications_none_rounded),
          selectedIcon: const Icon(Icons.notifications_active_rounded),
          color: on ? event.typeColor : const Color(0xFF6B7280),
          onPressed: () async {
            final nowOn = await center.toggleAlarm(event);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text(nowOn
                    ? "'${event.title}' 하루 전에 알려드릴게요."
                    : "'${event.title}' 알림을 껐어요."),
              ));
          },
        );
      },
    );
  }
}

/// 'D-3', '진행중' 같은 남은 날짜 배지
class DDayBadge extends StatelessWidget {
  const DDayBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final strong = label == 'D-Day' || label == '진행중';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: strong ? color : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: strong ? Colors.white : color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
