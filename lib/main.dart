import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/items_provider.dart';
import 'providers/permission_provider.dart';
import 'providers/swipe_match_provider.dart';
import 'services/service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Build services: local data + (Firebase-or-dev) auth + permissions,
  // notifications and location. The app is fully runnable with no Firebase.
  await ServiceLocator.setup();
  final repo = ServiceLocator.repository;
  final storage = ServiceLocator.storage;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              AuthProvider(ServiceLocator.authService, repo, storage),
        ),
        ChangeNotifierProvider(create: (_) => ItemsProvider(repo)),
        ChangeNotifierProvider(
          create: (_) =>
              SwipeMatchProvider(repo, ServiceLocator.notificationService),
        ),
        ChangeNotifierProvider(create: (_) => ChatProvider(repo)),
        ChangeNotifierProvider(
          create: (_) => PermissionProvider(
            ServiceLocator.permissionService,
            ServiceLocator.locationService,
          ),
        ),
      ],
      child: const ThriftSwapApp(),
    ),
  );
}
