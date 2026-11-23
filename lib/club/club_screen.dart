import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../app/widgets/pill_chip.dart';
import '../chat/chat_screen.dart';
import 'club.dart';
import 'club_repository.dart';
import 'widgets/club_card.dart';

class ClubScreen extends StatefulWidget {
  const ClubScreen({super.key});

  @override
  State<ClubScreen> createState() => _ClubScreenState();
}

class _ClubScreenState extends State<ClubScreen> {
  final ClubRepository _repo = ClubRepository();
  late final Stream<List<Club>> _clubsStream = _repo.watchAll();

  String _selectedCategory = '전체';
  static const List<String> _filters = ['전체', ...Club.categories];

  // 검색 상태
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// 저장소 호출을 실행하고, 성공/실패 메시지를 스낵바로 보여준다.
  Future<void> _run(Future<void> Function() action, {String? success}) async {
    try {
      await action();
      if (success != null) _showSnack(success);
    } on ClubException catch (e) {
      _showSnack(e.message);
    } catch (e) {
      _showSnack('알 수 없는 오류가 발생했어요.');
      debugPrint('ClubScreen error: $e');
    }
  }

  // =========================================================================
  // [실시간 채팅 연결] 모임마다 전용 채팅방 하나 (방 ID: club_<모임 문서 ID>)
  // 채팅 버튼은 모임장과 참여자에게만 보인다 (ClubCard).
  // =========================================================================
  void _openClubChat(Club club) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ChatRoomScreen(roomId: 'club_${club.id}', roomTitle: club.title),
      ),
    );
  }

  /// 새 글 작성 ([club]이 없을 때) 또는 내 글 수정 ([club]이 있을 때)
  Future<void> _showClubForm({Club? club}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _ClubFormDialog(repo: _repo, club: club),
    );
    if (saved == true) {
      _showSnack(club == null ? '소모임 모집글이 등록되었습니다!' : '모집글을 수정했어요.');
    }
  }

  Future<void> _confirmAndDelete(Club club) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('모집글 삭제'),
        content: const Text('정말로 이 소모임 모집글을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _run(() => _repo.delete(club.id), success: '모집글이 삭제되었습니다.');
    }
  }

  List<Club> _applyFilters(List<Club> clubs) {
    final filtered = clubs.where((c) {
      // 끝난 지 24시간 지난 모임은 목록에서 제거
      if (c.isHidden) return false;
      if (_selectedCategory != '전체' && c.category != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isEmpty) return true;
      return c.title.toLowerCase().contains(_searchQuery) ||
          c.location.toLowerCase().contains(_searchQuery) ||
          c.description.toLowerCase().contains(_searchQuery) ||
          c.creatorNickname.toLowerCase().contains(_searchQuery);
    }).toList();
    // 끝난 모임은 목록 맨 아래로 (나머지는 최신순 유지)
    final active = filtered.where((c) => !c.isExpired);
    final ended = filtered.where((c) => c.isExpired);
    return [...active, ...ended];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 헤더 (홈 화면과 같은 스타일)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (Navigator.canPop(context))
                    IconButton(
                      tooltip: '뒤로',
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  Expanded(
                    child: _isSearching
                        ? TextField(
                            controller: _searchController,
                            autofocus: true,
                            style: const TextStyle(fontSize: 16),
                            decoration: InputDecoration(
                              hintText: '제목·장소·닉네임 검색',
                              filled: true,
                              fillColor: const Color(0xFFF3F4F6),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (val) => setState(
                              () => _searchQuery = val.trim().toLowerCase(),
                            ),
                          )
                        : const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '함께할 사람 찾기',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.inkSub,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '한밭 소모임',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.8,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: _isSearching ? '검색 닫기' : '검색',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF3F4F6),
                      foregroundColor: AppColors.ink,
                      fixedSize: const Size(44, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: Icon(
                      _isSearching ? Icons.close_rounded : Icons.search_rounded,
                    ),
                    onPressed: () {
                      setState(() {
                        if (_isSearching) {
                          _searchQuery = '';
                          _searchController.clear();
                        }
                        _isSearching = !_isSearching;
                      });
                    },
                  ),
                ],
              ),
            ),

            // 카테고리 필터 (글자 크기에 맞춰 늘어나는 알약 버튼)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  for (var i = 0; i < _filters.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    PillChip(
                      label: _filters[i],
                      selected: _selectedCategory == _filters[i],
                      onTap: () =>
                          setState(() => _selectedCategory = _filters[i]),
                      leading: _filters[i] == '전체'
                          ? null
                          : Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: clubCategoryColor(_filters[i]),
                                shape: BoxShape.circle,
                              ),
                            ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Club>>(
                stream: _clubsStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final clubs = _applyFilters(snapshot.data!);
                  if (clubs.isEmpty) {
                    return Center(
                      child: Text(
                        _searchQuery.isNotEmpty
                            ? '\'$_searchQuery\'에 대한 검색 결과가 없습니다.'
                            : '아직 등록된 소모임이 없습니다.\n우측 하단 버튼을 눌러 첫 모임을 만들어보세요!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.inkSub,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    );
                  }

                  final uid = _repo.currentUid;
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    itemCount: clubs.length,
                    itemBuilder: (context, index) {
                      final club = clubs[index];
                      return ClubCard(
                        club: club,
                        uid: uid,
                        onJoin: () => _run(
                          () => _repo.join(club.id),
                          success: '모임 참여 완료! 이제 모임 채팅방에 입장할 수 있습니다.',
                        ),
                        onLeave: () => _run(
                          () => _repo.leave(club.id),
                          success: '모임 참여가 취소되었습니다.',
                        ),
                        onToggleClose: (val) => _run(
                          () => _repo.setClosedEarly(club.id, val),
                          success: val
                              ? '조기 모집 마감으로 전환되었습니다.'
                              : '모집이 다시 시작되었습니다.',
                        ),
                        onDelete: () => _confirmAndDelete(club),
                        onEdit: () => _showClubForm(club: club),
                        onOpenChat: () => _openClubChat(club),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showClubForm(),
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: const Icon(Icons.add_rounded, color: AppColors.accent),
        label: const Text(
          '모임 만들기',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

/// 모집글 작성·수정 다이얼로그.
/// [club]을 넘기면 수정 모드로 기존 내용을 채워서 연다.
class _ClubFormDialog extends StatefulWidget {
  const _ClubFormDialog({required this.repo, this.club});

  final ClubRepository repo;
  final Club? club;

  @override
  State<_ClubFormDialog> createState() => _ClubFormDialogState();
}

class _ClubFormDialogState extends State<_ClubFormDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final TextEditingController _descController;

  late String _category;
  late int _maxMembers;
  late DateTime _date; // 날짜만 (시·분은 아래 두 값)
  late int _hour;
  late int _minute;
  bool _submitting = false;
  String? _error;

  bool get _isEdit => widget.club != null;

  static const _minutes = [0, 10, 20, 30, 40, 50];
  static const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  void initState() {
    super.initState();
    final club = widget.club;
    _titleController = TextEditingController(text: club?.title ?? '');
    _locationController = TextEditingController(
      text: club == null || club.location == '학내 (상세내용 참고)'
          ? ''
          : club.location,
    );
    _descController = TextEditingController(text: club?.description ?? '');
    _category = club?.category ?? Club.categories.first;
    _maxMembers = club?.maxMembers ?? 4;

    // 기본 일시: 기존 모임 시간, 없거나 이미 지났으면 지금부터 1시간 뒤(10분 단위 올림)
    var initial = club?.meetAt;
    if (initial == null || initial.isBefore(DateTime.now())) {
      final soon = DateTime.now().add(const Duration(hours: 1));
      final roundUp = (10 - soon.minute % 10) % 10;
      initial = DateTime(
        soon.year,
        soon.month,
        soon.day,
        soon.hour,
        soon.minute,
      ).add(Duration(minutes: roundUp));
    }
    _date = DateTime(initial.year, initial.month, initial.day);
    _hour = initial.hour;
    _minute = (initial.minute ~/ 10) * 10;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descController.dispose();
    super.dispose();
  }

  DateTime get _meetAt =>
      DateTime(_date.year, _date.month, _date.day, _hour, _minute);

  /// 고를 수 있는 날짜: 오늘부터 2주 (수정 중인 글의 날짜가 범위 밖이면 함께 표시)
  List<DateTime> get _dateOptions {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = List.generate(14, (i) => today.add(Duration(days: i)));
    if (!days.contains(_date) && !_date.isBefore(today)) days.add(_date);
    return days;
  }

  String _dateChipLabel(DateTime d, int index) {
    return '${d.month}.${d.day}(${_weekdays[d.weekday - 1]})';
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = '모임 제목을 입력해 주세요.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final location = _locationController.text.trim();
      final args = (
        category: _category,
        title: title,
        location: location.isEmpty ? '학내 (상세내용 참고)' : location,
        meetAt: _meetAt,
        description: _descController.text.trim(),
        maxMembers: _maxMembers,
      );
      if (_isEdit) {
        await widget.repo.update(
          widget.club!.id,
          category: args.category,
          title: args.title,
          location: args.location,
          meetAt: args.meetAt,
          description: args.description,
          maxMembers: args.maxMembers,
        );
      } else {
        await widget.repo.create(
          category: args.category,
          title: args.title,
          location: args.location,
          meetAt: args.meetAt,
          description: args.description,
          maxMembers: args.maxMembers,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } on ClubException catch (e) {
      setState(() {
        _submitting = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final nickname = _isEdit
        ? widget.club!.creatorNickname
        : (widget.repo.myNickname ?? '익명');
    // 정원 최소값: 수정할 때는 지금 참여 인원 아래로 못 내림
    final int minMembers = _isEdit
        ? widget.club!.currentMembers.clamp(2, 30).toInt()
        : 2;
    final dates = _dateOptions;
    final past = _meetAt.isBefore(DateTime.now());

    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        _isEdit ? '모집글 수정하기' : '새 소모임 모집하기',
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '작성자: $nickname (자동 익명 닉네임)',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: '카테고리',
                  border: OutlineInputBorder(),
                ),
                items: Club.categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _category = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '모임 제목',
                  hintText: '예: 오늘 저녁 대운동장 풋살 2명 급구',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: '만나는 장소',
                  hintText: '예: 종합운동장, 도서관 스터디룸',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // ---------------- 모임 일시 ----------------
              const Text(
                '모임 날짜',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: dates.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (context, i) => PillChip(
                    label: _dateChipLabel(dates[i], i),
                    selected: dates[i] == _date,
                    selectedColor: AppColors.primary,
                    onTap: () => setState(() => _date = dates[i]),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    '시간',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _hour,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        labelText: '시',
                      ),
                      items: List.generate(
                        24,
                        (h) => DropdownMenuItem(value: h, child: Text('$h시')),
                      ),
                      onChanged: (v) {
                        if (v != null) setState(() => _hour = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _minute,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        labelText: '분',
                      ),
                      items: _minutes
                          .map(
                            (m) => DropdownMenuItem(
                              value: m,
                              child: Text('${m.toString().padLeft(2, '0')}분'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _minute = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                past
                    ? '이미 지난 시간이에요. 지금 이후로 골라 주세요.'
                    : '${formatMeetAt(_meetAt)} · 이 시간이 지나면 자동으로 \'모임 종료\'가 돼요.',
                style: TextStyle(
                  fontSize: 12,
                  color: past ? Colors.red : Colors.black54,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '모집 정원 (본인 포함)',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  IconButton(
                    tooltip: '정원 줄이기',
                    onPressed: _maxMembers > minMembers
                        ? () => setState(() => _maxMembers--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    '$_maxMembers명',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    tooltip: '정원 늘리기',
                    onPressed: _maxMembers < 30
                        ? () => setState(() => _maxMembers++)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              if (_isEdit && widget.club!.currentMembers > 2)
                Text(
                  '지금 ${widget.club!.currentMembers}명이 참여 중이라 그보다 줄일 수 없어요.',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              const SizedBox(height: 8),
              TextField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '상세 안내 및 공지사항',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context, false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _submitting || past ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEdit ? '수정하기' : '등록하기'),
        ),
      ],
    );
  }
}
