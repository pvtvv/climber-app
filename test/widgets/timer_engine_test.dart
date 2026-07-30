import 'package:climber_app/services/timer_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('each TimerEngine instance is independent (not a singleton)', () {
    final a = TimerEngine();
    final b = TimerEngine();
    expect(identical(a, b), isFalse);
    a.dispose();
    b.dispose();
  });

  testWidgets('start → tick (30 ms pump) → stop freezes durationMs',
      (tester) async {
    final engine = TimerEngine();

    engine.start();
    expect(engine.phase, TimerPhase.running);

    // Advance fake time enough for at least one periodic tick.
    await tester.pump(TimerEngine.tickInterval);
    await tester.pump(TimerEngine.tickInterval);
    expect(engine.elapsedMs, greaterThan(0));

    final frozen = engine.stop();
    expect(engine.phase, TimerPhase.stopped);
    expect(frozen, greaterThan(0));
    expect(engine.durationMs, frozen);

    await tester.pump(TimerEngine.tickInterval);
    expect(engine.durationMs, frozen);

    engine.dispose();
  });
}
