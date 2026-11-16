import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/models.dart';
import 'theme.dart';

/// Limita a largura em telas grandes (tablet/web) para manter a leitura confortável.
class Responsive extends StatelessWidget {
  const Responsive({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: child,
        ),
      );
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.onTap, this.semanticLabel});
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return Semantics(
      container: true,
      button: onTap != null,
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      onTap: onTap,
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(Sp.m), child: child),
        ),
      ),
    );
  }
}

class LevelChip extends StatelessWidget {
  const LevelChip(this.level, {super.key});
  final Level level;

  static const _label = {Level.low: 'Baixo', Level.medium: 'Médio', Level.high: 'Alto'};

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.levelColor(level, Theme.of(context).brightness);
    return Semantics(
      label: 'Nível de risco ${_label[level]}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: c, width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.warning_amber_rounded, size: 16, color: c),
          const SizedBox(width: 4),
          Text('Risco ${_label[level]}',
              style: TextStyle(color: c, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(Sp.m),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(icon, color: cs.onSecondaryContainer),
        const SizedBox(width: Sp.s + 4),
        Expanded(
          child: Text(text, style: TextStyle(color: cs.onSecondaryContainer)),
        ),
      ]),
    );
  }
}

/// Aviso obrigatório: o app apoia, mas não substitui a decisão humana.
class HumanDecisionBanner extends StatelessWidget {
  const HumanDecisionBanner({super.key});

  @override
  Widget build(BuildContext context) => const InfoBanner(
        icon: Icons.person_search,
        text: 'Os alertas apoiam, mas não substituem, a decisão humana. '
            'Toda ação deve ser avaliada e decidida por um gestor responsável.',
      );
}

class MetricTile extends StatelessWidget {
  const MetricTile(this.label, this.value, {super.key});
  final String label, value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: AppCard(
          semanticLabel: '$label: $value',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ]),
        ),
      );
}

class StatCard extends StatelessWidget {
  const StatCard(this.ind, {super.key, required this.onTap});
  final Indicator ind;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final value = '${ind.current.toStringAsFixed(1)} ${ind.unit}';
    return AppCard(
      onTap: onTap,
      semanticLabel:
          '${ind.name}: $value, tendência ${ind.trendPct >= 0 ? 'de alta' : 'de queda'} de '
          '${ind.trendPct.abs().toStringAsFixed(1)} por cento. Toque para ver detalhes.',
      child: Row(children: [
        Icon(ind.icon, size: 32, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: Sp.m),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ind.name, style: t.titleSmall),
            Text(value, style: t.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ]),
        ),
        Text(ind.trendLabel, style: t.labelLarge),
        const Icon(Icons.chevron_right),
      ]),
    );
  }
}

class TrendChart extends StatelessWidget {
  const TrendChart(this.ind, {super.key});
  final Indicator ind;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final all = [...ind.history, ...ind.forecast];
    final h = [
      for (var i = 0; i < ind.history.length; i++)
        FlSpot(i.toDouble(), ind.history[i].value),
    ];
    final f = [
      h.last,
      for (var i = 0; i < ind.forecast.length; i++)
        FlSpot((ind.history.length + i).toDouble(), ind.forecast[i].value),
    ];
    LineChartBarData line(List<FlSpot> s, Color c, {bool dashed = false}) =>
        LineChartBarData(
          spots: s,
          isCurved: true,
          color: c,
          barWidth: 3,
          dotData: const FlDotData(show: false),
          dashArray: dashed ? [6, 4] : null,
        );

    return Column(children: [
      Semantics(
        label: 'Gráfico de linha de ${ind.name}. Valor atual '
            '${ind.current.toStringAsFixed(1)} ${ind.unit}, tendência ${ind.trendLabel}.',
        child: ExcludeSemantics(
          child: SizedBox(
            height: 200,
            child: LineChart(LineChartData(
              lineBarsData: [line(h, cs.primary), line(f, cs.tertiary, dashed: true)],
              gridData: const FlGridData(drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    minIncluded: false,
                    maxIncluded: false,
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 5,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= all.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(fmtDate(all[i].date),
                            style: const TextStyle(fontSize: 11)),
                      );
                    },
                  ),
                ),
              ),
            )),
          ),
        ),
      ),
      const SizedBox(height: Sp.s),
      Text('Linha contínua: histórico · Linha tracejada: previsão',
          style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: Semantics(
          label: 'Carregando dados do território',
          child: const CircularProgressIndicator(),
        ),
      );
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(Sp.l),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: Sp.m),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: Sp.m),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ]),
        ),
      );
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.message, this.icon = Icons.inbox_outlined});
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(Sp.l),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 48),
            const SizedBox(height: Sp.m),
            Text(message, textAlign: TextAlign.center),
          ]),
        ),
      );
}
