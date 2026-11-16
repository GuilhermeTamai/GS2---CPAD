import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../core/validators.dart';
import '../core/widgets.dart';
import '../models/models.dart';
import '../state/app_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _rain, _heat, _z, _energy;

  @override
  void initState() {
    super.initState();
    final t = context.read<AppState>().thresholds;
    _rain = TextEditingController(text: '${t.rainMm}');
    _heat = TextEditingController(text: '${t.heatC}');
    _z = TextEditingController(text: '${t.waterZ}');
    _energy = TextEditingController(text: '${t.energyPct}');
  }

  @override
  void dispose() {
    for (final c in [_rain, _heat, _z, _energy]) {
      c.dispose();
    }
    super.dispose();
  }

  double _p(TextEditingController c) => double.parse(c.text.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    await context.read<AppState>().setThresholds(
          Thresholds(rainMm: _p(_rain), heatC: _p(_heat), waterZ: _p(_z), energyPct: _p(_energy)),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Limiares salvos e alertas recalculados.')));
  }

  Future<void> _revoke() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Apagar meus dados?'),
        content: const Text(
            'Ocorrências, decisões e configurações salvas neste aparelho serão apagadas e o consentimento será revogado.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Apagar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await context.read<AppState>().revokeAndClear();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, Routes.consent, (_) => false);
  }

  Widget _field(TextEditingController c, String label, double min, double max) =>
      Padding(
        padding: const EdgeInsets.only(bottom: Sp.m),
        child: TextFormField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: AppTheme.input(label, helper: 'Entre $min e $max'),
          validator: (v) => Validators.number(v, min: min, max: max),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: const Text('Ajustes')),
      body: Responsive(
        child: ListView(padding: const EdgeInsets.all(Sp.m), children: [
          Text('Limiares de alerta', style: t.titleMedium),
          const SizedBox(height: Sp.m),
          Form(
            key: _key,
            child: Column(children: [
              _field(_rain, 'Chuva (mm/dia)', 5, 200),
              _field(_heat, 'Temperatura máxima (°C)', 25, 50),
              _field(_z, 'Anomalia de água (desvios-padrão)', 1, 6),
              _field(_energy, 'Alta de energia (%)', 1, 50),
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: _save, child: const Text('Salvar limiares')),
              ),
            ]),
          ),
          const SizedBox(height: Sp.l),
          Text('Aparência', style: t.titleMedium),
          const SizedBox(height: Sp.s),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('Sistema')),
              ButtonSegment(value: ThemeMode.light, label: Text('Claro')),
              ButtonSegment(value: ThemeMode.dark, label: Text('Escuro')),
            ],
            selected: {s.themeMode},
            onSelectionChanged: (v) => s.setThemeMode(v.first),
          ),
          const SizedBox(height: Sp.m),
          Text('Tamanho da fonte: ${(s.fontScale * 100).round()}%'),
          Slider(
            value: s.fontScale,
            min: 0.85,
            max: 1.5,
            divisions: 13,
            label: '${(s.fontScale * 100).round()}%',
            semanticFormatterCallback: (v) => 'Tamanho da fonte ${(v * 100).round()} por cento',
            onChanged: s.setFontScale,
          ),
          const SizedBox(height: Sp.l),
          Text('Privacidade', style: t.titleMedium),
          const SizedBox(height: Sp.s),
          const Text('Nenhum dado pessoal é coletado. Tudo fica salvo apenas neste aparelho.'),
          const SizedBox(height: Sp.s),
          OutlinedButton.icon(
            onPressed: _revoke,
            icon: const Icon(Icons.delete_forever),
            label: const Text('Apagar meus dados e revogar consentimento'),
          ),
        ]),
      ),
    );
  }
}
