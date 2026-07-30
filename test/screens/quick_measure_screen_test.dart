import 'package:climber_app/models/quick_result.dart';
import 'package:climber_app/screens/mode_picker.dart';
import 'package:climber_app/screens/quick_measure_screen.dart';
import 'package:climber_app/services/quick_store.dart';
import 'package:climber_app/services/timer_engine.dart';
import 'package:climber_app/state/session_controller.dart';
import 'package:climber_app/services/session_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget wrap(QuickMeasureScreen screen) {
    return MaterialApp(home: screen);
  }

  testWidgets('opens in Idle when no cached result', (tester) async {
    await tester.pumpWidget(wrap(const QuickMeasureScreen()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('quick_start')), findsOneWidget);
    expect(find.byKey(const Key('quick_stop')), findsNothing);
    expect(find.byKey(const Key('quick_result_label')), findsNothing);
  });

  testWidgets('opens in Result when cached quick result exists', (tester) async {
    final dt = DateTime(2026, 7, 28, 10, 0, 0);
    SharedPreferences.setMockInitialValues({
      QuickStore.storageKey:
          '{"durationMs":5000,"completedAt":"${dt.toIso8601String()}"}',
    });

    await tester.pumpWidget(wrap(const QuickMeasureScreen()));
    await tester.pumpAndSettle();

    expect(find.text('00:05.00'), findsOneWidget);
    expect(find.byKey(const Key('quick_result_label')), findsOneWidget);
    expect(find.byKey(const Key('quick_start')), findsOneWidget);
  });

  testWidgets('Start → Stop persists to climber_quick_v1', (tester) async {
    final store = QuickStore();
    final engine = TimerEngine();

    await tester.pumpWidget(
      wrap(QuickMeasureScreen(store: store, engine: engine)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('quick_start')));
    await tester.pump(TimerEngine.tickInterval);
    await tester.pump(TimerEngine.tickInterval);

    await tester.tap(find.byKey(const Key('quick_stop')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('quick_result_label')), findsOneWidget);

    final loaded = await store.load();
    expect(loaded, isNotNull);
    expect(loaded!.durationMs, greaterThan(0));
    expect(loaded.completedAt, isNotNull);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(SessionStore.storageKey), isNull);

    engine.dispose();
  });

  testWidgets('Retake from Result starts new run and overwrites on Stop',
      (tester) async {
    final store = QuickStore();
    final engine = TimerEngine();
    final dt = DateTime(2026, 7, 28, 9, 0, 0);
    await store.save(QuickResult(durationMs: 3000, completedAt: dt));

    await tester.pumpWidget(
      wrap(QuickMeasureScreen(store: store, engine: engine)),
    );
    await tester.pumpAndSettle();

    expect(find.text('00:03.00'), findsOneWidget);

    await tester.tap(find.byKey(const Key('quick_start')));
    await tester.pump(TimerEngine.tickInterval);
    await tester.tap(find.byKey(const Key('quick_stop')));
    await tester.pumpAndSettle();

    final loaded = await store.load();
    expect(loaded, isNotNull);
    expect(loaded!.durationMs, isNot(3000));

    engine.dispose();
  });

  testWidgets('Start button shows Retake label in Result phase', (tester) async {
    final dt = DateTime(2026, 7, 28, 10, 0, 0);
    SharedPreferences.setMockInitialValues({
      QuickStore.storageKey:
          '{"durationMs":5000,"completedAt":"${dt.toIso8601String()}"}',
    });

    await tester.pumpWidget(wrap(const QuickMeasureScreen()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('quick_start')), findsOneWidget);
    expect(find.text('Retake'), findsOneWidget);
    expect(find.text('Start'), findsNothing);
  });

  testWidgets('AppBar back from Idle returns to ModePicker', (tester) async {
    final controller = SessionController(store: SessionStore());
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(home: ModePicker(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('mode_quick')));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byType(ModePicker), findsOneWidget);
  });

  testWidgets('AppBar back while Running shows confirm; Cancel resumes',
      (tester) async {
    final engine = TimerEngine();

    await tester.pumpWidget(
      wrap(QuickMeasureScreen(engine: engine)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('quick_start')));
    await tester.pump(TimerEngine.tickInterval);

    await tester.tap(find.byType(BackButton));
    // Avoid pumpAndSettle while Timer.periodic is live.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Leave? Your in-progress timing will be discarded.'),
        findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(QuickMeasureScreen), findsOneWidget);
    expect(find.byKey(const Key('quick_stop')), findsOneWidget);

    engine.stop();
    engine.dispose();
  });

  testWidgets('AppBar back while Running confirm Leave pops to picker',
      (tester) async {
    final controller = SessionController(store: SessionStore());
    await controller.load();
    final engine = TimerEngine();

    await tester.pumpWidget(
      MaterialApp(
        home: ModePicker(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('mode_quick')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('quick_start')));
    await tester.pump(TimerEngine.tickInterval);

    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();

    expect(find.byType(ModePicker), findsOneWidget);

    engine.dispose();
  });
}
