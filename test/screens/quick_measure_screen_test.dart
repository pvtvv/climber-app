import 'package:climber_app/models/quick_result.dart';
import 'package:climber_app/screens/mode_picker.dart';
import 'package:climber_app/screens/quick_measure_screen.dart';
import 'package:climber_app/services/quick_store.dart';
import 'package:climber_app/services/timer_engine.dart';
import 'package:climber_app/state/session_controller.dart';
import 'package:climber_app/services/session_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The test environment has no real platform to answer Clipboard method
  // calls, so `Clipboard.setData`/`getData` hang indefinitely unless the
  // `SystemChannels.platform` channel is mocked directly.
  String? clipboardText;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    clipboardText = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        clipboardText = (call.arguments as Map)['text'] as String?;
      } else if (call.method == 'Clipboard.getData') {
        return {'text': clipboardText};
      }
      return null;
    });
  });

  Widget wrap(QuickMeasureScreen screen) {
    return MaterialApp(home: screen);
  }

  /// A GestureDetector/MouseRegion that is both a descendant of
  /// QuickMeasureScreen and an ancestor of [target] would be a custom
  /// wrapper added around the button; internal wrappers used by
  /// FilledButton's own implementation are descendants of the button, not
  /// ancestors, so they are excluded here.
  Finder customWrapperOf(Finder target, Type wrapperType) => find.ancestor(
        of: target,
        matching: find.descendant(
          of: find.byType(QuickMeasureScreen),
          matching: find.byType(wrapperType),
        ),
      );

  testWidgets('opens in Idle when no cached result', (tester) async {
    await tester.pumpWidget(wrap(const QuickMeasureScreen()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('quick_start')), findsOneWidget);
    expect(find.byKey(const Key('quick_stop')), findsNothing);
    expect(find.text('00:00.00'), findsOneWidget);
  });

  testWidgets(
      'opens Idle with a cached duration shown; button reads Start, not Retake',
      (tester) async {
    final dt = DateTime(2026, 7, 28, 10, 0, 0);
    SharedPreferences.setMockInitialValues({
      QuickStore.storageKey:
          '{"durationMs":5000,"completedAt":"${dt.toIso8601String()}"}',
    });

    await tester.pumpWidget(wrap(const QuickMeasureScreen()));
    await tester.pumpAndSettle();

    expect(find.text('00:05.00'), findsOneWidget);
    expect(find.byKey(const Key('quick_start')), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Retake'), findsNothing);
    expect(find.byKey(const Key('quick_stop')), findsNothing);
  });

  testWidgets(
      'Start -> Stop persists to climber_quick_v1 and returns to Start immediately',
      (tester) async {
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

    // No separate result screen: the same button is already back to "Start".
    expect(find.byKey(const Key('quick_start')), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.byKey(const Key('quick_stop')), findsNothing);

    final loaded = await store.load();
    expect(loaded, isNotNull);
    expect(loaded!.durationMs, greaterThan(0));
    expect(loaded.completedAt, isNotNull);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(SessionStore.storageKey), isNull);

    engine.dispose();
  });

  testWidgets('Starting again after a completed run overwrites on Stop',
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
    expect(find.text('Start'), findsOneWidget);

    await tester.tap(find.byKey(const Key('quick_start')));
    await tester.pump(TimerEngine.tickInterval);
    await tester.tap(find.byKey(const Key('quick_stop')));
    await tester.pumpAndSettle();

    final loaded = await store.load();
    expect(loaded, isNotNull);
    expect(loaded!.durationMs, isNot(3000));

    engine.dispose();
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

  testWidgets('Idle button is 162 tall and there is no Spacer', (tester) async {
    await tester.pumpWidget(wrap(const QuickMeasureScreen()));
    await tester.pumpAndSettle();

    final size = tester.getSize(find.byKey(const Key('quick_start')));
    expect(size.height, 162);
    expect(find.byType(Spacer), findsNothing);
  });

  testWidgets(
      'Start and Stop have no custom gesture or mouse wrapper', (tester) async {
    final engine = TimerEngine();
    await tester.pumpWidget(wrap(QuickMeasureScreen(engine: engine)));
    await tester.pumpAndSettle();

    final start = find.byKey(const Key('quick_start'));
    expect(customWrapperOf(start, GestureDetector), findsNothing);
    expect(customWrapperOf(start, MouseRegion), findsNothing);
    expect(customWrapperOf(start, AnimatedContainer), findsNothing);

    await tester.tap(start);
    await tester.pump(TimerEngine.tickInterval);

    final stop = find.byKey(const Key('quick_stop'));
    expect(customWrapperOf(stop, GestureDetector), findsNothing);
    expect(customWrapperOf(stop, MouseRegion), findsNothing);

    engine.dispose();
  });

  testWidgets('Clock uses the shared tabular-figures, w600 style', (tester) async {
    await tester.pumpWidget(wrap(const QuickMeasureScreen()));
    await tester.pumpAndSettle();

    final clock = tester.widget<Text>(find.descendant(
      of: find.byKey(const Key('quick_elapsed')),
      matching: find.byType(Text),
      matchRoot: true,
    ));
    expect(clock.style, isNotNull);
    expect(
      clock.style!.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
    expect(clock.style!.fontWeight, FontWeight.w600);
  });

  testWidgets('Button label uses the shared labelLarge/fontSize 21 style',
      (tester) async {
    await tester.pumpWidget(wrap(const QuickMeasureScreen()));
    await tester.pumpAndSettle();

    final label = tester.widget<Text>(find.text('Start'));
    expect(label.style?.fontSize, 21);
  });

  testWidgets('Content column is centered on screen', (tester) async {
    await tester.pumpWidget(wrap(const QuickMeasureScreen()));
    await tester.pumpAndSettle();

    expect(
      find.ancestor(
        of: find.byKey(const Key('quick_elapsed')),
        matching: find.byType(Center),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'Long-press on the clock while idle with a completed duration copies it',
      (tester) async {
    final store = QuickStore();
    final engine = TimerEngine();
    await tester.pumpWidget(
      wrap(QuickMeasureScreen(store: store, engine: engine)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('quick_start')));
    await tester.pump(TimerEngine.tickInterval);
    await tester.tap(find.byKey(const Key('quick_stop')));
    await tester.pumpAndSettle();

    final displayed = tester
        .widget<Text>(find.descendant(
          of: find.byKey(const Key('quick_elapsed')),
          matching: find.byType(Text),
          matchRoot: true,
        ))
        .data!;

    await tester.longPress(find.byKey(const Key('quick_elapsed')));
    await tester.pump();

    expect(clipboardText, displayed);
    expect(find.text('Copied to clipboard'), findsOneWidget);

    engine.dispose();
  });

  testWidgets('Long-press on the clock while running has no effect',
      (tester) async {
    final engine = TimerEngine();
    await tester.pumpWidget(wrap(QuickMeasureScreen(engine: engine)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('quick_start')));
    await tester.pump(TimerEngine.tickInterval);

    await tester.longPress(find.byKey(const Key('quick_elapsed')));
    await tester.pump();

    expect(clipboardText, isNull);
    expect(find.text('Copied to clipboard'), findsNothing);

    engine.dispose();
  });

  testWidgets(
      'Long-press on the clock while idle with no prior result still copies 00:00.00',
      (tester) async {
    await tester.pumpWidget(wrap(const QuickMeasureScreen()));
    await tester.pumpAndSettle();

    expect(find.text('00:00.00'), findsOneWidget);

    await tester.longPress(find.byKey(const Key('quick_elapsed')));
    await tester.pump();

    expect(clipboardText, '00:00.00');
    expect(find.text('Copied to clipboard'), findsOneWidget);
  });
}
