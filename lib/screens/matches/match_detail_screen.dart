import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/enums.dart';
import '../../models/item_model.dart';
import '../../models/match_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/swipe_match_provider.dart';
import '../../widgets/common_widgets.dart';
import '../chat/chat_screen.dart';

/// Review screen for a confirmed swap: shows both items, the other swapper,
/// and a gateway into the product-scoped chat.
class MatchDetailScreen extends StatefulWidget {
  const MatchDetailScreen({super.key, required this.match});
  final MatchModel match;

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    final swipeMatch = context.read<SwipeMatchProvider>();
    final userId = context.read<AuthProvider>().currentUser!.id;
    // Opening the detail counts as seeing the match.
    swipeMatch.markSeen(widget.match.id, userId);
    _future = Future.wait([
      swipeMatch.item(widget.match.myItemId(userId)),
      swipeMatch.item(widget.match.theirItemId(userId)),
      swipeMatch.user(widget.match.otherUserId(userId)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Swap details')),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final mine = snap.data![0] as ItemModel?;
          final theirs = snap.data![1] as ItemModel?;
          final other = snap.data![2] as UserModel?;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _swapperHeader(other),
              const SizedBox(height: 20),
              _swapVisual(theirs, mine),
              const SizedBox(height: 24),
              if (theirs != null) _itemBlock('They give you', theirs, AppColors.like),
              if (mine != null) ...[
                const SizedBox(height: 16),
                _itemBlock('You give them', mine, AppColors.primary),
              ],
              const SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: other == null
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                match: widget.match,
                                otherUser: other,
                                myItem: mine,
                                theirItem: theirs,
                              ),
                            ),
                          ),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Start chatting'),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Matched ${Formatters.timeAgo(widget.match.createdAt)}',
                  style: const TextStyle(color: AppColors.textHint, fontSize: 12),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _swapperHeader(UserModel? other) {
    return Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          backgroundImage:
              other?.avatarUrl != null ? NetworkImage(other!.avatarUrl!) : null,
          child: other?.avatarUrl == null
              ? Text(
                  (other?.name ?? '?').characters.first,
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 20),
                )
              : null,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                other?.name ?? 'Swapper',
                style: const TextStyle(
                    fontSize: 19, fontWeight: FontWeight.w800),
              ),
              if ((other?.location ?? '').isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: AppColors.textHint),
                    const SizedBox(width: 2),
                    Text(
                      other!.location,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _swapVisual(ItemModel? theirs, ItemModel? mine) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.10),
            AppColors.primary.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(child: _thumbBig(theirs)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Icon(Icons.swap_horiz, color: AppColors.primary, size: 30),
          ),
          Expanded(child: _thumbBig(mine)),
        ],
      ),
    );
  }

  Widget _thumbBig(ItemModel? item) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
        ),
        child: item == null
            ? const SizedBox()
            : ItemImage(source: item.primaryImage),
      ),
    );
  }

  Widget _itemBlock(String label, ItemModel item, Color accent) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 76,
            height: 76,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: ItemImage(source: item.primaryImage),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                      color: accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4),
                ),
                const SizedBox(height: 3),
                Text(
                  item.title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    TagChip(label: '${item.category.emoji} ${item.category.label}'),
                    TagChip(
                      label: item.condition.label,
                      color: AppColors.superLike,
                    ),
                    if (item.estimatedValue != null)
                      TagChip(
                        label: '~${Formatters.money(item.estimatedValue!)}',
                        color: AppColors.primaryDark,
                      ),
                  ],
                ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    item.description,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13, height: 1.35),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
