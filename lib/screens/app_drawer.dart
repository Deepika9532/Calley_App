import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/session.dart';
import '../core/theme.dart';
import 'language_screen.dart';
import 'login_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    Widget item(IconData i, String t, [VoidCallback? on]) => ListTile(
          leading: Icon(i, color: C.primary),
          title: Text(t, style: const TextStyle(fontWeight: FontWeight.w500)),
          onTap: on ?? () => Navigator.pop(context),
        );

    return Drawer(
      child: Column(children: [
        Container(
          width: double.infinity,
          color: C.primary,
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 20),
          child: Row(children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.white,
              child: Text(Session.name[0].toUpperCase(),
                  style: const TextStyle(color: C.primary, fontSize: 22, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${Session.name}  •  Personal',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                Text(Session.email, style: const TextStyle(color: Colors.white70)),
              ]),
            ),
          ]),
        ),
        Expanded(
          child: ListView(padding: EdgeInsets.zero, children: [
            item(Icons.rocket_launch_outlined, 'Getting Started'),
            item(Icons.sync, 'Sync Data'),
            item(Icons.emoji_events_outlined, 'Gamification'),
            item(Icons.send_outlined, 'Send Logs'),
            item(Icons.translate, 'App Language', () {
              Navigator.pop(context);
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const LanguageScreen(fromSettings: true)));
            }),
            item(Icons.settings_outlined, 'Settings'),
            item(Icons.help_outline, 'Help?', () => launchUrl(Uri.parse('https://wa.me/917676286822'),
                mode: LaunchMode.externalApplication)),
            item(Icons.cancel_outlined, 'Cancel Subscription'),
            const Divider(),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text('App Info', style: TextStyle(color: C.muted, fontWeight: FontWeight.w600)),
            ),
            item(Icons.info_outline, 'About Us'),
            item(Icons.privacy_tip_outlined, 'Privacy Policy'),
            item(Icons.verified_outlined, 'Version 1.01.52'),
            item(Icons.share_outlined, 'Share App'),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
              onTap: () async {
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
                Navigator.pushAndRemoveUntil(
                    context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
              },
            ),
          ]),
        ),
      ]),
    );
  }
}
