import 'package:flutter/material.dart';

import 'lost_found_write_screen.dart';

class LostFoundScreen extends StatefulWidget {
  const LostFoundScreen({super.key});

  @override
  State<LostFoundScreen> createState() => _LostFoundScreenState();
}

class _LostFoundScreenState extends State<LostFoundScreen> {
  String selectedType = '분실물';
  String searchText = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 화면 테스트용 데이터. 페이지를 다시 열거나 새로고침하면 사라진다.
  final List<Map<String, String>> items = [
    {
      'type': '분실물',
      'title': '에어팟',
      'location': 'S1 도서관',
      'date': '2026-11-20',
      'description': '흰색 에어팟입니다. 도서관 2층에서 잃어버렸어요.',
    },
    {
      'type': '분실물',
      'title': '검은색 지갑',
      'location': 'S2 학생회관',
      'date': '2026-11-19',
      'description': '학생회관 근처에서 분실했습니다.',
    },
    {
      'type': '습득물',
      'title': '학생증',
      'location': 'S1 도서관',
      'date': '2026-11-20',
      'description': '도서관 입구에서 주웠습니다.',
    },
    {
      'type': '습득물',
      'title': '에어팟',
      'location': 'S1 도서관',
      'date': '2026-11-20',
      'description': '흰색 에어팟을 도서관에서 발견했습니다.',
    },
  ];

  Future<void> _openWriteScreen() async {
    final newItem = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(builder: (_) => const LostFoundWriteScreen()),
    );
    if (!mounted || newItem == null) return;

    setState(() {
      items.insert(0, newItem);
      selectedType = newItem['type']!;
      searchText = '';
      _searchController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('화면에 등록됐어요. (Firebase 저장 전)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = items.where((item) {
      final matchesType = item['type'] == selectedType;
      final query = searchText.toLowerCase();
      final matchesSearch = item['title']!.toLowerCase().contains(query) ||
          item['location']!.toLowerCase().contains(query);
      return matchesType && matchesSearch;
    }).toList();

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
                      selected: selectedType == type,
                      onSelected: (_) => setState(() => selectedType = type),
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
                  onChanged: (value) => setState(() => searchText = value),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '검색 결과 ${filteredItems.length}건',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
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
                  child: filteredItems.isEmpty
                      ? const Center(child: Text('검색 결과가 없습니다.'))
                      : ListView.builder(
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            return Card(
                              child: ListTile(
                                leading: const Icon(Icons.inventory_2_outlined),
                                title: Text(item['title']!),
                                subtitle: Text('${item['location']} · ${item['date']}'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  showDialog<void>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(item['title']!),
                                      content: Text(item['description']!),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('닫기'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
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
