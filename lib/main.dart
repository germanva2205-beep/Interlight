import 'package:flutter/material.dart';
import 'screens/alarms.dart';
import 'screens/calendar.dart';
import 'screens/history.dart';
import 'screens/home.dart';
import 'screens/notes.dart';
import 'native.dart';
import 'store.dart';
import 'widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await store.load();
  runApp(const HelpMeApp());
}

class HelpMeApp extends StatelessWidget {
  const HelpMeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Help Me',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(seedColor: hmOrange, brightness: Brightness.light),
          scaffoldBackgroundColor: const Color(0xFFFFFBF5),
        ),
        home: const Shell(),
      );
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    Native.listenForLaunch(_trigger);
    Native.consumeLaunch().then((v) {
      if (v) _trigger();
    });
  }

  void _trigger() {
    if (!mounted) return;
    setState(() => _tab = 0);
    listenSignal.value++;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(
          index: _tab,
          children: [
            HomeScreen(active: _tab == 0),
            const NotesScreen(),
            const CalendarScreen(),
            const AlarmsScreen(),
            const HistoryScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.mic_none), selectedIcon: Icon(Icons.mic), label: 'Главная'),
            NavigationDestination(icon: Icon(Icons.sticky_note_2_outlined), selectedIcon: Icon(Icons.sticky_note_2), label: 'Заметки'),
            NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Календарь'),
            NavigationDestination(icon: Icon(Icons.alarm), selectedIcon: Icon(Icons.alarm_on), label: 'Будильники'),
            NavigationDestination(icon: Icon(Icons.history), selectedIcon: Icon(Icons.history), label: 'История'),
          ],
        ),
      );
}
