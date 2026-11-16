import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../state/app_state.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _agree = false; // estado local da tela

  Future<void> _continue() async {
    await context.read<AppState>().acceptConsent();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Responsive(
          child: ListView(padding: const EdgeInsets.all(Sp.l), children: [
            Icon(Icons.location_city, size: 56, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: Sp.m),
            Text('Território Preditivo', style: t.headlineMedium),
            const SizedBox(height: Sp.s),
            Text('Antecipe problemas do seu território: chuva, calor, água e energia.',
                style: t.bodyLarge),
            const SizedBox(height: Sp.l),
            Text('Sua privacidade', style: t.titleMedium),
            const SizedBox(height: Sp.s),
            const Text(
              '• Não pedimos nome, telefone, e-mail nem localização exata.\n'
              '• As ocorrências que você registra ficam somente neste aparelho.\n'
              '• Os textos são verificados para impedir o envio de CPF, e-mail ou telefone.\n'
              '• Você pode apagar tudo e revogar este consentimento em Ajustes.',
            ),
            const SizedBox(height: Sp.l),
            const HumanDecisionBanner(),
            const SizedBox(height: Sp.m),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _agree,
              onChanged: (v) => setState(() => _agree = v ?? false),
              title: const Text('Li e concordo com o uso e o armazenamento local dos meus dados.'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: Sp.m),
            FilledButton(
              onPressed: _agree ? _continue : null,
              child: const Text('Continuar'),
            ),
          ]),
        ),
      ),
    );
  }
}
