import 'dart:async';

import 'package:flutter/material.dart';
import 'package:climber_app/models/time_format.dart';
import 'package:climber_app/services/timer_engine.dart';
import 'package:climber_app/widgets/leave_confirm.dart';

/// Timer overlay: Start → Stop → Save / Cancel.
/// @cpt-algo:cpt-climberapp-algo-measurement-mode-entry-timer-engine:p2
class TimerDialog extends StatefulWidget {
  const TimerDialog({
    super.key,
    this.engine,
    this.timingInProgress,
    this.onLeaveWhileRunning,
  });

  final TimerEngine? engine;
  final ValueNotifier<bool>? timingInProgress;
  final Future<void> Function()? onLeaveWhileRunning;

  @override
  State<TimerDialog> createState() => _TimerDialogState();
}

class _TimerDialogState extends State<TimerDialog> {
  late final TimerEngine _engine;
  late final bool _ownsEngine;
  StreamSubscription<int>? _tickSub;
  int _displayMs = 0;

  @override
  void initState() {
    super.initState();
    _ownsEngine = widget.engine == null;
    _engine = widget.engine ?? TimerEngine();
    _syncTimingInProgress();
  }

  @override
  void dispose() {
    _tickSub?.cancel();
    widget.timingInProgress?.value = false;
    if (_ownsEngine) {
      _engine.dispose();
    }
    super.dispose();
  }

  void _syncTimingInProgress() {
    widget.timingInProgress?.value = _engine.phase == TimerPhase.running;
  }

  void _onStart() {
    _tickSub?.cancel();
    _engine.start();
    _tickSub = _engine.tickStream.listen((ms) {
      if (mounted) {
        setState(() => _displayMs = ms);
      }
    });
    setState(() {
      _displayMs = 0;
      _syncTimingInProgress();
    });
  }

  void _onStop() {
    _tickSub?.cancel();
    _tickSub = null;
    final ms = _engine.stop();
    setState(() {
      _displayMs = ms;
      _syncTimingInProgress();
    });
  }

  void _onSave() {
    Navigator.of(context).pop<int>(_displayMs);
  }

  void _onCancel() {
    Navigator.of(context).pop<int?>(null);
  }

  Future<void> _handlePopWhileRunning() async {
    final leave = await confirmLeaveWhileRunning(context);
    if (!leave || !mounted) return;
    _tickSub?.cancel();
    _tickSub = null;
    _engine.stop();
    _syncTimingInProgress();
    Navigator.of(context).pop<int?>(null);
    if (widget.onLeaveWhileRunning != null) {
      await widget.onLeaveWhileRunning!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final phase = _engine.phase;
    final display = formatDurationMs(_displayMs);
    final startLarge = phase == TimerPhase.idle;
    final stopLarge = phase == TimerPhase.running;

    return PopScope(
      canPop: phase != TimerPhase.running,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handlePopWhileRunning();
      },
      child: Dialog(
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
              if (phase != TimerPhase.stopped) ...[
                SizedBox(
                  width: double.infinity,
                  height: startLarge ? 162 : 90,
                  child: FilledButton(
                    onPressed: phase == TimerPhase.idle ? _onStart : null,
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
                    onPressed: phase == TimerPhase.running ? _onStop : null,
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
      ),
    );
  }
}

/// Shows the timer dialog. Returns duration ms on Save, null on Cancel/dismiss.
Future<int?> showTimerDialog(
  BuildContext context, {
  ValueNotifier<bool>? timingInProgress,
  TimerEngine? engine,
  Future<void> Function()? onLeaveWhileRunning,
}) {
  return showDialog<int?>(
    context: context,
    barrierDismissible: false,
    builder: (_) => TimerDialog(
      engine: engine,
      timingInProgress: timingInProgress,
      onLeaveWhileRunning: onLeaveWhileRunning,
    ),
  ).whenComplete(() {
    timingInProgress?.value = false;
  });
}
