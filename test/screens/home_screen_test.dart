import 'package:climber_app/screens/home_screen.dart';
import 'package:climber_app/screens/mode_picker.dart';
import 'package:climber_app/services/session_store.dart';
import 'package:climber_app/services/timer_engine.dart';
import 'package:climber_app/state/session_controller.dart';
import 'package:climber_app/widgets/timer_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('AppBar back from Session pops to ModePicker', (tester) async {
    final controller = SessionController(store: SessionStore());
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(home: ModePicker(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('mode_session')));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byType(ModePicker), findsOneWidget);
  });

  testWidgets('TimerDialog uses TimerEngine tick stream for display',
      (tester) async {
    final engine = TimerEngine();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TimerDialog(engine: engine),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start'));
    await tester.pump(TimerEngine.tickInterval);

    expect(engine.phase, TimerPhase.running);

    engine.dispose();
  });

  testWidgets(
      'session leave-while-running: tap Cancel keeps screen and timing live',
      (tester) async {
    final controller = SessionController(
      store: SessionStore(),
      idGenerator: () => 'b1',
    );
    await controller.load();
    await controller.addAthlete('Jay');

    await tester.pumpWidget(
      MaterialApp(home: ModePicker(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('mode_session')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Jay'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tap to time…'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start'));
    await tester.pump(TimerEngine.tickInterval);

    // System back while running triggers confirm dialog.
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      find.text('Leave? Your in-progress timing will be discarded.'),
      findsOneWidget,
    );

    // Tapping Cancel dismisses the dialog; timing continues.
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(controller.hasPending('b1'), isTrue);

    // Stop the timer cleanly so test teardown doesn't throw on disposal.
    await tester.tap(find.text('Stop'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('system back while timer running shows confirm then pops',
      (tester) async {
    final controller = SessionController(
      store: SessionStore(),
      idGenerator: () => 'a1',
    );
    await controller.load();
    await controller.addAthlete('Ivy');

    await tester.pumpWidget(
      MaterialApp(
        home: ModePicker(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('mode_session')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ivy'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tap to time…'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start'));
    await tester.pump(TimerEngine.tickInterval);

    // System/browser back — PopScope on TimerDialog (not AppBar behind the modal).
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      find.text('Leave? Your in-progress timing will be discarded.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Leave'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(ModePicker), findsOneWidget);
    expect(controller.hasPending('a1'), isFalse);
  });
}
