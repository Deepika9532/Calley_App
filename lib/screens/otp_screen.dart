import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/api.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'login_screen.dart';

class OtpScreen extends StatefulWidget {
  final String email, phone;
  const OtpScreen({super.key, required this.email, this.phone = ''});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _ctrls = List.generate(6, (_) => TextEditingController());
  final _nodes = List.generate(6, (_) => FocusNode());
  Timer? _timer;
  int _left = 30;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _left = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_left == 0) return t.cancel();
      setState(() => _left--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _otp => _ctrls.map((c) => c.text).join();

  Future<void> _resend() async {
    if (_left > 0) return toast(context, 'You can resend in $_left s');
    try {
      await Api.sendOtp(widget.email);
      if (mounted) toast(context, 'OTP resent');
      _startTimer();
    } catch (e) {
      if (mounted) toast(context, e.toString(), error: true);
    }
  }

  Future<void> _verify() async {
    if (_otp.length != 6) return toast(context, 'Enter the 6-digit OTP', error: true);
    setState(() => _loading = true);
    try {
      await Api.verifyOtp(widget.email, _otp);
      if (!mounted) return;
      toast(context, 'Verified! Please sign in.');
      Navigator.pushAndRemoveUntil(
          context, MaterialPageRoute(builder: (_) => LoginScreen(email: widget.email)), (_) => false);
    } catch (e) {
      if (mounted) toast(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _box(int i) => SizedBox(
        width: 38,
        height: 40,
        child: TextField(
          controller: _ctrls[i],
          focusNode: _nodes[i],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(counterText: '', contentPadding: EdgeInsets.zero),
          onChanged: (v) {
            if (v.isNotEmpty && i < 5) _nodes[i + 1].requestFocus();
            if (v.isEmpty && i > 0) _nodes[i - 1].requestFocus();
            if (_otp.length == 6) FocusScope.of(context).unfocus();
          },
        ),
      );

  @override
  Widget build(BuildContext context) => AuthShell(
        centerBody: true,
        title: 'Whatsapp OTP\nVerification',
        subtitle: 'Please ensure that the email id mentioned is valid\nas we have sent an OTP to your email.',
        bottom: Column(mainAxisSize: MainAxisSize.min, children: [
          SwitchLine(
              text: "Didn't receive OTP code?",
              action: _left > 0 ? 'Resend OTP (${_left}s)' : 'Resend OTP',
              onTap: _resend),
          LoadingButton(label: 'Verify', loading: _loading, onPressed: _verify),
        ]),
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(6, _box)),
          const SizedBox(height: 18),
          Text(widget.phone.isNotEmpty ? '+91 ${widget.phone}?' : widget.email,
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: C.text)),
        ],
      );
}
