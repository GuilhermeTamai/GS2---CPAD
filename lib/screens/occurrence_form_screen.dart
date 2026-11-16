import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/validators.dart';
import '../core/widgets.dart';
import '../models/models.dart';
import '../state/app_state.dart';

class OccurrenceFormScreen extends StatefulWidget {
  const OccurrenceFormScreen({super.key});

  @override
  State<OccurrenceFormScreen> createState() => _OccurrenceFormScreenState();
}

class _OccurrenceFormScreenState extends State<OccurrenceFormScreen> {
  static const _categories = [
    'Vazamento de água',
    'Alagamento',
    'Queda de energia',
    'Lixo acumulado',
    'Calor extremo',
  ];
  static const _severities = ['Baixa', 'Média', 'Alta'];

  final _key = GlobalKey<FormState>();
  final _neighborhood = TextEditingController();
  final _description = TextEditingController();
  String? _category;
  String _severity = 'Média';

  @override
  void dispose() {
    _neighborhood.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_key.currentState!.validate()) return;
    final state = context.read<AppState>();
    await state.addOccurrence(Occurrence(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      category: _category!,
      neighborhood: _neighborhood.text.trim(),
      description: _description.text.trim(),
      severity: _severity,
      createdAt: DateTime.now(),
    ));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Ocorrência registrada (anônima).')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova ocorrência')),
      body: Responsive(
        child: Form(
          key: _key,
          child: ListView(padding: const EdgeInsets.all(Sp.m), children: [
            const InfoBanner(
              icon: Icons.privacy_tip,
              text: 'O registro é anônimo e fica só neste aparelho. Não informe nome, telefone, e-mail ou CPF.',
            ),
            const SizedBox(height: Sp.m),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: AppTheme.input('Categoria'),
              items: [for (final c in _categories) DropdownMenuItem(value: c, child: Text(c))],
              onChanged: (v) => setState(() => _category = v),
              validator: (v) => v == null ? 'Selecione uma categoria' : null,
            ),
            const SizedBox(height: Sp.m),
            TextFormField(
              controller: _neighborhood,
              decoration: AppTheme.input('Bairro ou região'),
              validator: (v) => Validators.required(v, min: 3, field: 'O bairro'),
            ),
            const SizedBox(height: Sp.m),
            DropdownButtonFormField<String>(
              initialValue: _severity,
              decoration: AppTheme.input('Gravidade'),
              items: [for (final c in _severities) DropdownMenuItem(value: c, child: Text(c))],
              onChanged: (v) => setState(() => _severity = v ?? _severity),
            ),
            const SizedBox(height: Sp.m),
            TextFormField(
              controller: _description,
              maxLines: 4,
              maxLength: 280,
              decoration: AppTheme.input('Descrição', alignLabelWithHint: true),
              validator: Validators.description,
            ),
            const SizedBox(height: Sp.m),
            FilledButton(onPressed: _submit, child: const Text('Registrar ocorrência')),
          ]),
        ),
      ),
    );
  }
}
