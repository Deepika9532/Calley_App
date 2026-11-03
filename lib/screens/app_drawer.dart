import 'package:flutter/material.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'getting_started_screen.dart';
import 'login_screen.dart';

class AppDrawer extends StatelessWidget {
  final VoidCallback onSettings;
  final Future<void> Function()? onSync;
  const AppDrawer({super.key, required this.onSettings, this.onSync});

  @override
  Widget build(BuildContext context) {
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    void say(String m) => messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m), behavior: SnackBarBehavior.floating));
    void close() => nav.pop();
    // Items with no screen in this app yet say so instead of doing nothing.
    void soon(String what) => say('$what is available on the Calley web panel');

    Widget item(IconData icon, String label, [VoidCallback? onTap]) => ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18),
          leading: Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: C.text),
          ),
          title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          onTap: () {
            close();
            onTap?.call();
          },
        );

    Future<void> logout() async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (d) => AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Logout')),
          ],
        ),
      );
      if (ok != true || !context.mounted) return;
      await Session.logout();
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    }

    return Drawer(
      backgroundColor: C.tint,
      shape: const RoundedRectangleBorder(),
      child: Column(children: [
        Container(
          width: double.infinity,
          color: C.primary,
          padding: EdgeInsets.fromLTRB(14, MediaQuery.of(context).padding.top + 10, 14, 12),
          child: Row(children: [
            const UserAvatar(radius: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text.rich(TextSpan(
                    text: Session.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                    children: const [
                      TextSpan(
                          text: '  •  Personal',
                          style: TextStyle(color: Color(0xFFFFD27A), fontSize: 11, fontWeight: FontWeight.w600)),
                    ])),
                Text(Session.email, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ]),
            ),
          ]),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.only(top: 8), children: [
            item(Icons.rocket_launch_outlined, 'Getting Started', () {
              nav.push(MaterialPageRoute(builder: (_) => const GettingStartedScreen()));
            }),
            item(Icons.cloud_sync_outlined, 'Sync Data', () async {
              await onSync?.call();
              say('Data synced');
            }),
            item(Icons.grid_view, 'Gamification', () => soon('Gamification')),
            item(Icons.phone_forwarded_outlined, 'Send Logs', () => soon('Send Logs')),
            item(Icons.settings_outlined, 'Settings', onSettings),
            item(Icons.headset_mic_outlined, 'Help?', () => openSupport(nav.context)),
            item(Icons.person_remove_outlined, 'Cancel Subscription', () => soon('Subscription management')),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Text('App Info', style: TextStyle(color: C.primary, fontWeight: FontWeight.w700, fontSize: 14)),
            ),
            item(Icons.contact_page_outlined, 'About Us', () => showAboutDialog(
                context: nav.context, applicationName: 'Calley', applicationVersion: '1.01.52',
                children: const [Text('Automatic call dialer by C S Tech Infosolutions.')])),
            item(Icons.privacy_tip_outlined, 'Privacy Policy', () => soon('Privacy Policy')),
            item(Icons.system_update_outlined, 'Version 1.01.52', () => say('You are on the latest version')),
            item(Icons.share_outlined, 'Share App', () => soon('Sharing')),
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 18),
              leading: Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.logout, size: 18, color: C.text),
              ),
              title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              onTap: logout,
            ),
            const SizedBox(height: 12),
          ]),
        ),
      ]),
    );
  }
}
