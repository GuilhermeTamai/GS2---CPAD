import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import 'alerts_screen.dart';
import 'occurrences_screen.dart';
import 'overview_screen.dart';
import 'settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _i = 0; // aba atual: estado local

  @override
  Widget build(BuildContext context) {
    final n = context.select<AppState, int>((s) => s.alerts.length);
    return Scaffold(
      body: IndexedStack(index: _i, children: const [
        OverviewScreen(),
        AlertsScreen(),
        OccurrencesScreen(),
        SettingsScreen(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (v) => setState(() => _i = v),
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Visão geral'),
          NavigationDestination(
              icon: Badge(
                  isLabelVisible: n > 0,
                  label: Text('$n'),
                  child: const Icon(Icons.notifications_outlined)),
              selectedIcon: const Icon(Icons.notifications),
              label: 'Alertas'),
          const NavigationDestination(
              icon: Icon(Icons.edit_note), label: 'Ocorrências'),
          const NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Ajustes'),
        ],
      ),
    );
  }
}
