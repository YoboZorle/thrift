import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/enums.dart';
import '../../models/item_model.dart';
import '../../models/match_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/swipe_match_provider.dart';
import '../../services/service_locator.dart';
import '../../widgets/common_widgets.dart';
import '../listings/add_item_screen.dart';
import '../matches/match_detail_screen.dart';
import 'swipe_item_detail_screen.dart';
import 'widgets/swipe_card.dart';
import 'widgets/swipe_card_stack.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  final _cardController = SwipeCardController();
  final Map<String, UserModel?> _ownerCache = {};

  ItemCategory? _filter;
  bool _exhausted = false;

  // Memoised view deck so the card stack isn't reset on every rebuild.
  String _deckKey = '';
  List<ItemModel> _viewDeck = [];
  bool _didInitialLoad = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId != null) {
        await context.read<SwipeMatchProvider>().loadDeck(userId);
      }
      if (mounted) setState(() => _didInitialLoad = true);
    });
  }

  Future<UserModel?> _owner(String id) async {
    if (_ownerCache.containsKey(id)) return _ownerCache[id];
    final u = await context.read<SwipeMatchProvider>().user(id);
    _ownerCache[id] = u;
    return u;
  }

  Future<void> _handleSwipe(ItemModel item, SwipeDirection direction) async {
    final userId = context.read<AuthProvider>().currentUser!.id;
    final match = await context.read<SwipeMatchProvider>().swipe(
          userId: userId,
          target: item,
          direction: direction,
        );
    if (match != null && mounted) _showMatchDialog(match);
  }

  Future<void> _onUndo() async {
    if (!_cardController.undo()) return;
    final userId = context.read<AuthProvider>().currentUser!.id;
    final item =
        await context.read<SwipeMatchProvider>().undoLast(userId: userId);
    if (mounted) setState(() => _exhausted = false);
    if (item != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Brought back "${item.title}"')),
      );
    }
  }

  /// When the visible top card hits its listing window (48h; 5 min in test),
  /// drop expired listings from the deck so they can no longer be matched.
  Future<void> _onCardExpired(ItemModel item) async {
    if (!mounted) return;
    if (_cardController.currentItem?.id != item.id) return;
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId != null) {
      setState(() => _exhausted = false);
      await context.read<SwipeMatchProvider>().loadDeck(userId);
    }
  }

  Future<void> _saveItem(ItemModel item) async {
    final userId = context.read<AuthProvider>().currentUser!.id;
    final nowSaved =
        await context.read<SwipeMatchProvider>().toggleSave(userId, item.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(nowSaved
              ? 'Saved "${item.title}"'
              : 'Removed "${item.title}" from saved'),
        ),
      );
    }
  }

  void _onSave() {
    final current = _cardController.currentItem;
    if (current != null) _saveItem(current);
  }

  Future<void> _openDetail(ItemModel item, UserModel? owner) async {
    final decision = await Navigator.of(context).push<SwipeDecision>(
      MaterialPageRoute(
        builder: (_) => SwipeItemDetailScreen(item: item, owner: owner),
      ),
    );
    if (!mounted || decision == null) return;
    switch (decision) {
      case SwipeDecision.like:
        await _decideFromReview(item, SwipeDirection.like);
        break;
      case SwipeDecision.pass:
        await _decideFromReview(item, SwipeDirection.pass);
        break;
      case SwipeDecision.save:
        await _saveItem(item);
        break;
      case SwipeDecision.none:
        break;
    }
  }

  /// Decisions made on the full review page act on THAT exact item (not just
  /// whatever card happens to be on top), record it, drop it from the deck so
  /// it never returns, and surface the match dialog on a match.
  Future<void> _decideFromReview(ItemModel item, SwipeDirection dir) async {
    final userId = context.read<AuthProvider>().currentUser!.id;
    final provider = context.read<SwipeMatchProvider>();
    final match = await provider.swipe(
      userId: userId,
      target: item,
      direction: dir,
    );
    if (mounted) setState(() => _exhausted = false);
    await provider.loadDeck(userId);
    if (match != null && mounted) _showMatchDialog(match);
  }

  void _showMatchDialog(MatchModel match) {
    final userId = context.read<AuthProvider>().currentUser!.id;
    showDialog(
      context: context,
      builder: (_) => _MatchDialog(
        match: match,
        userId: userId,
        onChat: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => MatchDetailScreen(match: match)),
          );
        },
      ),
    );
  }

  void _openFilter(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filter by category',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _filter == null,
                    onSelected: (_) {
                      setState(() {
                        _filter = null;
                        _exhausted = false;
                      });
                      Navigator.of(sheetCtx).pop();
                    },
                  ),
                  ...ItemCategory.values.map(
                    (c) => ChoiceChip(
                      label: Text('${c.emoji} ${c.label}'),
                      selected: _filter == c,
                      onSelected: (_) {
                        setState(() {
                          _filter = c;
                          _exhausted = false;
                        });
                        Navigator.of(sheetCtx).pop();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final swipeMatch = context.watch<SwipeMatchProvider>();
    final auth = context.watch<AuthProvider>();
    final location = (auth.currentUser?.location.isNotEmpty ?? false)
        ? auth.currentUser!.location
        : 'Discover near you';

    // Memoise the filtered view deck (keyed by filter + deck size so swipes,
    // which don't change the deck list, never reset the card stack).
    final key = '${_filter?.name ?? 'all'}|${swipeMatch.deck.length}';
    if (key != _deckKey) {
      _deckKey = key;
      _viewDeck = _filter == null
          ? List<ItemModel>.from(swipeMatch.deck)
          : swipeMatch.deck.where((i) => i.category == _filter).toList();
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(
              location: location,
              onAdd: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddItemScreen()),
              ),
              onFilter: () => _openFilter(context),
            ),
            Expanded(child: _buildDeck(swipeMatch)),
            // The Pass / interest action layer disappears when there are no
            // cards to act on (all caught up).
            if (_didInitialLoad && _viewDeck.isNotEmpty && !_exhausted) ...[
              _ActionBar(
                enabled: true,
                canUndo: swipeMatch.canUndo,
                onPass: () => _cardController.swipeLeft(),
                onUndo: _onUndo,
                onSave: _onSave,
                onLike: () => _cardController.swipeRight(),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeck(SwipeMatchProvider swipeMatch) {
    if (!_didInitialLoad) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_viewDeck.isEmpty) {
      return EmptyState(
        icon: Icons.done_all_rounded,
        title: 'All caught up!',
        message: _filter != null
            ? 'No items in this category right now. Try clearing the filter.'
            : 'You\'ve seen everything nearby. List an item or check back soon.',
        action: _filter != null
            ? OutlinedButton(
                onPressed: () => setState(() {
                  _filter = null;
                  _exhausted = false;
                }),
                child: const Text('Clear filter'),
              )
            : null,
      );
    }

    final stack = Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: SwipeCardStack(
        key: ValueKey(_deckKey),
        items: _viewDeck,
        controller: _cardController,
        onSwipe: _handleSwipe,
        onEmpty: () {
          if (mounted) setState(() => _exhausted = true);
        },
        cardBuilder: (context, item) {
          return FutureBuilder<UserModel?>(
            future: _owner(item.ownerId),
            builder: (context, snap) => SwipeCard(
              item: item,
              owner: snap.data,
              distanceLabel: ServiceLocator.locationService.labelFor(item),
              onExpand: () => _openDetail(item, snap.data),
              onExpire: () => _onCardExpired(item),
            ),
          );
        },
      ),
    );

    // The stack stays mounted even when exhausted so Undo can bring a card back.
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_exhausted)
          EmptyState(
            icon: Icons.done_all_rounded,
            title: 'All caught up!',
            message:
                'You\'ve seen everything nearby. Check back soon for new listings.',
            action: swipeMatch.canUndo
                ? OutlinedButton.icon(
                    onPressed: _onUndo,
                    icon: const Icon(Icons.replay_rounded, size: 18),
                    label: const Text('Undo last'),
                  )
                : null,
          )
        else
          const SizedBox.expand(),
        stack,
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.location,
    required this.onAdd,
    required this.onFilter,
  });

  final String location;
  final VoidCallback onAdd;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          _roundButton(Icons.add_rounded, onAdd),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'Discover',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on,
                        size: 13, color: AppColors.primary),
                    const SizedBox(width: 2),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: Text(
                        location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _roundButton(Icons.tune_rounded, onFilter),
        ],
      ),
    );
  }

  Widget _roundButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          color: AppColors.surfaceAlt,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 22),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.enabled,
    required this.canUndo,
    required this.onPass,
    required this.onUndo,
    required this.onSave,
    required this.onLike,
  });

  final bool enabled;
  final bool canUndo;
  final VoidCallback onPass;
  final VoidCallback onUndo;
  final VoidCallback onSave;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pill(
            color: AppColors.nope,
            icon: Icons.close_rounded,
            onTap: enabled ? onPass : null,
            wide: true,
          ),
          const SizedBox(width: 12),
          _pill(
            color: AppColors.surfaceAlt,
            iconColor: AppColors.textPrimary,
            icon: Icons.replay_rounded,
            onTap: canUndo ? onUndo : null,
          ),
          const SizedBox(width: 12),
          _pill(
            color: AppColors.surfaceAlt,
            iconColor: AppColors.textPrimary,
            icon: Icons.bookmark_border_rounded,
            onTap: enabled ? onSave : null,
          ),
          const SizedBox(width: 12),
          _pill(
            color: AppColors.like,
            icon: Icons.favorite_rounded,
            onTap: enabled ? onLike : null,
            wide: true,
          ),
        ],
      ),
    );
  }

  Widget _pill({
    required Color color,
    required IconData icon,
    required VoidCallback? onTap,
    Color iconColor = Colors.white,
    bool wide = false,
  }) {
    final disabled = onTap == null;
    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(wide ? 22 : 30),
        child: InkWell(
          borderRadius: BorderRadius.circular(wide ? 22 : 30),
          onTap: onTap,
          child: Container(
            width: wide ? 92 : 58,
            height: 58,
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: wide ? 30 : 26),
          ),
        ),
      ),
    );
  }
}

/// "It's a match!" celebration.
class _MatchDialog extends StatelessWidget {
  const _MatchDialog({
    required this.match,
    required this.userId,
    required this.onChat,
  });

  final MatchModel match;
  final String userId;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    final swipeMatch = context.read<SwipeMatchProvider>();
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
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'You both want to swap. Start chatting to arrange the exchange.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 22),
            FutureBuilder<List<ItemModel?>>(
              future: Future.wait([
                swipeMatch.item(match.myItemId(userId)),
                swipeMatch.item(match.theirItemId(userId)),
              ]),
              builder: (context, snap) {
                final mine = snap.data?.elementAt(0);
                final theirs = snap.data?.elementAt(1);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _matchItem(mine, 'You give'),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.swap_horiz,
                          color: Colors.black, size: 32),
                    ),
                    _matchItem(theirs, 'You get'),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                onPressed: onChat,
                child: const Text('Review & Chat'),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Keep swiping',
                  style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _matchItem(ItemModel? item, String label) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: item == null
              ? const SizedBox()
              : ItemImage(source: item.primaryImage),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(color: Colors.black87, fontSize: 12)),
      ],
    );
  }
}
