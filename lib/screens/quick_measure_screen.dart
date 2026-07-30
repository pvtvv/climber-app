import 'dart:async';

import 'package:flutter/material.dart';
import 'package:climber_app/models/quick_result.dart';
import 'package:climber_app/models/time_format.dart';
import 'package:climber_app/services/quick_store.dart';
import 'package:climber_app/services/timer_engine.dart';
import 'package:climber_app/widgets/leave_confirm.dart';

enum QuickPhase { idle, running, result }

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
  QuickResult? _cachedResult;
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
        // preserve the cached reference but never override the active phase.
        _cachedResult = cached;
        return;
      }
      setState(() {
        _cachedResult = cached;
        _phase = QuickPhase.result;
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
      _phase = QuickPhase.result;
      _displayMs = ms;
      _cachedResult = result;
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
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                formatDurationMs(_displayMs),
                key: const Key('quick_elapsed'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayMedium,
              ),
              if (_phase == QuickPhase.result && _cachedResult != null)
                Text(
                  key: const Key('quick_result_label'),
                  'Result saved',
                  textAlign: TextAlign.center,
                ),
              const Spacer(),
              if (_phase != QuickPhase.running)
                FilledButton(
                  key: const Key('quick_start'),
                  onPressed: _onStart,
                  child: Text(_phase == QuickPhase.result ? 'Retake' : 'Start'),
                ),
              if (_phase == QuickPhase.running) ...[
                FilledButton.tonal(
                  key: const Key('quick_stop'),
                  onPressed: _onStop,
                  child: const Text('Stop'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
