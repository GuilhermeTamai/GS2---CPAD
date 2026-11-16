import 'package:flutter/material.dart';
import '../screens/alert_detail_screen.dart';
import '../screens/consent_screen.dart';
import '../screens/home_shell.dart';
import '../screens/indicator_screen.dart';
import '../screens/occurrence_form_screen.dart';

/// Rotas nomeadas. Parâmetros viajam em `arguments` (ex.: id do indicador ou do alerta).
class Routes {
  static const consent = '/consent';
  static const home = '/home';
  static const indicator = '/indicator';
  static const alert = '/alert';
  static const occurrenceForm = '/occurrence-form';

  static Route<dynamic> generate(RouteSettings s) {
    final Widget page = switch (s.name) {
      consent => const ConsentScreen(),
      indicator => IndicatorScreen(id: s.arguments as String),
      alert => AlertDetailScreen(id: s.arguments as String),
      occurrenceForm => const OccurrenceFormScreen(),
      _ => const HomeShell(),
    };
    return MaterialPageRoute(builder: (_) => page, settings: s);
  }
}
