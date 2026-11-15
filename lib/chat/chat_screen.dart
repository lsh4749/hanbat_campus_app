import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('실시간 채팅')),
      body: const Center(child: Text('6번 팀원 개발 영역입니다.')),
    );
  }
}