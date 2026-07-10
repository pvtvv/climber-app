import 'package:flutter/material.dart';
import 'package:climber_app/screens/home_screen.dart';
import 'package:climber_app/state/session_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = SessionController();
  await controller.load();
  runApp(ClimberApp(controller: controller));
}

class ClimberApp extends StatelessWidget {
  const ClimberApp({super.key, required this.controller});

  final SessionController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Climber Speed Timer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: false),
      ),
      home: HomeScreen(controller: controller),
    );
  }
}
