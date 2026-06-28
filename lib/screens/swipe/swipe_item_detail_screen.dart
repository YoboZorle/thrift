import 'package:flutter/material.dart';

import '../../core/constants/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/enums.dart';
import '../../models/item_model.dart';
import '../../models/user_model.dart';
import '../../services/service_locator.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/countdown_text.dart';
import '../common/fullscreen_gallery.dart';

/// What the user chose on the scrollable detail view; the swipe screen acts on
/// it (triggering the same animated like/pass, or a save).
enum SwipeDecision { like, pass, save, none }

/// Full, scrollable view of an item and its owner — all photos, full details,
/// the owner's profile and their other listings — with Pass / Save / Swap.
class SwipeItemDetailScreen extends StatefulWidget {
  const SwipeItemDetailScreen({super.key, required this.item, this.owner});

  final ItemModel item;
  final UserModel? owner;

  @override
  State<SwipeItemDetailScreen> createState() => _SwipeItemDetailScreenState();
}

class _SwipeItemDetailScreenState extends State<SwipeItemDetailScreen> {
  final _pageController = PageController();
  int _page = 0;
  late Future<List<ItemModel>> _ownerItems;

  List<String> get _images =>
      widget.item.images.isEmpty ? [''] : widget.item.images;

  bool get _justListed =>
      DateTime.now().difference(widget.item.createdAt).inHours <=
      AppConfig.justListedHours;

  @override
  void initState() {
    super.initState();
    _ownerItems = _loadOwnerItems();
  }

  Future<List<ItemModel>> _loadOwnerItems() async {
    final all =
        await ServiceLocator.repository.getItemsByOwner(widget.item.ownerId);
    return all.where((i) => i.id != widget.item.id && i.isActive).toList();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final owner = widget.owner;
    final distance = ServiceLocator.locationService.labelFor(item);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 440,
            backgroundColor: AppColors.background,
            leading: _circleIcon(
              Icons.arrow_back_rounded,
              () => Navigator.of(context).pop(SwipeDecision.none),
            ),
            flexibleSpace: FlexibleSpaceBar(background: _photoHeader()),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_justListed) ...[
                    const TagChip(label: 'JUST LISTED', color: AppColors.like),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _countdownChip(),
                      if (item.estimatedValue != null)
                        _chip(Icons.sell_outlined,
                            '≈ ${Formatters.money(item.estimatedValue!)}'),
                      _chip(Icons.location_on_outlined, distance),
                      _chip(Icons.graphic_eq, item.condition.label),
                      _chip(null,
                          '${item.category.emoji} ${item.category.label}'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Description',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textHint,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  Text(
                    item.description.isEmpty
                        ? 'No description provided.'
                        : item.description,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.5,
                        fontSize: 15),
                  ),
                  if (item.defectNote.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.nope.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.nope.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.report_problem_outlined,
                              size: 18, color: AppColors.nope),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Faulty — stated defect',
                                    style: TextStyle(
                                        color: AppColors.nope,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5)),
                                const SizedBox(height: 2),
                                Text(item.defectNote,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13.5,
                                        height: 1.35)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text('Listed ${Formatters.timeAgo(item.createdAt)}',
                      style: const TextStyle(
                          color: AppColors.textHint, fontSize: 12.5)),
                  const SizedBox(height: 24),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 16),
                  if (owner != null) _ownerSection(owner),
                  const SizedBox(height: 12),
                  _ownerItemsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _actionBar(),
    );
  }

  Widget _photoHeader() {
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: () => FullscreenGallery.open(
            context,
            images: _images,
            initialIndex: _page,
          ),
          child: PageView.builder(
            controller: _pageController,
            itemCount: _images.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => ItemImage(source: _images[i]),
          ),
        ),
        const Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.cardScrim),
            ),
          ),
        ),
        if (_images.length > 1)
          Positioned(
            bottom: 14,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _images.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page ? 22 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i == _page
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _ownerSection(UserModel owner) {
    return Row(
      children: [
        ClipOval(
          child: SizedBox(
            width: 54,
            height: 54,
            child: ItemImage(source: owner.avatarUrl ?? ''),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(owner.name,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800)),
              if (owner.location.isNotEmpty)
                Text(owner.location,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
              if (owner.bio.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(owner.bio,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.35)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _ownerItemsSection() {
    return FutureBuilder<List<ItemModel>>(
      future: _ownerItems,
      builder: (context, snap) {
        final items = snap.data ?? const [];
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 18),
            Text(
              'More from ${widget.owner?.name ?? 'this swapper'}',
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 132,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final it = items[i];
                  return SizedBox(
                    width: 110,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 110,
                            height: 100,
                            child: ItemImage(source: it.primaryImage),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(it.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12.5, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _actionBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pop(SwipeDecision.pass),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  label: const Text('Pass'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.nope,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: () => Navigator.of(context).pop(SwipeDecision.save),
                icon: const Icon(Icons.bookmark_border_rounded),
                color: AppColors.textPrimary,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceAlt,
                  padding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pop(SwipeDecision.like),
                  icon: const Icon(Icons.favorite_rounded, size: 20),
                  label: const Text('Swap'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.like,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleIcon(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: Colors.black.withValues(alpha: 0.4),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _countdownChip() {
    return CountdownText(
      deadline: widget.item.createdAt.add(AppConfig.listingWindow),
      builder: (context, label, expired) {
        final color = expired ? AppColors.nope : AppColors.primary;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(expired ? Icons.timer_off_outlined : Icons.timer_outlined,
                  size: 15, color: color),
              const SizedBox(width: 5),
              Text(expired ? 'Expired' : '$label left',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        );
      },
    );
  }

  Widget _chip(IconData? icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: AppColors.textSecondary),
            const SizedBox(width: 5),
          ],
          Text(text,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
