import 'package:flutter/material.dart';
import 'live_trading_screen.dart';
import 'journal_screen.dart';
import 'history_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const LiveTradingScreen(),
    const JournalScreen(),
    const HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: Colors.tealAccent,
        unselectedItemColor: Colors.white54,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: "Live Trading",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: "Journal",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: "History",
          ),
        ],
      ),
    );
  }
}
