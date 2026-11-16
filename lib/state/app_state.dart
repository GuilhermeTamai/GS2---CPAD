import 'dart:math' show max;

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/alert_engine.dart';
import '../services/data_service.dart';
import '../services/storage.dart';

enum Status { loading, ready, error }

/// Estado global compartilhado entre todas as telas.
/// Estado local (campos de formulário, aba atual) fica nos próprios widgets.
class AppState extends ChangeNotifier {
  AppState(this._storage) : _service = DataService(_storage) {
    consent = _storage.consent;
    thresholds = _storage.thresholds;
    themeMode = _storage.themeMode;
    fontScale = _storage.fontScale;
    occurrences = _storage.occurrences;
    decisions = _storage.decisions;
  }

  final Storage _storage;
  final DataService _service;
  static const totalHouseholds = 4200;

  late bool consent;
  late Thresholds thresholds;
  late ThemeMode themeMode;
  late double fontScale;
  late List<Occurrence> occurrences;
  late Map<String, String> decisions; // id do alerta -> decisão humana

  Status status = Status.loading;
  List<Indicator> indicators = [];
  List<TerritoryAlert> alerts = [];
  bool offline = false, weatherMissing = false;

  Indicator? indicatorById(String id) {
    for (final i in indicators) {
      if (i.id == id) return i;
    }
    return null;
  }

  TerritoryAlert? alertById(String id) {
    for (final a in alerts) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// Indicador de benefício social: domicílios com aviso antecipado (estimativa).
  int get householdsCovered =>
      alerts.isEmpty ? 0 : alerts.map((a) => a.households).reduce(max);

  Future<void> refresh() async {
    status = Status.loading;
    notifyListeners();
    try {
      final s = await _service.load();
      indicators = s.indicators;
      offline = s.offline;
      weatherMissing = s.weatherMissing;
      alerts = AlertEngine.evaluate(indicators, thresholds);
      status = Status.ready;
    } catch (_) {
      status = Status.error;
    }
    notifyListeners();
  }

  Future<void> acceptConsent() async {
    consent = true;
    await _storage.setConsent(true);
    notifyListeners();
  }

  /// Direito de apagar: remove tudo que está salvo no aparelho e revoga o consentimento.
  Future<void> revokeAndClear() async {
    await _storage.clear();
    consent = false;
    thresholds = const Thresholds();
    themeMode = ThemeMode.system;
    fontScale = 1.0;
    occurrences = [];
    decisions = {};
    alerts = AlertEngine.evaluate(indicators, thresholds);
    notifyListeners();
  }

  Future<void> setThresholds(Thresholds t) async {
    thresholds = t;
    await _storage.saveThresholds(t);
    alerts = AlertEngine.evaluate(indicators, t);
    notifyListeners();
  }

  Future<void> addOccurrence(Occurrence o) async {
    occurrences = [o, ...occurrences];
    await _storage.saveOccurrences(occurrences);
    notifyListeners();
  }

  Future<void> removeOccurrence(String id) async {
    occurrences = occurrences.where((o) => o.id != id).toList();
    await _storage.saveOccurrences(occurrences);
    notifyListeners();
  }

  /// Decisão final sempre humana: o app só registra o que o gestor decidiu.
  Future<void> decide(String alertId, String? decision) async {
    decision == null ? decisions.remove(alertId) : decisions[alertId] = decision;
    await _storage.saveDecisions(decisions);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode m) async {
    themeMode = m;
    await _storage.saveThemeMode(m);
    notifyListeners();
  }

  Future<void> setFontScale(double v) async {
    fontScale = v;
    await _storage.saveFontScale(v);
    notifyListeners();
  }
}
