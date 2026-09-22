import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config.dart';
import '../main.dart';
import 'today_view.dart';
import 'history_view.dart';
import 'settings_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) store.retryIfPending();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: AnimatedBuilder(
          animation: store,
          builder: (context, _) => IndexedStack(index: _tab, children: [
                  TodayView(), HistoryView(), SettingsView(),
                ]),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 8, 24, 12),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xE61C1C20),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0x18FFFFFF))),
                  child: Row(children: [
                    _tabButton(0, Icons.radio_button_checked, 'Today'),
                    _tabButton(1, Icons.calendar_today_outlined, 'History'),
                    _tabButton(2, Icons.tune_rounded, 'Settings'),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabButton(int index, IconData icon, String label) {
    final selected = index == _tab;
    return Expanded(
      child: Semantics(
        selected: selected,
        child: TextButton(
          onPressed: () {
            if (_tab == index) return;
            HapticFeedback.selectionClick();
            setState(() => _tab = index);
          },
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 56),
            foregroundColor: selected ? C.label : C.label2,
            backgroundColor: selected ? const Color(0x14FFFFFF) : Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 9),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 21),
            const SizedBox(height: 5),
            Text(label, style: TextStyle(fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
          ]),
        ),
      ),
    );
  }
}
