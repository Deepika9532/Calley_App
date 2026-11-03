import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/session.dart';
import '../core/theme.dart';

/// Calley's official WhatsApp support number, digits only with country code
/// (e.g. '91XXXXXXXXXX'). Left empty because no confirmed number was provided;
/// WhatsApp then opens without a preset recipient.
const supportWhatsApp = '';

/// Opens WhatsApp (to [supportWhatsApp] if set). Shows a message if WhatsApp
/// can't be opened.
Future<void> openSupport([BuildContext? context]) async {
  final url = Uri.parse(supportWhatsApp.isEmpty ? 'https://wa.me/' : 'https://wa.me/$supportWhatsApp');
  var ok = false;
  try {
    ok = await launchUrl(url, mode: LaunchMode.externalApplication);
  } catch (_) {}
  if (!ok && context != null && context.mounted) {
    toast(context, 'WhatsApp is not installed on this device', error: true);
  }
}

/// Multicolour "C" swoosh + CALLEY wordmark, as on the Figma auth screens.
class CalleyLogo extends StatelessWidget {
  const CalleyLogo({super.key});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: 38, height: 38, child: CustomPaint(painter: _SwooshPainter())),
        const SizedBox(width: 10),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('CALLEY',
              style: TextStyle(fontSize: 17, letterSpacing: 1, color: Color(0xFF1AA6E8), fontWeight: FontWeight.w500)),
          Text('AUTOMATIC CALL DIALER',
              style: TextStyle(fontSize: 8, letterSpacing: .4, color: C.text, fontWeight: FontWeight.w600)),
        ]),
      ]);
}

class _SwooshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final rect = Rect.fromLTWH(3, 3, s.width - 6, s.height - 6);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(colors: [
        Color(0xFF00C2FF), Color(0xFF2563EB), Color(0xFF8B5CF6), Color(0xFFFF2D87),
        Color(0xFFFF8A00), Color(0xFFFFE000), Color(0xFF22C55E), Color(0xFF00C2FF),
      ]).createShader(rect);
    canvas.drawArc(rect, math.pi * .25, math.pi * 1.55, false, p);
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Grey header with logo + white rounded sheet; [bottom] is pinned above the
/// keyboard area like the Sign Up / Sign In / Verify buttons in Figma.
class AuthShell extends StatelessWidget {
  final String title, subtitle;
  final List<Widget> children;
  final Widget bottom;
  final bool centerBody;
  const AuthShell(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.children,
      required this.bottom,
      this.centerBody = false});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: C.bg,
        body: SafeArea(
          child: Column(children: [
            const SizedBox(height: 28),
            const CalleyLogo(),
            const SizedBox(height: 28),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                  border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: Column(children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (_, c) => SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: centerBody ? c.maxHeight - 36 : 0),
                          child: Column(
                            mainAxisAlignment: centerBody ? MainAxisAlignment.center : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(title,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: C.text)),
                              const SizedBox(height: 6),
                              Text(subtitle,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: C.muted, fontSize: 12.5, height: 1.4)),
                              const SizedBox(height: 22),
                              ...children,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 20), child: bottom),
                ]),
              ),
            ),
          ]),
        ),
      );
}

/// "Already have an account? Sign In" style line.
class SwitchLine extends StatelessWidget {
  final String text, action;
  final VoidCallback onTap;
  const SwitchLine({super.key, required this.text, required this.action, required this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Text.rich(
            TextSpan(style: const TextStyle(fontSize: 13, color: C.text), text: '$text ', children: [
              TextSpan(text: action, style: const TextStyle(color: C.primary, fontWeight: FontWeight.w700)),
            ]),
            textAlign: TextAlign.center,
          ),
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

/// Outlined WhatsApp square + "Star Calling Now" button row (Figma bottom row).
class CallActionRow extends StatelessWidget {
  final VoidCallback onStart;
  const CallActionRow({super.key, required this.onStart});
  @override
  Widget build(BuildContext context) => Row(children: [
        const WhatsAppButton(),
        const SizedBox(width: 10),
        Expanded(child: ElevatedButton(onPressed: onStart, child: const Text('Star Calling Now'))),
      ]);
}

/// Green-bordered rounded square with the WhatsApp logo (Figma page 3).
class WhatsAppButton extends StatelessWidget {
  final double size;
  const WhatsAppButton({super.key, this.size = 50});
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Open WhatsApp',
        excludeSemantics: true,
        child: Tooltip(
          message: 'WhatsApp',
          child: Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: C.whatsapp, width: 1.4),
            ),
            child: InkWell(
              onTap: () => openSupport(context),
              borderRadius: BorderRadius.circular(8),
              splashColor: C.whatsapp.withValues(alpha: .18),
              child: SizedBox(
                width: size,
                height: size,
                child: Center(
                  child: Image.asset('assets/images/whatsapp.png', width: size * .56, height: size * .56),
                ),
              ),
            ),
          ),
        ),
      );
}

/// Round avatar with the user's initial on a warm background.
class UserAvatar extends StatelessWidget {
  final double radius;
  const UserAvatar({super.key, this.radius = 20});
  @override
  Widget build(BuildContext context) => ClipOval(
        child: Image.asset('assets/images/avatar.png', width: radius * 2, height: radius * 2, fit: BoxFit.cover),
      );
}

/// Blue greeting card ("Hello Swati / Calley Personal").
class GreetingCard extends StatelessWidget {
  final String headline;
  const GreetingCard({super.key, required this.headline});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: C.primary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF93B4F5), width: 1.5),
        ),
        child: Row(children: [
          const UserAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Hello ${Session.name}', style: const TextStyle(color: Colors.white, fontSize: 11)),
              const SizedBox(height: 2),
              Text(headline,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
      );
}

/// Navy-headed card with a white body (LOAD NUMBER TO CALL, PROFILE SETTINGS…).
class SectionCard extends StatelessWidget {
  final String? title;
  final Widget header;
  final Widget child;
  final EdgeInsets padding;

  /// Fill the parent's height (use inside Expanded); the body then gets a
  /// bounded height instead of sizing to its content.
  final bool expand;
  SectionCard({super.key, String? title, Widget? header, required this.child,
      this.padding = const EdgeInsets.all(16), this.expand = false})
      : title = title,
        header = header ??
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(title ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5, letterSpacing: .3)),
            );
  @override
  Widget build(BuildContext context) {
    final body = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: child,
    );
    return Container(
      decoration: BoxDecoration(color: C.navy, borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [header, if (expand) Expanded(child: body) else body],
      ),
    );
  }
}

void toast(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red.shade600 : C.text,
        behavior: SnackBarBehavior.floating));
}
