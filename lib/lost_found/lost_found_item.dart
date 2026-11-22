import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore의 lost_items 문서 한 개.
class LostFoundItem {
  const LostFoundItem({
    required this.id,
    required this.type,
    required this.title,
    required this.category,
    required this.buildingCode,
    required this.location,
    required this.description,
    required this.eventTime,
    required this.status,
    required this.authorId,
    required this.createdAt,
  });

  final String id;
  final String type; // '분실물' 또는 '습득물'
  final String title;
  final String category;
  final String buildingCode;
  final String location;
  final String description;
  final DateTime? eventTime;
  final String status; // 'open' (나중에 'returned' 지원)
  final String authorId;
  final DateTime? createdAt;

  factory LostFoundItem.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final rawEventTime = data['eventTime'];
    final rawCreatedAt = data['createdAt'];
    return LostFoundItem(
      id: doc.id,
      type: (data['type'] ?? '').toString(),
      title: (data['title'] ?? '이름 없는 물품').toString(),
      category: (data['category'] ?? '기타').toString(),
      buildingCode: (data['buildingCode'] ?? '').toString(),
      location: (data['location'] ?? '장소 미기록').toString(),
      description: (data['description'] ?? '').toString(),
      eventTime: rawEventTime is Timestamp ? rawEventTime.toDate() : null,
      status: (data['status'] ?? 'open').toString(),
      authorId: (data['authorId'] ?? '').toString(),
      createdAt: rawCreatedAt is Timestamp ? rawCreatedAt.toDate() : null,
    );
  }

  String get eventDateLabel {
    final date = eventTime;
    if (date == null) return '날짜 미기록';
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)} '
        '${two(date.hour)}:${two(date.minute)}';
  }
}
