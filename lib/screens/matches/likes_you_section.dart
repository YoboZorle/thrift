import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
import 'match_detail_screen.dart';

/// "Likes You" inbox — incoming pending likes on MY items. Liking back forms a
/// match for that exact product pair; passing dismisses it.
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
        title: 'No incoming likes',
        message:
            'When someone wants to swap their item for one of yours, their '
            'offer lands here. Like back to make it a match.',
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
    setState(() => _busy = true);

    final match = await swipeMatch.respondToLike(
      userId: userId,
      incoming: widget.incoming,
      direction: direction,
    );

    if (!mounted) return;
    setState(() => _busy = false);

    if (direction == SwipeDirection.like && match != null) {
      _showMatch(match, userId);
    } else if (direction == SwipeDirection.pass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passed on this offer')),
      );
    }
  }

  void _showMatch(MatchModel match, String userId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _MatchPopup(
        onReview: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MatchDetailScreen(match: match),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final swipeMatch = context.read<SwipeMatchProvider>();
    final incoming = widget.incoming;

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        swipeMatch.item(incoming.swiperItemId), // their offered item
        swipeMatch.item(incoming.targetItemId), // my item they want
        swipeMatch.user(incoming.swiperUserId), // them
      ]),
      builder: (context, snap) {
        final theirItem = snap.data?[0] as ItemModel?;
        final myItem = snap.data?[1] as ItemModel?;
        final them = snap.data?[2] as UserModel?;

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
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    backgroundImage: (them?.avatarUrl != null)
                        ? NetworkImage(them!.avatarUrl!)
                        : null,
                    child: them?.avatarUrl == null
                        ? Text(
                            (them?.name ?? '?').characters.first,
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700),
                          )
                        : null,
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
                          'wants to swap · ${Formatters.timeAgo(incoming.createdAt)}',
                          style: const TextStyle(
                              color: AppColors.textHint, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _miniItem(
                      theirItem,
                      label: 'They give',
                      accent: AppColors.like,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.swap_horiz,
                        color: AppColors.primary, size: 22),
                  ),
                  Expanded(
                    child: _miniItem(
                      myItem,
                      label: 'For your',
                      accent: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => _respond(SwipeDirection.pass),
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
                      onPressed: _busy ? null : () => _respond(SwipeDirection.like),
                      icon: _busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
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

  Widget _miniItem(ItemModel? item, {required String label, required Color accent}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              color: accent, fontSize: 11, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        AspectRatio(
          aspectRatio: 1.4,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: item == null
                ? const SizedBox()
                : ItemImage(source: item.primaryImage),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          item?.title ?? '—',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _MatchPopup extends StatelessWidget {
  const _MatchPopup({
    required this.onReview,
  });

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
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'You both want to swap. Review the details and start chatting.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryDark,
                ),
                child: const Text('Review & chat'),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
