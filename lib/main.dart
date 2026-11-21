import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app/app_theme.dart';
import 'app/main_shell.dart';
import 'notifications/notification_center.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await _signInAnonymously();
  // 알림함: 새 소모임·분실물 글 구독, 일정 알림 계산 (화면을 막지 않도록 기다리지 않음)
  NotificationCenter.instance.start();
  runApp(const HanbatCampusApp());
}

/// 화면상으로는 로그인이 없지만(무로그인), 내부적으로 Firebase 익명 로그인을 해서
/// 기기마다 고유 uid를 받는다. Firestore 보안 규칙이 이 uid로 작성자를 확인한다.
/// (Firebase 콘솔 > Authentication > 로그인 방법 > '익명' 사용 설정 필요)
Future<void> _signInAnonymously() async {
  final auth = FirebaseAuth.instance;
  if (auth.currentUser != null) return;
  try {
    await auth.signInAnonymously();
  } catch (e) {
    debugPrint('익명 로그인 실패: $e');
  }
}

class HanbatCampusApp extends StatelessWidget {
  const HanbatCampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '한밭 라이프',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const MainShell(),
    );
  }
}