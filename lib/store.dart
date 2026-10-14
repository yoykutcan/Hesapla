import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class HistoryItem {
  final String text;
  final String? tool;
  final Map<String, String> inputs;
  HistoryItem(this.text, {this.tool, this.inputs = const {}});

  String encode() => jsonEncode({'t': text, 'k': tool, 'i': inputs});

  static HistoryItem decode(String s) {
    try {
      final m = jsonDecode(s);
      if (m is Map) {
        final raw = (m['i'] as Map?) ?? {};
        return HistoryItem(
          m['t'] as String,
          tool: m['k'] as String?,
          inputs: raw.map((k, v) => MapEntry(k.toString(), v.toString())),
        );
      }
    } catch (_) {}
    return HistoryItem(s);
  }
}

class AppStore extends ChangeNotifier {
  SharedPreferences? _p;
  Set<String> favorites = {};
  List<HistoryItem> history = [];
  ThemeMode themeMode = ThemeMode.light;

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    favorites = (_p!.getStringList('fav') ?? []).toSet();
    history = (_p!.getStringList('hist') ?? []).map(HistoryItem.decode).toList();
    themeMode = _p!.getBool('dark') == true ? ThemeMode.dark : ThemeMode.light;
  }

  void _saveHistory() =>
      _p?.setStringList('hist', history.map((h) => h.encode()).toList());

  void toggleFav(String id) {
    if (!favorites.remove(id)) favorites.add(id);
    _p?.setStringList('fav', favorites.toList());
    notifyListeners();
  }

  void addHistory(String text, {String? tool, Map<String, String>? inputs}) {
    history.insert(0, HistoryItem(text, tool: tool, inputs: inputs ?? const {}));
    if (history.length > 50) history = history.sublist(0, 50);
    _saveHistory();
    notifyListeners();
  }

  void clearHistory() {
    history = [];
    _saveHistory();
    notifyListeners();
  }

  void setDark(bool v) {
    themeMode = v ? ThemeMode.dark : ThemeMode.light;
    _p?.setBool('dark', v);
    notifyListeners();
  }
}

final AppStore store = AppStore();

// ---------- Sayı ve tarih yardımcıları ----------

double? numOf(TextEditingController c) => double.tryParse(
    c.text.trim().replaceAll('.', '').replaceAll(',', '.'));

String fmt(double v, [int d = 2]) {
  final neg = v < 0;
  final s = v.abs().toStringAsFixed(d);
  final parts = s.split('.');
  final ip = parts[0];
  final buf = StringBuffer();
  for (int i = 0; i < ip.length; i++) {
    if (i > 0 && (ip.length - i) % 3 == 0) buf.write('.');
    buf.write(ip[i]);
  }
  final r = d > 0 ? '$buf,${parts[1]}' : buf.toString();
  return neg ? '-$r' : r;
}

String fmtFlex(double v) {
  if (v == 0) return '0';
  if (v.abs() >= 1e12 || v.abs() < 1e-6) {
    return v.toStringAsExponential(4).replaceAll('.', ',');
  }
  var s = v.toStringAsFixed(6);
  if (s.contains('.')) {
    s = s.replaceAll(RegExp(r'0+$'), '');
    s = s.replaceAll(RegExp(r'\.$'), '');
  }
  return s.replaceAll('.', ',');
}

String _two(int n) => n.toString().padLeft(2, '0');
String fmtDate(DateTime d) => '${_two(d.day)}.${_two(d.month)}.${d.year}';
String dateKey(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';
DateTime? parseDateKey(String? s) => s == null ? null : DateTime.tryParse(s);

const weekdaysTr = [
  'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'
];

void warn(BuildContext c, String m) {
  ScaffoldMessenger.of(c)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));
}

void applyInit(Map<String, String>? init, Map<String, TextEditingController> f) {
  if (init == null) return;
  f.forEach((k, c) {
    final v = init[k];
    if (v != null) c.text = v;
  });
}

Map<String, String> snap(Map<String, TextEditingController> f,
    [Map<String, String>? extra]) {
  final m = {for (final e in f.entries) e.key: e.value.text};
  if (extra != null) m.addAll(extra);
  return m;
}

bool isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;

Color cardColor(BuildContext c) => isDark(c)
    ? const Color(0xFF2A2652).withAlpha(210)
    : Colors.white.withAlpha(215);

// ---------- Binlik ayraçlı sayı girişi ----------

