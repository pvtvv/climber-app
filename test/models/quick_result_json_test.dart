import 'package:climber_app/models/quick_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('QuickResult JSON round-trip preserves durationMs and completedAt', () {
    final dt = DateTime(2026, 7, 28, 14, 15, 30);

    final original = QuickResult(durationMs: 12345, completedAt: dt);
    final json = original.toJson();
    final restored = QuickResult.fromJson(json);

    expect(restored.durationMs, 12345);
    expect(restored.completedAt, dt);
    expect(restored, original);
  });
}
