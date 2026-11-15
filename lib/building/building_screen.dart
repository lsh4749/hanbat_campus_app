import 'package:flutter/material.dart';

class BuildingScreen extends StatelessWidget {
  const BuildingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('건물 및 주요 시설 안내')),
      body: const Center(child: Text('1번 팀원 개발 영역입니다.')),
    );
  }
}