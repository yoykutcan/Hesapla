import 'dart:math';

// 2026 yasal parametreleri. Yıl veya dönem değişince yalnızca bu dosyayı güncelle.
const double asgariBrut = 33030.0; // Aylık brüt asgari ücret
const double sgkTavan = 297270.0; // SGK prime esas kazanç üst sınırı (aylık)
const double sgkIsci = 0.14; // SGK işçi payı
const double issizlikIsci = 0.01; // İşsizlik sigortası işçi payı
const double damgaOrani = 0.00759; // Damga vergisi
const double kidemTavan = 73729.84; // Kıdem tazminatı tavanı (1 Temmuz - 31 Aralık 2026)

// Ücret geliri tarifesi: [dilim üst sınırı, oran]
final List<List<double>> gvDilimleri = [
  [190000.0, 0.15],
  [400000.0, 0.20],
  [1500000.0, 0.27],
  [5300000.0, 0.35],
  [double.infinity, 0.40],
];

double gelirVergisi(double matrah) {
  if (matrah <= 0) return 0;
  double tax = 0, prev = 0;
  for (final d in gvDilimleri) {
    final upper = d[0], rate = d[1];
    if (matrah > upper) {
      tax += (upper - prev) * rate;
      prev = upper;
    } else {
      tax += (matrah - prev) * rate;
      break;
    }
  }
  return tax;
}

class MonthRow {
  final double brut, sgk, issizlik, gv, damga, net;
  MonthRow(this.brut, this.sgk, this.issizlik, this.gv, this.damga, this.net);
}

// Kümülatif matrahla 12 aylık bordro. Asgari ücret gelir ve damga vergisi istisnası dahil.
List<MonthRow> hesaplaYil(double brut) {
  final rows = <MonthRow>[];
  final minSgk = min(asgariBrut, sgkTavan) * (sgkIsci + issizlikIsci);
  final minMatrah = asgariBrut - minSgk;
  double cum = 0, cumMin = 0, prevTax = 0, prevMinTax = 0;
  for (int i = 0; i < 12; i++) {
    final base = min(brut, sgkTavan);
    final sgk = base * sgkIsci;
    final iss = base * issizlikIsci;
    cum += brut - sgk - iss;
    final tax = gelirVergisi(cum);
    final gv = tax - prevTax;
    prevTax = tax;
    cumMin += minMatrah;
    final minTax = gelirVergisi(cumMin);
    final istisna = minTax - prevMinTax;
    prevMinTax = minTax;
    final gvNet = max(0.0, gv - istisna);
    final damga = max(0.0, (brut - asgariBrut) * damgaOrani);
    rows.add(MonthRow(brut, sgk, iss, gvNet, damga, brut - sgk - iss - gvNet - damga));
  }
  return rows;
}
