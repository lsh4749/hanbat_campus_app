import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
            _CommuterBusTab(),
            _IntegratedCarpoolTab(),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 1. 통학 임차버스 정류장 핀 & 노선 시간표 탭
// ============================================================================
class _CommuterBusTab extends StatefulWidget {
  const _CommuterBusTab();

  @override
  State<_CommuterBusTab> createState() => _CommuterBusTabState();
}

class _CommuterBusTabState extends State<_CommuterBusTab> {
  String _selectedRoute = '등교 노선 (유성온천역 · 현충원역 방면)';

  // 추후 정적 JSON 스키마와 1:1 매핑 가능한 구조
  final Map<String, Map<String, dynamic>> _busRoutes = {
    '등교 노선 (유성온천역 · 현충원역 방면)': {
      'badge': '등교 임차버스',
      'description': '평일 학기 중 운행 (공휴일·방학 미운행)',
      'stops': [
        {
          'name': '유성온천역 7번 출구 앞',
          'detail': '출구 직진 30m 버스 베이 승차',
          'coords': '36.3538, 127.3415',
        },
        {
          'name': '현충원역 3번 출구 건너편',
          'detail': '현충원역 시내버스 정류장 인근',
          'coords': '36.3589, 127.3218',
        },
        {
          'name': '한밭대학교 정문 (N1동 앞)',
          'detail': '교내 진입 후 도서관·N1동 방면 하차',
          'coords': '36.3508, 127.3005',
        },
      ],
      'times': ['08:10', '08:25', '08:40', '09:10', '09:40', '10:10'],
    },
    '하교 노선 (한밭대 → 유성온천역 방면)': {
      'badge': '하교 임차버스',
      'description': '수업 종료 시간대 집중 배차',
      'stops': [
        {
          'name': '한밭대학교 정문 승차장',
          'detail': 'N1동 맞은편 임차버스 대기 구역',
          'coords': '36.3508, 127.3005',
        },
        {
          'name': '현충원역 정류장',
          'detail': '도시철도 1호선 환승 하차',
          'coords': '36.3589, 127.3218',
        },
        {
          'name': '유성온천역 7번 출구',
          'detail': '종점 하차',
          'coords': '36.3538, 127.3415',
        },
      ],
      'times': ['15:10', '16:10', '17:10', '17:40', '18:10', '19:10'],
    },
  };

  String? _getNextBusInfo(List<String> times) {
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;

    for (final t in times) {
      final parts = t.split(':');
      final busMinutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      if (busMinutes >= nowMinutes) {
        final diff = busMinutes - nowMinutes;
        return '$t 출발 (${diff == 0 ? "곧 출발" : "$diff분 후"})';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final current = _busRoutes[_selectedRoute]!;
    final List> stops =
        List>.from(current['stops']);
    final List<String> times = List<String>.from(current['times']);
    final nextBus = _getNextBusInfo(times);
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<String>(
          value: _selectedRoute,
          decoration: const InputDecoration(
            labelText: '통학 임차버스 노선 선택',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          items: _busRoutes.keys
              .map((route) => DropdownMenuItem(value: route, child: Text(route)))
              .toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedRoute = val);
          },
        ),
        const SizedBox(height: 16),

        // 다음 배차 요약 카드
        Card(
          color: colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.departure_board, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      current['badge'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  nextBus ?? '금일 해당 노선 운행이 종료되었습니다.',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  current['description'],
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // 정류장 핀 안내 섹션
        Text(
          '정류장 위치 핀 & 승차 안내',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...stops.asMap().entries.map((entry) {
          final idx = entry.key;
          final stop = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: colorScheme.secondaryContainer,
                child: Icon(Icons.location_on, color: colorScheme.primary),
              ),
              title: Text(
                '${idx + 1}. ${stop['name']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${stop['detail']}\n좌표: ${stop['coords']}'),
              isThreeLine: true,
              trailing: IconButton(
                tooltip: '좌표 복사',
                icon: const Icon(Icons.copy, size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: stop['coords']!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${stop['name']} 좌표가 복사되었습니다.'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ),
          );
        }),
        const SizedBox(height: 16),

        // 전체 시간표 섹션
        Text(
          '노선별 운행 시간표',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: times.map((time) {
            final isNext = nextBus != null && nextBus.startsWith(time);
            return Chip(
              avatar: isNext
                  ? Icon(Icons.directions_bus,
                      size: 16, color: colorScheme.primary)
                  : null,
              label: Text(
                time,
                style: TextStyle(
                  fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                  color: isNext ? colorScheme.primary : null,
                ),
              ),
              backgroundColor:
                  isNext ? colorScheme.primaryContainer : Colors.grey.shade100,
              side: BorderSide(
                color: isNext ? colorScheme.primary : Colors.grey.shade300,
              ),
            );
          }).toList(),
        ),
      ],
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
  String _filterType = '전체'; // '전체', '택시', '자차'

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  /// No-Auth 환경: 로컬 기기 ID 및 사용자 설정 익명 닉네임 로드
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

  /// 익명 닉네임 변경 다이얼로그
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

  /// 파티 참여 / 취소 (Transaction 기반 동시성 제어)
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

  /// 파티 생성 및 수정 다이얼로그 (Create & Update)
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
                    // 이동 수단 선택 (택시 / 자차)
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
          // 상단 바: 익명 닉네임 표시 및 필터 칩
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

          // 실시간 파티 목록 (Read)
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
                            // 유형 배지 + 경로 + 인원
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

                            // 출발 시각 및 방장
                            Text(
                              '출발: $departureTime  ·  방장: $hostNick',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade700),
                            ),

                            // 현재 참여자 닉네임 목록
                            if (memberNicks.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                '참여자: ${memberNicks.join(', ')}',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey.shade800),
                              ),
                            ],

                            // 메모/차량 안내
                            if (note.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                note,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],

                            // 오픈채팅 링크 복사 버튼 (참여자 또는 방장에게 노출)
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

                            // 하단 CRUD 액션 버튼
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