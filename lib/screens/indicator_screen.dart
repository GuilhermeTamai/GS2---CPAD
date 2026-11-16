import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/models.dart';
import '../state/app_state.dart';

/// Dashboard de um indicador: métricas, gráfico com histórico/previsão e alertas relacionados.
class IndicatorScreen extends StatelessWidget {
  const IndicatorScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final i = s.indicatorById(id);
    if (i == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyView(message: 'Indicador não encontrado.'),
      );
    }
    final t = Theme.of(context).textTheme;
    final related = s.alerts.where((a) => a.indicatorId == id).toList();
    final maxF = i.forecast.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    return Scaffold(
      appBar: AppBar(title: Text(i.name)),
      body: Responsive(
        child: ListView(padding: const EdgeInsets.all(Sp.m), children: [
          IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              MetricTile('Último dia', '${i.current.toStringAsFixed(1)} ${i.unit}'),
              const SizedBox(width: Sp.s),
              MetricTile('Média 7 dias', '${i.avgLast(7).toStringAsFixed(1)} ${i.unit}'),
              const SizedBox(width: Sp.s),
              MetricTile('Tendência', i.trendLabel),
            ]),
          ),
          const SizedBox(height: Sp.m),
          AppCard(child: TrendChart(i)),
          const SizedBox(height: Sp.s),
          Text('Fonte: ${i.source}', style: t.bodySmall),
          const SizedBox(height: Sp.l),
          Text('Previsão (máx. ${maxF.toStringAsFixed(1)} ${i.unit})', style: t.titleMedium),
          const SizedBox(height: Sp.s),
          for (final p in i.forecast)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(fmtDate(p.date)),
              trailing: Text('${p.value.toStringAsFixed(1)} ${i.unit}'),
            ),
          const SizedBox(height: Sp.m),
          Text('Alertas deste indicador', style: t.titleMedium),
          const SizedBox(height: Sp.s),
          if (related.isEmpty)
            const Text('Nenhum alerta ativo: valores dentro dos limiares.'),
          for (final a in related)
            Padding(
              padding: const EdgeInsets.only(bottom: Sp.s),
              child: AppCard(
                onTap: () => Navigator.pushNamed(context, Routes.alert, arguments: a.id),
                child: Row(children: [
                  Expanded(child: Text(a.title, style: t.titleSmall)),
                  LevelChip(a.level),
                ]),
              ),
            ),
        ]),
      ),
    );
  }
}
