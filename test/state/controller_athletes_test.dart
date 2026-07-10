import 'package:climber_app/models/athlete_palette.dart';
import 'package:climber_app/services/session_store.dart';
import 'package:climber_app/state/session_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SessionController controller;
  var idCounter = 0;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    idCounter = 0;
    controller = SessionController(
      store: SessionStore(),
      idGenerator: () => 'id-${++idCounter}',
    );
  });

  test('adding 10 athletes succeeds with distinct color indices', () async {
    for (var i = 0; i < 10; i++) {
      final ok = await controller.addAthlete('Athlete $i');
      expect(ok, isTrue);
    }
    expect(controller.athletes.length, 10);
    final colors = controller.athletes.map((a) => a.colorIndex).toSet();
    expect(colors.length, 10);
    expect(colors, athletePalette.asMap().keys.toSet());
  });

  test('11th addAthlete is rejected and length stays 10', () async {
    for (var i = 0; i < 10; i++) {
      await controller.addAthlete('Athlete $i');
    }
    final ok = await controller.addAthlete('Overflow');
    expect(ok, isFalse);
    expect(controller.athletes.length, 10);
    expect(
      controller.athletes.any((a) => a.name == 'Overflow'),
      isFalse,
    );
  });

  test('clearSession empties athlete list', () async {
    await controller.addAthlete('Alice');
    await controller.addAthlete('Bob');
    expect(controller.athletes, isNotEmpty);
    await controller.clearSession();
    expect(controller.athletes, isEmpty);
  });
}
