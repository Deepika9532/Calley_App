import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/models.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'language_screen.dart';

/// Profile card, profile settings and the calling-list picker.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<CallList> _lists = [];
  bool _loading = false;
  String? _error;
  Future<void>? _inFlight; // the request in progress, so repeated taps reuse it

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  /// GET /api/list?userId=… — repeated calls while one is running share it.
  Future<void> _refresh() => _inFlight ??= _fetch().whenComplete(() => _inFlight = null);

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await Api.lists(Session.userId);
      _lists = extractList(res).map(CallList.fromJson).where((l) => l.id.isNotEmpty).toList();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Could not load calling lists. Check your connection and try again.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _listsBody() {
    if (_loading && _lists.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(children: [
          const Icon(Icons.cloud_off, color: C.muted),
          const SizedBox(height: 6),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5)),
          TextButton(onPressed: _refresh, child: const Text('Try again')),
        ]),
      );
    }
    if (_lists.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 16, top: 4),
        child: Text('No calling lists yet. Upload one at app.getcalley.com, then tap Refresh.',
            textAlign: TextAlign.center, style: TextStyle(color: C.muted, fontSize: 12.5)),
      );
    }
    final selected = Session.selectedListId;
    return Column(children: [
      if (Api.demoMode)
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text('Server unreachable – showing the sample list from the API documentation.',
              textAlign: TextAlign.center, style: TextStyle(color: C.pending, fontSize: 11.5)),
        ),
      for (final l in _lists)
        _tile(l.name, selected: l.id == selected, onTap: () async {
          await Session.selectList(l.id);
          if (mounted) Navigator.pop(context); // back to the list's dashboard
        }),
    ]);
  }

  Widget _tile(String label, {IconData? icon, VoidCallback? onTap, bool selected = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: C.tint,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: selected ? const BorderSide(color: C.primary, width: 1.5) : BorderSide.none,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              child: Row(children: [
                if (icon != null) ...[Icon(icon, size: 19, color: C.text), const SizedBox(width: 12)],
                Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                if (selected) ...[
                  const Icon(Icons.check_circle, size: 19, color: C.primary),
                  const SizedBox(width: 8),
                ],
                const Icon(Icons.exit_to_app, size: 19, color: C.text),
              ]),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final info = [
      Session.email,
      if (Session.phone.isNotEmpty) Session.phone,
      'Parent Account: NA',
      'Current Subscription: Calley Personal',
    ];
    return Scaffold(
      appBar: AppBar(titleSpacing: 0, title: const Text('Setting')),
      body: ListView(padding: const EdgeInsets.fromLTRB(12, 4, 12, 20), children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: C.primary,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF93B4F5), width: 1.5)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const UserAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Hello ${Session.name}',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                for (final line in info)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(line, style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
                  ),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'PROFILE SETTINGS',
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Column(children: [
            _tile('App Language',
                icon: Icons.language,
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const LanguageScreen(fromSettings: true)))),
            _tile('Change Password',
                icon: Icons.lock_outline, onTap: () => toast(context, 'Password reset link sent to your email')),
          ]),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'CALLING LISTS',
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Column(children: [
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
              decoration: BoxDecoration(color: C.tint, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Expanded(
                    child: Text('Select Calling List', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                SizedBox(
                  height: 32,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    onPressed: _loading ? null : _refresh,
                    icon: _loading
                        ? const SizedBox(
                            width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.sync, size: 16),
                    label: const Text('Refresh'),
                  ),
                ),
              ]),
            ),
            _listsBody(),
          ]),
        ),
      ]),
    );
  }
}
