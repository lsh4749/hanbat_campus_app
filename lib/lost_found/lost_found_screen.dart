import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'lost_found_item.dart';
import 'lost_found_repository.dart';
import 'lost_found_write_screen.dart';

class LostFoundScreen extends StatefulWidget {
  const LostFoundScreen({super.key});

  @override
  State<LostFoundScreen> createState() => _LostFoundScreenState();
}

class _LostFoundScreenState extends State<LostFoundScreen> {
  final _repository = LostFoundRepository();
  final _searchController = TextEditingController();
  late final Stream<List<LostFoundItem>> _itemsStream;
  String _selectedType = '분실물';
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _itemsStream = _repository.watchAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openWriteScreen() async {
    // 등록 화면에서 저장에 성공한 유형만 돌려준다.
    final savedType = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const LostFoundWriteScreen()),
    );
    if (!mounted || savedType == null) return;
    setState(() {
      _selectedType = savedType;
      _searchText = '';
      _searchController.clear();
    });
    // 목록은 Firestore의 snapshots()가 자동으로 갱신한다.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Firebase에 게시물이 등록됐어요.')),
    );
  }

  String _readError(Object error) {
    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return '게시물을 읽을 권한이 없어요. Firebase 규칙을 확인해 주세요.';
      }
      if (error.code == 'unavailable') {
        return '네트워크 연결을 확인해 주세요.';
      }
      return 'Firebase 조회 오류: ${error.message ?? error.code}';
    }
    return '게시물을 불러오지 못했어요: $error';
  }

  void _showDetail(LostFoundItem item) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(item.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('구분: ${item.type}'),
              Text('종류: ${item.category}'),
              Text('장소: ${item.location}'),
              Text('날짜: ${item.eventDateLabel}'),
              Text('상태: ${item.status == 'open' ? '진행 중' : '반환 완료'}'),
              const SizedBox(height: 12),
              Text(item.description),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('분실물 찾아주기')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '캠퍼스 분실물 찾기',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  children: ['분실물', '습득물'].map((type) {
                    return ChoiceChip(
                      label: Text(type),
                      selected: _selectedType == type,
                      onSelected: (_) => setState(() => _selectedType = type),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: '물품 이름 또는 장소 검색',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() => _searchText = value),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text('$_selectedType 목록',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    FilledButton.icon(
                      onPressed: _openWriteScreen,
                      icon: const Icon(Icons.add),
                      label: const Text('물품 등록'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: StreamBuilder<List<LostFoundItem>>(
                    stream: _itemsStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text(_readError(snapshot.error!)));
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final query = _searchText.trim().toLowerCase();
                      final visible = snapshot.data!.where((item) {
                        if (item.type != _selectedType) return false;
                        return item.title.toLowerCase().contains(query) ||
                            item.location.toLowerCase().contains(query);
                      }).toList();
                      if (visible.isEmpty) {
                        return const Center(
                          child: Text('등록된 게시물이나 검색 결과가 없습니다.'),
                        );
                      }
                      return ListView.builder(
                        itemCount: visible.length,
                        itemBuilder: (context, index) {
                          final item = visible[index];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.inventory_2_outlined),
                              title: Text(item.title),
                              subtitle: Text(
                                '${item.location} · ${item.eventDateLabel}',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _showDetail(item),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
