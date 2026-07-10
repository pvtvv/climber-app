import 'package:climber_app/models/athlete.dart';
import 'package:climber_app/models/run.dart';
import 'package:climber_app/models/session.dart';
import 'package:climber_app/services/session_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('load with no prior data returns empty session', () async {
    final store = SessionStore();
    final session = await store.load();
    expect(session.athletes, isEmpty);
    expect(session.isEmpty, isTrue);
  });

  test('empty → save → load restores athletes and runs', () async {
    final store = SessionStore();
    final dt = DateTime(2026, 7, 10, 10, 30, 15);
    
    final original = Session(
      athletes: [
        Athlete(
          id: 'a1',
          name: 'Alice',
          colorIndex: 2,
          runs: [
            Run(id: 'r1', runNumber: 1, durationMs: 9999, completedAt: dt),
          ],
        ),
        const Athlete(id: 'a2', name: 'Bob', colorIndex: 3),
      ],
    );

    await store.save(original);
    final loaded = await store.load();

    expect(loaded.athletes.length, 2);
    expect(loaded.athletes[0].name, 'Alice');
    expect(loaded.athletes[0].colorIndex, 2);
    expect(loaded.athletes[0].runs.single.durationMs, 9999);
    expect(loaded.athletes[0].runs.single.completedAt, dt);
    expect(loaded.athletes[1].name, 'Bob');
    expect(loaded, original);
  });
}
