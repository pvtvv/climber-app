import 'run.dart';

class Athlete {
  const Athlete({
    required this.id,
    required this.name,
    required this.colorIndex,
    this.runs = const [],
  });

  final String id;
  final String name;
  /// Index into the fixed 10-color palette.
  final int colorIndex;
  final List<Run> runs;

  Athlete copyWith({
    String? id,
    String? name,
    int? colorIndex,
    List<Run>? runs,
  }) {
    return Athlete(
      id: id ?? this.id,
      name: name ?? this.name,
      colorIndex: colorIndex ?? this.colorIndex,
      runs: runs ?? this.runs,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorIndex': colorIndex,
        'runs': runs.map((r) => r.toJson()).toList(),
      };

  factory Athlete.fromJson(Map<String, dynamic> json) {
    final rawRuns = json['runs'] as List<dynamic>? ?? const [];
    return Athlete(
      id: json['id'] as String,
      name: json['name'] as String,
      colorIndex: json['colorIndex'] as int,
      runs: rawRuns
          .map((e) => Run.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Athlete &&
        other.id == id &&
        other.name == name &&
        other.colorIndex == colorIndex &&
        _listEquals(other.runs, runs);
  }

  @override
  int get hashCode => Object.hash(id, name, colorIndex, Object.hashAll(runs));
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
