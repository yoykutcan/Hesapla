import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'store.dart';
import 'tools.dart';

// Reklam eklerken alt bardaki banner alanını açmak için true yap.
const bool showAdSlot = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await store.load();
  runApp(const App());
}

ThemeData _theme(Brightness b) => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6C63FF),
        brightness: b,
      ),
    );

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (_, __) => MaterialApp(
        title: 'Hesapla',
        debugShowCheckedModeBanner: false,
        locale: const Locale('tr', 'TR'),
        supportedLocales: const [Locale('tr', 'TR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        themeMode: store.themeMode,
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        home: const Shell(),
      ),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    return GradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: IndexedStack(
            index: tab,
            children: const [
              HomePage(),
              FavoritesPage(),
              HistoryPage(),
              SettingsPage(),
            ],
          ),
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showAdSlot)
              Container(
                height: 50,
                width: double.infinity,
                alignment: Alignment.center,
                color: Colors.black12,
                child: const Text('Reklam alanı'),
              ),
            NavigationBar(
              backgroundColor: cardColor(context),
              selectedIndex: tab,
              onDestinationSelected: (i) => setState(() => tab = i),
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: 'Ana sayfa'),
                NavigationDestination(
                    icon: Icon(Icons.star_border_rounded),
                    selectedIcon: Icon(Icons.star_rounded),
                    label: 'Favoriler'),
                NavigationDestination(
                    icon: Icon(Icons.history_rounded),
                    selectedIcon: Icon(Icons.history_rounded),
                    label: 'Geçmiş'),
                NavigationDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings_rounded),
                    label: 'Ayarlar'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ToolGrid extends StatelessWidget {
  final List<Tool> list;
  const ToolGrid({super.key, required this.list});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: list.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (_, i) => ToolCard(t: list[i]),
    );
  }
}

class ToolCard extends StatelessWidget {
  final Tool t;
  const ToolCard({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (ctx, _) {
        final fav = store.favorites.contains(t.id);
        return Material(
          color: cardColor(ctx),
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => Navigator.push(
                ctx, MaterialPageRoute(builder: (_) => t.page(null))),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: t.color.withAlpha(45),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(t.icon, color: t.color, size: 24),
                      ),
                      InkResponse(
                        onTap: () => store.toggleFav(t.id),
                        child: Icon(
                          fav ? Icons.star_rounded : Icons.star_border_rounded,
                          color: fav ? const Color(0xFFF5B301) : null,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(t.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(t.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomeState();
}

class _HomeState extends State<HomePage> {
  String query = '';
  String cat = 'Tümü';
  static const cats = ['Tümü', 'Finans', 'Günlük', 'Sağlık'];

  @override
  Widget build(BuildContext context) {
    final q = query.toLowerCase();
    final list = tools
        .where((t) =>
            (cat == 'Tümü' || t.category == cat) &&
            (q.isEmpty || t.title.toLowerCase().contains(q)))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Text('Hesaplama araçları',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => query = v),
            decoration: InputDecoration(
              hintText: 'Araç ara',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: cardColor(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final c in cats)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(c),
                    selected: cat == c,
                    onSelected: (_) => setState(() => cat = c),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text('Araç bulunamadı'))
              : ToolGrid(list: list),
        ),
      ],
    );
  }
}

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (_, __) {
        final list =
            tools.where((t) => store.favorites.contains(t.id)).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text('Favoriler',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600)),
            ),
            Expanded(
              child: list.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'Sık kullandığın araçlara yıldız koy, burada hızlıca bul.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ToolGrid(list: list),
            ),
          ],
        );
      },
    );
  }
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (ctx, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Geçmiş',
                      style:
                          TextStyle(fontSize: 26, fontWeight: FontWeight.w600)),
                  if (store.history.isNotEmpty)
                    TextButton(
                        onPressed: store.clearHistory,
                        child: const Text('Temizle')),
                ],
              ),
            ),
            Expanded(
              child: store.history.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'Yaptığın hesaplar burada görünür. Birine dokununca aracı aynı değerlerle açar.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: store.history.length,
                      itemBuilder: (_, i) {
                        final h = store.history[i];
                        final known =
                            tools.where((t) => t.id == h.tool).toList();
                        final tool = known.isEmpty ? null : known.first;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: cardColor(ctx),
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: tool == null
                                  ? null
                                  : () => Navigator.push(
                                      ctx,
                                      MaterialPageRoute(
                                          builder: (_) => tool.page(h.inputs))),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    if (tool != null)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 12),
                                        child: Icon(tool.icon,
                                            color: tool.color, size: 22),
                                      ),
                                    Expanded(child: Text(h.text)),
                                    if (tool != null)
                                      const Icon(Icons.chevron_right_rounded),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (ctx, _) => _settingsBody(ctx),
    );
  }

  Widget _settingsBody(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 0, 4, 12),
          child: Text('Ayarlar',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600)),
        ),
        Container(
          decoration: BoxDecoration(
            color: cardColor(context),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Koyu tema'),
                value: store.themeMode == ThemeMode.dark,
                onChanged: store.setDark,
              ),
              const ListTile(
                title: Text('Sürüm'),
                trailing: Text('1.1.0'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
