import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/settings_provider.dart';
import 'theme/app_theme.dart';
import 'screens/today_screen.dart';
import 'screens/weight_screen.dart';
import 'screens/events_screen.dart';
import 'screens/journal_screen.dart';
import 'screens/report_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/about_screen.dart';
// SettingsScreen is accessible via the ⚙ icon in Today's AppBar, not a tab.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = SettingsProvider();
  await settings.load();
  final prefs = await SharedPreferences.getInstance();
  final setupComplete = prefs.getBool('setup_complete') ?? false;

  runApp(
    ChangeNotifierProvider.value(
      value: settings,
      child: RegenerationApp(showOnboarding: !setupComplete),
    ),
  );
}

class RegenerationApp extends StatelessWidget {
  final bool showOnboarding;
  const RegenerationApp({super.key, this.showOnboarding = false});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return MaterialApp(
      title: 'Regeneration',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(settings.colorTheme),
      darkTheme: AppTheme.getDarkTheme(settings.colorTheme),
      themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: showOnboarding ? '/onboarding' : '/home',
      routes: {
        '/onboarding': (_) => const OnboardingScreen(),
        '/home': (_) => const MainShell(),
        '/about': (_) => const AboutScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
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

  final List<Widget> _screens = const [
    TodayScreen(),
    WeightScreen(),
    EventsScreen(),
    JournalScreen(),
    ReportScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: cs.surface,
        indicatorColor: cs.primaryContainer,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.monitor_weight_outlined),
            selectedIcon: Icon(Icons.monitor_weight),
            label: 'Weight',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note),
            label: 'Events',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Journal',
          ),
          NavigationDestination(
            icon: Icon(Icons.summarize_outlined),
            selectedIcon: Icon(Icons.summarize),
            label: 'Report',
          ),
        ],
      ),
    );
  }
}
