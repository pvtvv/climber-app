import 'package:climber_app/models/session.dart';
import 'package:climber_app/models/time_format.dart';

class CsvExport {
  /// Builds CSV text: header + one row per saved run across all athletes.
  String buildCsv(Session session) {
    final buffer = StringBuffer('athlete,run,time\n');
    for (final athlete in session.athletes) {
      for (final run in athlete.runs) {
        if (run.isPending || run.durationMs == null) continue;
        buffer.writeln(
          '${_escape(athlete.name)},${run.runNumber},${formatDurationMs(run.durationMs)}',
        );
      }
    }
    return buffer.toString();
  }

  String _escape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
