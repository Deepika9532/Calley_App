import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'app_drawer.dart';
import 'calls_screen.dart';

/// Summary of one calling list, parsed defensively from the API.
class CallList {
  final String id, name;
  final int total, pending, done, scheduled;
  final List<Map<String, dynamic>> calls;
  CallList(this.id, this.name, this.total, this.pending, this.done, this.scheduled, this.calls);

  factory CallList.fromJson(Map<String, dynamic> j, [List<Map<String, dynamic>> calls = const []]) {
    String st(Map<String, dynamic> c) => pick(c, ['status', 'callStatus']).toLowerCase();
    final pending = calls.isNotEmpty
        ? calls.where((c) => st(c).contains('pend')).length
        : pickInt(j, ['pending', 'pendingCalls']);
    final done = calls.isNotEmpty
        ? calls.where((c) => st(c).contains('call') || st(c).contains('done') || st(c).contains('complet')).length
        : pickInt(j, ['called', 'done', 'calledCalls', 'completed']);
    final sched = calls.isNotEmpty
        ? calls.where((c) => st(c).contains('sched') || st(c).contains('resched')).length
        : pickInt(j, ['rescheduled', 'scheduled', 'rescheduledCalls']);
    var total = calls.isNotEmpty ? calls.length : pickInt(j, ['totalCalls', 'total', 'count', 'calls']);
    if (total == 0) total = pending + done + sched;
    return CallList(pick(j, ['_id', 'id', 'listId']), pick(j, ['name', 'listName', 'title'], 'Calling List'),
        total, pending, done, sched, calls);
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tab = 0;
  bool _loading = true;
  String? _error;
  List<CallList> _lists = [];
  CallList? _active;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await Api.lists(Session.userId);
      _lists = extractList(res).map((e) => CallList.fromJson(e)).toList();
      if (_lists.isNotEmpty) await _open(_lists.first);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(CallList l) async {
    try {
      final res = await Api.listDetail(l.id);
      final detail = res['list'] is Map ? Map<String, dynamic>.from(res['list']) : res;
      final merged = {...detail, if (pick(detail, ['name', 'listName']).isEmpty) 'name': l.name, '_id': l.id};
      _active = CallList.fromJson(merged, extractList(res));
    } catch (_) {
      _active = l;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: C.bg,
        drawer: const AppDrawer(),
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Row(children: [
            CircleAvatar(
                radius: 18,
                backgroundColor: C.primary,
                child: Text(Session.name.isNotEmpty ? Session.name[0].toUpperCase() : 'C',
                    style: const TextStyle(color: Colors.white))),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Hello ${Session.name}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const Text('Calley Personal', style: TextStyle(fontSize: 12, color: C.muted)),
              ]),
            ),
          ]),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
            IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
          ],
        ),
        floatingActionButton: const WhatsAppFab(),
        body: _tab == 0 ? _gettingStarted() : _dashboard(),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          backgroundColor: Colors.white,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(
                icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          ],
        ),
      );

  Widget _gettingStarted() => ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [C.primary, C.primaryDark]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('If you are here for the first time then ensure that you have uploaded the list to call '
                'from calley Web Panel hosted on https://app.getcalley.com',
                style: TextStyle(color: Colors.white, height: 1.4)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => launchUrl(Uri.parse('https://www.youtube.com/watch?v=bP4U-L4EHcg'),
                  mode: LaunchMode.externalApplication),
              child: Container(
                height: 160,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.play_circle_fill, color: Colors.white, size: 56),
                  SizedBox(height: 8),
                  Text('2 MINUTE CHALLENGE',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  Text('Watch how to use Calley', style: TextStyle(color: Colors.white70)),
                ]),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              onPressed: () => launchUrl(Uri.parse('https://wa.me/917676286822'),
                  mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.chat, color: C.whatsapp),
              label: const Text('Support'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(onPressed: () => setState(() => _tab = 1), child: const Text('Start Calling Now')),
          ),
        ]),
      ]);

  Widget _dashboard() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
          child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off, size: 48, color: C.muted),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextButton(onPressed: _load, child: const Text('Retry')),
        ]),
      ));
    }
    if (_active == null) {
      return const Center(child: Text('No calling lists assigned yet.', style: TextStyle(color: C.muted)));
    }
    final l = _active!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('LOADED', style: TextStyle(color: C.muted, fontSize: 12)),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: l.id,
                      isDense: true,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: C.text),
                      items: [
                        for (final x in _lists) DropdownMenuItem(value: x.id, child: Text(x.name))
                      ],
                      onChanged: (id) => _open(_lists.firstWhere((x) => x.id == id)),
                    ),
                  ),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: C.primary, borderRadius: BorderRadius.circular(20)),
                child: Text('${l.total} CALLS',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ]),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, t, _) => CustomPaint(
                  painter: _Donut([l.pending.toDouble(), l.done.toDouble(), l.scheduled.toDouble()],
                      const [C.pending, C.done, C.schedule], t),
                  child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('${l.total}', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
                      const Text('Total Calls', style: TextStyle(color: C.muted)),
                    ]),
                  ),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        Row(children: [
          _stat('Pending', l.pending, C.pending),
          const SizedBox(width: 10),
          _stat('Done', l.done, C.done),
          const SizedBox(width: 10),
          _stat('Schedule', l.scheduled, C.schedule),
        ]),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CallsScreen(list: l))),
          child: const Text('Start Calling Now'),
        ),
      ]),
    );
  }

  Widget _stat(String label, int v, Color c) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(color: c, width: 4))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: C.muted, fontSize: 12)),
            const SizedBox(height: 4),
            Text('$v Calls', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: c)),
          ]),
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
    final r = math.min(size.width, size.height) / 2 - 12;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: r);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.butt;
    final sum = values.fold<double>(0, (a, b) => a + b);
    if (sum == 0) {
      canvas.drawArc(rect, 0, math.pi * 2, false, p..color = C.border);
      return;
    }
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / sum * math.pi * 2 * t;
      canvas.drawArc(rect, start, sweep, false, p..color = colors[i]);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_Donut old) => old.t != t || old.values != values;
}
