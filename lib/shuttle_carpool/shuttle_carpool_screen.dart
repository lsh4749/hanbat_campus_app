import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'commuter_bus_tab.dart';

class ShuttleCarpoolScreen extends StatelessWidget {
  const ShuttleCarpoolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('통학 임차버스 & 카풀·동승'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.directions_bus), text: '임차버스·정류장'),
              Tab(icon: Icon(Icons.directions_car), text: '택시·자차 동승'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            CommuterBusTab(),
            _IntegratedCarpoolTab(),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 2. 택시 · 자차 통합 파티 모집 CRUD 탭 (No-Auth 익명 닉네임 + 오픈채팅 연동)
// ============================================================================
class _IntegratedCarpoolTab extends StatefulWidget {
  const _IntegratedCarpoolTab();

  @override
  State<_IntegratedCarpoolTab> createState() => _IntegratedCarpoolTabState();
}

class _IntegratedCarpoolTabState extends State<_IntegratedCarpoolTab> {
  final CollectionReference _partyRef =
      FirebaseFirestore.instance.collection('carpool_parties');

  String _userId = '';
  String _nickname = '익명 한밭인';
  String _filterType = '전체';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString('no_auth_user_id');
    if (id == null) {
      id = 'anon_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString('no_auth_user_id', id);
    }
    final savedNick = prefs.getString('no_auth_nickname') ?? '익명 한밭인';
    if (mounted) {
      setState(() {
        _userId = id!;
        _nickname = savedNick;
      });
    }
  }

  void _showNicknameDialog() {
    final nickCtrl = TextEditingController(text: _nickname);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('익명 닉네임 설정'),
        content: TextField(
          controller: nickCtrl,
          maxLength: 12,
          decoration: const InputDecoration(
            labelText: '파티에서 표시될 닉네임',
            hintText: '예: 컴공23학번',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              final newNick = nickCtrl.text.trim();
              if (newNick.isEmpty) return;
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('no_auth_nickname', newNick);
              if (mounted) setState(() => _nickname = newNick);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleJoin(DocumentSnapshot doc) async {
    if (_userId.isEmpty) return;

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final fresh = await tx.get(doc.reference);
      if (!fresh.exists) return;

      final data = fresh.data() as Map<String, dynamic>;
      final List<String> memberIds =
          List<String>.from(data['memberIds'] ?? []);
      final List<String> memberNicks =
          List<String>.from(data['memberNicks'] ?? []);
      final int maxMembers = data['maxMembers'] ?? 4;

      final existingIndex = memberIds.indexOf(_userId);
      if (existingIndex != -1) {
        memberIds.removeAt(existingIndex);
        if (existingIndex < memberNicks.length) {
          memberNicks.removeAt(existingIndex);
        }
      } else {
        if (memberIds.length >= maxMembers) return;
        memberIds.add(_userId);
        memberNicks.add(_nickname);
      }

      tx.update(doc.reference, {
        'memberIds': memberIds,
        'memberNicks': memberNicks,
        'isClosed': memberIds.length >= maxMembers,
      });
    });
  }

  void _showPartyFormDialog({DocumentSnapshot? existingDoc}) {
    final isEdit = existingDoc != null;
    final data = isEdit ? existingDoc.data() as Map<String, dynamic> : {};

    String rideType = data['rideType'] ?? '택시';
    final departureCtrl =
        TextEditingController(text: data['departure'] ?? '유성온천역 7번 출구');
    final destinationCtrl =
        TextEditingController(text: data['destination'] ?? '한밭대 정문');
    final timeCtrl =
        TextEditingController(text: data['departureTime'] ?? '10분 뒤 출발');
    final openChatCtrl =
        TextEditingController(text: data['openChatUrl'] ?? '');
    final noteCtrl = TextEditingController(text: data['note'] ?? '');
    int maxMembers = data['maxMembers'] ?? 4;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? '동승 파티 수정' : '택시·자차 파티 모집'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: '택시',
                          icon: Icon(Icons.local_taxi),
                          label: Text('택시 카풀'),
                        ),
                        ButtonSegment(
                          value: '자차',
                          icon: Icon(Icons.directions_car),
                          label: Text('자차 동승'),
                        ),
                      ],
                      selected: {rideType},
                      onSelectionChanged: (selected) {
                        setDialogState(() => rideType = selected.first);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: departureCtrl,
                      decoration: const InputDecoration(labelText: '출발지'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: destinationCtrl,
                      decoration: const InputDecoration(labelText: '도착지'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: timeCtrl,
                      decoration: const InputDecoration(
                        labelText: '출발 예정 시간',
                        hintText: '예: 08:40 또는 10분 뒤',
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: maxMembers,
                      decoration: const InputDecoration(labelText: '모집 정원'),
                      items: [2, 3, 4]
                          .map((n) =>
                              DropdownMenuItem(value: n, child: Text('$n명')))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => maxMembers = val);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: openChatCtrl,
                      decoration: const InputDecoration(
                        labelText: '카카오톡 오픈채팅 링크 (선택)',
                        hintText: 'https://open.kakao.com/o/...',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteCtrl,
                      decoration: InputDecoration(
                        labelText: rideType == '자차'
                            ? '차량 정보 / 유류비 분담 안내'
                            : '합류 위치 / 메모',
                        hintText: rideType == '자차'
                            ? '예: 아반떼 흰색, 유류비 2천원'
                            : '예: 7번 출구 편의점 앞 대기',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (departureCtrl.text.trim().isEmpty ||
                        destinationCtrl.text.trim().isEmpty) {
                      return;
                    }

                    if (isEdit) {
                      await existingDoc.reference.update({
                        'rideType': rideType,
                        'departure': departureCtrl.text.trim(),
                        'destination': destinationCtrl.text.trim(),
                        'departureTime': timeCtrl.text.trim(),
                        'maxMembers': maxMembers,
                        'openChatUrl': openChatCtrl.text.trim(),
                        'note': noteCtrl.text.trim(),
                      });
                    } else {
                      await _partyRef.add({
                        'rideType': rideType,
                        'departure': departureCtrl.text.trim(),
                        'destination': destinationCtrl.text.trim(),
                        'departureTime': timeCtrl.text.trim(),
                        'maxMembers': maxMembers,
                        'memberIds': [_userId],
                        'memberNicks': [_nickname],
                        'openChatUrl': openChatCtrl.text.trim(),
                        'note': noteCtrl.text.trim(),
                        'hostId': _userId,
                        'hostNick': _nickname,
                        'isClosed': false,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(isEdit ? '수정 완료' : '파티 등록'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            color: colorScheme.surfaceContainerLowest,
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['전체', '택시', '자차'].map((type) {
                        final selected = _filterType == type;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(type),
                            selected: selected,
                            onSelected: (_) =>
                                setState(() => _filterType = type),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.person_outline, size: 16),
                  label: Text(_nickname),
                  onPressed: _showNicknameDialog,
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  _partyRef.orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child: Text('데이터 로드 실패:\n${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allDocs = snapshot.data?.docs ?? [];
                final filteredDocs = allDocs.where((doc) {
                  if (_filterType == '전체') return true;
                  final data = doc.data() as Map<String, dynamic>;
                  return (data['rideType'] ?? '택시') == _filterType;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text(
                      '조건에 맞는 모집 파티가 없습니다.\n우측 하단 버튼으로 새 파티를 만들어보세요!',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 84),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final String rideType = data['rideType'] ?? '택시';
                    final String departure = data['departure'] ?? '';
                    final String destination = data['destination'] ?? '';
                    final String departureTime = data['departureTime'] ?? '';
                    final String openChatUrl = data['openChatUrl'] ?? '';
                    final String note = data['note'] ?? '';
                    final String hostNick = data['hostNick'] ?? '익명';
                    final int maxMembers = data['maxMembers'] ?? 4;
                    final List<String> memberIds =
                        List<String>.from(data['memberIds'] ?? []);
                    final List<String> memberNicks =
                        List<String>.from(data['memberNicks'] ?? []);

                    final bool isJoined = memberIds.contains(_userId);
                    final bool isHost = data['hostId'] == _userId;
                    final bool isFull = memberIds.length >= maxMembers;
                    final bool isCar = rideType == '자차';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isCar
                                        ? Colors.teal.shade50
                                        : Colors.amber.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isCar ? '자차 동승' : '택시 카풀',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isCar
                                          ? Colors.teal.shade800
                                          : Colors.brown.shade800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '$departure → $destination',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${memberIds.length}/$maxMembers명',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isFull
                                        ? Colors.red
                                        : colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '출발: $departureTime  ·  방장: $hostNick',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade700),
                            ),
                            if (memberNicks.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                '참여자: ${memberNicks.join(', ')}',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey.shade800),
                              ),
                            ],
                            if (note.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                note,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                            if (openChatUrl.isNotEmpty &&
                                (isJoined || isHost)) ...[
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: () {
                                  Clipboard.setData(
                                      ClipboardData(text: openChatUrl));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('오픈채팅 링크가 복사되었습니다.'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.chat_bubble_outline,
                                    size: 16),
                                label: const Text('오픈채팅 링크 복사'),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (isHost) ...[
                                  IconButton(
                                    tooltip: '수정',
                                    onPressed: () =>
                                        _showPartyFormDialog(existingDoc: doc),
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 20),
                                  ),
                                  IconButton(
                                    tooltip: '삭제',
                                    onPressed: () => doc.reference.delete(),
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red, size: 20),
                                  ),
                                ],
                                const SizedBox(width: 4),
                                FilledButton(
                                  onPressed: (!isJoined && isFull)
                                      ? null
                                      : () => _toggleJoin(doc),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: isJoined
                                        ? Colors.grey.shade600
                                        : colorScheme.primary,
                                  ),
                                  child: Text(
                                    isJoined
                                        ? '참여 취소'
                                        : (isFull ? '모집 마감' : '동승 참여'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPartyFormDialog(),
        icon: const Icon(Icons.add),
        label: const Text('파티 모집'),
      ),
    );
  }
}
