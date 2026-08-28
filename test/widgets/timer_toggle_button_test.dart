import 'package:climber_app/widgets/timer_toggle_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('elapsedClockTextStyle returns tabular-figures, w600 style',
      (tester) async {
    TextStyle? style;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            style = elapsedClockTextStyle(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(style, isNotNull);
    expect(style!.fontFeatures, contains(const FontFeature.tabularFigures()));
    expect(style!.fontWeight, FontWeight.w600);
  });

  testWidgets('TimerToggleButton shows Start when not running', (tester) async {
    var started = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TimerToggleButton(
            isRunning: false,
            onStart: () => started = true,
            onStop: null,
          ),
        ),
      ),
    );

    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Stop'), findsNothing);
    expect(tester.getSize(find.byType(TimerToggleButton)).height, 162);

    await tester.tap(find.text('Start'));
    expect(started, isTrue);
  });

  testWidgets('TimerToggleButton shows Stop when running', (tester) async {
    var stopped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TimerToggleButton(
            isRunning: true,
            onStart: null,
            onStop: () => stopped = true,
          ),
        ),
      ),
    );

    expect(find.text('Stop'), findsOneWidget);
    expect(find.text('Start'), findsNothing);

    await tester.tap(find.text('Stop'));
    expect(stopped, isTrue);
  });
}
