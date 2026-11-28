import 'dart:convert';
import 'package:flutter/services.dart';

/// 룰렛 칸과 맛집 데이터의 category 값이 반드시 같은 문자열이어야 필터링된다.
const foodCategories = ['한식', '중식', '일식', '양식', '분식', '치킨', '고기', '국밥'];

class Restaurant {
  final String id, name, category, menu, hours, address;

  Restaurant.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        name = j['name'] as String,
        category = j['category'] as String,
        menu = j['menu'] as String,
        hours = j['hours'] as String,
        address = (j['address'] as String?) ?? '';

  static Future<List<Restaurant>> load() async {
    final s = await rootBundle.loadString('assets/data/restaurants.json');
    return (jsonDecode(s) as List)
        .map((e) => Restaurant.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
