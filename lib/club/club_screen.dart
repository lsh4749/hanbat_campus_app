import 'package:flutter/material.dart';

class ClubScreen extends StatelessWidget {
  const ClubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('한밭 소모임 모집')),
      body: const Center(child: Text('5번 팀원(이승현) 개발 영역입니다.')),
    );
  }
}