import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'otp_screen.dart';

class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final _controller = TextEditingController();
  String _dialCode = '+234';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Normalises the entered number to its national significant digits, or null
  /// if it isn't valid for the selected country. Drops a local trunk '0' (e.g.
  /// 0803… → 803…) which Nigerians commonly type.
  String? _normalized() {
    var raw = _controller.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.startsWith('0')) raw = raw.replaceFirst(RegExp(r'^0+'), '');
    if (_dialCode == '+234') {
      return raw.length == 10 ? raw : null; // NG national numbers are 10 digits
    }
    return (raw.length >= 7 && raw.length <= 14) ? raw : null;
  }

  Future<void> _submit() async {
    final raw = _normalized();
    if (raw == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_dialCode == '+234'
              ? 'Enter a valid Nigerian number — 10 digits after +234 (e.g. 803 123 4567).'
              : 'Enter a valid phone number.'),
        ),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final e164 = '$_dialCode$raw';
    final sent = await auth.startPhoneAuth(e164);
    if (!mounted) return;
    if (sent) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const OtpScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.phoneError ?? 'Could not send the code.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Your phone')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              const Text(
                'What\'s your number?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'We\'ll text you a 6-digit code to verify it\'s really you.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _DialCodePicker(
                    value: _dialCode,
                    onChanged: (v) => setState(() => _dialCode = v),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      keyboardType: TextInputType.phone,
                      autofocus: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                      ],
                      maxLength: 15,
                      decoration: InputDecoration(
                        counterText: '',
                        hintText:
                            _dialCode == '+234' ? '803 123 4567' : '555 123 4567',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: AppColors.textSecondary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Demo build: no real SMS is sent. Use code 123456 on the next screen.',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: auth.sendingCode ? null : _submit,
                  child: auth.sendingCode
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.4, color: Colors.black),
                        )
                      : const Text('Send code'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialCodePicker extends StatelessWidget {
  const _DialCodePicker({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  static const _codes = ['+234', '+1', '+44', '+91', '+27', '+254', '+233'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: AppColors.surfaceAlt,
          items: _codes
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) => v == null ? null : onChanged(v),
        ),
      ),
    );
  }
}
