import 'package:flutter/material.dart';
import '../core/api.dart';
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
      await Api.sendOtp(email);
      if (!mounted) return;
      toast(context, 'OTP sent to $email');
      Navigator.push(context, MaterialPageRoute(builder: (_) => OtpScreen(email: email)));
    } catch (e) {
      if (mounted) toast(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthScaffold(
        title: 'Welcome!',
        subtitle: 'Please register to continue',
        children: [
          Form(
            key: _form,
            child: Column(children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(hintText: 'Name', suffixIcon: Icon(Icons.person_outline)),
                validator: (v) => (v ?? '').trim().length < 2 ? 'Enter your name' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'Email address', suffixIcon: Icon(Icons.mail_outline)),
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
                      icon: Icon(_hide ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _hide = !_hide)),
                ),
                validator: (v) => (v ?? '').length < 6 ? 'Minimum 6 characters' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(
                    counterText: '',
                    hintText: 'Mobile number',
                    prefixIcon: Padding(
                        padding: EdgeInsets.fromLTRB(14, 14, 6, 14),
                        child: Text('🇮🇳 +91', style: TextStyle(fontWeight: FontWeight.w600))),
                    suffixIcon: Icon(Icons.chat_outlined, color: C.whatsapp)),
                validator: (v) => RegExp(r'^\d{10}$').hasMatch(v ?? '') ? null : 'Enter 10-digit number',
              ),
            ]),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Checkbox(value: _agree, onChanged: (v) => setState(() => _agree = v ?? false)),
            const Expanded(
                child: Text.rich(TextSpan(text: 'I agree to the ', children: [
              TextSpan(text: 'Terms and Conditions', style: TextStyle(color: C.primary, fontWeight: FontWeight.w600))
            ]))),
          ]),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('Already have an account? ', style: TextStyle(color: C.muted)),
            GestureDetector(
              onTap: () => Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => const LoginScreen())),
              child: const Text('Sign In', style: TextStyle(color: C.primary, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 16),
          LoadingButton(label: 'Sign Up', loading: _loading, onPressed: _submit),
        ],
      );
}
