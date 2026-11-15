import 'package:flutter/material.dart';

class RestaurantScreen extends StatelessWidget {
  const RestaurantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('대학가 맛집 & 추천 룰렛')),
      body: const Center(child: Text('4번 팀원 개발 영역입니다.')),
    );
  }
}