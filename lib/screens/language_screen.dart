import 'package:flutter/material.dart';
import '../core/session.dart';
import '../core/theme.dart';
import 'register_screen.dart';

class LanguageScreen extends StatefulWidget {
  final bool fromSettings;
  const LanguageScreen({super.key, this.fromSettings = false});
  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  static const langs = [
    ('English', 'Hi'),
    ('Hindi', 'नमस्ते'),
    ('Bengali', 'হ্যালো'),
    ('Kannada', 'ನಮಸ್ಕಾರ'),
    ('Punjabi', 'ਸਤ ਸ੍ਰੀ ਅਕਾਲ'),
    ('Tamil', 'வணக்கம்'),
    ('Telugu', 'హలో'),
    ('French', 'Bonjour'),
    ('Spanish', 'Hola'),
  ];
  late String selected = Session.language;

  Future<void> _select() async {
    await Session.setLanguage(selected);
    if (!mounted) return;
    if (widget.fromSettings) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: C.bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              const SizedBox(height: 8),
              const Text('Choose Your Language',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: C.text)),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: langs.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (_, i) {
                      final (name, hi) = langs[i];
                      final sel = selected == name;
                      return ListTile(
                        onTap: () => setState(() => selected = name),
                        title: Text(name,
                            style: TextStyle(fontWeight: FontWeight.w600, color: sel ? C.primary : C.text)),
                        subtitle: Text(hi),
                        trailing: Icon(sel ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: sel ? C.primary : C.muted),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _select, child: const Text('Select')),
            ]),
          ),
        ),
      );
}
