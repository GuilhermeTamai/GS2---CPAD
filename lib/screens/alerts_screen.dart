import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../state/app_state.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: const Text('Alertas preditivos')),
      body: switch (s.status) {
        Status.loading => const LoadingView(),
        Status.error => ErrorView(message: 'Falha ao carregar alertas.', onRetry: s.refresh),
        Status.ready => Responsive(
            child: ListView(padding: const EdgeInsets.all(Sp.m), children: [
              const HumanDecisionBanner(),
              const SizedBox(height: Sp.m),
              if (s.alerts.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: Sp.l),
                  child: EmptyView(
                      message: 'Nenhum alerta ativo. Os indicadores estão dentro dos limiares.',
                      icon: Icons.check_circle_outline),
                ),
              for (final a in s.alerts)
                Padding(
                  padding: const EdgeInsets.only(bottom: Sp.s),
                  child: AppCard(
                    onTap: () => Navigator.pushNamed(context, Routes.alert, arguments: a.id),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(a.title, style: t.titleSmall)),
                        LevelChip(a.level),
                      ]),
                      const SizedBox(height: Sp.s),
                      Text('Confiança: ${(a.confidence * 100).round()}%'),
                      if (s.decisions[a.id] != null)
                        Text('Decisão: ${s.decisions[a.id]}', style: t.labelLarge),
                    ]),
                  ),
                ),
            ]),
          ),
      },
    );
  }
}
