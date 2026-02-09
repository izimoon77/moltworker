import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/pointage_screen.dart';
import 'screens/employees_screen.dart';
import 'screens/history_screen.dart';
import 'screens/export_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  runApp(const PointageApp());
}

class PointageApp extends StatelessWidget {
  const PointageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pointage',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _titles = [
    'Pointage',
    'Employés',
    'Historique',
    'Export comptable',
  ];

  final _screens = const [
    PointageScreen(),
    EmployeesScreen(),
    HistoryScreen(),
    ExportScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        centerTitle: true,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.fingerprint),
            selectedIcon: Icon(Icons.fingerprint, color: Colors.blue),
            label: 'Pointage',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: Colors.blue),
            label: 'Employés',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            selectedIcon: Icon(Icons.history, color: Colors.blue),
            label: 'Historique',
          ),
          NavigationDestination(
            icon: Icon(Icons.file_download_outlined),
            selectedIcon: Icon(Icons.file_download, color: Colors.blue),
            label: 'Export',
          ),
        ],
      ),
    );
  }
}
