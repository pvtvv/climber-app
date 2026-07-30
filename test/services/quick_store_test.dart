import 'package:climber_app/models/quick_result.dart';
import 'package:climber_app/services/quick_store.dart';
import 'package:climber_app/services/session_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('load with no prior data returns null', () async {
    final store = QuickStore();
    final result = await store.load();
    expect(result, isNull);
  });

  test('load with empty string stored returns null', () async {
    SharedPreferences.setMockInitialValues({QuickStore.storageKey: ''});
    final store = QuickStore();
    final result = await store.load();
    expect(result, isNull);
  });

  test('save → load round-trip preserves duration and timestamp', () async {
    final store = QuickStore();
    final dt = DateTime(2026, 7, 28, 12, 0, 0);

    final original = QuickResult(durationMs: 5432, completedAt: dt);
    await store.save(original);
    final loaded = await store.load();

    expect(loaded, isNotNull);
    expect(loaded!.durationMs, 5432);
    expect(loaded.completedAt, dt);
    expect(loaded, original);
  });

  test('save Quick does not write climber_session_v1', () async {
    final store = QuickStore();
    final dt = DateTime(2026, 7, 28, 12, 30, 0);
    await store.save(QuickResult(durationMs: 1000, completedAt: dt));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(QuickStore.storageKey), isNotNull);
    expect(prefs.getString(SessionStore.storageKey), isNull);
  });
}
