import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/models.dart';
import '../state/app_state.dart';

class OccurrencesScreen extends StatelessWidget {
  const OccurrencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: const Text('Ocorrências cidadãs')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, Routes.occurrenceForm),
        icon: const Icon(Icons.add),
        label: const Text('Registrar'),
      ),
      body: s.occurrences.isEmpty
          ? const EmptyView(
              message: 'Nenhuma ocorrência registrada.\nToque em "Registrar" para relatar um problema no território.',
              icon: Icons.edit_note)
          : Responsive(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(Sp.m, Sp.m, Sp.m, 88),
                itemCount: s.occurrences.length,
                separatorBuilder: (_, __) => const SizedBox(height: Sp.s),
                itemBuilder: (_, k) {
                  final o = s.occurrences[k];
                  return AppCard(
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${o.category} · ${o.severity}', style: t.titleSmall),
                          Text('${o.neighborhood} · ${fmtDate(o.createdAt)}', style: t.bodySmall),
                          const SizedBox(height: 4),
                          Text(o.description),
                        ]),
                      ),
                      IconButton(
                        tooltip: 'Remover ocorrência',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => s.removeOccurrence(o.id),
                      ),
                    ]),
                  );
                },
              ),
            ),
    );
  }
}
