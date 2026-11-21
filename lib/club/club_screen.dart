import 'package:flutter/material.dart';

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
  // [추후 실시간 채팅 팀원 기능 연결 지점]
  // 채팅 담당 팀원이 만든 화면(예: ChatRoomScreen)이 완성되면 아래 주석을 해제하고 연결하세요.
  // =========================================================================
  void _openClubChat(Club club) {
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (_) => ChatRoomScreen(
    //       roomId: 'club_${club.id}',
    //       roomTitle: club.title,
    //     ),
    //   ),
    // );
    _showSnack('[${club.title}] 채팅방 연결 예정 (Room ID: club_${club.id})');
  }

  Future<void> _showCreateClubDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _CreateClubDialog(repo: _repo),
    );
    if (created == true) _showSnack('소모임 모집글이 등록되었습니다!');
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
    return clubs.where((c) {
      if (_selectedCategory != '전체' && c.category != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isEmpty) return true;
      return c.title.toLowerCase().contains(_searchQuery) ||
          c.location.toLowerCase().contains(_searchQuery) ||
          c.description.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '제목·장소·내용 검색 (예: 풋살, 롤, 도서관)',
                  border: InputBorder.none,
                ),
                onChanged: (val) =>
                    setState(() => _searchQuery = val.trim().toLowerCase()),
              )
            : const Text(
                '한밭 소모임 모집',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            tooltip: _isSearching ? '검색 닫기' : '검색',
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
      body: Column(
        children: [
          // 카테고리 필터 칩
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _filters[index];
                return ChoiceChip(
                  label: Text(category),
                  selected: _selectedCategory == category,
                  onSelected: (_) =>
                      setState(() => _selectedCategory = category),
                );
              },
            ),
          ),
          const Divider(height: 1),
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
                      style: const TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  );
                }

                final uid = _repo.currentUid;
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
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
                        success:
                            val ? '조기 모집 마감으로 전환되었습니다.' : '모집이 다시 시작되었습니다.',
                      ),
                      onDelete: () => _confirmAndDelete(club),
                      onOpenChat: () => _openClubChat(club),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateClubDialog,
        icon: const Icon(Icons.add),
        label: const Text('모임 만들기'),
      ),
    );
  }
}

/// 새 모집글 작성 다이얼로그.
/// 별도 StatefulWidget으로 분리해 TextEditingController를 제대로 dispose 한다.
class _CreateClubDialog extends StatefulWidget {
  const _CreateClubDialog({required this.repo});

  final ClubRepository repo;

  @override
  State<_CreateClubDialog> createState() => _CreateClubDialogState();
}

class _CreateClubDialogState extends State<_CreateClubDialog> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _timeController = TextEditingController();
  final _descController = TextEditingController();

  String _category = Club.categories.first;
  int _maxMembers = 4;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _timeController.dispose();
    _descController.dispose();
    super.dispose();
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
      final time = _timeController.text.trim();
      await widget.repo.create(
        category: _category,
        title: title,
        location: location.isEmpty ? '학내 (상세내용 참고)' : location,
        time: time.isEmpty ? '추후 협의' : time,
        description: _descController.text.trim(),
        maxMembers: _maxMembers,
      );
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
    return AlertDialog(
      title: const Text(
        '새 소모임 모집하기',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 12),
            TextField(
              controller: _timeController,
              decoration: const InputDecoration(
                labelText: '일시',
                hintText: '예: 오늘 19:00 / 매주 수요일',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text('모집 정원 (본인 포함)',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                ),
                IconButton(
                  onPressed: _maxMembers > 2
                      ? () => setState(() => _maxMembers--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '$_maxMembers명',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: _maxMembers < 30
                      ? () => setState(() => _maxMembers++)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
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
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context, false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('등록하기'),
        ),
      ],
    );
  }
}
