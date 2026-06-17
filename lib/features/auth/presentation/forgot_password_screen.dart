import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hanpay_mobil/core/network/api_exception.dart';
import 'package:hanpay_mobil/features/auth/data/auth_repository.dart';
import 'package:hanpay_mobil/features/auth/presentation/auth_controller.dart';
import 'package:hanpay_mobil/shared/models/role.dart';
import 'package:hanpay_mobil/shared/widgets/gradient_filled_button.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _showResetStep = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _tokenCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _requestToken() async {
    setState(() => _loading = true);
    try {
      final token = await ref.read(authRepositoryProvider).forgotPassword(email: _emailCtrl.text.trim());
      setState(() {
        _showResetStep = true;
        if (token != null && token.isNotEmpty) _tokenCtrl.text = token;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sıfırlama talimatları gönderildi. Token varsa alan dolduruldu.')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    setState(() => _loading = true);
    try {
      final session = await ref.read(authRepositoryProvider).resetPassword(
            email: _emailCtrl.text.trim(),
            token: _tokenCtrl.text.trim(),
            newPassword: _passwordCtrl.text,
          );
      ref.read(authControllerProvider.notifier).applySession(session);
      if (!mounted) return;
      context.go(postLoginPath(session.role));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Şifremi unuttum')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'E-posta'),
          ),
          if (_showResetStep) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _tokenCtrl,
              decoration: const InputDecoration(labelText: 'Sıfırlama token'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Yeni şifre'),
            ),
          ],
          const SizedBox(height: 24),
          GradientFilledButton(
            onPressed: _loading ? null : (_showResetStep ? _resetPassword : _requestToken),
            loading: _loading,
            child: Text(_showResetStep ? 'Şifreyi sıfırla' : 'Token iste'),
          ),
          TextButton(onPressed: () => context.go('/login'), child: const Text('Girişe dön')),
        ],
      ),
    );
  }
}
