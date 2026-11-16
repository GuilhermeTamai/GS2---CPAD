import 'dart:math' show max, sqrt;

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

import '../models/models.dart';

class Fit {
  const Fit(this.slope, this.intercept, this.r2);
  final double slope, intercept, r2;
  double at(num x) => intercept + slope * x;
}

double mean(List<double> v) => v.reduce((a, b) => a + b) / v.length;

double stdDev(List<double> v) {
  final m = mean(v);
  return sqrt(v.map((e) => (e - m) * (e - m)).reduce((a, b) => a + b) / v.length);
}

/// Regressão linear simples (x = 0..n-1). r2 indica o quanto a tendência explica os dados.
Fit linearFit(List<double> y) {
  final n = y.length;
  final xm = (n - 1) / 2;
  final ym = mean(y);
  double sxy = 0, sxx = 0, syy = 0;
  for (var i = 0; i < n; i++) {
    sxy += (i - xm) * (y[i] - ym);
    sxx += (i - xm) * (i - xm);
    syy += (y[i] - ym) * (y[i] - ym);
  }
  final slope = sxy / sxx;
  return Fit(slope, ym - slope * xm, syy == 0 ? 0 : (sxy * sxy) / (sxx * syy));
}

/// Projeta [n] dias à frente com a tendência linear dos dados históricos.
List<Point> project(List<Point> history, int n) {
  final fit = linearFit(history.map((e) => e.value).toList());
  final len = history.length;
  return [
    for (var k = 0; k < n; k++)
      Point(history.last.date.add(Duration(days: k + 1)),
          max(0, fit.at(len + k)).toDouble()),
  ];
}

/// Gera alertas a partir de regras explícitas sobre os indicadores.
/// Cada alerta carrega evidência, confiança e limitações.
class AlertEngine {
  static List<TerritoryAlert> evaluate(List<Indicator> inds, Thresholds t) {
    final out = <TerritoryAlert>[];
    for (final i in inds) {
      TerritoryAlert? a;
      switch (i.id) {
        case 'rain':
          a = _peak(
            i, t.rainMm, 'rain', 'Risco de alagamento', 'mm', 1,
            'Chuva forte prevista. Os dados não medem o estado real da drenagem.',
            'Verificar bueiros e pontos de alagamento e avisar a Defesa Civil.',
            850,
          );
        case 'temp':
          a = _peak(
            i, t.heatC, 'heat', 'Calor extremo', '°C', 6,
            'Temperatura de estação regional; microclimas (ilhas de calor) não são capturados.',
            'Abrir pontos de hidratação e priorizar idosos e crianças.',
            1500,
          );
        case 'water':
          a = _water(i, t);
        case 'energy':
          a = _energy(i, t);
      }
      if (a != null) out.add(a);
    }
    out.sort((a, b) {
      final c = b.level.index.compareTo(a.level.index);
      return c != 0 ? c : b.confidence.compareTo(a.confidence);
    });
    // Saída de depuração (só em modo debug): mostra cada alerta com sua justificativa.
    if (kDebugMode) {
      for (final a in out) {
        debugPrint('[alerta] ${a.id} | risco ${a.level.name} | '
            'confiança ${(a.confidence * 100).round()}% | ${a.evidence}');
      }
    }
    return out;
  }

  static TerritoryAlert? _peak(Indicator i, double limit, String id, String title,
      String unit, double scale, String limits, String rec, int households) {
    var idx = -1;
    var peak = limit;
    for (var k = 0; k < i.forecast.length; k++) {
      if (i.forecast[k].value >= peak) {
        peak = i.forecast[k].value;
        idx = k;
      }
    }
    if (idx < 0) return null;
    final excess = (peak - limit) / limit * scale;
    return TerritoryAlert(
      id: id,
      title: title,
      indicatorId: i.id,
      level: excess >= 0.5 ? Level.high : excess >= 0.2 ? Level.medium : Level.low,
      // Confiança cai com o horizonte da previsão (dia 1 = 90%, -8 p.p. por dia).
      confidence: (0.9 - 0.08 * idx).clamp(0.4, 0.9).toDouble(),
      evidence:
          'Previsão de ${peak.toStringAsFixed(1)} $unit em ${fmtDate(i.forecast[idx].date)} '
          '(limiar configurado: ${limit.toStringAsFixed(0)} $unit). Fonte: ${i.source}.',
      limitations:
          '$limits A incerteza da previsão aumenta com o número de dias à frente.',
      recommendation: rec,
      households: households,
    );
  }

