// Advanced Flutter UI (single-file prototype)
// File: advanced_flutter_ui.dart
// Purpose: Modern, stylish UI for a Fake Message & URL Detector
// Notes: This is a single-file prototype containing main app + three screens
// To use in a real project, split widgets into separate files and wire real detection logic.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDark = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuMail Detector',
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo, brightness: Brightness.dark),
        brightness: Brightness.dark,
      ),
      home: MainScaffold(
        isDark: _isDark,
        onThemeToggle: () => setState(() => _isDark = !_isDark),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScaffold extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isDark;
  const MainScaffold({Key? key, required this.onThemeToggle, required this.isDark}) : super(key: key);

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> with TickerProviderStateMixin {
  int _index = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTapped(int i) {
    setState(() => _index = i);
    _pageController.animateToPage(i, duration: const Duration(milliseconds: 350), curve: Curves.ease);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          HomeScreen(onShowResult: _openResult),
          HistoryScreen(onShowResult: _openResult),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BottomNavigationBar(
            currentIndex: _index,
            selectedItemColor: Theme.of(context).colorScheme.secondary,
            unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            onTap: _onNavTapped,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
            ],
            backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.95),
            elevation: 12,
            type: BottomNavigationBarType.fixed,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAssistant(),
        icon: const Icon(Icons.smart_toy),
        label: const Text('AI Assistant'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  void _openAssistant() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const AssistantSheet(),
    );
  }

  void _openResult(DetectionResult result) {
    Navigator.of(context).push(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 450),
      reverseTransitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
        opacity: animation,
        child: ResultScreen(result: result),
      ),
    ));
  }
}

// -------------------------------
// Models
// -------------------------------
class DetectionResult {
  final String title;
  final String snippet;
  final String url;
  final double phishingScore; // 0..1
  final DateTime time;

  DetectionResult({
    required this.title,
    required this.snippet,
    required this.url,
    required this.phishingScore,
    required this.time,
  });
}

