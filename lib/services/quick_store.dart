import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:climber_app/models/quick_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuickStore {
  QuickStore({SharedPreferences? prefs}) {
    if (prefs != null) {
      _prefsFuture = Future.value(prefs);
    }
  }

  static const storageKey = 'climber_quick_v1';

  // Single-flight future: all concurrent callers await the same instance.
  Future<SharedPreferences>? _prefsFuture;

  Future<SharedPreferences> _ensurePrefs() {
    return _prefsFuture ??= SharedPreferences.getInstance();
  }

  Future<QuickResult?> load() async {
    final prefs = await _ensurePrefs();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      return QuickResult.fromJson(Map<String, dynamic>.from(decoded));
    } catch (e) {
      debugPrint('QuickStore.load parse error: $e');
      return null;
    }
  }

  Future<void> save(QuickResult result) async {
    final prefs = await _ensurePrefs();
    await prefs.setString(storageKey, jsonEncode(result.toJson()));
  }

  Future<void> clear() async {
    final prefs = await _ensurePrefs();
    await prefs.remove(storageKey);
  }
}
