import 'dart:math';
import 'package:flutter/material.dart';
import 'store.dart';
import 'salary.dart';
import 'dates.dart';

typedef Init = Map<String, String>?;

class Tool {
  final String id, title, subtitle, category;
  final IconData icon;
  final Color color;
  final Widget Function(Init init) page;
  Tool(this.id, this.title, this.subtitle, this.category, this.icon, this.color,
      this.page);
}

final List<Tool> tools = [
  Tool('calc', 'Hesap makinesi', 'Dört işlem ve yüzde', 'Günlük',
      Icons.calculate_rounded, const Color(0xFF5B6CFF), (i) => CalcPage(init: i)),
  Tool('percent', 'Yüzde', 'Yüzde bul, ekle, çıkar', 'Günlük',
      Icons.percent_rounded, const Color(0xFF14B87A), (i) => PercentPage(init: i)),
  Tool('interest', 'Faiz', 'Basit ve bileşik faiz', 'Finans',
      Icons.savings_rounded, const Color(0xFFD97706), (i) => InterestPage(init: i)),
  Tool('loan', 'Kredi taksit', 'Taksit, ödeme planı, erken kapama', 'Finans',
      Icons.account_balance_rounded, const Color(0xFF8B5CF6),
      (i) => LoanPage(init: i)),
  Tool('salary', 'Brüt-net maaş', '2026 bordro hesabı', 'Finans',
      Icons.payments_rounded, const Color(0xFFDC2626), (i) => SalaryPage(init: i)),
  Tool('severance', 'Kıdem tazminatı', 'Brüt ve net tutar', 'Finans',
      Icons.business_center_rounded, const Color(0xFFB45309),
      (i) => SeverancePage(init: i)),
  Tool('vat', 'KDV', 'KDV dahil ve hariç', 'Finans',
      Icons.receipt_long_rounded, const Color(0xFF0EA5E9), (i) => VatPage(init: i)),
  Tool('fuel', 'Yakıt', 'Yol maliyeti ve tüketim', 'Günlük',
      Icons.local_gas_station_rounded, const Color(0xFFF97316),
      (i) => FuelPage(init: i)),
  Tool('dates', 'Tarih araçları', 'Yaş, gün farkı, gün ekle', 'Günlük',
      Icons.calendar_month_rounded, const Color(0xFFE11D48),
      (i) => DatesPage(init: i)),
  Tool('bmi', 'Kilo / BMI', 'Vücut kitle indeksi', 'Sağlık',
      Icons.monitor_weight_rounded, const Color(0xFFEC4899), (i) => BmiPage(init: i)),
  Tool('units', 'Birim çevirici', 'Uzunluk, ağırlık, sıcaklık', 'Günlük',
      Icons.swap_horiz_rounded, const Color(0xFF14B8A6), (i) => UnitPage(init: i)),
];

Tool toolById(String id) => tools.firstWhere((t) => t.id == id);

class ToolPage extends StatelessWidget {
  final Tool tool;
  final Widget child;
  const ToolPage({super.key, required this.tool, required this.child});

  @override
  Widget build(BuildContext context) {
    return GradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          scrolledUnderElevation: 0,
          title: Text(tool.title),
          actions: [
            AnimatedBuilder(
              animation: store,
              builder: (_, __) => IconButton(
                icon: Icon(store.favorites.contains(tool.id)
                    ? Icons.star_rounded
                    : Icons.star_border_rounded),
                onPressed: () => store.toggleFav(tool.id),
              ),
            ),
          ],
        ),
        body: SafeArea(child: child),
      ),
    );
  }
}

