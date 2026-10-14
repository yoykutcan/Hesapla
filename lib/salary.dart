import 'package:flutter/material.dart';
import 'store.dart';
import 'tools.dart';
import 'params.dart';
import 'dates.dart';

const monthsTr = [
  'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
];

// ---------------- Brüt-net maaş ----------------

class SalaryPage extends StatefulWidget {
  final Init init;
  const SalaryPage({super.key, this.init});
  @override
  State<SalaryPage> createState() => _SalaryState();
}

class _SalaryState extends State<SalaryPage> {
  final amount = TextEditingController();
  int mode = 0;
  ResultData? r;
  List<List<String>> table = [];

  @override
  void initState() {
    super.initState();
    applyInit(widget.init, {'amount': amount});
    mode = int.tryParse(widget.init?['mode'] ?? '') ?? 0;
  }

  void calc() {
    final x = numOf(amount);
    if (x == null || x <= 0) {
      warn(context, 'Maaş tutarını gir');
      return;
    }
    double brut;
    if (mode == 0) {
      brut = x;
    } else {
      double lo = x, hi = x * 4;
      for (int i = 0; i < 80; i++) {
        final mid = (lo + hi) / 2;
        if (hesaplaYil(mid)[0].net < x) {
          lo = mid;
        } else {
          hi = mid;
        }
      }
      brut = (lo + hi) / 2;
    }
    final rs = hesaplaYil(brut);
    final first = rs.first, last = rs.last;
    final total = rs.fold<double>(0, (s, e) => s + e.net);
    final lines = <String>[
      if (mode == 1) 'Ocak ayı net: ${fmt(first.net)} ₺',
      'SGK işçi payı: ${fmt(first.sgk)} ₺',
      'İşsizlik sigortası: ${fmt(first.issizlik)} ₺',
      'Gelir vergisi (Ocak): ${fmt(first.gv)} ₺',
      'Damga vergisi: ${fmt(first.damga)} ₺',
      'Aralık ayı net: ${fmt(last.net)} ₺',
      'Yıllık ortalama net: ${fmt(total / 12)} ₺',
      '2026 parametreleri, asgari ücret istisnası dahil.',
    ];
    store.addHistory(
        mode == 0
            ? 'Maaş: brüt ${fmt(brut)} ₺ → Ocak neti ${fmt(first.net)} ₺'
            : 'Maaş: net ${fmt(x)} ₺ → brüt ${fmt(brut)} ₺',
        tool: 'salary',
        inputs: snap({'amount': amount}, {'mode': '$mode'}));
    setState(() {
      r = mode == 0
          ? ResultData('Ocak ayı net maaş', '${fmt(first.net)} ₺', lines)
          : ResultData('Gereken brüt maaş', '${fmt(brut)} ₺', lines);
      table = [
        for (int i = 0; i < 12; i++)
          [
            monthsTr[i].substring(0, 3),
            fmt(rs[i].sgk + rs[i].issizlik, 0),
            fmt(rs[i].gv + rs[i].damga, 0),
            fmt(rs[i].net, 0),
          ]
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final tool = toolById('salary');
    return ToolPage(
      tool: tool,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ModeChips(
            labels: const ['Brütten nete', 'Netten brüte (Ocak neti)'],
            selected: mode,
            color: tool.color,
            onChanged: (i) => setState(() {
              mode = i;
              r = null;
            }),
          ),
          NumField(
              label: mode == 0 ? 'Aylık brüt maaş' : 'İstediğin net maaş',
              c: amount,
              suffix: '₺'),
          actionButton(tool.color, calc),
          if (r != null) ResultCard(data: r!, color: tool.color),
          if (r != null)
            MiniTable(
              title: '12 aylık dağılım',
              headers: const ['Ay', 'SGK+İşs.', 'Vergi', 'Net'],
              rows: table,
            ),
        ],
      ),
    );
  }
}

// ---------------- Kıdem tazminatı ----------------

class SeverancePage extends StatefulWidget {
  final Init init;
  const SeverancePage({super.key, this.init});
  @override
  State<SeverancePage> createState() => _SeveranceState();
}

class _SeveranceState extends State<SeverancePage> {
  final salary = TextEditingController();
  final cap = TextEditingController(text: fmt(kidemTavan));
  DateTime? start;
  DateTime? end = DateTime.now();
  ResultData? r;

  @override
  void initState() {
    super.initState();
    applyInit(widget.init, {'salary': salary, 'cap': cap});
    final s = parseDateKey(widget.init?['start']);
    final e = parseDateKey(widget.init?['end']);
    if (s != null) start = s;
    if (e != null) end = e;
  }

  void calc() {
    final w = numOf(salary), t = numOf(cap);
    if (start == null || end == null || w == null || t == null) {
      warn(context, 'Tarihleri ve maaşı gir');
      return;
    }
    if (!end!.isAfter(start!)) {
      warn(context, 'Çıkış tarihi girişten sonra olmalı');
      return;
    }
    final d = dateDiff(start!, end!);
    final years = d[0] + d[1] / 12 + d[2] / 365;
    final base = w < t ? w : t;
    final svc = '${d[0]} yıl ${d[1]} ay ${d[2]} gün';
    ResultData res;
    String hist;
    if (d[0] < 1) {
      res = ResultData('Brüt kıdem tazminatı', '0 ₺', [
        'Çalışma süresi: $svc',
        'Kıdem tazminatı için en az 1 yıl çalışmış olmak gerekir.',
      ]);
      hist = 'Kıdem: $svc → hak doğmaz';
    } else {
      final brut = base * years;
      final damga = brut * damgaOrani;
      res = ResultData('Net kıdem tazminatı', '${fmt(brut - damga)} ₺', [
        'Çalışma süresi: $svc',
        'Brüt tazminat: ${fmt(brut)} ₺',
        'Damga vergisi: ${fmt(damga)} ₺',
        if (w > t) 'Maaşın tavanı aştığı için ${fmt(t)} ₺ üzerinden hesaplandı.',
        'İhbar tazminatı ve kullanılmayan izin ücreti ayrıca hesaplanır.',
      ]);
      hist = 'Kıdem: $svc, maaş ${fmt(w)} ₺ → net ${fmt(brut - damga)} ₺';
    }
    store.addHistory(hist,
        tool: 'severance',
        inputs: snap({'salary': salary, 'cap': cap},
            {'start': dateKey(start!), 'end': dateKey(end!)}));
    setState(() => r = res);
  }

  @override
  Widget build(BuildContext context) {
    final tool = toolById('severance');
    return ToolPage(
      tool: tool,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DateField(
              label: 'İşe giriş tarihi',
              value: start,
              onChanged: (d) => setState(() => start = d)),
          DateField(
              label: 'İşten çıkış tarihi',
              value: end,
              onChanged: (d) => setState(() => end = d)),
          NumField(label: 'Aylık giydirilmiş brüt ücret', c: salary, suffix: '₺'),
          NumField(label: 'Kıdem tazminatı tavanı', c: cap, suffix: '₺'),
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              'Varsayılan tavan 1 Temmuz - 31 Aralık 2026 için geçerlidir. Farklı bir dönemde ayrıldıysan tavanı değiştir.',
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          actionButton(tool.color, calc),
          if (r != null) ResultCard(data: r!, color: tool.color),
        ],
      ),
    );
  }
}
