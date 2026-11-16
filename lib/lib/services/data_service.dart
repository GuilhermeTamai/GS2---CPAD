import 'dart:convert';
import 'dart:math' show Random;

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/models.dart';
import 'alert_engine.dart';
import 'storage.dart';

class Snapshot {
  const Snapshot(this.indicators, {this.offline = false, this.weatherMissing = false});
  final List<Indicator> indicators;
  final bool offline, weatherMissing;
}

class DataService {
  DataService(this._storage);
  final Storage _storage;

  // Open-Meteo: API pública, gratuita e sem chave. Coordenadas do centro de São Paulo.
  static const _url = 'https://api.open-meteo.com/v1/forecast'
      '?latitude=-23.55&longitude=-46.63'
      '&daily=precipitation_sum,temperature_2m_max'
      '&past_days=14&forecast_days=7&timezone=America%2FSao_Paulo';

  Future<Snapshot> load() async {
    // Água e energia: "API municipal" simulada (dados sintéticos e determinísticos).
    await Future.delayed(const Duration(milliseconds: 600));
    final list = <Indicator>[
      _synthetic('water', 'Consumo de água', 'L/hab/dia', Icons.water_drop,
          seed: 1, base: 150, slope: 0.3, noise: 5, spike: 22),
      _synthetic('energy', 'Consumo de energia', 'kWh/hab/dia', Icons.bolt,
          seed: 2, base: 4.0, slope: 0.06, noise: 0.15, spike: 0),
    ];

    // Clima: API real, com fallback para o último cache salvo.
    final w = await _weather();
    if (w == null) {
      return Snapshot(list, weatherMissing: true);
    }
    list.addAll(_parse(w.$1));
    // Saída de depuração (só em modo debug): prova que os dados da API chegaram.
    if (kDebugMode) {
      for (final i in list) {
        debugPrint('[dados] ${i.name}: ${i.history.length} dias de histórico, '
            '${i.forecast.length} de previsão, último valor '
            '${i.current.toStringAsFixed(1)} ${i.unit} '
            '(fonte: ${i.source}${w.$2 ? ', CACHE' : ''})');
      }
    }
    return Snapshot(list, offline: w.$2);
  }

  Future<(Map<String, dynamic>, bool)?> _weather() async {
    try {
      final r = await http.get(Uri.parse(_url)).timeout(const Duration(seconds: 8));
      if (r.statusCode == 200) {
        await _storage.saveWeather(r.body);
        return (jsonDecode(r.body) as Map<String, dynamic>, false);
      }
    } catch (_) {
      // sem rede: cai para o cache
    }
    final cached = _storage.loadWeather();
    return cached == null ? null : (jsonDecode(cached) as Map<String, dynamic>, true);
  }

  List<Indicator> _parse(Map<String, dynamic> j) {
    final d = j['daily'] as Map<String, dynamic>;
    final days = (d['time'] as List).map((e) => DateTime.parse(e as String)).toList();

    Indicator build(String id, String name, String unit, IconData icon, String key) {
      final v = (d[key] as List).map((e) => ((e ?? 0) as num).toDouble()).toList();
      final pts = [for (var i = 0; i < days.length; i++) Point(days[i], v[i])];
      return Indicator(
        id: id,
        name: name,
        unit: unit,
        source: 'Open-Meteo',
        icon: icon,
        history: pts.sublist(0, 14),
        forecast: pts.sublist(14),
      );
    }

    return [
      build('rain', 'Chuva', 'mm', Icons.umbrella, 'precipitation_sum'),
      build('temp', 'Temperatura máxima', '°C', Icons.thermostat, 'temperature_2m_max'),
    ];
  }

  Indicator _synthetic(String id, String name, String unit, IconData icon,
      {required int seed,
      required double base,
      required double slope,
      required double noise,
      required double spike}) {
    final rnd = Random(seed);
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day)
        .subtract(const Duration(days: 13));
    final hist = [
      for (var i = 0; i < 14; i++)
        Point(
          start.add(Duration(days: i)),
          base + slope * i + (rnd.nextDouble() * 2 - 1) * noise + (i >= 11 ? spike : 0),
        ),
    ];
    return Indicator(
      id: id,
      name: name,
      unit: unit,
      source: 'Dados sintéticos (API municipal simulada)',
      icon: icon,
      history: hist,
      forecast: project(hist, 7),
    );
  }
}
