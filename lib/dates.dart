import 'package:flutter/material.dart';
import 'store.dart';
import 'tools.dart';

// a <= b olmalı. [yıl, ay, gün]
List<int> dateDiff(DateTime a, DateTime b) {
  int y = b.year - a.year, m = b.month - a.month, d = b.day - a.day;
  if (d < 0) {
    m--;
    d += DateTime(b.year, b.month, 0).day;
  }
  if (m < 0) {
    y--;
    m += 12;
  }
  return [y, m, d];
}

int daysBetween(DateTime a, DateTime b) =>
    DateTime.utc(b.year, b.month, b.day)
        .difference(DateTime.utc(a.year, a.month, a.day))
        .inDays;

class DatesPage extends StatefulWidget {
  final Init init;
  const DatesPage({super.key, this.init});
  @override
  State<DatesPage> createState() => _DatesState();
}

class _DatesState extends State<DatesPage> {
  final days = TextEditingController();
  DateTime? a;
  DateTime? b = DateTime.now();
  int mode = 0;
  ResultData? r;

  static const modes = ['Yaş hesapla', 'Tarih farkı', 'Gün ekle', 'Gün çıkar'];

  @override
  void initState() {
    super.initState();
    applyInit(widget.init, {'n': days});
    final x = parseDateKey(widget.init?['a']);
    final y = parseDateKey(widget.init?['b']);
    if (x != null) a = x;
    if (y != null) b = y;
    mode = int.tryParse(widget.init?['mode'] ?? '') ?? 0;
  }

  void calc() {
    final today = DateTime.now();
    ResultData res;
    String hist;
    if (mode == 0) {
      if (a == null) {
        warn(context, 'Doğum tarihini seç');
        return;
      }
      if (a!.isAfter(today)) {
        warn(context, 'Doğum tarihi bugünden sonra olamaz');
        return;
      }
      final d = dateDiff(a!, today);
      var next = DateTime(today.year, a!.month, a!.day);
      if (next.isBefore(DateTime(today.year, today.month, today.day))) {
        next = DateTime(today.year + 1, a!.month, a!.day);
      }
      final left = daysBetween(today, next);
      res = ResultData('Yaş', '${d[0]} yıl ${d[1]} ay ${d[2]} gün', [
        'Yaşadığın gün: ${fmt(daysBetween(a!, today).toDouble(), 0)}',
        left == 0
            ? 'Bugün doğum günün!'
            : 'Sonraki doğum günü: $left gün sonra (${weekdaysTr[next.weekday - 1]})',
      ]);
      hist = 'Yaş: ${fmtDate(a!)} doğumlu → ${d[0]} yıl ${d[1]} ay ${d[2]} gün';
    } else if (mode == 1) {
      if (a == null || b == null) {
        warn(context, 'İki tarihi de seç');
        return;
      }
      final from = a!.isAfter(b!) ? b! : a!;
      final to = a!.isAfter(b!) ? a! : b!;
      final total = daysBetween(from, to);
      final d = dateDiff(from, to);
      res = ResultData('Aradaki süre', '${fmt(total.toDouble(), 0)} gün', [
        '${d[0]} yıl ${d[1]} ay ${d[2]} gün',
        'Yaklaşık ${fmt(total / 7, 1)} hafta',
      ]);
      hist = 'Tarih farkı: ${fmtDate(from)} - ${fmtDate(to)} = $total gün';
    } else {
      final n = numOf(days);
      if (a == null || n == null) {
        warn(context, 'Tarihi ve gün sayısını gir');
        return;
      }
      final k = n.round() * (mode == 2 ? 1 : -1);
      final t = DateTime(a!.year, a!.month, a!.day + k);
      res = ResultData(mode == 2 ? 'Gün eklenmiş tarih' : 'Gün çıkarılmış tarih',
          fmtDate(t), [weekdaysTr[t.weekday - 1]]);
      hist =
          'Tarih: ${fmtDate(a!)} ${mode == 2 ? '+' : '-'} ${n.round()} gün = ${fmtDate(t)}';
    }
    store.addHistory(hist,
        tool: 'dates',
        inputs: snap({'n': days}, {
          'mode': '$mode',
          if (a != null) 'a': dateKey(a!),
          if (b != null) 'b': dateKey(b!),
        }));
    setState(() => r = res);
  }

  @override
  Widget build(BuildContext context) {
    final tool = toolById('dates');
    return ToolPage(
      tool: tool,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ModeChips(
            labels: modes,
            selected: mode,
            color: tool.color,
            onChanged: (i) => setState(() {
              mode = i;
              r = null;
            }),
          ),
          DateField(
              label: mode == 0
                  ? 'Doğum tarihi'
                  : (mode == 1 ? 'Başlangıç tarihi' : 'Tarih'),
              value: a,
              onChanged: (d) => setState(() => a = d)),
          if (mode == 1)
            DateField(
                label: 'Bitiş tarihi',
                value: b,
                onChanged: (d) => setState(() => b = d)),
          if (mode >= 2) NumField(label: 'Gün sayısı', c: days, suffix: 'gün'),
          actionButton(tool.color, calc),
          if (r != null) ResultCard(data: r!, color: tool.color),
        ],
      ),
    );
  }
}
