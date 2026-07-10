import 'package:climber_app/models/athlete.dart';
import 'package:climber_app/models/run.dart';
import 'package:climber_app/models/session.dart';
import 'package:climber_app/services/csv_export.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buildCsv includes all athletes name/run/time/date/timestamp', () {
    final dt1 = DateTime(2026, 7, 10, 10, 30, 15);
    final dt2 = DateTime(2026, 7, 10, 10, 35, 20);
    final dt3 = DateTime(2026, 7, 10, 10, 40, 5);
    
    final session = Session(
      athletes: [
        Athlete(
          id: 'a1',
          name: 'Alice',
          colorIndex: 0,
          runs: [
            Run(id: 'r1', runNumber: 1, durationMs: 12500, completedAt: dt1),
            Run(id: 'r2', runNumber: 2, durationMs: 11000, completedAt: dt2),
          ],
        ),
        Athlete(
          id: 'a2',
          name: 'Bob',
          colorIndex: 1,
          runs: [
            Run(id: 'r3', runNumber: 1, durationMs: 15000, completedAt: dt3),
            const Run(id: 'rp', runNumber: 2, isPending: true),
          ],
        ),
      ],
    );

    final csv = CsvExport().buildCsv(session);
    expect(csv, contains('athlete,run,time,date,timestamp'));
    expect(csv, contains('Alice,1,00:12.50,2026-07-10,10:30:15'));
    expect(csv, contains('Alice,2,00:11.00,2026-07-10,10:35:20'));
    expect(csv, contains('Bob,1,00:15.00,2026-07-10,10:40:05'));
    expect(csv, isNot(contains('Bob,2')));
  });
}
