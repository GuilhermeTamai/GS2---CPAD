import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:territory_insights/core/validators.dart';
import 'package:territory_insights/models/models.dart';
import 'package:territory_insights/services/alert_engine.dart';

Indicator ind(String id, List<double> h, List<double> f) {
  final d = DateTime(2026, 11, 1);
  return Indicator(
    id: id,
    name: id,
    unit: 'u',
    source: 'teste',
    icon: Icons.circle,
    history: [for (var i = 0; i < h.length; i++) Point(d.add(Duration(days: i)), h[i])],
    forecast: [for (var i = 0; i < f.length; i++) Point(d.add(Duration(days: 14 + i)), f[i])],
  );
}

void main() {
  const t = Thresholds();
  final flat = List.filled(14, 0.0);

  test('chuva acima do limiar gera alerta com evidência e confiança', () {
    final alerts = AlertEngine.evaluate([ind('rain', flat, [0, 55, 0, 0, 0, 0, 0])], t);
    expect(alerts.single.id, 'rain');
    expect(alerts.single.confidence, closeTo(0.82, 0.001)); // dia 2 do horizonte
    expect(alerts.single.evidence, contains('55.0'));
  });

  test('chuva abaixo do limiar não gera alerta', () {
    expect(AlertEngine.evaluate([ind('rain', flat, List.filled(7, 5.0))], t), isEmpty);
  });

  test('anomalia de consumo de água gera alerta', () {
    final h = [for (var i = 0; i < 14; i++) (i >= 11 ? 190.0 : 150.0 + (i % 2))];
    final alerts = AlertEngine.evaluate([ind('water', h, List.filled(7, 190.0))], t);
    expect(alerts.single.id, 'water');
  });

  test('validadores', () {
    expect(Validators.description('curta'), isNotNull);
    expect(Validators.description('Vazamento na rua principal'), isNull);
    expect(Validators.description('Ligue 11 98765-4321 para falar'), isNotNull);
    expect(Validators.number('abc', min: 1, max: 5), isNotNull);
    expect(Validators.number('3,5', min: 1, max: 5), isNull);
  });
}
