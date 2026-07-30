import 'package:climber_app/main.dart';
import 'package:climber_app/models/athlete.dart';
import 'package:climber_app/models/run.dart';
import 'package:climber_app/models/session.dart';
import 'package:climber_app/services/session_store.dart';
import 'package:climber_app/state/session_controller.dart';
import 'package:climber_app/widgets/timer_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SessionController> _controllerWith(Session session) async {
  SharedPreferences.setMockInitialValues({});
  final store = SessionStore();
  await store.save(session);
  var n = 0;
  final controller = SessionController(
    store: store,
    idGenerator: () => 'gen-${++n}',
  );
  await controller.load();
  return controller;
}

/// Enters Session mode from ModePicker when the Session tile is present.
Future<void> _enterSession(WidgetTester tester) async {
  final sessionTile = find.text('Session');
  if (sessionTile.evaluate().isNotEmpty) {
    await tester.tap(sessionTile);
    await tester.pumpAndSettle();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('add athlete via dialog appears in list', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = SessionController(
      store: SessionStore(),
      idGenerator: () => 'a-new',
    );
    await controller.load();
    await tester.pumpWidget(ClimberApp(controller: controller));
    await tester.pumpAndSettle();
    await _enterSession(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Casey');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.text('Casey'), findsOneWidget);
    expect(controller.athletes.length, 1);
  });

  testWidgets('add athlete FAB disabled at 10', (tester) async {
    final athletes = List.generate(
      10,
      (i) => Athlete(id: 'a$i', name: 'A$i', colorIndex: i),
    );
    final controller = await _controllerWith(Session(athletes: athletes));
    await tester.pumpWidget(ClimberApp(controller: controller));
    await tester.pumpAndSettle();
    await _enterSession(tester);

    expect(controller.canAddAthlete, isFalse);
    final fab = tester.widget<FloatingActionButton>(
      find.byType(FloatingActionButton),
    );
    expect(fab.onPressed, isNull);
  });

  testWidgets('runs table shows run#/time and sort reorders', (tester) async {
    final dt1 = DateTime(2026, 7, 10, 10, 30, 0);
    final dt2 = DateTime(2026, 7, 10, 10, 35, 0);
    
    final controller = await _controllerWith(
      Session(
        athletes: [
          Athlete(
            id: 'a1',
            name: 'Dana',
            colorIndex: 0,
            runs: [
              Run(id: 'r1', runNumber: 1, durationMs: 30000, completedAt: dt1),
              Run(id: 'r2', runNumber: 2, durationMs: 10000, completedAt: dt2),
            ],
          ),
        ],
      ),
    );
    await tester.pumpWidget(ClimberApp(controller: controller));
    await tester.pumpAndSettle();
    await _enterSession(tester);

    await tester.tap(find.text('Dana'));
    await tester.pumpAndSettle();

    expect(find.text('00:30.00'), findsOneWidget);
    expect(find.text('00:10.00'), findsOneWidget);

    await tester.tap(find.text('Sort by time'));
    await tester.pumpAndSettle();

    final times =
        controller.athletes.single.runs.map((r) => r.durationMs).toList();
    expect(times, [10000, 30000]);
  });

  testWidgets('plus adds one pending row; second plus is no-op', (tester) async {
    final controller = await _controllerWith(
      Session(
        athletes: [
          const Athlete(id: 'a1', name: 'Eve', colorIndex: 1),
        ],
      ),
    );
    await tester.pumpWidget(ClimberApp(controller: controller));
    await tester.pumpAndSettle();
    await _enterSession(tester);
    await tester.tap(find.text('Eve'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('Tap to time…'), findsOneWidget);
    expect(controller.athletes.single.runs.length, 1);

    // Second add is a no-op at controller level while pending exists.
    final again = await controller.addPendingRun('a1');
    expect(again, isFalse);
    expect(controller.athletes.single.runs.length, 1);
  });

  testWidgets('timer Start then Stop shows Save/Cancel', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: TimerDialog())),
    );
    await tester.pumpAndSettle();

    expect(find.text('00:00.00'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);

    // Start button is large (height 162) while idle.
    final startBefore =
        tester.getSize(find.widgetWithText(FilledButton, 'Start'));
    expect(startBefore.height, 162);

    await tester.tap(find.text('Start'));
    // Advance fake time so periodic ticker fires once.
    await tester.pump(const Duration(milliseconds: 30));

    final stopSize = tester.getSize(find.widgetWithText(FilledButton, 'Stop'));
    expect(stopSize.height, 162);

    await tester.tap(find.text('Stop'));
    await tester.pumpAndSettle();
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('timer Cancel path discards pending via controller', (tester) async {
    final controller = await _controllerWith(
      Session(
        athletes: [
          const Athlete(id: 'a1', name: 'Finn', colorIndex: 2),
        ],
      ),
    );
    await controller.addPendingRun('a1');
    expect(controller.hasPending('a1'), isTrue);
    await controller.discardPending('a1');
    expect(controller.hasPending('a1'), isFalse);
    expect(controller.athletes.single.runs, isEmpty);
  });

  testWidgets('persist reload restores athletes and runs', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = SessionStore();
    var n = 0;
    final c1 = SessionController(
      store: store,
      idGenerator: () => 'x${++n}',
    );
    await c1.load();
    await c1.addAthlete('Gina');
    await c1.addPendingRun(c1.athletes.single.id);
    await c1.saveRun(c1.athletes.single.id, 22200);

    final c2 = SessionController(store: store);
    await c2.load();
    expect(c2.athletes.single.name, 'Gina');
    expect(c2.athletes.single.runs.single.durationMs, 22200);
    expect(c2.athletes.single.runs.single.completedAt, isNotNull);
  });

  testWidgets('new session cancel clears without requiring export', (tester) async {
    final dt = DateTime(2026, 7, 10, 10, 30, 0);
    
    final controller = await _controllerWith(
      Session(
        athletes: [
          Athlete(
            id: 'a1',
            name: 'Hank',
            colorIndex: 0,
            runs: [Run(id: 'r1', runNumber: 1, durationMs: 5000, completedAt: dt)],
          ),
        ],
      ),
    );
    await tester.pumpWidget(ClimberApp(controller: controller));
    await tester.pumpAndSettle();
    await _enterSession(tester);

    await tester.tap(find.byTooltip('New session'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(controller.athletes, isEmpty);
    expect(find.textContaining('No athletes yet'), findsOneWidget);
  });
}
