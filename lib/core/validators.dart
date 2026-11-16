class Validators {
  // CPF, e-mail e telefone: o cidadão não deve digitar dados pessoais no texto livre.
  static final _pii = RegExp(
    r'(\b\d{3}\.?\d{3}\.?\d{3}-?\d{2}\b)|([\w.+-]+@[\w-]+\.[\w.]+)|(\(?\d{2}\)?\s?9?\d{4}-?\d{4})',
  );

  static String? required(String? v,
      {int min = 1, String field = 'Campo', bool feminine = false}) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return '$field é obrigatóri${feminine ? 'a' : 'o'}';
    if (t.length < min) return '$field deve ter ao menos $min caracteres';
    return null;
  }

  static String? description(String? v) {
    final base = required(v, min: 10, field: 'A descrição', feminine: true);
    if (base != null) return base;
    final t = v!.trim();
    if (t.length > 280) return 'Máximo de 280 caracteres';
    if (_pii.hasMatch(t)) {
      return 'Não inclua dados pessoais (CPF, e-mail ou telefone)';
    }
    return null;
  }

  static String? number(String? v, {required double min, required double max}) {
    final n = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
    if (n == null) return 'Digite um número válido';
    if (n < min || n > max) return 'Use um valor entre $min e $max';
    return null;
  }
}