// -------------------------------
// Home Screen
// -------------------------------
class HomeScreen extends StatefulWidget {
  final void Function(DetectionResult) onShowResult;
  const HomeScreen({Key? key, required this.onShowResult}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _inputCtl = TextEditingController();
  bool _scanning = false;
  DetectionResult? _lastResult;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const StylizedBackground(),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Hero(tag: 'logo', child: CircleAvatar(radius: 22, child: Icon(Icons.shield))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('QuMail Detector', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 2),
                          Text('Protecting you from fake messages & malicious links', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showQuickActions(),
                      icon: const Icon(Icons.more_vert),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                _buildInputCard(context),
                const SizedBox(height: 18),
                _buildQuickStats(context),
                const SizedBox(height: 12),
                Expanded(child: _buildRecentList(context)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputCard(BuildContext context) {
    return Hero(
      tag: 'scanCard',
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              TextField(
                controller: _inputCtl,
                decoration: InputDecoration(
                  hintText: 'Paste message text or URL here...',
                  prefixIcon: const Icon(Icons.link),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.paste),
                    onPressed: () async {
                      var data = await Clipboard.getData('text/plain');
                      if (data?.text != null) {
                        _inputCtl.text = data!.text!;
                      }
                    },
                  ),
                ),
                minLines: 1,
                maxLines: 4,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: _scanning ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.search),
                      label: Text(_scanning ? 'Scanning...' : 'Scan Now'),
                      onPressed: _scanning ? null : _onScan,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () => _showExamples(),
                    child: const Icon(Icons.remove_red_eye),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    // Small cards for quick stats
    return Row(
      children: [
        Expanded(
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(children: const [Text('Scanned Today', style: TextStyle(fontSize: 12)), SizedBox(height: 6), Text('128', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))]),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(children: const [Text('Threats Blocked', style: TextStyle(fontSize: 12)), SizedBox(height: 6), Text('23', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentList(BuildContext context) {
    // sample recent items
    final samples = List.generate(6, (i) => DetectionResult(
          title: 'Message #${i + 1}',
          snippet: 'This message contains a suspicious link. Looks like phishing attempt.',
          url: 'http://bit.ly/fake${i + 1}',
          phishingScore: (i + 1) / 10.0,
          time: DateTime.now().subtract(Duration(minutes: i * 15)),
        ));

    return ListView.builder(
      itemCount: samples.length,
      itemBuilder: (context, idx) {
        final r = samples[idx];
        return ListTile(
          leading: CircleAvatar(child: Icon(r.phishingScore > 0.5 ? Icons.warning_amber_rounded : Icons.check_circle)),
          title: Text(r.title),
          subtitle: Text(r.snippet, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Text('${r.phishingScore * 100 ~/ 1}%'),
          onTap: () => widget.onShowResult(r),
        );
      },
    );
  }

  void _onScan() async {
    final input = _inputCtl.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter message text or URL')));
      return;
    }
    setState(() => _scanning = true);
    await Future.delayed(const Duration(milliseconds: 700)); // simulate work

    // Naive demo scoring: phishing if contains suspicious words or a shortener
    double score = 0.05;
    final lower = input.toLowerCase();
    if (lower.contains('verify') || lower.contains('password') || lower.contains('urgent') || lower.contains('click')) score += 0.4;
    if (lower.contains('bit.ly') || lower.contains('tinyurl') || lower.contains('lnkd.in')) score += 0.3;
    if (lower.contains('http') && !lower.contains('https')) score += 0.15;
    score = score.clamp(0.0, 0.99);

    final result = DetectionResult(
      title: input.length > 40 ? input.substring(0, 40) + '...' : input,
      snippet: input.length > 120 ? input.substring(0, 120) + '...' : input,
      url: input,
      phishingScore: double.parse((score).toStringAsFixed(2)),
      time: DateTime.now(),
    );

    setState(() {
      _lastResult = result;
      _scanning = false;
    });

    widget.onShowResult(result);
  }

  void _showExamples() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Example Inputs'),
        content: Column(mainAxisSize: MainAxisSize.min, children: const [Text('1) http://bit.ly/abcd'), Text('2) "Verify your account password"'), Text('3) https://example.com/safe')]),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _showQuickActions() {
    showModalBottomSheet(context: context, builder: (_) => ListView(shrinkWrap: true, children: [ListTile(leading: const Icon(Icons.info), title: const Text('About detector'), subtitle: const Text('Scans message text and URLs for suspicious patterns'), onTap: () {}), ListTile(leading: const Icon(Icons.settings), title: const Text('Settings'), onTap: () {})]));
  }
}

// -------------------------------
// History Screen
// -------------------------------
class HistoryScreen extends StatefulWidget {
  final void Function(DetectionResult) onShowResult;
  const HistoryScreen({Key? key, required this.onShowResult}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _search = TextEditingController();
  String _filter = 'All';
  List<DetectionResult> _history = [];

  @override
  void initState() {
    super.initState();
    _history = List.generate(20, (i) => DetectionResult(
      title: 'History ${i+1}',
      snippet: 'Sample history entry #${i+1} — suspicious link found',
      url: 'http://phish${i+1}.com',
      phishingScore: Random().nextDouble(),
      time: DateTime.now().subtract(Duration(hours: i*3)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _history.where((h) {
      final q = _search.text.toLowerCase();
      if (q.isNotEmpty && !(h.title.toLowerCase().contains(q) || h.snippet.toLowerCase().contains(q) || h.url.toLowerCase().contains(q))) return false;
      if (_filter == 'Threats' && h.phishingScore < 0.5) return false;
      if (_filter == 'Safe' && h.phishingScore >= 0.5) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Scan History'),
        actions: [
          IconButton(onPressed: _exportAll, icon: const Icon(Icons.upload_file)),
          PopupMenuButton<String>(
            onSelected: (v) => setState(() => _filter = v),
            itemBuilder: (_) => const [PopupMenuItem(value: 'All', child: Text('All')), PopupMenuItem(value: 'Threats', child: Text('Threats')), PopupMenuItem(value: 'Safe', child: Text('Safe'))],
          )
        ],
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Column(children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
              child: Row(children: [
                const Icon(Icons.search),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _search, decoration: const InputDecoration.collapsed(hintText: 'Search history...'), onChanged: (_) => setState(() {}))),
                IconButton(onPressed: () => setState(() { _search.clear(); }), icon: const Icon(Icons.clear)),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: ListView.separated(
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, idx) {
              final r = filtered[idx];
              return ListTile(
                leading: CircleAvatar(child: Icon(r.phishingScore > 0.5 ? Icons.warning : Icons.check)),
                title: Text(r.title),
                subtitle: Text(r.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Wrap(spacing: 6, children: [Text('${(r.phishingScore*100).toInt()}%'), IconButton(icon: const Icon(Icons.share), onPressed: () => _shareResult(r))]),
                onTap: () => widget.onShowResult(r),
              );
            },
          )),
        ]),
      ),
    );
  }

  void _shareResult(DetectionResult r) {
    Share.share('Scan result: ${r.title}\nURL: ${r.url}\nRisk: ${(r.phishingScore*100).toInt()}%');
  }

  void _exportAll() {
    // For demo: just build a simple CSV string and share
    final csv = StringBuffer();
    csv.writeln('title,url,score,time');
    for (var h in _history) {
      csv.writeln('"${h.title}","${h.url}",${h.phishingScore},"${h.time.toIso8601String()}"');
    }
    Share.share(csv.toString(), subject: 'QuMail Scan History');
  }
}

// -------------------------------
// Result Screen
// -------------------------------
class ResultScreen extends StatelessWidget {
  final DetectionResult result;
  const ResultScreen({Key? key, required this.result}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isThreat = result.phishingScore >= 0.5;
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Result'),
        actions: [IconButton(icon: const Icon(Icons.share), onPressed: () => _share(context)), IconButton(icon: const Icon(Icons.open_in_new), onPressed: () {})],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(children: [
        const StylizedBackground(),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Hero(tag: 'logo', child: CircleAvatar(radius: 28, child: Icon(isThreat ? Icons.warning_amber_rounded : Icons.shield))),
                const SizedBox(width: 12),
                Expanded(child: Text(result.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                Chip(label: Text(isThreat ? 'Threat' : 'Safe'))
              ]),
              const SizedBox(height: 18),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('URL / Message', style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 8),
                    SelectableText(result.url),
                    const SizedBox(height: 12),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Risk Score', style: Theme.of(context).textTheme.labelSmall), const SizedBox(height: 6), Text('${(result.phishingScore*100).toInt()}%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))]),
                      SizedBox(width: 120, height: 120, child: RiskGauge(score: result.phishingScore)),
                    ]),
                    const SizedBox(height: 12),
                    Text('Analysis', style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 8),
                    Text(result.snippet),
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, children: [
                      ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.block), label: const Text('Block Sender')),
                      OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.open_in_new), label: const Text('Open Safely')),
                    ])
                  ]),
                ),
              ),
              const SizedBox(height: 18),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                    Text('Suggested Actions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('\u2022 Don\'t click suspicious links.'),
                    Text('\u2022 Report sender to your provider.'),
                    Text('\u2022 Change passwords if you clicked and entered credentials.'),
                  ]),
                ),
              )
            ]),
          ),
        )
      ]),
    );
  }

  void _share(BuildContext context) {
    Share.share('Scan: ${result.title}\nURL: ${result.url}\nRisk: ${(result.phishingScore*100).toInt()}%');
  }
}

