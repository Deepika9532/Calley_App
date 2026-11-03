import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/api.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'login_screen.dart';
import 'otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _phone = TextEditingController();
  bool _agree = false, _hide = true, _loading = false;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (!_agree) return toast(context, 'Please accept the Terms and Conditions', error: true);
    setState(() => _loading = true);
    try {
      final email = _email.text.trim();
      await Api.register(username: _name.text.trim(), email: email, password: _pass.text);
      await Session.savePhone(email, _phone.text);
      await Api.sendOtp(email);
      if (!mounted) return;
      toast(context, 'OTP sent to $email');
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => OtpScreen(email: email, phone: _phone.text)));
    } catch (e) {
      if (mounted) toast(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthShell(
        title: 'Welcome!',
        subtitle: 'Please register to continue',
        bottom: Column(mainAxisSize: MainAxisSize.min, children: [
          SwitchLine(
            text: 'Already have an account?',
            action: 'Sign In',
            onTap: () =>
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
          ),
          LoadingButton(label: 'Sign Up', loading: _loading, onPressed: _submit),
        ]),
        children: [
          Form(
            key: _form,
            child: Column(children: [
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'Name', suffixIcon: Icon(Icons.person_outline, size: 20)),
                validator: (v) => (v ?? '').trim().length < 2 ? 'Enter your name' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration:
                    const InputDecoration(hintText: 'Email address', suffixIcon: Icon(Icons.mail_outline, size: 20)),
                validator: (v) =>
                    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((v ?? '').trim()) ? null : 'Enter a valid email',
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _pass,
                obscureText: _hide,
                decoration: InputDecoration(
                  hintText: 'Password',
                  suffixIcon: IconButton(
                      icon: Icon(_hide ? Icons.lock_outline : Icons.lock_open_outlined, size: 20),
                      onPressed: () => setState(() => _hide = !_hide)),
                ),
                validator: (v) => (v ?? '').length < 3 ? 'Enter a password' : null,
              ),
              const SizedBox(height: 14),
              // Country code row with WhatsApp icon, as in Figma.
              InputDecorator(
                decoration: const InputDecoration(
                  suffixIcon: Icon(Icons.chat_outlined, size: 18),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                child: const Row(children: [
                  Text('🇮🇳', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 6),
                  Text('+91', style: TextStyle(fontSize: 14)),
                ]),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                    counterText: '',
                    hintText: 'Mobile number',
                    suffixIcon: Icon(Icons.smartphone, size: 20)),
                validator: (v) => RegExp(r'^\d{10}$').hasMatch(v ?? '') ? null : 'Enter 10-digit number',
              ),
            ]),
          ),
          const SizedBox(height: 6),
          Row(children: [
            SizedBox(
              width: 32,
              child: Checkbox(
                value: _agree,
                visualDensity: VisualDensity.compact,
                side: const BorderSide(color: C.muted),
                onChanged: (v) => setState(() => _agree = v ?? false),
              ),
            ),
            const Expanded(
              child: Text.rich(TextSpan(style: TextStyle(fontSize: 12.5), text: 'I agree to the ', children: [
                TextSpan(text: 'Terms and Conditions', style: TextStyle(color: C.primary)),
              ])),
            ),
          ]),
        ],
      );
}
