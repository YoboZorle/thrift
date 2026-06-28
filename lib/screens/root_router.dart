import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/permission_provider.dart';
import 'auth/profile_setup_screen.dart';
import 'home/home_shell.dart';
import 'onboarding/welcome_screen.dart';
import 'permissions/permission_gate_screen.dart';
import 'splash_screen.dart';

/// Single source of truth for top-level navigation. Renders the right screen
/// purely from auth + permission state. Permissions are compulsory and are
/// re-checked on every resume, so revoking one immediately re-gates the app.
class RootRouter extends StatefulWidget {
  const RootRouter({super.key});

  @override
  State<RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<RootRouter> with WidgetsBindingObserver {
  final _authNavKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<AuthProvider>().bootstrap();
      if (!mounted) return;
      await context.read<PermissionProvider>().refresh();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Compulsory: re-check permissions every time the app returns to foreground.
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<PermissionProvider>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoading) return const SplashScreen();

    if (!auth.isAuthenticated) {
      // Nested navigator for onboarding -> auth steps, kept stable via key.
      return Navigator(
        key: _authNavKey,
        onGenerateRoute: (_) =>
            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    }

    if (auth.needsProfileSetup) return const ProfileSetupScreen();

    // Compulsory permission gates — notifications first, then location.
    final perm = context.watch<PermissionProvider>();
    if (perm.needsNotification) {
      return const PermissionGateScreen(kind: PermissionKind.notification);
    }
    if (perm.needsLocation) {
      return const PermissionGateScreen(kind: PermissionKind.location);
    }

    return const HomeShell();
  }
}
