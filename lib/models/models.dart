import 'package:flutter/material.dart';

enum Level { low, medium, high }

String fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

String fmtInt(int n) =>
    n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');

class Point {
  const Point(this.date, this.value);
  final DateTime date;
  final double value;
}

class Indicator {
  const Indicator({
    required this.id,
    required this.name,
    required this.unit,
    required this.source,
    required this.icon,
    required this.history,
    required this.forecast,
  });

  final String id, name, unit, source;
  final IconData icon;
  final List<Point> history, forecast;

  double get current => history.last.value;

  double avgLast(int n) {
    final p = history.sublist(history.length - n);
    return p.map((e) => e.value).reduce((a, b) => a + b) / n;
  }

  /// Variação % da média dos últimos 7 dias contra os 7 dias anteriores.
  double get trendPct {
    if (history.length < 14) return 0;
    final prev = history
            .sublist(history.length - 14, history.length - 7)
            .map((e) => e.value)
            .reduce((a, b) => a + b) /
        7;
    return prev == 0 ? 0 : (avgLast(7) - prev) / prev * 100;
  }

  String get trendLabel =>
      '${trendPct >= 0 ? '▲' : '▼'} ${trendPct.abs().toStringAsFixed(1)}%';
}

class TerritoryAlert {
  const TerritoryAlert({
    required this.id,
    required this.title,
    required this.indicatorId,
    required this.level,
    required this.confidence,
    required this.evidence,
    required this.limitations,
    required this.recommendation,
    required this.households,
  });

  final String id, title, indicatorId, evidence, limitations, recommendation;
  final Level level;
  final double confidence; // 0..1
  final int households; // domicílios potencialmente afetados (estimativa)
}

class Thresholds {
  const Thresholds({
    this.rainMm = 30,
    this.heatC = 35,
    this.waterZ = 2.0,
    this.energyPct = 10,
  });

  final double rainMm, heatC, waterZ, energyPct;

  Map<String, dynamic> toJson() =>
      {'rain': rainMm, 'heat': heatC, 'z': waterZ, 'energy': energyPct};

  factory Thresholds.fromJson(Map<String, dynamic> j) => Thresholds(
        rainMm: (j['rain'] as num).toDouble(),
        heatC: (j['heat'] as num).toDouble(),
        waterZ: (j['z'] as num).toDouble(),
        energyPct: (j['energy'] as num).toDouble(),
      );
}

/// Ocorrência cidadã. Propositalmente SEM nome, contato ou localização exata.
class Occurrence {
  const Occurrence({
    required this.id,
    required this.category,
    required this.neighborhood,
    required this.description,
    required this.severity,
    required this.createdAt,
  });

  final String id, category, neighborhood, description, severity;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'cat': category,
        'nb': neighborhood,
        'desc': description,
        'sev': severity,
        'at': createdAt.toIso8601String(),
      };

  factory Occurrence.fromJson(Map<String, dynamic> j) => Occurrence(
        id: j['id'],
        category: j['cat'],
        neighborhood: j['nb'],
        description: j['desc'],
        severity: j['sev'],
        createdAt: DateTime.parse(j['at']),
      );
}
