import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const HanbatCampusApp());
}

class HanbatCampusApp extends StatelessWidget {
  const HanbatCampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '한밭 라이프',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF004098)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}