import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/permission_provider.dart';

enum PermissionKind { notification, location }

/// A blocking, compulsory permission page. The app cannot proceed until the
/// permission is granted. If it's been permanently denied, the only path is
/// Settings — and RootRouter re-checks on resume, so returning with it enabled
/// unlocks the app automatically.
class PermissionGateScreen extends StatelessWidget {
  const PermissionGateScreen({super.key, required this.kind});

  final PermissionKind kind;

  bool get _isNotification => kind == PermissionKind.notification;

  @override
  Widget build(BuildContext context) {
    final perm = context.watch<PermissionProvider>();
    final blocked =
        _isNotification ? perm.notifPermDenied : perm.locationPermDenied;

    final icon = _isNotification
        ? Icons.notifications_active_rounded
        : Icons.location_on_rounded;
    final title =
        _isNotification ? 'Turn on notifications' : 'Turn on location';
    final body = _isNotification
        ? 'Notifications are required so you never miss a swap match or a new message. This keeps the swap going.'
        : 'Location is required to show items near you and match you with swappers in your city and state.';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 50, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                body,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary, height: 1.5, fontSize: 15),
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
                    Icon(Icons.lock_outline,
                        size: 18, color: AppColors.textSecondary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This permission is required to continue.',
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
                  onPressed: () async {
                    if (blocked) {
                      await perm.openSettings();
                    } else if (_isNotification) {
                      await perm.requestNotification();
                    } else {
                      await perm.requestLocation();
                    }
                  },
                  child: Text(blocked ? 'Open Settings' : 'Enable'),
                ),
              ),
              if (blocked) ...[
                const SizedBox(height: 10),
                Text(
                  'You\'ve denied this before. Enable it in Settings, then return here.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textHint, fontSize: 12.5),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
