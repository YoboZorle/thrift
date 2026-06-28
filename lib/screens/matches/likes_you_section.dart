import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/enums.dart';
import '../../models/item_model.dart';
import '../../models/match_model.dart';
import '../../models/swipe_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/swipe_match_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/countdown_text.dart';
import 'match_detail_screen.dart';

/// "Likes You" inbox — people who've liked one of YOUR items. Swap back (like
/// any of their items) to make it a match; pass dismisses them.
class LikesYouSection extends StatelessWidget {
  const LikesYouSection({super.key});

  @override
  Widget build(BuildContext context) {
    final swipeMatch = context.watch<SwipeMatchProvider>();
    final userId = context.read<AuthProvider>().currentUser!.id;
    final likes = swipeMatch.likesReceived;

    if (likes.isEmpty) {
      return const EmptyState(
        icon: Icons.volunteer_activism_outlined,
        title: 'No likes yet',
        message:
            'When someone likes one of your items, they show up here. Swap '
            'back to make it a match.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => swipeMatch.refreshAll(userId),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: likes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _LikeTile(incoming: likes[i]),
      ),
    );
  }
}

class _LikeTile extends StatefulWidget {
  const _LikeTile({required this.incoming});
  final SwipeModel incoming;

  @override
  State<_LikeTile> createState() => _LikeTileState();
}

class _LikeTileState extends State<_LikeTile> {
  bool _busy = false;

  Future<void> _respond(SwipeDirection direction) async {
    final swipeMatch = context.read<SwipeMatchProvider>();
    final userId = context.read<AuthProvider>().currentUser!.id;
    // Capture stable refs: responding reloads the inbox, which disposes THIS
    // tile before the await returns — so we can't rely on its context after.
    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);

    final match = await swipeMatch.respondToLike(
      userId: userId,
      incoming: widget.incoming,
      direction: direction,
    );

    if (mounted) setState(() => _busy = false);

    if (direction == SwipeDirection.like) {
      if (match != null) {
        _showMatch(navigator, match);
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text('Liked back — this offer has expired.')),
        );
      }
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Dismissed')),
      );
    }
  }

  void _showMatch(NavigatorState navigator, MatchModel match) {
    showDialog(
      context: navigator.context,
      barrierDismissible: false,
      builder: (_) => _MatchPopup(
        onReview: () {
          navigator.pop();
          navigator.push(
            MaterialPageRoute(builder: (_) => MatchDetailScreen(match: match)),
          );
        },
      ),
    );
  }

  void _reloadLikes() {
    if (!mounted) return;
    final userId = context.read<AuthProvider>().currentUser!.id;
    context.read<SwipeMatchProvider>().loadLikesReceived(userId);
  }

  @override
  Widget build(BuildContext context) {
    final swipeMatch = context.read<SwipeMatchProvider>();
    final incoming = widget.incoming;

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        swipeMatch.user(incoming.swiperUserId), // them
        swipeMatch.item(incoming.targetItemId), // my item they liked
        swipeMatch.itemsOf(incoming.swiperUserId), // their items to swap for
      ]),
      builder: (context, snap) {
        final them = snap.data?[0] as UserModel?;
        final myItem = snap.data?[1] as ItemModel?;
        final theirItems = (snap.data?[2] as List<ItemModel>? ?? const [])
            .where((i) => i.isActive)
            .toList();

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipOval(
                    child: SizedBox(
                      width: 34,
                      height: 34,
                      child: ItemImage(source: them?.avatarUrl ?? ''),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          them?.name ?? 'Someone',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        Text(
                          'likes your ${myItem?.title ?? 'item'} · ${Formatters.timeAgo(incoming.createdAt)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.textHint, fontSize: 12),
                        ),
                        const SizedBox(height: 3),
                        CountdownText(
                          deadline: incoming.createdAt
                              .add(AppConfig.listingWindow),
                          onExpired: _reloadLikes,
                          builder: (context, label, expired) => Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                  expired
                                      ? Icons.timer_off_outlined
                                      : Icons.timer_outlined,
                                  size: 12,
                                  color: expired
                                      ? AppColors.nope
                                      : AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                expired
                                    ? 'Offer expired'
                                    : 'Reciprocate within $label',
                                style: TextStyle(
                                    color: expired
                                        ? AppColors.nope
                                        : AppColors.primary,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (myItem != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 38,
                        height: 38,
                        child: ItemImage(source: myItem.primaryImage),
                      ),
                    ),
                ],
              ),
              if (theirItems.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Swap for one of their items',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12.5),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 76,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: theirItems.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 76,
                        height: 76,
                        child: ItemImage(source: theirItems[i].primaryImage),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _busy ? null : () => _respond(SwipeDirection.pass),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Pass'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.nope,
                        side: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          _busy ? null : () => _respond(SwipeDirection.like),
                      icon: _busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black),
                            )
                          : const Icon(Icons.swap_horiz, size: 18),
                      label: const Text('Swap back'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MatchPopup extends StatelessWidget {
  const _MatchPopup({required this.onReview});
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "It's a Swap Match! 🎉",
              style: TextStyle(
                color: Colors.black,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'You both want to swap. Review the details and start chatting.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Review & chat'),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}
