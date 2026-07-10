/// Formats milliseconds as `MM:SS.cc` (centiseconds).
String formatDurationMs(int? durationMs) {
  if (durationMs == null) return '--:--.--';
  final totalCs = (durationMs / 10).round();
  final minutes = totalCs ~/ 6000;
  final seconds = (totalCs % 6000) ~/ 100;
  final centiseconds = totalCs % 100;
  final mm = minutes.toString().padLeft(2, '0');
  final ss = seconds.toString().padLeft(2, '0');
  final cc = centiseconds.toString().padLeft(2, '0');
  return '$mm:$ss.$cc';
}
