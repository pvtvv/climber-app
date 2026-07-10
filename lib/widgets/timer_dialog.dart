import 'dart:async';

import 'package:flutter/material.dart';
import 'package:climber_app/models/time_format.dart';

/// Timer overlay: Start → Stop → Save / Cancel.
class TimerDialog extends StatefulWidget {
  const TimerDialog({super.key});

  @override
  State<TimerDialog> createState() => _TimerDialogState();
}

enum _TimerPhase { idle, running, stopped }

class _TimerDialogState extends State<TimerDialog> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;
  _TimerPhase _phase = _TimerPhase.idle;
  Duration _elapsed = Duration.zero;

  @override
  void dispose() {
    _ticker?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  void _onStart() {
    _ticker?.cancel();
    _stopwatch
      ..reset()
      ..start();
    setState(() {
      _phase = _TimerPhase.running;
      _elapsed = Duration.zero;
    });
    _ticker = Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (!mounted || _phase != _TimerPhase.running) return;
      setState(() {
        _elapsed = _stopwatch.elapsed;
      });
    });
  }

  void _onStop() {
    _ticker?.cancel();
    _ticker = null;
    _stopwatch.stop();
    setState(() {
      _phase = _TimerPhase.stopped;
      _elapsed = _stopwatch.elapsed;
    });
  }

  void _onSave() {
    Navigator.of(context).pop<int>(_elapsed.inMilliseconds);
  }

  void _onCancel() {
    Navigator.of(context).pop<int?>(null);
  }

  @override
  Widget build(BuildContext context) {
    final display = formatDurationMs(_elapsed.inMilliseconds);
    final startLarge = _phase == _TimerPhase.idle;
    final stopLarge = _phase == _TimerPhase.running;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              display,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 24),
            if (_phase != _TimerPhase.stopped) ...[
              SizedBox(
                width: double.infinity,
                height: startLarge ? 162 : 90,
                child: FilledButton(
                  onPressed: _phase == _TimerPhase.idle ? _onStart : null,
                  child: Text(
                    'Start',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontSize: 21,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: stopLarge ? 162 : 90,
                child: FilledButton.tonal(
                  onPressed: _phase == _TimerPhase.running ? _onStop : null,
                  child: Text(
                    'Stop',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontSize: 21,
                        ),
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _onSave,
                  child: const Text('Save'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _onCancel,
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shows the timer dialog. Returns duration ms on Save, null on Cancel/dismiss.
Future<int?> showTimerDialog(BuildContext context) {
  return showDialog<int?>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const TimerDialog(),
  );
}
