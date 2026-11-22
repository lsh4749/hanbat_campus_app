import 'package:flutter/material.dart';

import '../building/building_data.dart';
import 'lost_found_repository.dart';

/// 조장이 보낸 시안을 참고한 분실물·습득물 등록 화면.
/// 입력한 데이터를 팀 Firebase의 lost_items 컬렉션에 저장한다.
class LostFoundWriteScreen extends StatefulWidget {
  const LostFoundWriteScreen({super.key});

  @override
  State<LostFoundWriteScreen> createState() => _LostFoundWriteScreenState();
}

class _LostFoundWriteScreenState extends State<LostFoundWriteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _repository = LostFoundRepository();

  late final Future<CampusBuildings> _buildingsFuture;
  String _type = '분실물';
  String? _category;
  String? _buildingCode;
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  bool _saving = false;

  static const _categories = [
    '전자기기', '지갑', '학생증/카드', '가방', '의류', '우산', '기타'
  ];

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
    if (selected != null && mounted) setState(() => _date = selected);
  }

  Future<void> _chooseTime() async {
    final selected = await showTimePicker(context: context, initialTime: _time);
    if (selected != null && mounted) setState(() => _time = selected);
  }

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    if (_buildingCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('건물을 선택해 주세요.')),
      );
      return;
    }

    final eventTime = DateTime(
      _date.year, _date.month, _date.day, _time.hour, _time.minute,
    );
    if (eventTime.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('분실·습득 시간은 현재보다 늦을 수 없어요.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final campus = await _buildingsFuture;
      if (!mounted) return;
      final building = campus.buildings.firstWhere((b) => b.code == _buildingCode);
      await _repository.create(
        type: _type,
        title: _titleController.text.trim(),
        category: _category!,
        buildingCode: building.code,
        location: '${building.code} ${building.name}',
        eventTime: eventTime,
        description: _descriptionController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(_type);
    } on LostFoundException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      setState(() => _saving = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('등록 도중 오류가 발생했어요: $e')),
      );
      setState(() => _saving = false);
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
                  onSelectionChanged: _saving
                      ? null
                      : (values) => setState(() => _type = values.first),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleController,
                  enabled: !_saving,
                  maxLength: 60,
                  decoration: const InputDecoration(
                    labelText: '물품 이름',
                    hintText: '예: 에어팟, 지갑',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? '물품 이름을 입력해 주세요.' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: '물품 종류', border: OutlineInputBorder(),
                  ),
                  initialValue: _category,
                  items: [
                    for (final category in _categories)
                      DropdownMenuItem(value: category, child: Text(category)),
                  ],
                  onChanged: _saving ? null : (v) => setState(() => _category = v),
                  validator: (value) => value == null ? '물품 종류를 선택해 주세요.' : null,
                ),
                const SizedBox(height: 20),
                FutureBuilder<CampusBuildings>(
                  future: _buildingsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return const Text('건물 목록을 불러오지 못했어요.');
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _buildingCode,
                      decoration: InputDecoration(
                        labelText: _type == '분실물' ? '분실 장소 (건물)' : '습득 장소 (건물)',
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        for (final building in snapshot.data!.buildings)
                          DropdownMenuItem(
                            value: building.code,
                            child: Text('${building.code} ${building.name}',
                                overflow: TextOverflow.ellipsis),
                          ),
                      ],
                      onChanged: _saving ? null : (v) => setState(() => _buildingCode = v),
                      validator: (value) => value == null ? '건물을 선택해 주세요.' : null,
                    );
                  },
                ),
                const SizedBox(height: 20),
                const Text('분실·습득 날짜 및 시간',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(spacing: 12, runSpacing: 8, children: [
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _chooseDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(_dateText(_date)),
                  ),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _chooseTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(_time.format(context)),
                  ),
                ]),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _descriptionController,
                  enabled: !_saving,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: '상세 설명',
                    hintText: '색상, 정확한 위치(층수·좌석), 물품 특징 등을 적어 주세요.',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? '상세 설명을 입력해 주세요.' : null,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox(height: 18, width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check),
                  label: Text(_saving ? '저장 중...' : '등록하기'),
                ),
                const SizedBox(height: 8),
                const Text(
                  '등록하면 팀 Firebase에 저장되어 다른 사용자에게도 보여요.',
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
