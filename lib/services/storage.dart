import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// Camada de persistência local (funciona sem internet).
class Storage {
  Storage(this._p);
  final SharedPreferences _p;

  bool get consent => _p.getBool('consent') ?? false;
  Future<void> setConsent(bool v) => _p.setBool('consent', v);

  Thresholds get thresholds {
    final s = _p.getString('thr');
    return s == null ? const Thresholds() : Thresholds.fromJson(jsonDecode(s));
  }

  Future<void> saveThresholds(Thresholds t) =>
      _p.setString('thr', jsonEncode(t.toJson()));

  ThemeMode get themeMode => ThemeMode.values[_p.getInt('theme') ?? 0];
  Future<void> saveThemeMode(ThemeMode m) => _p.setInt('theme', m.index);

  double get fontScale => _p.getDouble('font') ?? 1.0;
  Future<void> saveFontScale(double v) => _p.setDouble('font', v);

  List<Occurrence> get occurrences => (_p.getStringList('occ') ?? [])
      .map((e) => Occurrence.fromJson(jsonDecode(e)))
      .toList();

  Future<void> saveOccurrences(List<Occurrence> l) =>
      _p.setStringList('occ', l.map((e) => jsonEncode(e.toJson())).toList());

  Map<String, String> get decisions {
    final s = _p.getString('dec');
    return s == null ? {} : Map<String, String>.from(jsonDecode(s));
  }

  Future<void> saveDecisions(Map<String, String> m) =>
      _p.setString('dec', jsonEncode(m));

  String? loadWeather() => _p.getString('weather');
  Future<void> saveWeather(String raw) => _p.setString('weather', raw);

  Future<void> clear() => _p.clear();
}
