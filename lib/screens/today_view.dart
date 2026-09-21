import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config.dart';
import '../main.dart';
import '../store.dart';

class TodayView extends StatelessWidget {
  const TodayView({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final s = store.sprint();
    final pct = store.todayPct();
    final done = store.doneOn(store.todayKey);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 48),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('EEEE').format(now),
                    style: const TextStyle(
                        fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: -0.9)),
                Text(DateFormat('MMMM d').format(now),
                    style: const TextStyle(fontSize: 15, color: C.label2)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
              decoration:
                  BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(100)),
              child: Text('🔥 $done/${store.habits.length}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Center(
          child: SizedBox(
            width: 180,
            height: 180,
            child: CustomPaint(
              painter: _RingPainter(todayPct: pct, sprintPct: s.pct),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${(pct * 100).round()}%',
                        style: const TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.5)),
                    const Text('TODAY',
                        style: TextStyle(
                            fontSize: 12,
                            color: C.label3,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2)),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        _goalCard(s),
        const SizedBox(height: 26),
        const _SectionTitle('Daily tasks'),
        const SizedBox(height: 8),
        _taskGroup(),
        const SizedBox(height: 26),
        const _SectionTitle('This month'),
        const SizedBox(height: 8),
        _monthStrip(now),
      ],
    );
  }

  Widget _goalCard(Sprint s) {
    final pct = (s.pct * 100).round();
    final target =
        DateFormat('MMMM d, y').format(DateTime.parse(store.goal.target));
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🎯 ${store.goal.label}',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600, color: C.label2)),
                  const SizedBox(height: 6),
                  Text('${s.remaining} days left',
                      style: const TextStyle(
                          fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: -0.8)),
                  const SizedBox(height: 3),
                  Text('Deadline · $target',
                      style: const TextStyle(fontSize: 13, color: C.label3)),
                ],
              ),
              Text('$pct%',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700, color: C.label)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: s.pct,
              minHeight: 6,
              backgroundColor: const Color(0x3D78788C),
              valueColor: const AlwaysStoppedAnimation(C.indigo),
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskGroup() {
    if (store.habits.isEmpty) {
      return _card(const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No tasks yet — add some in Settings',
            style: TextStyle(color: C.label3)),
      ));
    }
    final today = store.log[store.todayKey] ?? {};
    return _card(Column(
      children: [
        for (int i = 0; i < store.habits.length; i++)
          _taskRow(store.habits[i], today[store.habits[i].id] == true,
              i != store.habits.length - 1),
      ],
    ));
  }

  Widget _taskRow(Habit h, bool done, bool sep) {
    final tint = C.tileTints[h.id.hashCode.abs() % C.tileTints.length];
    return InkWell(
      onTap: () => store.toggle(h.id),
      child: Container(
        decoration: sep
            ? const BoxDecoration(
                border: Border(bottom: BorderSide(color: C.sep, width: 0.5)))
            : null,
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration:
                  BoxDecoration(color: tint, borderRadius: BorderRadius.circular(9)),
              alignment: Alignment.center,
              child: Text(h.emoji, style: const TextStyle(fontSize: 19)),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(h.name,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: done ? C.label3 : C.label)),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? C.green : Colors.transparent,
                border: Border.all(
                    color: done ? C.green : const Color(0x8078788C), width: 2),
              ),
              child: done
                  ? const Icon(Icons.check, size: 15, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _monthStrip(DateTime now) {
    final days = DateUtils.getDaysInMonth(now.year, now.month);
    final total = store.habits.length;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(days, (i) {
        final key = DateFormat('yyyy-MM-dd')
            .format(DateTime(now.year, now.month, i + 1));
        final future = key.compareTo(store.todayKey) > 0;
        Color c;
        if (future) {
          c = const Color(0x3878788C);
        } else if (total == 0) {
          c = const Color(0x4D78788C);
        } else {
          final ratio = store.doneOn(key) / total;
          c = HSLColor.fromAHSL(1, 120 * ratio, 0.72, 0.48).toColor();
        }
        return Container(
          width: 15,
          height: 15,
          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(5)),
        );
      }),
    );
  }

  Widget _card(Widget child) => Container(
        decoration:
            BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: child,
      );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: C.label2)),
      );
}

class _RingPainter extends CustomPainter {
  final double todayPct, sprintPct;
  _RingPainter({required this.todayPct, required this.sprintPct});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    const start = -math.pi / 2;

    void arc(double r, double w, Color track, Color fill, double pct) {
      final rect = Rect.fromCircle(center: c, radius: r);
      final tp = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..color = track;
      canvas.drawArc(rect, 0, 2 * math.pi, false, tp);
      if (pct > 0) {
        final fp = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..strokeCap = StrokeCap.round
          ..color = fill;
        canvas.drawArc(rect, start, 2 * math.pi * pct.clamp(0, 1), false, fp);
      }
    }

    arc(72, 5, const Color(0x3378788C), C.indigo, sprintPct);
    arc(56, 14, const Color(0x3378788C),
        todayPct >= 1 ? C.green : C.blue, todayPct);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.todayPct != todayPct || old.sprintPct != sprintPct;
}
