/// Cached Quick-mode timing result persisted under [QuickStore.storageKey].
class QuickResult {
  const QuickResult({
    required this.durationMs,
    required this.completedAt,
  });

  final int durationMs;
  final DateTime completedAt;

  Map<String, dynamic> toJson() => {
        'durationMs': durationMs,
        'completedAt': completedAt.toIso8601String(),
      };

  factory QuickResult.fromJson(Map<String, dynamic> json) {
    return QuickResult(
      durationMs: json['durationMs'] as int,
      completedAt: DateTime.parse(json['completedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is QuickResult &&
        other.durationMs == durationMs &&
        other.completedAt == completedAt;
  }

  @override
  int get hashCode => Object.hash(durationMs, completedAt);
}
