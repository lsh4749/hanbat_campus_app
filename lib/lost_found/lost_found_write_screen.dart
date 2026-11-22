import 'package:flutter/material.dart';

import '../building/building_data.dart';

/// 등록 화면. 아직 Firebase에 저장하지 않고 입력값을 이전 화면으로 돌려준다.
class LostFoundWriteScreen extends StatefulWidget {
  const LostFoundWriteScreen({super.key});

  @override
  State<LostFoundWriteScreen> createState() => _LostFoundWriteScreenState();
}

class _LostFoundWriteScreenState extends State<LostFoundWriteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  late final Future<CampusBuildings> _buildingsFuture;
  String _type = '분실물';
  String? _category;
  String? _buildingCode;
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();

  static const _categories = ['전자기기', '지갑', '학생증/카드', '가방', '의류', '우산', '기타'];

  @override
  void initState() {
    super.initState();
    _buildingsFuture = CampusRepository.instance.loadBuildings();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _dateText(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (selected != null && mounted) {
      setState(() => _date = selected);
    }
  }

  Future<void> _chooseTime() async {
    final selected = await showTimePicker(context: context, initialTime: _time);
    if (selected != null && mounted) {
      setState(() => _time = selected);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final eventTime = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    if (eventTime.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('분실·습득 시간은 현재보다 늦을 수 없어요.')),
      );
      return;
    }

    try {
      final campus = await _buildingsFuture;
      if (!mounted) return;
      final building = campus.buildings.firstWhere(
        (b) => b.code == _buildingCode,
      );
      Navigator.of(context).pop(<String, String>{
        'type': _type,
        'title': _titleController.text.trim(),
        'category': _category!,
        'buildingCode': building.code,
        'location': '${building.code} ${building.name}',
        'date': _dateText(_date),
        'eventTime': eventTime.toIso8601String(),
        'description': _descriptionController.text.trim(),
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('건물 정보를 불러오지 못했어요. 다시 시도해 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('분실물·습득물 등록')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text('등록 유형', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: '분실물', label: Text('분실물')),
                    ButtonSegment(value: '습득물', label: Text('습득물')),
                  ],
                  selected: {_type},
                  onSelectionChanged: (values) => setState(() => _type = values.first),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleController,
                  maxLength: 60,
                  decoration: const InputDecoration(
                    labelText: '물품 이름',
                    hintText: '예: 에어팟, 지갑',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? '물품 이름을 입력해 주세요.'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: '물품 종류',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: _category,
                  items: [
                    for (final category in _categories)
                      DropdownMenuItem(value: category, child: Text(category)),
                  ],
                  onChanged: (value) => setState(() => _category = value),
                  validator: (value) => value == null ? '물품 종류를 선택해 주세요.' : null,
                ),
                const SizedBox(height: 20),
                FutureBuilder<CampusBuildings>(
                  future: _buildingsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Text('건물 목록을 불러오지 못했어요.');
                    }
                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final buildings = snapshot.data!.buildings;
                    return DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _buildingCode,
                      decoration: InputDecoration(
                        labelText: _type == '분실물' ? '분실 장소 (건물)' : '습득 장소 (건물)',
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        for (final b in buildings)
                          DropdownMenuItem(
                            value: b.code,
                            child: Text('${b.code} ${b.name}', overflow: TextOverflow.ellipsis),
                          ),
                      ],
                      onChanged: (value) => setState(() => _buildingCode = value),
                      validator: (value) => value == null ? '건물을 선택해 주세요.' : null,
                    );
                  },
                ),
                const SizedBox(height: 20),
                const Text('분실·습득 날짜 및 시간',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _chooseDate,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(_dateText(_date)),
                    ),
                    OutlinedButton.icon(
                      onPressed: _chooseTime,
                      icon: const Icon(Icons.access_time),
                      label: Text(_time.format(context)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: '상세 설명',
                    hintText: '색상, 상세 위치(층수·좌석), 물품 특징 등을 적어 주세요.',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? '상세 설명을 입력해 주세요.'
                      : null,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check),
                  label: const Text('등록하기'),
                ),
                const SizedBox(height: 8),
                const Text(
                  '현재 단계는 화면 테스트용입니다. 등록 내용은 Firebase에 저장되지 않습니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
