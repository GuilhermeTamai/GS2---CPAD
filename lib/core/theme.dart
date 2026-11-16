import 'package:flutter/material.dart';
import '../models/models.dart';

/// Espaçamentos padronizados.
class Sp {
  static const double s = 8, m = 16, l = 24;
}

class AppTheme {
  static const _seed = Color(0xFF0F766E);

  static ThemeData _build(Brightness b) => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: b),
      );

  static final light = _build(Brightness.light);
  static final dark = _build(Brightness.dark);

  /// Decoração padrão dos campos de formulário, reutilizada em todas as telas.
  static InputDecoration input(String label,
          {String? helper, bool alignLabelWithHint = false}) =>
      InputDecoration(
        labelText: label,
        helperText: helper,
        alignLabelWithHint: alignLabelWithHint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  /// Cores de risco com contraste adequado em ambos os temas.
  /// O nível também é sempre comunicado por texto, nunca só por cor.
  static Color levelColor(Level l, Brightness b) {
    final dark = b == Brightness.dark;
    switch (l) {
      case Level.low:
        return dark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
      case Level.medium:
        return dark ? const Color(0xFFFFB74D) : const Color(0xFF9A5B00);
      case Level.high:
        return dark ? const Color(0xFFEF9A9A) : const Color(0xFFC62828);
    }
  }
}
