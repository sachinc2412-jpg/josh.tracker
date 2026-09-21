import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../config.dart';
import '../main.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});
  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _adding = false;
  final _newName = TextEditingController();
  final _newEmoji = TextEditingController(text: '⭐');

  Future<void> _pickDate(String which, String current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(current) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      final s = DateFormat('yyyy-MM-dd').format(picked);
      store.updateGoal(start: which == 'start' ? s : null, target: which == 'target' ? s : null);
    }
  }

  Future<void> _share(String content, String filename) async {
    try {
      final dir = await getTemporaryDirectory();
      final f = File('${dir.path}/$filename');
      await f.writeAsString(content);
      await Share.shareXFiles([XFile(f.path)]);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 48),
      children: [
        _title('Goal'),
        _card(Column(children: [
          _editRow('Goal name', store.goal.label,
              (v) => store.updateGoal(label: v)),
          _dateRow('Deadline', store.goal.target, () => _pickDate('target', store.goal.target)),
          _dateRow('Start date', store.goal.start, () => _pickDate('start', store.goal.start), last: true),
        ])),
        const SizedBox(height: 26),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _title('Daily tasks', pad: false),
            TextButton(
              onPressed: () => setState(() => _adding = !_adding),
              child: Text(_adding ? 'Close' : '+ Add',
                  style: const TextStyle(color: C.blue, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        if (_adding) _addCard(),
        _card(Column(children: [
          for (int i = 0; i < store.habits.length; i++)
            _manageRow(i),
        ])),
        const SizedBox(height: 26),
        _title('Export'),
        _card(Column(children: [
          _exportRow('📄  Download report (CSV)',
              () => _share(store.exportCsv(), 'josh-tracker-${store.todayKey}.csv')),
          _exportRow('💾  Full backup (JSON)',
              () => _share(store.exportJson(), 'josh-tracker-${store.todayKey}.json'),
              last: true),
        ])),
        const SizedBox(height: 26),
        _title('Account'),
        _card(Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(store.user?.email ?? 'Signed in',
                  style: const TextStyle(color: C.label2, fontSize: 14)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => store.signOut(),
                child: const Text('Sign out',
                    style: TextStyle(color: C.red, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _addCard() => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(20)),
        child: Column(children: [
          Row(children: [
            SizedBox(width: 56, child: _input(_newEmoji, '😀', center: true)),
            const SizedBox(width: 10),
            Expanded(child: _input(_newName, 'Task name...')),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () {
                if (_newName.text.trim().isEmpty) return;
                store.addHabit(_newName.text.trim(), _newEmoji.text.trim());
                _newName.clear();
                _newEmoji.text = '⭐';
                setState(() => _adding = false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: C.blue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Add Task',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      );

  Widget _manageRow(int i) {
    final h = store.habits[i];
    final tint = C.tileTints[h.id.hashCode.abs() % C.tileTints.length];
    return Container(
      decoration: i != store.habits.length - 1
          ? const BoxDecoration(border: Border(bottom: BorderSide(color: C.sep, width: 0.5)))
          : null,
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
      child: Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(9)),
          alignment: Alignment.center,
          child: Text(h.emoji, style: const TextStyle(fontSize: 19)),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Text(h.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ),
        GestureDetector(
          onTap: () => store.deleteHabit(h.id),
          child: const Icon(Icons.close, color: C.red, size: 20),
        ),
      ]),
    );
  }

  Widget _editRow(String label, String value, ValueChanged<String> onChanged,
      {bool last = false}) {
    final c = TextEditingController(text: value);
    return _rowBox(
      last,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: C.label2)),
          const SizedBox(height: 8),
          _input(c, '', onSubmitted: onChanged),
        ],
      ),
    );
  }

  Widget _dateRow(String label, String value, VoidCallback onTap, {bool last = false}) {
    return _rowBox(
      last,
      GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 15)),
            Text(value, style: const TextStyle(fontSize: 15, color: C.blue)),
          ],
        ),
      ),
    );
  }

  Widget _exportRow(String label, VoidCallback onTap, {bool last = false}) {
    return _rowBox(
      last,
      GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Text(label,
            style: const TextStyle(fontSize: 16, color: C.blue, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _rowBox(bool last, Widget child) => Container(
        decoration: last
            ? null
            : const BoxDecoration(border: Border(bottom: BorderSide(color: C.sep, width: 0.5))),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: child,
      );

  Widget _input(TextEditingController c, String hint,
      {bool center = false, ValueChanged<String>? onSubmitted, ValueChanged<String>? onEditing}) {
    return TextField(
      controller: c,
      textAlign: center ? TextAlign.center : TextAlign.start,
      style: const TextStyle(color: C.label, fontSize: 16),
      onChanged: onEditing,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: C.label3),
        filled: true,
        fillColor: C.card2,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _title(String t, {bool pad = true}) => Padding(
        padding: EdgeInsets.only(left: 2, bottom: pad ? 12 : 0),
        child: Text(t,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
      );

  Widget _card(Widget child) => Container(
        decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: child,
      );
}
