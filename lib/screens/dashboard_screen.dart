import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/models.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'app_drawer.dart';
import 'calls_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';

/// Bottom-bar destinations. [play] isn't a tab: it opens the calling queue.
enum _Tab { home, contacts, play, callLog, schedule }

/// Dashboard with header actions and the 5-item bottom bar.
///
/// Home shows "Load number to call" until a list is picked in Settings, then
/// that list's stats. Contacts / Call log / Schedule show the loaded list's
/// calls filtered by status, so they work on real API data.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  _Tab _tab = _Tab.home;
  bool _loading = false;
  String? _error;
  CallList? _list;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = Session.selectedListId;
    if (id == null) {
      setState(() => _list = null);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final lists = extractList(await Api.lists(Session.userId)).map(CallList.fromJson).toList();
      final summary = lists.firstWhere((l) => l.id == id,
          orElse: () => lists.isNotEmpty ? lists.first : CallList(id, 'Calling List', 0, 0, 0, 0, const []));
      _list = await summary.withDetails();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openSettings() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
    if (mounted) _load();
  }

  void _openNotifications() =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));

  void _startCalling() {
    final l = _list;
    if (l == null) {
      toast(context, 'Select a calling list in Settings first');
      _openSettings();
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => CallsScreen(list: l)));
  }

  void _onNav(_Tab t) {
    if (t == _Tab.play) return _startCalling();
    if (t == _tab) return; // already here: no duplicate rebuild/push
    setState(() => _tab = t);
  }

  String get _title => switch (_tab) {
        _Tab.contacts => 'Contacts',
        _Tab.callLog => 'Call Log',
        _Tab.schedule => 'Schedule',
        _ => 'Dashboard',
      };

  @override
  Widget build(BuildContext context) => PopScope(
        // Android back on a non-Home tab returns to Home instead of leaving.
        canPop: _tab == _Tab.home,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) setState(() => _tab = _Tab.home);
        },
        child: Scaffold(
          drawer: AppDrawer(onSettings: _openSettings, onSync: _load),
          appBar: AppBar(
            titleSpacing: 0,
            leading: Builder(
              builder: (c) => IconButton(
                tooltip: 'Menu',
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(c).openDrawer(),
              ),
            ),
            title: Text(_title),
            actions: [
              IconButton(
                tooltip: 'Support',
                icon: const Icon(Icons.headset_mic_outlined, size: 22),
                onPressed: () => openSupport(context),
              ),
              IconButton(
                tooltip: 'Notifications',
                icon: const Icon(Icons.notifications_none, size: 22),
                onPressed: _openNotifications,
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: SafeArea(
            bottom: false,
            child: Padding(padding: const EdgeInsets.fromLTRB(12, 4, 12, 12), child: _body()),
          ),
          bottomNavigationBar: _BottomBar(selected: _tab, onTap: _onNav),
        ),
      );

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _errorView();
    if (_tab == _Tab.home) return _list == null ? _loadNumbersView() : _statsView(_list!);
    final l = _list;
    if (l == null) return _pickListPrompt();
    return switch (_tab) {
      _Tab.contacts => CallTiles(calls: l.calls, emptyText: 'No contacts in ${l.name}'),
      _Tab.callLog => CallTiles(calls: filterCalls(l.calls, CallFilter.called), emptyText: 'No calls made yet'),
      _ => CallTiles(
          calls: filterCalls(l.calls, CallFilter.scheduled),
          showSchedule: true,
          emptyText: 'No scheduled calls'),
    };
  }

  Widget _errorView() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off, size: 44, color: C.muted),
          const SizedBox(height: 10),
          Text(_error!, textAlign: TextAlign.center),
          TextButton(onPressed: _load, child: const Text('Retry')),
        ]),
      );

  Widget _pickListPrompt() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.list_alt, size: 44, color: C.muted),
          const SizedBox(height: 10),
          const Text('No calling list loaded', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Pick one in Settings → Calling Lists', style: TextStyle(color: C.muted)),
          const SizedBox(height: 14),
          SizedBox(
            width: 200,
            child: ElevatedButton(onPressed: _openSettings, child: const Text('Open Settings')),
          ),
        ]),
      );

  Widget _loadNumbersView() => Column(children: [
        const GreetingCard(headline: 'Welcome to Calley!'),
        const SizedBox(height: 12),
        Expanded(
          child: SectionCard(
            title: 'LOAD NUMBER TO CALL',
            expand: true,
            padding: EdgeInsets.zero,
            child: const Column(children: [
              Padding(
                padding: EdgeInsets.fromLTRB(24, 22, 24, 0),
                child: Text.rich(
                  TextSpan(style: TextStyle(fontSize: 12.5, height: 1.6, color: C.text), children: [
                    TextSpan(text: 'Visit '),
                    TextSpan(text: 'https://app.getcalley.com', style: TextStyle(color: C.primary)),
                    TextSpan(text: ' to upload numbers that you wish to call using Calley Mobile App.'),
                  ]),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(child: _UploadIllustration()),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        CallActionRow(onStart: _startCalling),
      ]);

  Widget _statsView(CallList l) => RefreshIndicator(
        onRefresh: _load,
        child: ListView(children: [
          if (Api.demoMode) const _DemoBanner(),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 14, 16),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB))),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 2),
                  Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                    Text('${l.total}',
                        style: const TextStyle(color: C.primary, fontSize: 24, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 4),
                    const Text('CALLS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                  ]),
                ]),
              ),
              Container(
                width: 48,
                height: 44,
                decoration: BoxDecoration(color: C.primary, borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: Text(Session.name.isEmpty ? 'C' : Session.name[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
          const SizedBox(height: 36),
          SizedBox(
            height: 170,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, t, _) => CustomPaint(
                painter: _Donut([l.done, l.scheduled, l.pending].map((e) => e.toDouble()).toList(),
                    const [C.done, C.schedule, C.pending], t),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Row(children: [
            _stat('Pending', l.pending, C.pending, C.pendingBg),
            const SizedBox(width: 8),
            _stat('Done', l.done, C.doneGreen, C.doneBg),
            const SizedBox(width: 8),
            _stat('Schedule', l.scheduled, C.schedule, C.scheduleBg),
          ]),
          const SizedBox(height: 18),
          ElevatedButton(onPressed: _startCalling, child: const Text('Star Calling Now')),
        ]),
      );

  Widget _stat(String label, int v, Color bar, Color bg) => Expanded(
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 12, 6, 12),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Container(width: 3, height: 34, decoration: BoxDecoration(color: bar, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Flexible(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                  Text(v.toString().padLeft(2, '0'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 3),
                  const Text('Calls', style: TextStyle(fontSize: 8.5, color: C.muted)),
                ]),
              ]),
            ),
          ]),
        ),
      );
}

