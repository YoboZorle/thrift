import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/enums.dart';
import '../../models/item_model.dart';
import '../../models/match_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/items_provider.dart';
import '../../providers/swipe_match_provider.dart';
import '../../services/service_locator.dart';
import '../../widgets/common_widgets.dart';
import '../listings/add_item_screen.dart';
import '../listings/item_detail_screen.dart';
import '../matches/match_detail_screen.dart';
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
  String? _personaId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureActiveItem());
  }

  Future<void> _ensureActiveItem() async {
    final auth = context.read<AuthProvider>();
    final userId = auth.currentUser?.id;
    if (userId == null) return;
    final items = context.read<ItemsProvider>().myItems;
    final swipeMatch = context.read<SwipeMatchProvider>();

    final active = swipeMatch.activeItem;
    final personaChanged = _personaId != userId;
    _personaId = userId;

    if (items.isEmpty) return;
    if (active == null ||
        personaChanged ||
        active.ownerId != userId) {
      _exhausted = false;
      await swipeMatch.setActiveItem(userId, items.first);
    } else {
      await swipeMatch.loadDeck(userId);
    }
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
    final item = await context.read<SwipeMatchProvider>().undoLast(userId: userId);
    if (mounted) setState(() => _exhausted = false);
    if (item != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Brought back "${item.title}"')),
      );
    }
  }

  Future<void> _onSave() async {
    final current = _cardController.currentItem;
    if (current == null) return;
    final userId = context.read<AuthProvider>().currentUser!.id;
    final nowSaved =
        await context.read<SwipeMatchProvider>().toggleSave(userId, current.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(nowSaved
              ? 'Saved "${current.title}"'
              : 'Removed "${current.title}" from saved'),
        ),
      );
    }
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

  void _openSelector(List<ItemModel> items, SwipeMatchProvider sm, String uid) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('Swap with which item?',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ),
            ...items.map(
              (it) => ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ItemImage(
                      source: it.primaryImage, width: 46, height: 46),
                ),
                title: Text(it.title),
                subtitle: Text(it.category.label),
                trailing: it.id == sm.activeItem?.id
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _ownerCache.clear();
                  setState(() => _exhausted = false);
                  sm.setActiveItem(uid, it);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
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
                      setState(() => _filter = null);
                      Navigator.of(sheetCtx).pop();
                    },
                  ),
                  ...ItemCategory.values.map(
                    (c) => ChoiceChip(
                      label: Text('${c.emoji} ${c.label}'),
                      selected: _filter == c,
                      onSelected: (_) {
                        setState(() => _filter = c);
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
    final items = context.watch<ItemsProvider>().myItems;
    final swipeMatch = context.watch<SwipeMatchProvider>();
    final auth = context.watch<AuthProvider>();
    final userId = auth.currentUser?.id;
    final location = (auth.currentUser?.location.isNotEmpty ?? false)
        ? auth.currentUser!.location
        : 'Discover near you';

    // Re-ensure when persona changes (dev switch) while this stays mounted.
    if (userId != null && userId != _personaId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureActiveItem());
    }

    // Memoise the filtered view deck.
    final activeId = swipeMatch.activeItem?.id ?? '';
    final key = '$activeId|${_filter?.name ?? 'all'}|${swipeMatch.deck.length}';
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
            if (items.isNotEmpty)
              _SwapWithBar(
                active: swipeMatch.activeItem,
                onTap: userId == null
                    ? null
                    : () => _openSelector(items, swipeMatch, userId),
              ),
            Expanded(
              child: items.isEmpty
                  ? EmptyState(
                      icon: Icons.add_box_outlined,
                      title: 'List an item first',
                      message:
                          'You need at least one item to swap before you can start discovering.',
                      action: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const AddItemScreen()),
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('Add an item'),
                      ),
                    )
                  : _buildDeck(swipeMatch),
            ),
            if (items.isNotEmpty)
              _ActionBar(
                enabled: _viewDeck.isNotEmpty && !_exhausted,
                canUndo: swipeMatch.canUndo,
                onPass: () => _cardController.swipeLeft(),
                onUndo: _onUndo,
                onSave: _onSave,
                onLike: () => _cardController.swipeRight(),
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildDeck(SwipeMatchProvider swipeMatch) {
    if (swipeMatch.deckLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_viewDeck.isEmpty) {
      return EmptyState(
        icon: Icons.done_all_rounded,
        title: 'All caught up!',
        message: _filter != null
            ? 'No more items in this category. Try clearing the filter.'
            : 'No more items to swipe with this listing. Switch listing or check back later.',
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
              distanceLabel:
                  ServiceLocator.locationService.labelFor(item),
              onExpand: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => ItemDetailScreen(item: item)),
              ),
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
          const EmptyState(
            icon: Icons.done_all_rounded,
            title: 'All caught up!',
            message:
                'No more items to swipe with this listing. Tap undo to revisit, switch listing, or check back later.',
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
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
                Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12.5),
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

class _SwapWithBar extends StatelessWidget {
  const _SwapWithBar({required this.active, this.onTap});
  final ItemModel? active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.swap_horiz_rounded,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Swapping: ',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12.5),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(
                  active?.title ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 18, color: AppColors.textSecondary),
            ],
          ),
        ),
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
