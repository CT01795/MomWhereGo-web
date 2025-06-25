import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:mom_where_go/firebase_options.dart';

import 'pages/history_events_page.dart';
import 'pages/planned_events_page.dart';
import 'pages/suggested_events_page.dart';

var logger = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);
    logger.i('✅ Firebase Initialized');
  } catch (e) {
    logger.e('❌ Firebase.initializeApp() error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MomWhereGo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        iconTheme: const IconThemeData(size: 36),
        textTheme: ThemeData.light().textTheme.copyWith(
              bodyLarge: const TextStyle(fontSize: 24),
              bodyMedium: const TextStyle(fontSize: 24),
              titleLarge:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              labelLarge:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
      ),
      //home: const MyHomePage(title: 'Dear, Where Are We Going?'),
      debugShowCheckedModeBanner: false,
      home: kIsWeb ? SuggestedEventsPage() : const MyHomePage(title: 'Dear, Where Are We Going?'), // 👈 這裡要是你要的首頁
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  List<Widget> _buildPages() {
    if (kIsWeb) {
      return [const SuggestedEventsPage()];
    }

    // Android/iOS
    return const [
      SuggestedEventsPage(),
      PlannedEventsPage(),
      HistoryEventsPage(),
    ];
  }

  List<BottomNavigationBarItem> _buildBottomNavItems() {
    if (kIsWeb) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.lightbulb_outline),
          label: '建議活動',
        ),
      ];
    }

    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.lightbulb_outline),
        label: '建議活動',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.event_note),
        label: '預計活動',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.history),
        label: '歷史活動',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages();
    final items = _buildBottomNavItems();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: kIsWeb
          ? SuggestedEventsPage() // 網頁只顯示建議活動頁
          : pages[_selectedIndex],
      bottomNavigationBar: kIsWeb ? null :
        BottomNavigationBar(
          items: items,
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          selectedItemColor: Colors.deepPurple,
          selectedIconTheme: const IconThemeData(size: 60),
          unselectedIconTheme: const IconThemeData(size: 40),
          selectedLabelStyle:
              const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 16),
        ),
    );
  }
}