import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'getting_started_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final String? email;
  const LoginScreen({super.key, this.email});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.email);
  final _pass = TextEditingController();
  bool _hide = true, _loading = false;

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final res = await Api.login(_email.text.trim(), _pass.text);
      final user = Map<String, dynamic>.from((res['user'] ?? res['data'] ?? {'email': _email.text.trim()}) as Map);
      user['email'] ??= _email.text.trim();
      await Session.saveUser(user);
      if (!mounted) return;
      if (Api.demoMode) toast(context, 'Server unreachable – continuing with sample data');
      Navigator.pushAndRemoveUntil(
          context, MaterialPageRoute(builder: (_) => const GettingStartedScreen()), (_) => false);
    } catch (e) {
      if (mounted) toast(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthShell(
        centerBody: true,
        title: 'Welcome',
        subtitle: 'Please sign-in to continue',
        bottom: Column(mainAxisSize: MainAxisSize.min, children: [
          SwitchLine(
            text: "Don't have an account?",
            action: 'Sign Up',
            onTap: () =>
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
          ),
          LoadingButton(label: 'Sign In', loading: _loading, onPressed: _login),
        ]),
        children: [
          Form(
            key: _form,
            child: Column(children: [
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration:
                    const InputDecoration(hintText: 'Email address', suffixIcon: Icon(Icons.mail_outline, size: 20)),
                validator: (v) => (v ?? '').contains('@') ? null : 'Enter a valid email',
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
                validator: (v) => (v ?? '').isEmpty ? 'Enter your password' : null,
              ),
            ]),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              style: TextButton.styleFrom(padding: EdgeInsets.zero, foregroundColor: C.text),
              onPressed: () => toast(context, 'Password reset link will be sent to your email'),
              child: const Text('Forgot Password?', style: TextStyle(fontSize: 12.5)),
            ),
          ),
        ],
      );
}
