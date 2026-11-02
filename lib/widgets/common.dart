import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';

class CalleyLogo extends StatelessWidget {
  final double size;
  const CalleyLogo({super.key, this.size = 30});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: size * 1.2,
          height: size * 1.2,
          decoration: BoxDecoration(color: C.primary, borderRadius: BorderRadius.circular(size * .3)),
          child: Icon(Icons.call, color: Colors.white, size: size * .75),
        ),
        const SizedBox(width: 8),
        Text('Calley',
            style: TextStyle(fontSize: size * .9, fontWeight: FontWeight.w800, color: C.text)),
      ]);
}

/// Rounded white card that sits on the blue header, used by auth screens.
class AuthScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  const AuthScaffold({super.key, required this.title, required this.subtitle, required this.children});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: C.bg,
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.fromLTRB(20, 24, 20, 24), children: [
            const Center(child: CalleyLogo()),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 6))]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: C.text)),
                const SizedBox(height: 6),
                Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: C.muted)),
                const SizedBox(height: 22),
                ...children,
              ]),
            ),
          ]),
        ),
      );
}

class LoadingButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;
  const LoadingButton({super.key, required this.label, required this.loading, this.onPressed});
  @override
  Widget build(BuildContext context) => ElevatedButton(
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : Text(label),
      );
}

class WhatsAppFab extends StatelessWidget {
  const WhatsAppFab({super.key});
  @override
  Widget build(BuildContext context) => FloatingActionButton(
        heroTag: 'wa',
        backgroundColor: C.whatsapp,
        onPressed: () => launchUrl(Uri.parse('https://wa.me/917676286822'),
            mode: LaunchMode.externalApplication),
        child: const Icon(Icons.chat, color: Colors.white),
      );
}

void toast(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red.shade600 : C.text,
        behavior: SnackBarBehavior.floating));
}
