import 'package:climber_app/screens/quick_measure_screen.dart';
import 'package:climber_app/services/timer_engine.dart';
import 'package:climber_app/widgets/timer_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Direct cross-surface checks that `TimerDialog` and `QuickMeasureScreen`
/// render their shared clock/toggle-button elements identically, per the
/// `timer-toggle-control` spec's "Matching Visual Presentation and
/// Position" requirement.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Clock TextStyle is identical between TimerDialog and QuickMeasureScreen',
      (tester) async {
    final dialogEngine = TimerEngine();
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: TimerDialog(engine: dialogEngine))),
    );
    await tester.pumpAndSettle();
    final dialogClockStyle =
        tester.widget<Text>(find.text('00:00.00')).style;

    final quickEngine = TimerEngine();
    await tester.pumpWidget(
      MaterialApp(home: QuickMeasureScreen(engine: quickEngine)),
    );
    await tester.pumpAndSettle();
    final quickClockStyle = tester
        .widget<Text>(find.descendant(
          of: find.byKey(const Key('quick_elapsed')),
          matching: find.byType(Text),
          matchRoot: true,
        ))
        .style;

    expect(quickClockStyle, dialogClockStyle);

    dialogEngine.dispose();
    quickEngine.dispose();
  });

  testWidgets(
      'Toggle button height and label style are identical between TimerDialog and QuickMeasureScreen',
      (tester) async {
    final dialogEngine = TimerEngine();
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: TimerDialog(engine: dialogEngine))),
    );
    await tester.pumpAndSettle();
    final dialogButtonHeight =
        tester.getSize(find.widgetWithText(FilledButton, 'Start')).height;
    final dialogLabelStyle = tester.widget<Text>(find.text('Start')).style;

    final quickEngine = TimerEngine();
    await tester.pumpWidget(
      MaterialApp(home: QuickMeasureScreen(engine: quickEngine)),
    );
    await tester.pumpAndSettle();
    final quickButtonHeight =
        tester.getSize(find.byKey(const Key('quick_start'))).height;
    final quickLabelStyle = tester.widget<Text>(find.text('Start')).style;

    expect(quickButtonHeight, dialogButtonHeight);
    expect(quickButtonHeight, 162);
    expect(quickLabelStyle?.fontSize, dialogLabelStyle?.fontSize);
    expect(quickLabelStyle?.fontSize, 21);

    dialogEngine.dispose();
    quickEngine.dispose();
  });
}
