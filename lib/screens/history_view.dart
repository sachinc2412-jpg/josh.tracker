import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config.dart';
import '../main.dart';
import '../store.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});
  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  int _monthOffset = 0;
  String _selected = DateTime.now().toIso8601String().split('T').first;
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    if (_filter != 'all' && !store.habits.any((h) => h.id == _filter)) {
      _filter = 'all';
    }
    final now = DateTime.now();
    final base = DateTime(now.year, now.month + _monthOffset, 1);
    final days = DateUtils.getDaysInMonth(base.year, base.month);
    final firstWeekday = DateTime(base.year, base.month, 1).weekday % 7; // Sun=0
    final total = store.habits.length;
    final filterHabit =
        _filter == 'all' ? null : store.habits.where((h) => h.id == _filter).firstOrNull;

    final cells = <Widget>[];
    for (var i = 0; i < firstWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var d = 1; d <= days; d++) {
      final key = DateFormat('yyyy-MM-dd').format(DateTime(base.year, base.month, d));
      final future = key.compareTo(store.todayKey) > 0;
      final dayLog = store.log[key] ?? {};
      Color bg = C.card;
      Color fg = C.label2;
      if (future) {
        bg = C.card;
        fg = C.label3;
      } else if (filterHabit != null) {
        final ok = dayLog[filterHabit.id] == true;
        bg = ok ? C.green : const Color(0x47FF453A);
        fg = Colors.white;
      } else {
        final done = store.doneOn(key);
        if (total > 0 && done == total) {
          bg = C.green; fg = Colors.white;
        } else if (done > 0) {
          bg = C.blue; fg = Colors.white;
        } else {
          bg = const Color(0x47FF453A); fg = Colors.white70;
        }
      }
      final selected = key == _selected;
      cells.add(GestureDetector(
        onTap: future ? null : () => setState(() => _selected = key),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(11),
            border: selected ? Border.all(color: Colors.white, width: 2.5) : null,
          ),
          alignment: Alignment.center,
          child: Text('$d',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: fg)),
        ),
      ));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 128),
      children: [
        const Text('History', style: TextStyle(fontSize: 34,
            fontWeight: FontWeight.w700, letterSpacing: -0.9)),
        const SizedBox(height: 6),
        const Text('A clearer view of your consistency.', style: TextStyle(fontSize: 14, color: C.label2)),
        const SizedBox(height: 28),
        _filterDropdown(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _navBtn(Icons.chevron_left, () => setState(() => _monthOffset--)),
            Text(DateFormat('MMMM y').format(base),
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.4)),
            Opacity(
              opacity: _monthOffset >= 0 ? 0 : 1,
              child: _navBtn(Icons.chevron_right,
                  _monthOffset >= 0 ? null : () => setState(() => _monthOffset++)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map((d) => Expanded(
                    child: Center(
                      child: Text(d,
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600, color: C.label3)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 7,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: cells,
        ),
        const SizedBox(height: 22),
        _detail(filterHabit, total),
      ],
    );
  }

  Widget _filterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _filter,
          isExpanded: true,
          dropdownColor: C.card2,
          style: const TextStyle(fontSize: 15, color: C.label),
          items: [
            const DropdownMenuItem(value: 'all', child: Text('All tasks')),
            ...store.habits.map((h) => DropdownMenuItem(
                value: h.id, child: Text('${h.emoji}  ${h.name}'))),
          ],
          onChanged: (v) => setState(() => _filter = v ?? 'all'),
        ),
      ),
    );
  }

  Widget _navBtn(IconData icon, VoidCallback? onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(color: C.card, shape: BoxShape.circle),
          child: Icon(icon, color: C.blue, size: 22),
        ),
      );

  Widget _detail(Habit? filterHabit, int total) {
    final dayLog = store.log[_selected] ?? {};
    final label =
        DateFormat('EEEE, MMMM d').format(DateTime.parse(_selected));
    final rows = <Widget>[];
    final list = filterHabit != null ? [filterHabit] : store.habits;
    for (var i = 0; i < list.length; i++) {
      final h = list[i];
      final ok = dayLog[h.id] == true;
      rows.add(Container(
        decoration: i != list.length - 1
            ? const BoxDecoration(
                border: Border(bottom: BorderSide(color: C.sep, width: 0.5)))
            : null,
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${h.emoji}  ${h.name}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            Text(ok ? 'Done' : 'Missed',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ok ? C.green : C.label3)),
          ],
        ),
      ));
    }
    final score = filterHabit == null ? '${store.doneOn(_selected)}/$total' : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 14, 0, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                Text(score,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: C.label2)),
              ],
            ),
          ),
          ...rows,
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
