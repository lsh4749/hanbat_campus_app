import 'package:flutter/material.dart';

class LostFoundScreen extends StatelessWidget {
  const LostFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('분실물 찾아주기')),
      body: const Center(child: Text('3번 팀원 개발 영역입니다.')),
    );
  }
}