  static TerritoryAlert? _water(Indicator i, Thresholds t) {
    final h = i.history.map((e) => e.value).toList();
    final base = h.sublist(0, h.length - 3);
    final recent = mean(h.sublist(h.length - 3));
    final m = mean(base);
    final sd = stdDev(base);
    final z = sd == 0 ? 0.0 : (recent - m) / sd;
    if (kDebugMode) {
      debugPrint('[z-score água] média recente=${recent.toStringAsFixed(1)} '
          'base=${m.toStringAsFixed(1)} desvio-padrão=${sd.toStringAsFixed(2)} '
          'z=${z.toStringAsFixed(2)} (limiar ${t.waterZ})');
    }
    if (z < t.waterZ) return null;
    return TerritoryAlert(
      id: 'water',
      title: 'Consumo de água anômalo',
      indicatorId: i.id,
      level: z >= 4 ? Level.high : z >= 3 ? Level.medium : Level.low,
      confidence: (0.5 + 0.08 * z).clamp(0.5, 0.9).toDouble(),
      evidence:
          'Média dos últimos 3 dias (${recent.toStringAsFixed(0)} L/hab/dia) está '
          '${z.toStringAsFixed(1)} desvios-padrão acima da linha de base '
          '(${m.toStringAsFixed(0)} L/hab/dia). Fonte: ${i.source}.',
      limitations:
          'Baseia-se em apenas 14 dias de histórico e não distingue vazamento de '
          'evento pontual (feriado, obra, abastecimento de caminhão-pipa).',
      recommendation: 'Inspecionar a rede do setor e confirmar com medição em campo.',
      households: 4200,
    );
  }

  static TerritoryAlert? _energy(Indicator i, Thresholds t) {
    final hist = i.history.map((e) => e.value).toList();
    final growth =
        (mean(i.forecast.map((e) => e.value).toList()) - mean(hist)) / mean(hist) * 100;
    final fit = linearFit(hist);
    if (kDebugMode) {
      debugPrint('[regressão energia] inclinação=${fit.slope.toStringAsFixed(3)} '
          'kWh/hab/dia · R²=${fit.r2.toStringAsFixed(2)} · '
          'alta prevista=${growth.toStringAsFixed(1)}% (limiar ${t.energyPct}%)');
    }
    if (growth < t.energyPct) return null;
    return TerritoryAlert(
      id: 'energy',
      title: 'Alta sustentada no consumo de energia',
      indicatorId: i.id,
      level: growth >= 2 * t.energyPct
          ? Level.high
          : growth >= 1.5 * t.energyPct
              ? Level.medium
              : Level.low,
      // Confiança = R² da regressão (quanto a tendência explica os dados).
      confidence: fit.r2.clamp(0.3, 0.9).toDouble(),
      evidence:
          'A previsão média dos próximos 7 dias é ${growth.toStringAsFixed(1)}% maior '
          'que a média dos últimos 14 dias (limiar: ${t.energyPct.toStringAsFixed(0)}%). '
          'R² da tendência: ${fit.r2.toStringAsFixed(2)}.',
      limitations:
          'Regressão linear simples: ignora sazonalidade, temperatura e feriados.',
      recommendation: 'Avaliar campanha de uso consciente e revisar a demanda dos prédios públicos.',
      households: 4200,
    );
  }
}
