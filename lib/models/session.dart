import 'athlete.dart';

class Session {
  const Session({this.athletes = const []});

  final List<Athlete> athletes;

  bool get isEmpty => athletes.isEmpty;

  Session copyWith({List<Athlete>? athletes}) {
    return Session(athletes: athletes ?? this.athletes);
  }

  Map<String, dynamic> toJson() => {
        'athletes': athletes.map((a) => a.toJson()).toList(),
      };

  factory Session.fromJson(Map<String, dynamic> json) {
    final raw = json['athletes'] as List<dynamic>? ?? const [];
    return Session(
      athletes: raw
          .map((e) => Athlete.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  factory Session.empty() => const Session();

  @override
  bool operator ==(Object other) {
    return other is Session && _listEquals(other.athletes, athletes);
  }

  @override
  int get hashCode => Object.hashAll(athletes);
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
