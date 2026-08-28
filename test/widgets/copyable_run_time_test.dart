import 'package:climber_app/widgets/copyable_run_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

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

  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('long-press copies the displayed string and shows the SnackBar',
      (tester) async {
    await tester.pumpWidget(
      wrap(const CopyableRunTime(display: '00:12.34')),
    );

    await tester.longPress(find.byType(CopyableRunTime));
    await tester.pump();

    expect(clipboardText, '00:12.34');
    expect(find.text('Copied to clipboard'), findsOneWidget);
  });

  testWidgets(
      'a second rapid long-press replaces rather than stacks the SnackBar',
      (tester) async {
    await tester.pumpWidget(
      wrap(const CopyableRunTime(display: '00:12.34')),
    );

    await tester.longPress(find.byType(CopyableRunTime));
    await tester.pump();
    expect(find.text('Copied to clipboard'), findsOneWidget);

    await tester.longPress(find.byType(CopyableRunTime));
    await tester.pump();

    expect(find.text('Copied to clipboard'), findsOneWidget);
  });

  testWidgets('disposing during the async copy does not throw', (tester) async {
    await tester.pumpWidget(
      wrap(const CopyableRunTime(display: '00:05.00')),
    );

    await tester.longPress(find.byType(CopyableRunTime));
    // Unmount before the async Clipboard.setData continuation runs.
    await tester.pumpWidget(wrap(const SizedBox()));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
