import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/permission_provider.dart';

/// Shown once per session after sign-in when notifications/location are missing.
/// Triggers the real OS prompts and explains *why* each is useful.
class PermissionPrimingScreen extends StatelessWidget {
  const PermissionPrimingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final perm = context.watch<PermissionProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.tune_rounded,
                    size: 40, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              const Text(
                'Turn on the good stuff',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Two quick permissions make swapping work properly.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 28),
              _PermRow(
                icon: Icons.notifications_active_rounded,
                title: 'Notifications',
                subtitle: 'Know the moment someone wants to swap with you.',
                granted: perm.notifGranted,
                blocked: perm.notifPermDenied && !perm.notifGranted,
                onEnable: () => perm.requestNotification(),
                onSettings: () => perm.openSettings(),
              ),
              const SizedBox(height: 14),
              _PermRow(
                icon: Icons.location_on_rounded,
                title: 'Location',
                subtitle: 'See how far away each item is (e.g. "2 KM away").',
                granted: perm.locationGranted,
                blocked: perm.locationPermDenied && !perm.locationGranted,
                onEnable: () => perm.requestLocation(),
                onSettings: () => perm.openSettings(),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => perm.markPrimed(),
                  child: Text(perm.allGranted ? 'Continue' : 'Done'),
                ),
              ),
              if (!perm.allGranted)
                TextButton(
                  onPressed: () => perm.markPrimed(),
                  child: const Text('Maybe later'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermRow extends StatelessWidget {
  const _PermRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.granted,
    required this.blocked,
    required this.onEnable,
    required this.onSettings,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool granted;
  final bool blocked;
  final VoidCallback onEnable;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12.5)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (granted)
            const Icon(Icons.check_circle, color: AppColors.like)
          else if (blocked)
            TextButton(onPressed: onSettings, child: const Text('Settings'))
          else
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              onPressed: onEnable,
              child: const Text('Enable'),
            ),
        ],
      ),
    );
  }
}
