import 'package:climber_app/models/athlete.dart';
import 'package:climber_app/models/run.dart';
import 'package:climber_app/models/session.dart';
import 'package:climber_app/services/csv_export.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buildCsv includes all athletes name/run/time', () {
    final session = Session(
      athletes: [
        Athlete(
          id: 'a1',
          name: 'Alice',
          colorIndex: 0,
          runs: const [
            Run(id: 'r1', runNumber: 1, durationMs: 12500),
            Run(id: 'r2', runNumber: 2, durationMs: 11000),
          ],
        ),
        Athlete(
          id: 'a2',
          name: 'Bob',
          colorIndex: 1,
          runs: const [
            Run(id: 'r3', runNumber: 1, durationMs: 15000),
            Run(id: 'rp', runNumber: 2, isPending: true),
          ],
        ),
      ],
    );

    final csv = CsvExport().buildCsv(session);
    expect(csv, contains('athlete,run,time'));
    expect(csv, contains('Alice,1,00:12.50'));
    expect(csv, contains('Alice,2,00:11.00'));
    expect(csv, contains('Bob,1,00:15.00'));
    expect(csv, isNot(contains('Bob,2')));
  });
}