// -------------------------------
// Settings Screen (simple)
// -------------------------------
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Settings'), backgroundColor: Colors.transparent, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(children: [
          Card(child: ListTile(leading: const Icon(Icons.shield), title: const Text('Detection Sensitivity'), subtitle: const Text('Medium'), trailing: const Icon(Icons.keyboard_arrow_right))),
          const SizedBox(height: 12),
          Card(child: ListTile(leading: const Icon(Icons.history), title: const Text('Manage History'), subtitle: const Text('Export or clear logs'), trailing: const Icon(Icons.delete_forever))),
        ]),
      ),
    );
  }
}

// -------------------------------
// Assistant Sheet
// -------------------------------
class AssistantSheet extends StatelessWidget {
  const AssistantSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(4))),
        const SizedBox(height: 12),
        Row(children: const [CircleAvatar(child: Icon(Icons.smart_toy)), SizedBox(width: 12), Text('AI Assistant', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]),
        const SizedBox(height: 12),
        const Text('How can I help? You can ask the assistant to:'),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          ActionChip(label: const Text('Explain result'), onPressed: () {}),
          ActionChip(label: const Text('Suggest actions'), onPressed: () {}),
          ActionChip(label: const Text('Show similar cases'), onPressed: () {}),
        ]),
        const SizedBox(height: 12),
      ]),
    );
  }
}

// -------------------------------
// Stylized Background (glassmorphism + gradient)
// -------------------------------
class StylizedBackground extends StatelessWidget {
  const StylizedBackground({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary.withOpacity(0.12), scheme.secondary.withOpacity(0.06)],
        ),
      ),
      child: Stack(children: [
        // subtle blurred shapes
        Positioned(top: -60, left: -40, child: _blob(220, 120)),
        Positioned(bottom: -80, right: -50, child: _blob(260, 140)),
      ]),
    );
  }

  Widget _blob(double w, double h) => Container(width: w, height: h, decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(120)));
}

// -------------------------------
// Risk Gauge (simple donut)
// -------------------------------
class RiskGauge extends StatelessWidget {
  final double score; // 0..1
  const RiskGauge({Key? key, required this.score}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GaugePainter(score),
      child: Center(child: Text('${(score*100).toInt()}%')),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double score;
  _GaugePainter(this.score);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = min(size.width, size.height) / 2 - 6;
    final stroke = Paint()..style = PaintingStyle.stroke..strokeWidth = 12..strokeCap = StrokeCap.round..color = Colors.grey.withOpacity(0.25);
    canvas.drawCircle(center, radius, stroke);

    final sweep = 2 * pi * score;
    final prog = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(colors: [Colors.green, Colors.yellow, Colors.red]).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi/2, sweep, false, prog);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// End of file