/// Rounded bottom bar from the Figma; each item has a 48dp tap target.
class _BottomBar extends StatelessWidget {
  final _Tab selected;
  final ValueChanged<_Tab> onTap;
  const _BottomBar({required this.selected, required this.onTap});

  static const _items = [
    (_Tab.home, Icons.home_outlined, 'Home'),
    (_Tab.contacts, Icons.contact_mail_outlined, 'Contacts'),
    (_Tab.play, Icons.play_arrow_outlined, 'Start calling'),
    (_Tab.callLog, Icons.phone_callback_outlined, 'Call log'),
    (_Tab.schedule, Icons.calendar_month_outlined, 'Schedule'),
  ];

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          border: Border(top: BorderSide(color: Color(0xFF93B4F5))),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(children: [
              for (final (tab, icon, label) in _items)
                Expanded(
                  child: Tooltip(
                    message: label,
                    child: Semantics(
                      button: true,
                      selected: tab == selected,
                      label: label,
                      child: InkResponse(
                        onTap: () => onTap(tab),
                        radius: 28,
                        child: SizedBox(
                          height: 52,
                          child: Center(
                            child: _pill(tab, icon),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      );

  // The play button is always the blue pill, as in Figma; the selected tab gets a tint.
  Widget _pill(_Tab tab, IconData icon) {
    final isPlay = tab == _Tab.play;
    final isSel = tab == selected;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: isPlay ? 50 : 40,
      height: 34,
      decoration: BoxDecoration(
        color: isPlay ? C.primary : (isSel ? C.primary.withValues(alpha: .12) : Colors.transparent),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Icon(icon, size: 21, color: isPlay ? Colors.white : (isSel ? C.primary : C.text)),
    );
  }
}

class _DemoBanner extends StatelessWidget {
  const _DemoBanner();
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: C.pendingBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: C.pending)),
        child: const Row(children: [
          Icon(Icons.info_outline, color: C.pending, size: 18),
          SizedBox(width: 8),
          Expanded(
              child: Text('Server unreachable. Showing sample data from the API documentation.',
                  style: TextStyle(fontSize: 11.5))),
        ]),
      );
}

/// "Agent with phone upload" illustration from the Figma design.
class _UploadIllustration extends StatelessWidget {
  const _UploadIllustration();
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Image.asset('assets/images/upload_illustration.png', fit: BoxFit.contain),
        ),
      );
}

class _Donut extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final double t;
  _Donut(this.values, this.colors, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = math.min(size.width, size.height) / 2 - 16;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(c, r * .62, Paint()..color = const Color(0xFFF1F2F4));
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30;
    final sum = values.fold<double>(0, (a, b) => a + b);
    if (sum == 0) {
      canvas.drawArc(rect, 0, math.pi * 2, false, p..color = C.border);
      return;
    }
    const gap = .05;
    var start = -math.pi / 2 + gap / 2;
    for (var i = 0; i < values.length; i++) {
      if (values[i] == 0) continue;
      final sweep = values[i] / sum * math.pi * 2 * t;
      canvas.drawArc(rect, start, math.max(0, sweep - gap), false, p..color = colors[i]);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_Donut old) => old.t != t || old.values != values;
}
