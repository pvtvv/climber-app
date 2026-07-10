import 'package:climber_app/models/session.dart';
import 'package:climber_app/models/time_format.dart';

class CsvExport {
  /// Builds CSV text: header + one row per saved run across all athletes.
  String buildCsv(Session session) {
    final buffer = StringBuffer('athlete,run,time,date,timestamp\n');
    for (final athlete in session.athletes) {
      for (final run in athlete.runs) {
        if (run.isPending || run.durationMs == null) continue;
        final dateStr = run.completedAt != null
            ? _formatDate(run.completedAt!)
            : '';
        final timeStr = run.completedAt != null
            ? _formatTime(run.completedAt!)
            : '';
        buffer.writeln(
          '${_escape(athlete.name)},${run.runNumber},${formatDurationMs(run.durationMs)},$dateStr,$timeStr',
        );
      }
    }
    return buffer.toString();
  }

  String _formatDate(DateTime dt) {
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '${dt.year}-$month-$day';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  String _escape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
