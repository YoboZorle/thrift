import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'phone_input_screen.dart';

class AuthLandingScreen extends StatelessWidget {
  const AuthLandingScreen({super.key});

  Future<void> _social(
    BuildContext context,
    Future<bool> Function() action,
  ) async {
    final auth = context.read<AuthProvider>();
    final ok = await action();
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.lastError ?? 'Sign-in failed.')),
      );
    }
    // On success RootRouter swaps the screen automatically.
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.swap_horiz_rounded,
                    size: 40, color: Colors.black),
              ),
              const SizedBox(height: 24),
              const Text(
                'Create your account',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to start swapping. We\'ll keep your number private.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: auth.busy
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const PhoneInputScreen()),
                        ),
                icon: const Icon(Icons.phone_rounded, size: 20),
                label: const Text('Continue with phone'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: auth.busy
                    ? null
                    : () => _social(context, auth.continueWithGoogle),
                icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                label: const Text('Continue with Google'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: auth.busy
                    ? null
                    : () => _social(context, auth.continueWithApple),
                icon: const Icon(Icons.apple_rounded, size: 22),
                label: const Text('Continue with Apple'),
              ),
              const SizedBox(height: 18),
              if (auth.busy)
                const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                )
              else
                TextButton(
                  onPressed: () => _social(context, auth.continueAsGuest),
                  child: const Text('Browse as guest'),
                ),
              const SizedBox(height: 8),
              const Text(
                'By continuing you agree to ${AppConstants.appName}\'s Terms & Privacy Policy.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textHint, fontSize: 11.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
