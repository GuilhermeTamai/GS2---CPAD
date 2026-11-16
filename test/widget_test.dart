import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:territory_insights/core/theme.dart';
import 'package:territory_insights/core/widgets.dart';
import 'package:territory_insights/models/models.dart';

Widget host(Widget child) =>
    MaterialApp(theme: AppTheme.light, home: Scaffold(body: child));

void main() {
  testWidgets('aviso de que a decisão final é humana está visível', (tester) async {
    await tester.pumpWidget(host(const HumanDecisionBanner()));
    expect(find.textContaining('não substituem'), findsOneWidget);
  });

  testWidgets('nível de risco é comunicado por texto, não só por cor', (tester) async {
    await tester.pumpWidget(host(const LevelChip(Level.high)));
    expect(find.text('Risco Alto'), findsOneWidget);
  });

  testWidgets('tela vazia exibe a mensagem informada', (tester) async {
    await tester.pumpWidget(host(const EmptyView(message: 'Nada por aqui')));
    expect(find.text('Nada por aqui'), findsOneWidget);
  });
}
