import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/permission_provider.dart';
import 'auth/profile_setup_screen.dart';
import 'home/home_shell.dart';
import 'onboarding/welcome_screen.dart';
import 'permissions/permission_priming_screen.dart';
import 'splash_screen.dart';

/// Single source of truth for top-level navigation. Renders the right screen
/// purely from auth + permission state, so transitions need no manual routing.
class RootRouter extends StatefulWidget {
  const RootRouter({super.key});

  @override
  State<RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<RootRouter> {
  final _authNavKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<AuthProvider>().bootstrap();
      if (!mounted) return;
      await context.read<PermissionProvider>().refresh();
    });
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

    final perm = context.watch<PermissionProvider>();
    if (perm.needsPriming) return const PermissionPrimingScreen();

    return const HomeShell();
  }
}
