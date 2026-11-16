import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../state/app_state.dart';

class AlertDetailScreen extends StatelessWidget {
  const AlertDetailScreen({super.key, required this.id});
  final String id;

  static const actions = ['Ação encaminhada', 'Descartado após análise'];

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final a = s.alertById(id);
    if (a == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyView(message: 'Este alerta não está mais ativo.'),
      );
    }
    final t = Theme.of(context).textTheme;
    final decision = s.decisions[id];

    Widget section(String title, String body) => Padding(
          padding: const EdgeInsets.only(bottom: Sp.m),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: t.titleSmall),
            const SizedBox(height: 4),
            Text(body),
          ]),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhe do alerta')),
      body: Responsive(
        child: ListView(padding: const EdgeInsets.all(Sp.m), children: [
          Text(a.title, style: t.headlineSmall),
          const SizedBox(height: Sp.s),
          Align(alignment: Alignment.centerLeft, child: LevelChip(a.level)),
          const SizedBox(height: Sp.m),
          Text('Nível de confiança: ${(a.confidence * 100).round()}%', style: t.titleSmall),
          const SizedBox(height: 4),
          Semantics(
            label: 'Confiança de ${(a.confidence * 100).round()} por cento',
            child: LinearProgressIndicator(value: a.confidence, minHeight: 8),
          ),
          const SizedBox(height: Sp.l),
          section('Justificativa (evidência)', a.evidence),
          section('Limitações', a.limitations),
          section('Ação sugerida', a.recommendation),
          const HumanDecisionBanner(),
          const SizedBox(height: Sp.m),
          Text('Decisão do gestor', style: t.titleSmall),
          const SizedBox(height: Sp.s),
          if (decision != null) ...[
            Text('Registrado: $decision'),
            TextButton(
                onPressed: () => s.decide(id, null), child: const Text('Desfazer decisão')),
          ] else
            Wrap(spacing: Sp.s, runSpacing: Sp.s, children: [
              for (final d in actions)
                FilledButton.tonal(onPressed: () => s.decide(id, d), child: Text(d)),
            ]),
          const SizedBox(height: Sp.m),
          OutlinedButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, Routes.indicator, arguments: a.indicatorId),
            icon: const Icon(Icons.show_chart),
            label: const Text('Ver indicador'),
          ),
        ]),
      ),
    );
  }
}
