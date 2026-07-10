class Run {
  const Run({
    required this.id,
    required this.runNumber,
    this.durationMs,
    this.isPending = false,
  });

  final String id;
  final int runNumber;
  /// Elapsed time in milliseconds. Null while pending / unsaved.
  final int? durationMs;
  final bool isPending;

  Run copyWith({
    String? id,
    int? runNumber,
    int? durationMs,
    bool? isPending,
    bool clearDuration = false,
  }) {
    return Run(
      id: id ?? this.id,
      runNumber: runNumber ?? this.runNumber,
      durationMs: clearDuration ? null : (durationMs ?? this.durationMs),
      isPending: isPending ?? this.isPending,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'runNumber': runNumber,
        'durationMs': durationMs,
        'isPending': isPending,
      };

  factory Run.fromJson(Map<String, dynamic> json) {
    return Run(
      id: json['id'] as String,
      runNumber: json['runNumber'] as int,
      durationMs: json['durationMs'] as int?,
      isPending: json['isPending'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Run &&
        other.id == id &&
        other.runNumber == runNumber &&
        other.durationMs == durationMs &&
        other.isPending == isPending;
  }

  @override
  int get hashCode => Object.hash(id, runNumber, durationMs, isPending);
}
