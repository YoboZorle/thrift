import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/items_provider.dart';
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

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId != null) {
        await context.read<ItemsProvider>().loadMyItems(userId);
        if (!mounted) return;
        await context.read<SwipeMatchProvider>().refreshAll(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final swipeMatch = context.watch<SwipeMatchProvider>();
    final pendingBadge = swipeMatch.likesYouCount + swipeMatch.unseenMatchCount;

    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
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