class ThousandsFormatter extends TextInputFormatter {
  final bool allowNegative;
  ThousandsFormatter({this.allowNegative = false});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;
    var cursor = newValue.selection.baseOffset;
    if (cursor < 0 || cursor > text.length) cursor = text.length;
    if (text.length == oldValue.text.length + 1 &&
        cursor > 0 &&
        text[cursor - 1] == '.') {
      text = text.replaceRange(cursor - 1, cursor, ',');
    }
    final neg = allowNegative && text.startsWith('-');
    final keep = RegExp(r'[0-9,]');
    int sig = 0;
    for (int i = 0; i < cursor && i < text.length; i++) {
      if (keep.hasMatch(text[i])) sig++;
    }
    final clean = text.replaceAll(RegExp(r'[^0-9,]'), '');
    final ci = clean.indexOf(',');
    var ip = ci >= 0 ? clean.substring(0, ci) : clean;
    final dp = ci >= 0 ? clean.substring(ci + 1).replaceAll(',', '') : '';
    ip = ip.replaceFirst(RegExp(r'^0+(?=[0-9])'), '');
    if (ci >= 0 && ip.isEmpty) {
      ip = '0';
      sig++;
    }
    final buf = StringBuffer();
    for (int i = 0; i < ip.length; i++) {
      if (i > 0 && (ip.length - i) % 3 == 0) buf.write('.');
      buf.write(ip[i]);
    }
    final out = (neg ? '-' : '') + buf.toString() + (ci >= 0 ? ',$dp' : '');
    int pos = 0;
    if (sig == 0) {
      pos = neg ? 1 : 0;
    } else {
      int count = 0;
      pos = out.length;
      for (int i = 0; i < out.length; i++) {
        if (keep.hasMatch(out[i])) count++;
        if (count == sig) {
          pos = i + 1;
          break;
        }
      }
    }
    if (pos > out.length) pos = out.length;
    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: pos),
    );
  }
}

// ---------- Ortak arayüz parçaları ----------

class GradientBg extends StatelessWidget {
  final Widget child;
  const GradientBg({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF1E1A4A), Color(0xFF0F2F45), Color(0xFF3A1737)]
              : const [Color(0xFFD9D2FF), Color(0xFFC9E8FF), Color(0xFFFFD9EC)],
        ),
      ),
      child: child,
    );
  }
}

class ResultData {
  final String label;
  final String main;
  final List<String> lines;
  const ResultData(this.label, this.main, [this.lines = const []]);

  String get shareText =>
      '$label: $main${lines.isEmpty ? '' : '\n${lines.join('\n')}'}\n\nHesapla uygulaması ile hesaplandı';
}

class ResultCard extends StatelessWidget {
  final ResultData data;
  final Color color;
  const ResultCard({super.key, required this.data, required this.color});

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: data.shareText));
    if (context.mounted) warn(context, 'Sonuç kopyalandı');
  }

  Future<void> _whatsapp(BuildContext context) async {
    final uri =
        Uri.parse('https://wa.me/?text=${Uri.encodeComponent(data.shareText)}');
    bool ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!ok && context.mounted) warn(context, 'WhatsApp açılamadı');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.fromLTRB(18, 18, 10, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.25)!],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.label,
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(data.main,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w600)),
                ),
                if (data.lines.isNotEmpty) const SizedBox(height: 10),
                for (final l in data.lines)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(l,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                onPressed: () => _copy(context),
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Kopyala'),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                onPressed: () => _whatsapp(context),
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text('WhatsApp'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class NumField extends StatelessWidget {
  final String label;
  final TextEditingController c;
  final String? suffix;
  final bool allowNegative;
  const NumField({
    super.key,
    required this.label,
    required this.c,
    this.suffix,
    this.allowNegative = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: TextInputType.numberWithOptions(
            decimal: true, signed: allowNegative),
        inputFormatters: [ThousandsFormatter(allowNegative: allowNegative)],
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          filled: true,
          fillColor: cardColor(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: cardColor(context),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
            );
            if (d != null) onChanged(d);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                      Text(value == null ? 'Tarih seç' : fmtDate(value!),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ModeChips extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final Color color;
  final ValueChanged<int> onChanged;
  const ModeChips({
    super.key,
    required this.labels,
    required this.selected,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (int i = 0; i < labels.length; i++)
            ChoiceChip(
              label: Text(labels[i]),
              selected: selected == i,
              selectedColor: color.withAlpha(70),
              onSelected: (_) => onChanged(i),
            ),
        ],
      ),
    );
  }
}

class MiniTable extends StatelessWidget {
  final String title;
  final List<String> headers;
  final List<List<String>> rows;
  const MiniTable({
    super.key,
    required this.title,
    required this.headers,
    required this.rows,
  });

  Widget _row(List<String> cells, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          for (int i = 0; i < cells.length; i++)
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: i == 0 ? Alignment.centerLeft : Alignment.centerRight,
                child: Text(cells[i],
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: bold ? FontWeight.w600 : FontWeight.w400)),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: cardColor(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(title),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Column(
                children: [
                  _row(headers, bold: true),
                  for (final r in rows) _row(r),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CalcButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final Color? bg;
  final Color? fg;
  const CalcButton({
    super.key,
    required this.text,
    required this.onTap,
    this.bg,
    this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Material(
          color: bg ?? cardColor(context),
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Center(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                      color: fg ?? Theme.of(context).colorScheme.onSurface)),
            ),
          ),
        ),
      ),
    );
  }
}
