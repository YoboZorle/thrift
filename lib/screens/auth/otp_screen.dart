import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _controller.text.trim();
    if (code.length < 6) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.confirmCode(code);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.otpError ?? 'Invalid code.')),
      );
    }
    // On success, RootRouter advances to profile setup / home automatically.
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Verify')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Enter the code',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sent to ${auth.pendingPhone ?? 'your phone'}.',
                style: const TextStyle(
                    color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 12,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: '— — — — — —',
                ),
                onChanged: (v) {
                  if (v.length == 6) _verify();
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: auth.sendingCode
                      ? null
                      : () async {
                          final phone = auth.pendingPhone;
                          if (phone != null) {
                            await auth.startPhoneAuth(phone);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Code resent.')),
                              );
                            }
                          }
                        },
                  child: const Text('Resend code'),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: auth.verifyingCode ? null : _verify,
                  child: auth.verifyingCode
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.4, color: Colors.black),
                        )
                      : const Text('Verify & continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
