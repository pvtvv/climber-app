import 'package:flutter/material.dart';
import 'package:climber_app/screens/home_screen.dart';
import 'package:climber_app/screens/quick_measure_screen.dart';
import 'package:climber_app/state/session_controller.dart';

/// Launch screen: Quick vs Session mode entry.
/// @cpt-flow:cpt-climberapp-flow-measurement-mode-entry-launch-to-picker:p1
class ModePicker extends StatelessWidget {
  const ModePicker({super.key, required this.controller});

  final SessionController controller;

  static const quickLabel = 'Quick';
  static const quickSubtitle = 'One timer. One result.';
  static const sessionLabel = 'Session';
  static const sessionSubtitle = 'Multiple athletes. Track runs.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Climber Speed Timer')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          ListTile(
            key: const Key('mode_quick'),
            title: const Text(quickLabel),
            subtitle: const Text(quickSubtitle),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const QuickMeasureScreen(),
                ),
              );
            },
          ),
          ListTile(
            key: const Key('mode_session'),
            title: const Text(sessionLabel),
            subtitle: const Text(sessionSubtitle),
            onTap: () async {
              // @cpt-algo:cpt-climberapp-algo-measurement-mode-entry-lazy-load-session-store:p2
              if (!controller.isLoaded) {
                await controller.load();
              }
              if (!context.mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => HomeScreen(controller: controller),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
