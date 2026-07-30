import 'package:climber_app/screens/home_screen.dart';
import 'package:climber_app/screens/mode_picker.dart';
import 'package:climber_app/screens/quick_measure_screen.dart';
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

  testWidgets('ModePicker shows Quick and Session tiles with subtitle copy',
      (tester) async {
    final controller = SessionController(store: SessionStore());
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(home: ModePicker(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text(ModePicker.quickLabel), findsOneWidget);
    expect(find.text(ModePicker.quickSubtitle), findsOneWidget);
    expect(find.text(ModePicker.sessionLabel), findsOneWidget);
    expect(find.text(ModePicker.sessionSubtitle), findsOneWidget);
  });

  testWidgets('tapping Quick navigates to QuickMeasureScreen', (tester) async {
    final controller = SessionController(store: SessionStore());
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(home: ModePicker(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('mode_quick')));
    await tester.pumpAndSettle();

    expect(find.byType(QuickMeasureScreen), findsOneWidget);
    expect(find.text('Quick'), findsOneWidget);
  });

  testWidgets('tapping Session navigates to HomeScreen', (tester) async {
    final controller = SessionController(store: SessionStore());
    expect(controller.isLoaded, isFalse);

    await tester.pumpWidget(
      MaterialApp(home: ModePicker(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('mode_session')));
    await tester.pumpAndSettle();

    expect(controller.isLoaded, isTrue);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.textContaining('No athletes yet'), findsOneWidget);
  });

  testWidgets('Quick path does not load session store', (tester) async {
    SharedPreferences.setMockInitialValues({
      SessionStore.storageKey:
          '{"athletes":[{"id":"s1","name":"Stored","colorIndex":0,"runs":[]}]}',
    });

    final controller = SessionController(store: SessionStore());
    expect(controller.isLoaded, isFalse);

    await tester.pumpWidget(
      MaterialApp(home: ModePicker(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('mode_quick')));
    await tester.pumpAndSettle();

    expect(controller.isLoaded, isFalse);
    expect(controller.athletes, isEmpty);
  });
}
