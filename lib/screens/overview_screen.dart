import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/models.dart';
import '../state/app_state.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: const Text('Território Preditivo'), actions: [
        IconButton(
            tooltip: 'Atualizar dados',
            icon: const Icon(Icons.refresh),
            onPressed: s.refresh),
      ]),
      body: switch (s.status) {
        Status.loading => const LoadingView(),
        Status.error => ErrorView(
            message: 'Não foi possível carregar os dados do território.',
            onRetry: s.refresh),
        Status.ready => s.indicators.isEmpty
            ? const EmptyView(message: 'Nenhum indicador disponível.')
            : _Body(s),
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body(this.s);
  final AppState s;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final pct = (s.householdsCovered / AppState.totalHouseholds * 100).round();
    return RefreshIndicator(
      onRefresh: s.refresh,
      child: Responsive(
        child: ListView(
          padding: const EdgeInsets.all(Sp.m),
          children: [
            if (s.offline)
              const Padding(
                padding: EdgeInsets.only(bottom: Sp.s),
                child: InfoBanner(
                    icon: Icons.cloud_off,
                    text: 'Sem conexão: exibindo os últimos dados de clima salvos.'),
              ),
            if (s.weatherMissing)
              const Padding(
                padding: EdgeInsets.only(bottom: Sp.s),
                child: InfoBanner(
                    icon: Icons.cloud_off,
                    text: 'Clima indisponível: sem conexão e sem dados salvos.'),
              ),
            const HumanDecisionBanner(),
            const SizedBox(height: Sp.m),
            AppCard(
              semanticLabel:
                  'Benefício social estimado: ${fmtInt(s.householdsCovered)} de '
                  '${fmtInt(AppState.totalHouseholds)} domicílios com aviso antecipado. '
                  '${s.occurrences.length} ocorrências cidadãs registradas.',
              child: Row(children: [
                Icon(Icons.favorite, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: Sp.m),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Benefício social (estimativa)', style: t.titleSmall),
                    Text(
                        '${fmtInt(s.householdsCovered)} de ${fmtInt(AppState.totalHouseholds)} '
                        'domicílios com aviso antecipado ($pct%)'),
                    Text('${s.occurrences.length} ocorrências cidadãs registradas',
                        style: t.bodySmall),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: Sp.l),
            Text('Indicadores', style: t.titleMedium),
            const SizedBox(height: Sp.s),
            for (final i in s.indicators) ...[
              StatCard(i,
                  onTap: () => Navigator.pushNamed(context, Routes.indicator, arguments: i.id)),
              const SizedBox(height: Sp.s),
            ],
          ],
        ),
      ),
    );
  }
}
