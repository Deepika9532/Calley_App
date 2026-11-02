import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'dashboard_screen.dart';

class CallsScreen extends StatefulWidget {
  final CallList list;
  const CallsScreen({super.key, required this.list});
  @override
  State<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends State<CallsScreen> {
  static const tabs = ['All', 'Pending', 'Done', 'Scheduled'];
  final Map<int, String> _feedback = {};

  List<Map<String, dynamic>> _filter(String tab) {
    if (tab == 'All') return widget.list.calls;
    final key = {'Pending': 'pend', 'Done': 'call', 'Scheduled': 'sched'}[tab]!;
    return widget.list.calls
        .where((c) => pick(c, ['status', 'callStatus']).toLowerCase().contains(key))
        .toList();
  }

  Future<void> _call(Map<String, dynamic> c, int idx) async {
    final phone = pick(c, ['phone', 'phoneNumber', 'mobile', 'number']);
    if (phone.isEmpty) return toast(context, 'No phone number', error: true);
    await launchUrl(Uri(scheme: 'tel', path: phone));
    if (!mounted) return;
    final fb = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('How did the call go?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          for (final o in ['Very positive', 'Satisfied', 'Needs follow-up', 'Neutral', 'Negative'])
            ListTile(title: Text(o), onTap: () => Navigator.pop(context, o)),
        ]),
      ),
    );
    if (fb != null) setState(() => _feedback[idx] = fb);
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: tabs.length,
        child: Scaffold(
          backgroundColor: C.bg,
          appBar: AppBar(
            title: Text(widget.list.name),
            bottom: TabBar(tabs: [for (final t in tabs) Tab(text: t)]),
          ),
          body: TabBarView(children: [
            for (final t in tabs)
              Builder(builder: (_) {
                final items = _filter(t);
                if (items.isEmpty) {
                  return const Center(child: Text('No calls here', style: TextStyle(color: C.muted)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final c = items[i];
                    final idx = widget.list.calls.indexOf(c);
                    final name = pick(c, ['name', 'fullName', 'firstName'], 'Contact');
                    final status = pick(c, ['status', 'callStatus'], 'pending');
                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                        leading: CircleAvatar(
                            backgroundColor: C.primary.withValues(alpha: .12),
                            child: Text(name[0].toUpperCase(),
                                style: const TextStyle(color: C.primary, fontWeight: FontWeight.w700))),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text([
                          pick(c, ['phone', 'phoneNumber', 'mobile']),
                          pick(c, ['company', 'companyName']),
                          _feedback[idx] ?? status,
                        ].where((s) => s.isNotEmpty).join('  •  ')),
                        trailing: IconButton.filled(
                          style: IconButton.styleFrom(backgroundColor: C.primary),
                          icon: const Icon(Icons.call, color: Colors.white),
                          onPressed: () => _call(c, idx),
                        ),
                      ),
                    );
                  },
                );
              }),
          ]),
        ),
      );
}
