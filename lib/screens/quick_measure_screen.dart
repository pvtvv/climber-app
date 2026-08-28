import 'dart:async';

import 'package:flutter/material.dart';
import 'package:climber_app/models/quick_result.dart';
import 'package:climber_app/models/time_format.dart';
import 'package:climber_app/services/quick_store.dart';
import 'package:climber_app/services/timer_engine.dart';
import 'package:climber_app/widgets/copyable_run_time.dart';
import 'package:climber_app/widgets/leave_confirm.dart';
import 'package:climber_app/widgets/timer_toggle_button.dart';

enum QuickPhase { idle, running }

/// Full-screen Quick measure surface.
/// @cpt-flow:cpt-climberapp-flow-measurement-mode-entry-enter-quick:p1
class QuickMeasureScreen extends StatefulWidget {
  const QuickMeasureScreen({
    super.key,
    this.store,
    this.engine,
  });

  final QuickStore? store;
  final TimerEngine? engine;

  @override
  State<QuickMeasureScreen> createState() => _QuickMeasureScreenState();
}

class _QuickMeasureScreenState extends State<QuickMeasureScreen> {
  late final QuickStore _store;
  late final TimerEngine _engine;
  QuickPhase _phase = QuickPhase.idle;
  int _displayMs = 0;
  StreamSubscription<int>? _tickSub;

  @override
  void initState() {
    super.initState();
    _store = widget.store ?? QuickStore();
    _engine = widget.engine ?? TimerEngine();
    _loadCached();
  }

  @override
  void dispose() {
    _tickSub?.cancel();
    if (widget.engine == null) {
      _engine.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCached() async {
    final cached = await _store.load();
    if (!mounted) return;
    if (cached != null) {
      if (_phase != QuickPhase.idle) {
        // User already started a run while the async load was in flight;
        // never override the active phase.
        return;
      }
      setState(() {
        _displayMs = cached.durationMs;
      });
    }
  }

  void _onStart() {
    _tickSub?.cancel();
    _engine.start();
    _tickSub = _engine.tickStream.listen((ms) {
      if (mounted && _phase == QuickPhase.running) {
        setState(() => _displayMs = ms);
      }
    });
    setState(() {
      _phase = QuickPhase.running;
      _displayMs = 0;
    });
  }

  Future<void> _onStop() async {
    _tickSub?.cancel();
    _tickSub = null;
    final ms = _engine.stop();
    final result = QuickResult(durationMs: ms, completedAt: DateTime.now());
    // Transition phase before the async save so the Stop button disappears
    // immediately and a second tap cannot re-enter this method (F-009).
    // The in-memory result is already shown even if save fails (F-003).
    if (!mounted) return;
    setState(() {
      _phase = QuickPhase.idle;
      _displayMs = ms;
    });
    try {
      await _store.save(result);
    } catch (e) {
      debugPrint('QuickStore.save failed: $e');
    }
  }

  Future<void> _handleBack() async {
    if (_phase == QuickPhase.running) {
      final leave = await confirmLeaveWhileRunning(context);
      if (!leave || !mounted) return;
      _engine.stop();
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _phase != QuickPhase.running,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: _handleBack),
          title: const Text('Quick'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_phase == QuickPhase.running)
                  Text(
                    formatDurationMs(_displayMs),
                    key: const Key('quick_elapsed'),
                    textAlign: TextAlign.center,
                    style: elapsedClockTextStyle(context),
                  )
                else
                  CopyableRunTime(
                    key: const Key('quick_elapsed'),
                    display: formatDurationMs(_displayMs),
                    textAlign: TextAlign.center,
                    style: elapsedClockTextStyle(context),
                  ),
                const SizedBox(height: 24),
                TimerToggleButton(
                  key: _phase == QuickPhase.running
                      ? const Key('quick_stop')
                      : const Key('quick_start'),
                  isRunning: _phase == QuickPhase.running,
                  onStart: _onStart,
                  onStop: _onStop,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
