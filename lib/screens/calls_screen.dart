import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

/// [called] = every call made (done + scheduled), used by the Call Log tab.
enum CallFilter { all, pending, done, scheduled, called }

/// Filters calls using the same groups as the dashboard counts.
List<Map<String, dynamic>> filterCalls(List<Map<String, dynamic>> calls, CallFilter f) => switch (f) {
      CallFilter.all => calls,
      CallFilter.called => calls.where((c) => callGroup(c) != CallGroup.pending).toList(),
      CallFilter.pending => calls.where((c) => callGroup(c) == CallGroup.pending).toList(),
      CallFilter.done => calls.where((c) => callGroup(c) == CallGroup.done).toList(),
      CallFilter.scheduled => calls.where((c) => callGroup(c) == CallGroup.scheduled).toList(),
    };

/// Full-screen calling queue opened by "Star Calling Now" / the play button.
class CallsScreen extends StatelessWidget {
  final CallList list;
  const CallsScreen({super.key, required this.list});

  static const _tabs = {
    'All': CallFilter.all,
    'Pending': CallFilter.pending,
    'Done': CallFilter.done,
    'Scheduled': CallFilter.scheduled,
  };

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: _tabs.length,
        initialIndex: 1,
        child: Scaffold(
          appBar: AppBar(
            title: Text(list.name),
            bottom: TabBar(tabs: [for (final t in _tabs.keys) Tab(text: t)]),
          ),
          body: TabBarView(children: [
            for (final f in _tabs.values)
              CallTiles(calls: filterCalls(list.calls, f), showSchedule: f == CallFilter.scheduled),
          ]),
        ),
      );
}

/// Scrollable list of call cards with tap-to-dial and a feedback sheet.
class CallTiles extends StatefulWidget {
  final List<Map<String, dynamic>> calls;
  final bool showSchedule;
  final String emptyText;
  const CallTiles({super.key, required this.calls, this.showSchedule = false, this.emptyText = 'No calls here'});
  @override
  State<CallTiles> createState() => _CallTilesState();
}

class _CallTilesState extends State<CallTiles> {
  final Map<Map<String, dynamic>, String> _feedback = {};

  Future<void> _call(Map<String, dynamic> c) async {
    final phone = pick(c, ['Phone', 'phone', 'phoneNumber', 'mobile']);
    if (phone.isEmpty) return toast(context, 'No phone number for this contact', error: true);
    var opened = false;
    try {
      opened = await launchUrl(Uri(scheme: 'tel', path: phone));
    } catch (_) {}
    if (!mounted) return;
    if (!opened) return toast(context, 'Calling is not available on this device', error: true);
    final fb = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheet) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('How did the call go?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          for (final o in ['Very positive', 'Satisfied', 'Needs follow-up', 'Neutral', 'Negative'])
            ListTile(title: Text(o), onTap: () => Navigator.pop(sheet, o)),
        ]),
      ),
    );
    if (fb != null && mounted) setState(() => _feedback[c] = fb);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.calls.isEmpty) {
      return Center(child: Text(widget.emptyText, style: const TextStyle(color: C.muted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: widget.calls.length,
      itemBuilder: (_, i) {
        final c = widget.calls[i];
        final name = [
          pick(c, ['Title']),
          pick(c, ['FirstName', 'firstName', 'name'], 'Contact'),
          pick(c, ['LastName', 'lastName']),
        ].where((x) => x.isNotEmpty).join(' ');
        final status = _feedback[c] ?? pick(c, ['feedback', 'status', 'callStatus'], 'pending');
        final when = widget.showSchedule ? pick(c, ['rescheduledAt', 'scheduledAt']) : '';
        return Card(
          elevation: 0,
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            leading: CircleAvatar(
              backgroundColor: C.primary.withValues(alpha: .12),
              child: Text(name.isEmpty ? 'C' : pick(c, ['FirstName', 'name'], 'C')[0].toUpperCase(),
                  style: const TextStyle(color: C.primary, fontWeight: FontWeight.w700)),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text([
              if (when.isNotEmpty) '📅 $when',
              pick(c, ['Phone', 'phone', 'phoneNumber']),
              pick(c, ['Company', 'company']),
              status,
            ].where((s) => s.isNotEmpty).join('  •  ')),
            trailing: IconButton.filled(
              tooltip: 'Call',
              style: IconButton.styleFrom(backgroundColor: C.primary),
              icon: const Icon(Icons.call, color: Colors.white),
              onPressed: () => _call(c),
            ),
          ),
        );
      },
    );
  }
}
