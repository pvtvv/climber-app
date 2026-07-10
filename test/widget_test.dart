import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:climber_app/main.dart';
import 'package:climber_app/state/session_controller.dart';
import 'package:climber_app/services/session_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('empty state is shown when no athletes', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = SessionController(store: SessionStore());
    await controller.load();

    await tester.pumpWidget(ClimberApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.textContaining('No athletes yet'), findsOneWidget);
    expect(find.text('Climber Speed Timer'), findsOneWidget);
  });

  testWidgets('added athlete appears with expand/collapse', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = SessionController(
      store: SessionStore(),
      idGenerator: () => 'a1',
    );
    await controller.load();
    await controller.addAthlete('Alice');

    await tester.pumpWidget(ClimberApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Alice'), findsOneWidget);
    expect(find.textContaining('No athletes yet'), findsNothing);

    // Expand
    await tester.tap(find.text('Alice'));
    await tester.pumpAndSettle();
    expect(find.text('Runs'), findsOneWidget);

    // Collapse
    await tester.tap(find.text('Alice'));
    await tester.pumpAndSettle();
    expect(find.text('Runs'), findsNothing);
  });
}
