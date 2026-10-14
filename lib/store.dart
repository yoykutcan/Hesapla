import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppStore extends ChangeNotifier {
  SharedPreferences? _p;
  Set<String> favorites = {};
  List<String> history = [];
  ThemeMode themeMode = ThemeMode.light;

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    favorites = (_p!.getStringList('fav') ?? []).toSet();
    history = _p!.getStringList('hist') ?? [];
    themeMode = _p!.getBool('dark') == true ? ThemeMode.dark : ThemeMode.light;
  }

  void toggleFav(String id) {
    if (!favorites.remove(id)) favorites.add(id);
    _p?.setStringList('fav', favorites.toList());
    notifyListeners();
  }

  void addHistory(String s) {
    history.insert(0, s);
    if (history.length > 50) history = history.sublist(0, 50);
    _p?.setStringList('hist', history);
    notifyListeners();
  }

  void clearHistory() {
    history = [];
    _p?.setStringList('hist', history);
    notifyListeners();
  }

  void setDark(bool v) {
    themeMode = v ? ThemeMode.dark : ThemeMode.light;
    _p?.setBool('dark', v);
    notifyListeners();
  }
}

final AppStore store = AppStore();

double? numOf(TextEditingController c) =>
    double.tryParse(c.text.trim().replaceAll(',', '.'));

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

void warn(BuildContext c, String m) {
  ScaffoldMessenger.of(c)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));
}

bool isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;

Color cardColor(BuildContext c) => isDark(c)
    ? const Color(0xFF2A2652).withAlpha(210)
    : Colors.white.withAlpha(215);

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
}

class ResultCard extends StatelessWidget {
  final ResultData data;
  final Color color;
  const ResultCard({super.key, required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(18),
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
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
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
  const NumField({super.key, required this.label, required this.c, this.suffix});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
