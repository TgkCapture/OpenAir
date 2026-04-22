import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:openair/core/di/injection.dart';
import 'package:openair/features/auth/repository/auth_repository.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await getIt<AuthRepository>().forgotPassword(_emailCtrl.text.trim());
      setState(() => _sent = true);
    } catch (_) {
      setState(() => _sent = true); // Always show sent to prevent enumeration
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _sent
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.mark_email_read_outlined, size: 64),
                  const SizedBox(height: 16),
                  const Text('Check your email', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('If that email exists, an OTP has been sent.', textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  OutlinedButton(onPressed: () => context.go('/login'), child: const Text('Back to sign in')),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Enter your email and we\'ll send you a reset OTP.'),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Send OTP'),
                  ),
                ],
              ),
      ),
    );
  }
}