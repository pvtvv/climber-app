import 'dart:async';

/// Shared timer phases + centisecond tick (30 ms interval).
enum TimerPhase { idle, running, stopped }

/// @cpt-algo:cpt-climberapp-algo-measurement-mode-entry-timer-engine:p2
class TimerEngine {
  TimerEngine();

  TimerPhase _phase = TimerPhase.idle;
  Timer? _ticker;
  DateTime? _start;
  int _elapsedMs = 0;
  int _durationMs = 0;

  final StreamController<int> _tickController =
      StreamController<int>.broadcast();

  TimerPhase get phase => _phase;

  /// Frozen elapsed milliseconds after [stop]; zero while idle before first run.
  int get durationMs => _durationMs;

  /// Live elapsed milliseconds while running; frozen value after stop.
  int get elapsedMs =>
      _phase == TimerPhase.running ? _elapsedMs : _durationMs;

  Stream<int> get tickStream => _tickController.stream;

  static const tickInterval = Duration(milliseconds: 30);

  void start() {
    _ticker?.cancel();
    _elapsedMs = 0;
    _durationMs = 0;
    _start = DateTime.now();
    _phase = TimerPhase.running;
    // Wall-clock elapsed: DateTime.now() is advanced by flutter_test FakeAsync
    // pumps, so tests remain accurate without a Stopwatch.
    _ticker = Timer.periodic(tickInterval, (_) {
      if (_phase != TimerPhase.running) return;
      _elapsedMs = DateTime.now().difference(_start!).inMilliseconds;
      if (!_tickController.isClosed) {
        _tickController.add(_elapsedMs);
      }
    });
  }

  /// Stops ticking and returns frozen [durationMs] based on wall-clock elapsed.
  int stop() {
    _ticker?.cancel();
    _ticker = null;
    _durationMs = _start != null
        ? DateTime.now().difference(_start!).inMilliseconds
        : _elapsedMs;
    _start = null;
    _phase = TimerPhase.stopped;
    return _durationMs;
  }

  void dispose() {
    _ticker?.cancel();
    _ticker = null;
    _start = null;
    _phase = TimerPhase.idle;
    if (!_tickController.isClosed) {
      _tickController.close();
    }
  }
}
