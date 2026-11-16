import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/routes.dart';
import 'core/theme.dart';
import 'services/storage.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(Storage(prefs))..refresh(),
      child: const App(),
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return MaterialApp(
      title: 'Território Preditivo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: s.themeMode,
      // Respeita a fonte do sistema; se o usuário ajustar no app, usa o valor dele.
      builder: (c, child) {
        final mq = MediaQuery.of(c);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: s.fontScale == 1.0 ? mq.textScaler : TextScaler.linear(s.fontScale),
          ),
          child: child!,
        );
      },
      initialRoute: s.consent ? Routes.home : Routes.consent,
      onGenerateRoute: Routes.generate,
    );
  }
}
