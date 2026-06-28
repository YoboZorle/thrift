import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/item_model.dart';
import '../../models/match_model.dart';
import '../../models/swipe_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/swipe_match_provider.dart';
import '../../widgets/common_widgets.dart';
import '../listings/add_item_screen.dart';
import '../listings/my_listings_screen.dart';
import 'likes_you_section.dart';
import 'match_detail_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId != null) {
        context.read<SwipeMatchProvider>().refreshAll(userId);
      }
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final swipeMatch = context.watch<SwipeMatchProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matches'),
        actions: [
          IconButton(
            tooltip: 'My listings',
            icon: const Icon(Icons.inventory_2_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MyListingsScreen()),
            ),
          ),
          IconButton(
            tooltip: 'List an item',
            icon: const Icon(Icons.add_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddItemScreen()),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: 'Matches (${swipeMatch.matchCount})'),
            Tab(text: 'Likes You (${swipeMatch.likesYouCount})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _MatchesTab(),
          LikesYouSection(),
        ],
      ),
    );
  }
}

class _MatchesTab extends StatelessWidget {
  const _MatchesTab();

  @override
  Widget build(BuildContext context) {
    final swipeMatch = context.watch<SwipeMatchProvider>();
    final userId = context.read<AuthProvider>().currentUser!.id;
    final matches = swipeMatch.matches;

    if (matches.isEmpty) {
      return const EmptyState(
        icon: Icons.favorite_border,
        title: 'No matches yet',
        message:
            'Keep swiping! When someone wants to swap their item for yours, it shows up here.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => swipeMatch.refreshAll(userId),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: matches.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _MatchTile(match: matches[i]),
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({required this.match});
  final MatchModel match;

  @override
  Widget build(BuildContext context) {
    final swipeMatch = context.read<SwipeMatchProvider>();
    final userId = context.read<AuthProvider>().currentUser!.id;

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        swipeMatch.item(match.myItemId(userId)),
        swipeMatch.item(match.theirItemId(userId)),
        swipeMatch.user(match.otherUserId(userId)),
      ]),
      builder: (context, snap) {
        final mine = snap.data?[0] as ItemModel?;
        final theirs = snap.data?[1] as ItemModel?;
        final other = snap.data?[2] as UserModel?;

        return Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              swipeMatch.markSeen(match.id, userId);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MatchDetailScreen(match: match),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: match.seen ? AppColors.border : AppColors.primary,
                  width: match.seen ? 1 : 1.6,
                ),
              ),
              child: Row(
                children: [
                  _thumb(theirs),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.swap_horiz,
                        color: AppColors.primary, size: 20),
                  ),
                  _thumb(mine),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                other?.name ?? 'Swapper',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                            ),
                            if (!match.seen)
                              Container(
                                width: 9,
                                height: 9,
                                decoration: const BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          theirs == null || mine == null
                              ? ''
                              : '${theirs.title}  for  ${mine.title}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          Formatters.timeAgo(match.lastActivity),
                          style: const TextStyle(
                              color: AppColors.textHint, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _thumb(ItemModel? item) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: item == null
          ? const SizedBox()
          : ItemImage(source: item.primaryImage),
    );
  }
}
