import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/items_provider.dart';
import '../../providers/permission_provider.dart';
import '../../providers/swipe_match_provider.dart';
import '../../widgets/common_widgets.dart';
import '../chats/chats_screen.dart';
import '../explore/explore_screen.dart';
import '../matches/matches_screen.dart';
import '../profile/profile_screen.dart';
import '../swipe/swipe_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _index = 0;
  bool _permSheetOpen = false;

  final _pages = const [
    SwipeScreen(),
    ExploreScreen(),
    MatchesScreen(),
    ChatsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId != null) {
        await context.read<ItemsProvider>().loadMyItems(userId);
        if (!mounted) return;
        await context.read<SwipeMatchProvider>().refreshAll(userId);
      }
      _checkPermissions();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // "Always check on launch/resume": re-evaluate permissions every time the
    // app comes to the foreground.
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final perm = context.read<PermissionProvider>();
    await perm.refresh();
    if (!mounted) return;
    // Ask wisely: only nudge when something is missing AND still askable.
    if (perm.anyMissing && !perm.blockedInSettings && !_permSheetOpen) {
      _showPermissionSheet(perm);
    }
  }

  Future<void> _showPermissionSheet(PermissionProvider perm) async {
    _permSheetOpen = true;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _PermissionSheet(perm: perm),
    );
    _permSheetOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    final swipeMatch = context.watch<SwipeMatchProvider>();
    final perm = context.watch<PermissionProvider>();
    final pendingBadge = swipeMatch.likesYouCount + swipeMatch.unseenMatchCount;

    return Scaffold(
      body: Column(
        children: [
          if (perm.blockedInSettings)
            _SettingsBanner(onTap: () => perm.openSettings()),
          Expanded(
            child: IndexedStack(index: _index, children: _pages),
          ),
        ],
      ),
      bottomNavigationBar: _BumbleNav(
        index: _index,
        badge: pendingBadge,
        onTap: (i) {
          setState(() => _index = i);
          final userId = context.read<AuthProvider>().currentUser?.id;
          if (userId != null && (i == 2 || i == 3)) {
            context.read<SwipeMatchProvider>().refreshAll(userId);
          }
        },
      ),
    );
  }
}

class _SettingsBanner extends StatelessWidget {
  const _SettingsBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceAlt,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          child: Row(
            children: [
              const Icon(Icons.info_outline,
                  size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Notifications/location are off. Enable them in Settings for the full experience.',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12.5),
                ),
              ),
              TextButton(onPressed: onTap, child: const Text('Settings')),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionSheet extends StatelessWidget {
  const _PermissionSheet({required this.perm});
  final PermissionProvider perm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Finish setting up',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text(
            'Enable these so you never miss a swap match.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          if (!perm.notifGranted)
            _row(
              context,
              icon: Icons.notifications_active_rounded,
              label: 'Notifications',
              onTap: () => perm.requestNotification(),
            ),
          if (!perm.locationGranted)
            _row(
              context,
              icon: Icons.location_on_rounded,
              label: 'Location',
              onTap: () => perm.requestLocation(),
            ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Not now'),
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Future<bool> Function() onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              await onTap();
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }
}

class _BumbleNav extends StatelessWidget {
  const _BumbleNav({
    required this.index,
    required this.onTap,
    required this.badge,
  });

  final int index;
  final ValueChanged<int> onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              _item(0, Icons.home_rounded, Icons.home_outlined),
              _item(1, Icons.explore_rounded, Icons.explore_outlined),
              _item(2, Icons.swap_horiz_rounded, Icons.swap_horiz_rounded,
                  badge: badge),
              _item(3, Icons.chat_bubble_rounded, Icons.chat_bubble_outline),
              _item(4, Icons.person_rounded, Icons.person_outline),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(int i, IconData active, IconData inactive, {int badge = 0}) {
    final selected = i == index;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(i),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Icon(
              selected ? active : inactive,
              color: selected ? AppColors.primary : AppColors.textHint,
              size: 27,
            ),
            if (badge > 0)
              Positioned(
                right: 28,
                top: 10,
                child: CountBadge(count: badge, color: AppColors.accent),
              ),
          ],
        ),
      ),
    );
  }
}
