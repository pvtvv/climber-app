import 'package:climber_app/services/timer_engine.dart';
import 'package:climber_app/widgets/timer_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Interaction-state and layout-shape regression tests for `TimerDialog`'s
/// single toggling Start/Stop button, per the `timer-toggle-control` spec:
/// exactly one button while idle/running, default hover/press only, no
/// custom wrappers, Save/Cancel unchanged after Stop.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The test environment has no real platform to answer Clipboard method
  // calls, so `Clipboard.setData`/`getData` hang indefinitely unless the
  // `SystemChannels.platform` channel is mocked directly.
  String? clipboardText;

  setUp(() {
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

  /// The clock is the only Text in the tree whose data is a MM:SS.cc
  /// duration; button labels ("Start"/"Stop"/"Save"/"Cancel") never match.
  String clockText(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data)
      .firstWhere((s) => s != null && RegExp(r'^\d\d:\d\d\.\d\d$').hasMatch(s))!;

  /// A GestureDetector/MouseRegion that is both a descendant of TimerDialog
  /// and an ancestor of [target] would be a custom wrapper added around the
  /// button; internal wrappers used by FilledButton's own implementation are
  /// descendants of the button, not ancestors, so they are excluded here.
  Finder customWrapperOf(Finder target, Type wrapperType) => find.ancestor(
        of: target,
        matching: find.descendant(
          of: find.byType(TimerDialog),
          matching: find.byType(wrapperType),
        ),
      );

  testWidgets('Idle phase shows exactly one Start button, no custom wrapper',
      (tester) async {
    final engine = TimerEngine();
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: TimerDialog(engine: engine))),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FilledButton), findsOneWidget);
    final start = find.widgetWithText(FilledButton, 'Start');
    expect(start, findsOneWidget);
    expect(find.text('Stop'), findsNothing);

    expect(customWrapperOf(start, GestureDetector), findsNothing);
    expect(customWrapperOf(start, MouseRegion), findsNothing);
    expect(customWrapperOf(start, AnimatedContainer), findsNothing);

    engine.dispose();
  });

  testWidgets(
      'Tapping Start relabels the same button to Stop, no custom wrapper',
      (tester) async {
    final engine = TimerEngine();
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: TimerDialog(engine: engine))),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Start'));
    await tester.pump(TimerEngine.tickInterval);

    expect(engine.phase, TimerPhase.running);
    expect(find.byType(FilledButton), findsOneWidget);
    final stop = find.widgetWithText(FilledButton, 'Stop');
    expect(stop, findsOneWidget);
    expect(find.text('Start'), findsNothing);

    expect(customWrapperOf(stop, GestureDetector), findsNothing);
    expect(customWrapperOf(stop, MouseRegion), findsNothing);

    engine.dispose();
  });

  testWidgets('Save and Cancel have no custom gesture or mouse wrapper',
      (tester) async {
    final engine = TimerEngine();
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: TimerDialog(engine: engine))),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Start'));
    await tester.pump(TimerEngine.tickInterval);
    await tester.tap(find.widgetWithText(FilledButton, 'Stop'));
    await tester.pumpAndSettle();

    expect(find.byType(FilledButton), findsNWidgets(2));
    final save = find.widgetWithText(FilledButton, 'Save');
    final cancel = find.widgetWithText(FilledButton, 'Cancel');
    expect(save, findsOneWidget);
    expect(cancel, findsOneWidget);
    expect(find.text('Start'), findsNothing);
    expect(find.text('Stop'), findsNothing);

    for (final button in [save, cancel]) {
      expect(customWrapperOf(button, GestureDetector), findsNothing);
      expect(customWrapperOf(button, MouseRegion), findsNothing);
    }
  });

  testWidgets(
      'Tapping the toggle button across separate frames starts then stops exactly once',
      (tester) async {
    final engine = TimerEngine();
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: TimerDialog(engine: engine))),
    );
    await tester.pumpAndSettle();

    // First tap: Idle -> Running. One frame is enough for the button to
    // rebuild with the Stop label and the Stop handler.
    await tester.tap(find.widgetWithText(FilledButton, 'Start'));
    await tester.pump();
    expect(engine.phase, TimerPhase.running);
    expect(find.widgetWithText(FilledButton, 'Stop'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);

    // Second tap on the now-relabeled button: Running -> Stopped, exactly
    // once - not a second Start and not a double-stop.
    await tester.tap(find.widgetWithText(FilledButton, 'Stop'));
    await tester.pump();
    expect(engine.phase, TimerPhase.stopped);
    final durationAfterStop = engine.durationMs;

    // Stop is gone once stopped (replaced by Save/Cancel), so a further tap
    // at the same location cannot replay against a stale Stop handler.
    expect(find.widgetWithText(FilledButton, 'Stop'), findsNothing);
    expect(engine.durationMs, durationAfterStop);
  });

  testWidgets(
      'Long-press on the frozen duration after Stop copies it and shows a SnackBar',
      (tester) async {
    final engine = TimerEngine();
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: TimerDialog(engine: engine))),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Start'));
    await tester.pump(TimerEngine.tickInterval);
    await tester.tap(find.widgetWithText(FilledButton, 'Stop'));
    await tester.pumpAndSettle();

    final frozenDisplay = clockText(tester);

    await tester.longPress(find.text(frozenDisplay));
    await tester.pump();

    expect(clipboardText, frozenDisplay);
    expect(find.text('Copied to clipboard'), findsOneWidget);
  });

  testWidgets('Long-press on the live clock before Stop has no effect',
      (tester) async {
    final engine = TimerEngine();
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: TimerDialog(engine: engine))),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.text(clockText(tester)));
    await tester.pump();

    expect(clipboardText, isNull);
    expect(find.text('Copied to clipboard'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'Start'));
    await tester.pump(TimerEngine.tickInterval);

    await tester.longPress(find.text(clockText(tester)));
    await tester.pump();

    expect(clipboardText, isNull);
    expect(find.text('Copied to clipboard'), findsNothing);

    engine.dispose();
  });
}
