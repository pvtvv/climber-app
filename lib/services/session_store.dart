import 'dart:convert';

import 'package:climber_app/models/session.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionStore {
  SessionStore({this._prefs});

  static const storageKey = 'climber_session_v1';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<Session> load() async {
    final prefs = await _ensurePrefs();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return Session.empty();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return Session.empty();
      }
      return Session.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return Session.empty();
    }
  }

  Future<void> save(Session session) async {
    final prefs = await _ensurePrefs();
    await prefs.setString(storageKey, jsonEncode(session.toJson()));
  }

  Future<void> clear() async {
    final prefs = await _ensurePrefs();
    await prefs.remove(storageKey);
  }
}