Widget actionButton(Color color, VoidCallback onTap, [String text = 'Hesapla']) {
  return FilledButton(
    onPressed: onTap,
    style: FilledButton.styleFrom(
      backgroundColor: color,
      minimumSize: const Size.fromHeight(54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    child: Text(text, style: const TextStyle(fontSize: 17)),
  );
}

// ---------------- Hesap makinesi ----------------

class CalcPage extends StatefulWidget {
  final Init init;
  const CalcPage({super.key, this.init});
  @override
  State<CalcPage> createState() => _CalcState();
}

class _CalcState extends State<CalcPage> {
  String display = '0';
  String expr = '';
  double? acc;
  String? op;
  bool fresh = true;

  String show(double v) {
    if (v.isNaN || v.isInfinite) return 'Hata';
    if (v == v.roundToDouble() && v.abs() < 1e15) return v.toStringAsFixed(0);
    var s = v.toStringAsFixed(8);
    s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    return s;
  }

  double cur() => double.tryParse(display) ?? 0;

  double apply(double a, String o, double b) {
    switch (o) {
      case '+':
        return a + b;
      case '−':
        return a - b;
      case '×':
        return a * b;
      case '÷':
        return b == 0 ? double.nan : a / b;
    }
    return b;
  }

  void digit(String d) {
    setState(() {
      if (fresh) {
        display = d == '.' ? '0.' : d;
        fresh = false;
      } else {
        if (d == '.' && display.contains('.')) return;
        if (display == '0' && d != '.') {
          display = d;
        } else {
          display += d;
        }
      }
    });
  }

  void setOp(String o) {
    setState(() {
      if (acc != null && op != null && !fresh) {
        acc = apply(acc!, op!, cur());
        display = show(acc!);
      } else {
        acc = cur();
      }
      op = o;
      fresh = true;
      expr = '${show(acc!)} $o';
    });
  }

  void equals() {
    if (acc == null || op == null) return;
    final b = cur();
    final r = apply(acc!, op!, b);
    store.addHistory('Hesap makinesi: ${show(acc!)} $op ${show(b)} = ${show(r)}',
        tool: 'calc');
    setState(() {
      display = show(r);
      acc = null;
      op = null;
      fresh = true;
      expr = '';
    });
  }

  void clear() {
    setState(() {
      display = '0';
      expr = '';
      acc = null;
      op = null;
      fresh = true;
    });
  }

  void back() {
    if (fresh) return;
    setState(() {
      display = display.length > 1 ? display.substring(0, display.length - 1) : '0';
      if (display == '-') display = '0';
    });
  }

  void percent() {
    setState(() {
      display = show(cur() / 100);
      fresh = true;
    });
  }

  void negate() {
    setState(() {
      if (display == '0') return;
      display = display.startsWith('-') ? display.substring(1) : '-$display';
    });
  }

  Widget row(List<Widget> kids) => Expanded(child: Row(children: kids));

  @override
  Widget build(BuildContext context) {
    final tool = toolById('calc');
    final c = tool.color;
    final opBg = c.withAlpha(50);
    return ToolPage(
      tool: tool,
      child: Column(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              alignment: Alignment.bottomRight,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(expr,
                      style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(display,
                        style: const TextStyle(
                            fontSize: 60, fontWeight: FontWeight.w400)),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Column(
                children: [
                  row([
                    CalcButton(text: 'C', onTap: clear, bg: opBg, fg: c),
                    CalcButton(text: '⌫', onTap: back, bg: opBg, fg: c),
                    CalcButton(text: '%', onTap: percent, bg: opBg, fg: c),
                    CalcButton(text: '÷', onTap: () => setOp('÷'), bg: opBg, fg: c),
                  ]),
                  row([
                    CalcButton(text: '7', onTap: () => digit('7')),
                    CalcButton(text: '8', onTap: () => digit('8')),
                    CalcButton(text: '9', onTap: () => digit('9')),
                    CalcButton(text: '×', onTap: () => setOp('×'), bg: opBg, fg: c),
                  ]),
                  row([
                    CalcButton(text: '4', onTap: () => digit('4')),
                    CalcButton(text: '5', onTap: () => digit('5')),
                    CalcButton(text: '6', onTap: () => digit('6')),
                    CalcButton(text: '−', onTap: () => setOp('−'), bg: opBg, fg: c),
                  ]),
                  row([
                    CalcButton(text: '1', onTap: () => digit('1')),
                    CalcButton(text: '2', onTap: () => digit('2')),
                    CalcButton(text: '3', onTap: () => digit('3')),
                    CalcButton(text: '+', onTap: () => setOp('+'), bg: opBg, fg: c),
                  ]),
                  row([
                    CalcButton(text: '±', onTap: negate),
                    CalcButton(text: '0', onTap: () => digit('0')),
                    CalcButton(text: ',', onTap: () => digit('.')),
                    CalcButton(text: '=', onTap: equals, bg: c, fg: Colors.white),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- Yüzde ----------------

class PercentPage extends StatefulWidget {
  final Init init;
  const PercentPage({super.key, this.init});
  @override
  State<PercentPage> createState() => _PercentState();
}

class _PercentState extends State<PercentPage> {
  final a = TextEditingController();
  final b = TextEditingController();
  int mode = 0;
  ResultData? r;

  static const modes = [
    "A'nın %B'si",
    "A, B'nin yüzde kaçı",
    'A sayısına %B ekle',
    'A sayısından %B çıkar',
  ];

  @override
  void initState() {
    super.initState();
    applyInit(widget.init, {'a': a, 'b': b});
    mode = int.tryParse(widget.init?['mode'] ?? '') ?? 0;
  }

  void calc() {
    final x = numOf(a), y = numOf(b);
    if (x == null || y == null) {
      warn(context, 'İki değeri de gir');
      return;
    }
    ResultData res;
    String hist;
    if (mode == 0) {
      final v = x * y / 100;
      res = ResultData('Sonuç', fmt(v));
      hist = "${fmtFlex(x)} sayısının %${fmtFlex(y)}'si = ${fmt(v)}";
    } else if (mode == 1) {
      if (y == 0) {
        warn(context, 'B değeri 0 olamaz');
        return;
      }
      final v = x / y * 100;
      res = ResultData('Sonuç', '% ${fmt(v)}');
      hist = "${fmtFlex(x)}, ${fmtFlex(y)} sayısının %${fmt(v)}'i";
    } else if (mode == 2) {
      final d = x * y / 100;
      res = ResultData('Sonuç', fmt(x + d), ['Eklenen: ${fmt(d)}']);
      hist = '${fmtFlex(x)} + %${fmtFlex(y)} = ${fmt(x + d)}';
    } else {
      final d = x * y / 100;
      res = ResultData('Sonuç', fmt(x - d), ['Çıkarılan: ${fmt(d)}']);
      hist = '${fmtFlex(x)} - %${fmtFlex(y)} = ${fmt(x - d)}';
    }
    store.addHistory('Yüzde: $hist',
        tool: 'percent', inputs: snap({'a': a, 'b': b}, {'mode': '$mode'}));
    setState(() => r = res);
  }

  @override
  Widget build(BuildContext context) {
    final tool = toolById('percent');
    final labels =
        mode == 1 ? ['Değer (A)', 'Toplam (B)'] : ['Sayı (A)', 'Yüzde (B)'];
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
          NumField(label: labels[0], c: a),
          NumField(label: labels[1], c: b),
          actionButton(tool.color, calc),
          if (r != null) ResultCard(data: r!, color: tool.color),
        ],
      ),
    );
  }
}

// ---------------- Faiz ----------------

class InterestPage extends StatefulWidget {
  final Init init;
  const InterestPage({super.key, this.init});
  @override
  State<InterestPage> createState() => _InterestState();
}

class _InterestState extends State<InterestPage> {
  final p = TextEditingController();
  final rate = TextEditingController();
  final months = TextEditingController();
  int mode = 0;
  ResultData? r;

  @override
  void initState() {
    super.initState();
    applyInit(widget.init, {'p': p, 'rate': rate, 'months': months});
    mode = int.tryParse(widget.init?['mode'] ?? '') ?? 0;
  }

  void calc() {
    final P = numOf(p), y = numOf(rate), m = numOf(months);
    if (P == null || y == null || m == null) {
      warn(context, 'Tüm alanları doldur');
      return;
    }
    double total;
    if (mode == 0) {
      total = P + P * y / 100 * m / 12;
    } else {
      total = P * pow(1 + y / 100 / 12, m).toDouble();
    }
    final faiz = total - P;
    store.addHistory(
        'Faiz (${mode == 0 ? 'basit' : 'bileşik'}): ${fmt(P)} ₺, %${fmtFlex(y)}, ${fmtFlex(m)} ay → ${fmt(total)} ₺',
        tool: 'interest',
        inputs: snap({'p': p, 'rate': rate, 'months': months}, {'mode': '$mode'}));
    setState(() => r = ResultData('Vade sonu toplam', '${fmt(total)} ₺', [
          'Faiz tutarı: ${fmt(faiz)} ₺',
          'Anapara: ${fmt(P)} ₺',
        ]));
  }

  @override
  Widget build(BuildContext context) {
    final tool = toolById('interest');
    return ToolPage(
      tool: tool,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ModeChips(
            labels: const ['Basit faiz', 'Bileşik faiz (aylık)'],
            selected: mode,
            color: tool.color,
            onChanged: (i) => setState(() {
              mode = i;
              r = null;
            }),
          ),
          NumField(label: 'Anapara', c: p, suffix: '₺'),
          NumField(label: 'Yıllık faiz oranı', c: rate, suffix: '%'),
          NumField(label: 'Vade', c: months, suffix: 'ay'),
          actionButton(tool.color, calc),
          if (r != null) ResultCard(data: r!, color: tool.color),
        ],
      ),
    );
  }
}

// ---------------- Kredi ----------------

class LoanPage extends StatefulWidget {
  final Init init;
  const LoanPage({super.key, this.init});
  @override
  State<LoanPage> createState() => _LoanState();
}

class _LoanState extends State<LoanPage> {
  final amount = TextEditingController();
  final rate = TextEditingController();
  final months = TextEditingController();
  final early = TextEditingController();
  ResultData? r;
  List<List<String>> plan = [];

  @override
  void initState() {
    super.initState();
    applyInit(widget.init,
        {'amount': amount, 'rate': rate, 'months': months, 'early': early});
  }

  void calc() {
    final P = numOf(amount), y = numOf(rate), m = numOf(months);
    if (P == null || y == null || m == null || m < 1 || P <= 0) {
      warn(context, 'Tutar, faiz ve vadeyi doldur');
      return;
    }
    final n = m.round();
    final i = y / 100;
    double taksit;
    if (i == 0) {
      taksit = P / n;
    } else {
      final f = pow(1 + i, n).toDouble();
      taksit = P * i * f / (f - 1);
    }
    final toplam = taksit * n;

    final rows = <List<String>>[];
    final balances = <double>[];
    double bal = P;
    for (int mo = 1; mo <= n; mo++) {
      final faiz = bal * i;
      final ana = taksit - faiz;
      bal = max(0.0, bal - ana);
      balances.add(bal);
      rows.add([
        '$mo',
        fmt(taksit),
        fmt(ana),
        fmt(faiz),
        fmt(mo == n ? 0 : bal),
      ]);
    }

    final lines = <String>[
      'Toplam geri ödeme: ${fmt(toplam)} ₺',
      'Toplam faiz: ${fmt(toplam - P)} ₺',
    ];
    final k = numOf(early);
    if (k != null && k >= 1 && k < n) {
      final ki = k.round();
      final kalan = balances[ki - 1];
      final tasarruf = taksit * (n - ki) - kalan;
      lines.add('$ki. taksitten sonra kapatırsan ödeyeceğin kalan borç: ${fmt(kalan)} ₺');
      lines.add('Kalan faizden tasarruf: ${fmt(tasarruf)} ₺');
    } else if (k != null && (k < 1 || k >= n)) {
      lines.add('Erken kapama için 1 ile ${n - 1} arasında bir taksit sayısı gir.');
    }
    lines.add('KKDF, BSMV ve erken ödeme komisyonu dahil değildir.');

    store.addHistory(
        'Kredi: ${fmt(P)} ₺, aylık %${fmtFlex(y)}, $n ay → taksit ${fmt(taksit)} ₺',
        tool: 'loan',
        inputs: snap({
          'amount': amount,
          'rate': rate,
          'months': months,
          'early': early
        }));
    setState(() {
      plan = rows;
      r = ResultData('Aylık taksit', '${fmt(taksit)} ₺', lines);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tool = toolById('loan');
    return ToolPage(
      tool: tool,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          NumField(label: 'Kredi tutarı', c: amount, suffix: '₺'),
          NumField(label: 'Aylık faiz oranı', c: rate, suffix: '%'),
          NumField(label: 'Vade', c: months, suffix: 'ay'),
          NumField(label: 'Erken kapama: ödenen taksit sayısı (isteğe bağlı)', c: early),
          actionButton(tool.color, calc),
          if (r != null) ResultCard(data: r!, color: tool.color),
          if (r != null)
            MiniTable(
              title: 'Ödeme planı',
              headers: const ['Ay', 'Taksit', 'Anapara', 'Faiz', 'Kalan'],
              rows: plan,
            ),
        ],
      ),
    );
  }
}

// ---------------- KDV ----------------

class VatPage extends StatefulWidget {
  final Init init;
  const VatPage({super.key, this.init});
  @override
  State<VatPage> createState() => _VatState();
}

class _VatState extends State<VatPage> {
  final amount = TextEditingController();
  final rate = TextEditingController(text: '20');
  int mode = 0;
  ResultData? r;

  @override
  void initState() {
    super.initState();
    applyInit(widget.init, {'amount': amount, 'rate': rate});
    mode = int.tryParse(widget.init?['mode'] ?? '') ?? 0;
  }

  void calc() {
    final a = numOf(amount), y = numOf(rate);
    if (a == null || y == null) {
      warn(context, 'Tutar ve oranı gir');
      return;
    }
    final inputs = snap({'amount': amount, 'rate': rate}, {'mode': '$mode'});
    if (mode == 0) {
      final kdv = a * y / 100;
      store.addHistory('KDV: ${fmt(a)} ₺ + %${fmtFlex(y)} = ${fmt(a + kdv)} ₺',
          tool: 'vat', inputs: inputs);
      setState(() => r = ResultData('KDV dahil tutar', '${fmt(a + kdv)} ₺',
          ['KDV tutarı: ${fmt(kdv)} ₺', 'KDV hariç: ${fmt(a)} ₺']));
    } else {
      final net = a / (1 + y / 100);
      store.addHistory(
          'KDV: ${fmt(a)} ₺ içinden %${fmtFlex(y)} = ${fmt(net)} ₺ hariç',
          tool: 'vat',
          inputs: inputs);
      setState(() => r = ResultData('KDV hariç tutar', '${fmt(net)} ₺',
          ['KDV tutarı: ${fmt(a - net)} ₺', 'KDV dahil: ${fmt(a)} ₺']));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tool = toolById('vat');
    return ToolPage(
      tool: tool,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ModeChips(
            labels: const ['KDV ekle', 'KDV ayır'],
            selected: mode,
            color: tool.color,
            onChanged: (i) => setState(() {
              mode = i;
              r = null;
            }),
          ),
          NumField(label: 'Tutar', c: amount, suffix: '₺'),
          NumField(label: 'KDV oranı', c: rate, suffix: '%'),
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Wrap(
              spacing: 8,
              children: [
                for (final v in ['1', '10', '20'])
                  ActionChip(
                    label: Text('%$v'),
                    onPressed: () => setState(() => rate.text = v),
                  ),
              ],
            ),
          ),
          actionButton(tool.color, calc),
          if (r != null) ResultCard(data: r!, color: tool.color),
        ],
      ),
    );
  }
}

// ---------------- Yakıt ----------------

class FuelPage extends StatefulWidget {
  final Init init;
  const FuelPage({super.key, this.init});
  @override
  State<FuelPage> createState() => _FuelState();
}

class _FuelState extends State<FuelPage> {
  final km = TextEditingController();
  final cons = TextEditingController();
  final price = TextEditingController();
  final litres = TextEditingController();
  int mode = 0;
  ResultData? r;

  @override
  void initState() {
    super.initState();
    applyInit(widget.init,
        {'km': km, 'cons': cons, 'price': price, 'litres': litres});
    mode = int.tryParse(widget.init?['mode'] ?? '') ?? 0;
  }

  void calc() {
    final d = numOf(km);
    if (d == null || d <= 0) {
      warn(context, 'Mesafeyi gir');
      return;
    }
    final inputs = snap(
        {'km': km, 'cons': cons, 'price': price, 'litres': litres},
        {'mode': '$mode'});
    if (mode == 0) {
      final c = numOf(cons), p = numOf(price);
      if (c == null || p == null) {
        warn(context, 'Tüm alanları doldur');
        return;
      }
      final l = d * c / 100;
      final total = l * p;
      store.addHistory(
          'Yakıt: ${fmtFlex(d)} km, ${fmtFlex(c)} L/100km → ${fmt(total)} ₺ (km başı ${fmt(total / d)} ₺)',
          tool: 'fuel',
          inputs: inputs);
      setState(() => r = ResultData('Toplam yakıt maliyeti', '${fmt(total)} ₺', [
            'Harcanan yakıt: ${fmt(l)} L',
            'Km başı maliyet: ${fmt(total / d)} ₺',
          ]));
    } else {
      final l = numOf(litres);
      if (l == null) {
        warn(context, 'Harcanan litreyi gir');
        return;
      }
      final per100 = l / d * 100;
      store.addHistory(
          'Tüketim: ${fmtFlex(d)} km, ${fmtFlex(l)} L → ${fmt(per100)} L/100km',
          tool: 'fuel',
          inputs: inputs);
      setState(() => r = ResultData(
              'Ortalama tüketim', '${fmt(per100)} L / 100 km', [
            'Km başına: ${fmt(l / d, 3)} L',
          ]));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tool = toolById('fuel');
    return ToolPage(
      tool: tool,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ModeChips(
            labels: const ['Yol maliyeti', 'Tüketim bul'],
            selected: mode,
            color: tool.color,
            onChanged: (i) => setState(() {
              mode = i;
              r = null;
            }),
          ),
          NumField(label: 'Mesafe', c: km, suffix: 'km'),
          if (mode == 0) ...[
            NumField(label: 'Tüketim (100 km)', c: cons, suffix: 'L'),
            NumField(label: 'Litre fiyatı', c: price, suffix: '₺'),
          ] else
            NumField(label: 'Harcanan yakıt', c: litres, suffix: 'L'),
          actionButton(tool.color, calc),
          if (r != null) ResultCard(data: r!, color: tool.color),
        ],
      ),
    );
  }
}

// ---------------- BMI ----------------

class BmiPage extends StatefulWidget {
  final Init init;
  const BmiPage({super.key, this.init});
  @override
  State<BmiPage> createState() => _BmiState();
}

class _BmiState extends State<BmiPage> {
  final kg = TextEditingController();
  final cm = TextEditingController();
  ResultData? r;

  @override
  void initState() {
    super.initState();
    applyInit(widget.init, {'kg': kg, 'cm': cm});
  }

  void calc() {
    final w = numOf(kg), h = numOf(cm);
    if (w == null || h == null || h <= 0) {
      warn(context, 'Kilo ve boyu gir');
      return;
    }
    final bmi = w / pow(h / 100, 2).toDouble();
    String cat;
    if (bmi < 18.5) {
      cat = 'Zayıf';
    } else if (bmi < 25) {
      cat = 'Normal';
    } else if (bmi < 30) {
      cat = 'Fazla kilolu';
    } else {
      cat = 'Obez';
    }
    store.addHistory(
        'BMI: ${fmtFlex(w)} kg, ${fmtFlex(h)} cm → ${fmt(bmi, 1)} ($cat)',
        tool: 'bmi',
        inputs: snap({'kg': kg, 'cm': cm}));
    setState(() => r = ResultData('BMI', fmt(bmi, 1), [
          'Sınıf: $cat',
          'Genel bilgidir, tıbbi tavsiye yerine geçmez.',
        ]));
  }

  @override
  Widget build(BuildContext context) {
    final tool = toolById('bmi');
    return ToolPage(
      tool: tool,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          NumField(label: 'Kilo', c: kg, suffix: 'kg'),
          NumField(label: 'Boy', c: cm, suffix: 'cm'),
          actionButton(tool.color, calc),
          if (r != null) ResultCard(data: r!, color: tool.color),
        ],
      ),
    );
  }
}

// ---------------- Birim çevirici ----------------

const Map<String, Map<String, double>> unitCats = {
  'Uzunluk': {
    'Metre': 1.0,
    'Kilometre': 1000.0,
    'Santimetre': 0.01,
    'Milimetre': 0.001,
    'Mil': 1609.344,
    'Yard': 0.9144,
    'Fit': 0.3048,
    'İnç': 0.0254,
  },
  'Ağırlık': {
    'Kilogram': 1.0,
    'Gram': 0.001,
    'Miligram': 0.000001,
    'Ton': 1000.0,
    'Pound': 0.45359237,
    'Ons': 0.028349523125,
  },
  'Alan': {
    'Metrekare': 1.0,
    'Dönüm': 1000.0,
    'Hektar': 10000.0,
    'Kilometrekare': 1000000.0,
    'Fit kare': 0.09290304,
  },
  'Hacim': {
    'Litre': 1.0,
    'Mililitre': 0.001,
    'Metreküp': 1000.0,
    'Galon (ABD)': 3.785411784,
  },
  'Sıcaklık': {
    'Celsius': 0.0,
    'Fahrenheit': 0.0,
    'Kelvin': 0.0,
  },
};

class UnitPage extends StatefulWidget {
  final Init init;
  const UnitPage({super.key, this.init});
  @override
  State<UnitPage> createState() => _UnitState();
}

class _UnitState extends State<UnitPage> {
  final c = TextEditingController();
  String cat = 'Uzunluk';
  String from = 'Metre';
  String to = 'Kilometre';
  ResultData? r;

  @override
  void initState() {
    super.initState();
    final init = widget.init;
    if (init != null) {
      c.text = init['v'] ?? '';
      final k = init['cat'];
      if (k != null && unitCats.containsKey(k)) {
        cat = k;
        final keys = unitCats[k]!.keys;
        from = keys.contains(init['from']) ? init['from']! : keys.first;
        to = keys.contains(init['to']) ? init['to']! : keys.elementAt(1);
      }
    }
  }

  void setCat(String v) {
    final keys = unitCats[v]!.keys;
    setState(() {
      cat = v;
      from = keys.first;
      to = keys.elementAt(1);
      r = null;
    });
  }

  void calc() {
    final v = numOf(c);
    if (v == null) {
      warn(context, 'Bir değer gir');
      return;
    }
    final units = unitCats[cat]!;
    double out;
    if (cat == 'Sıcaklık') {
      double cel;
      if (from == 'Celsius') {
        cel = v;
      } else if (from == 'Fahrenheit') {
        cel = (v - 32) * 5 / 9;
      } else {
        cel = v - 273.15;
      }
      if (to == 'Celsius') {
        out = cel;
      } else if (to == 'Fahrenheit') {
        out = cel * 9 / 5 + 32;
      } else {
        out = cel + 273.15;
      }
    } else {
      out = v * units[from]! / units[to]!;
    }
    store.addHistory('Çevirici: ${fmtFlex(v)} $from = ${fmtFlex(out)} $to',
        tool: 'units',
        inputs: {'v': c.text, 'cat': cat, 'from': from, 'to': to});
    setState(() => r = ResultData('$from → $to', '${fmtFlex(out)} $to'));
  }

  Widget dropdown(String label, String value, ValueChanged<String> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(label),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButton<String>(
              isExpanded: true,
              underline: const SizedBox(),
              value: value,
              items: [
                for (final k in unitCats[cat]!.keys)
                  DropdownMenuItem(value: k, child: Text(k)),
              ],
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tool = toolById('units');
    return ToolPage(
      tool: tool,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final k in unitCats.keys)
                  ChoiceChip(
                    label: Text(k),
                    selected: cat == k,
                    selectedColor: tool.color.withAlpha(70),
                    onSelected: (_) => setCat(k),
                  ),
              ],
            ),
          ),
          NumField(label: 'Değer', c: c, allowNegative: cat == 'Sıcaklık'),
          dropdown('Kaynak', from, (v) => setState(() => from = v)),
          dropdown('Hedef', to, (v) => setState(() => to = v)),
          actionButton(tool.color, calc, 'Çevir'),
          if (r != null) ResultCard(data: r!, color: tool.color),
        ],
      ),
    );
  }
}
