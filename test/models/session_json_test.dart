import 'package:climber_app/models/athlete.dart';
import 'package:climber_app/models/run.dart';
import 'package:climber_app/models/session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Session JSON round-trip preserves athletes and runs', () {
    final session = Session(
      athletes: [
        Athlete(
          id: 'a1',
          name: 'Alice',
          colorIndex: 0,
          runs: const [
            Run(id: 'r1', runNumber: 1, durationMs: 12340),
            Run(id: 'r2', runNumber: 2, durationMs: 11890),
          ],
        ),
        Athlete(
          id: 'a2',
          name: 'Bob',
          colorIndex: 1,
          runs: const [
            Run(id: 'r3', runNumber: 1, durationMs: 15000),
          ],
        ),
      ],
    );

    final json = session.toJson();
    final restored = Session.fromJson(json);

    expect(restored.athletes.length, 2);
    expect(restored.athletes[0].id, 'a1');
    expect(restored.athletes[0].name, 'Alice');
    expect(restored.athletes[0].colorIndex, 0);
    expect(restored.athletes[0].runs.length, 2);
    expect(restored.athletes[0].runs[0].id, 'r1');
    expect(restored.athletes[0].runs[0].runNumber, 1);
    expect(restored.athletes[0].runs[0].durationMs, 12340);
    expect(restored.athletes[0].runs[1].runNumber, 2);
    expect(restored.athletes[0].runs[1].durationMs, 11890);

    expect(restored.athletes[1].id, 'a2');
    expect(restored.athletes[1].name, 'Bob');
    expect(restored.athletes[1].colorIndex, 1);
    expect(restored.athletes[1].runs.length, 1);
    expect(restored.athletes[1].runs[0].id, 'r3');
    expect(restored.athletes[1].runs[0].runNumber, 1);
    expect(restored.athletes[1].runs[0].durationMs, 15000);

    expect(restored, session);
  });
}
