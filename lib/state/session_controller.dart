import 'package:climber_app/models/athlete.dart';
import 'package:climber_app/models/athlete_palette.dart';
import 'package:climber_app/models/run.dart';
import 'package:climber_app/models/session.dart';
import 'package:climber_app/services/csv_download.dart';
import 'package:climber_app/services/csv_export.dart';
import 'package:climber_app/services/session_store.dart';
import 'package:flutter/foundation.dart';

typedef IdGenerator = String Function();

class SessionController extends ChangeNotifier {
  SessionController({
    SessionStore? store,
    CsvExport? csvExport,
    IdGenerator? idGenerator,
  })  : _store = store ?? SessionStore(),
        _csvExport = csvExport ?? CsvExport(),
        _idGenerator = idGenerator ?? _defaultId;

  static const maxAthletes = 10;

  final SessionStore _store;
  final CsvExport _csvExport;
  final IdGenerator _idGenerator;

  Session _session = Session.empty();
  bool _loaded = false;
  bool _sortedByTime = false;

  Session get session => _session;
  List<Athlete> get athletes => _session.athletes;
  bool get isLoaded => _loaded;
  bool get canAddAthlete => _session.athletes.length < maxAthletes;
  bool get sortedByTime => _sortedByTime;

  static String _defaultId() =>
      DateTime.now().microsecondsSinceEpoch.toString();

  Future<void> load() async {
    _session = await _store.load();
    // Drop any leftover pending rows from a previous crash mid-timer.
    _session = Session(
      athletes: _session.athletes
          .map(
            (a) => a.copyWith(
              runs: a.runs.where((r) => !r.isPending).toList(),
            ),
          )
          .toList(),
    );
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    await _store.save(_session);
  }

  /// Adds an athlete with the next palette color. Returns false if at cap.
  Future<bool> addAthlete(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    if (_session.athletes.length >= maxAthletes) return false;

    final used = _session.athletes.map((a) => a.colorIndex).toSet();
    var colorIndex = 0;
    for (var i = 0; i < athletePalette.length; i++) {
      if (!used.contains(i)) {
        colorIndex = i;
        break;
      }
    }

    final athlete = Athlete(
      id: _idGenerator(),
      name: trimmed,
      colorIndex: colorIndex,
    );
    _session = _session.copyWith(
      athletes: [..._session.athletes, athlete],
    );
    notifyListeners();
    await _persist();
    return true;
  }

  Future<void> clearSession() async {
    _session = Session.empty();
    _sortedByTime = false;
    notifyListeners();
    await _store.clear();
  }

  Athlete? _athleteById(String athleteId) {
    for (final a in _session.athletes) {
      if (a.id == athleteId) return a;
    }
    return null;
  }

  bool hasPending(String athleteId) {
    final athlete = _athleteById(athleteId);
    if (athlete == null) return false;
    return athlete.runs.any((r) => r.isPending);
  }

  /// Adds at most one pending empty row. Returns false if one already exists.
  Future<bool> addPendingRun(String athleteId) async {
    final athlete = _athleteById(athleteId);
    if (athlete == null) return false;
    if (athlete.runs.any((r) => r.isPending)) return false;

    final nextNumber = athlete.runs
            .where((r) => !r.isPending)
            .map((r) => r.runNumber)
            .fold<int>(0, (m, n) => n > m ? n : m) +
        1;

    final pending = Run(
      id: _idGenerator(),
      runNumber: nextNumber,
      isPending: true,
    );

    _replaceAthlete(
      athlete.copyWith(runs: [...athlete.runs, pending]),
    );
    notifyListeners();
    await _persist();
    return true;
  }

  /// Converts the pending run into a saved run with [durationMs].
  Future<bool> saveRun(String athleteId, int durationMs) async {
    final athlete = _athleteById(athleteId);
    if (athlete == null) return false;
    final pendingIndex = athlete.runs.indexWhere((r) => r.isPending);
    if (pendingIndex < 0) return false;

    final updated = [...athlete.runs];
    final pending = updated[pendingIndex];
    updated[pendingIndex] = pending.copyWith(
      durationMs: durationMs,
      isPending: false,
    );
    _replaceAthlete(athlete.copyWith(runs: updated));
    if (_sortedByTime) {
      _sortAthleteRuns(athleteId);
    }
    notifyListeners();
    await _persist();
    return true;
  }

  /// Removes the pending row; leaves saved runs unchanged.
  Future<bool> discardPending(String athleteId) async {
    final athlete = _athleteById(athleteId);
    if (athlete == null) return false;
    if (!athlete.runs.any((r) => r.isPending)) return false;

    _replaceAthlete(
      athlete.copyWith(
        runs: athlete.runs.where((r) => !r.isPending).toList(),
      ),
    );
    notifyListeners();
    await _persist();
    return true;
  }

  /// Orders saved runs ascending by duration; pending stays at end.
  void sortByTime(String athleteId) {
    _sortedByTime = true;
    _sortAthleteRuns(athleteId);
    notifyListeners();
    _persist();
  }

  void clearSort() {
    _sortedByTime = false;
    notifyListeners();
  }

  void _sortAthleteRuns(String athleteId) {
    final athlete = _athleteById(athleteId);
    if (athlete == null) return;
    final saved = athlete.runs.where((r) => !r.isPending).toList()
      ..sort((a, b) {
        final da = a.durationMs ?? 0;
        final db = b.durationMs ?? 0;
        return da.compareTo(db);
      });
    final pending = athlete.runs.where((r) => r.isPending);
    _replaceAthlete(athlete.copyWith(runs: [...saved, ...pending]));
  }

  void _replaceAthlete(Athlete updated) {
    _session = _session.copyWith(
      athletes: _session.athletes
          .map((a) => a.id == updated.id ? updated : a)
          .toList(),
    );
  }

  /// Builds CSV and triggers browser download.
  String exportCsv({bool download = true}) {
    final csv = _csvExport.buildCsv(_session);
    if (download) {
      downloadCsvFile(csv);
    }
    return csv;
  }

  /// New Session → Save: export then clear.
  Future<void> newSessionSave() async {
    exportCsv(download: true);
    await clearSession();
  }

  /// New Session → Cancel: clear without export.
  Future<void> newSessionCancel() async {
    await clearSession();
  }
}
