import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/support.dart';
import '../../models/enums.dart';
import '../../models/item_model.dart';
import '../../models/match_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/swipe_match_provider.dart';
import '../../widgets/common_widgets.dart';
import '../matches/match_detail_screen.dart';
import '../swipe/swipe_item_detail_screen.dart';

/// Public profile of another swapper: their details + their active listings,
/// which you can open to swipe (and match) with right from here.
class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key, required this.user});
  final UserModel user;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late Future<List<ItemModel>> _items;

  @override
  void initState() {
    super.initState();
    _items = _load();
  }

  Future<List<ItemModel>> _load() async {
    final all =
        await context.read<SwipeMatchProvider>().itemsOf(widget.user.id);
    return all.where((i) => i.isActive).toList();
  }

  int? get _age {
    final d = widget.user.dob;
    if (d == null) return null;
    final n = DateTime.now();
    var a = n.year - d.year;
    if (n.month < d.month || (n.month == d.month && n.day < d.day)) a--;
    return a;
  }

  Future<void> _openItem(ItemModel item) async {
    final me = context.read<AuthProvider>().currentUser!.id;
    final provider = context.read<SwipeMatchProvider>();

    final decision = await Navigator.of(context).push<SwipeDecision>(
      MaterialPageRoute(
        builder: (_) => SwipeItemDetailScreen(item: item, owner: widget.user),
      ),
    );
    if (!mounted || decision == null || decision == SwipeDecision.none) return;

    if (decision == SwipeDecision.save) {
      await provider.toggleSave(me, item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved "${item.title}"')),
        );
      }
      return;
    }

    final dir =
        decision == SwipeDecision.like ? SwipeDirection.like : SwipeDirection.pass;
    final match =
        await provider.swipe(userId: me, target: item, direction: dir);
    await provider.loadDeck(me);
    if (mounted) setState(() => _items = _load());
    if (match != null && mounted) _showMatch(match);
  }

  void _showMatch(MatchModel match) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
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
              const Text("It's a Swap Match! 🎉",
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text('You and ${widget.user.name} both want to swap.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black87)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => MatchDetailScreen(match: match)));
                  },
                  child: const Text('Review & chat'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Later',
                    style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final detail = [
      if (u.gender != null) u.gender!,
      if (_age != null) '${_age}',
    ].join(' · ');

    return Scaffold(
      appBar: AppBar(
        title: Text(u.name),
        actions: [
          IconButton(
            tooltip: 'Report ${u.name.split(' ').first}',
            icon: const Icon(Icons.flag_outlined),
            onPressed: () async {
              final ok = await Support.contactAdmin(
                  message: Support.reportUser(u.name, u.id));
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Couldn\'t open WhatsApp. Please install it or try again.')),
                );
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<ItemModel>>(
        future: _items,
        builder: (context, snap) {
          final items = snap.data ?? const [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              Row(
                children: [
                  ClipOval(
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: ItemImage(source: u.avatarUrl ?? ''),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u.name,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w800)),
                        if (detail.isNotEmpty)
                          Text(detail,
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13)),
                        if (u.location.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on_outlined,
                                    size: 14, color: AppColors.textHint),
                                const SizedBox(width: 2),
                                Text(u.location,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (u.bio.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(u.bio,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14.5,
                        height: 1.4)),
              ],
              const SizedBox(height: 24),
              Text('${u.name.split(' ').first}\'s items',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Tap an item to swap with it.',
                  style: TextStyle(
                      color: AppColors.textHint, fontSize: 12.5)),
              const SizedBox(height: 14),
              if (snap.connectionState == ConnectionState.waiting)
                const Center(child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ))
              else if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('No active listings right now.',
                        style: TextStyle(color: AppColors.textHint)),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: items.length,
                  itemBuilder: (_, i) => _ItemCard(
                    item: items[i],
                    onTap: () => _openItem(items[i]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.onTap});
  final ItemModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: ItemImage(source: item.primaryImage)),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13.5)),
                  const SizedBox(height: 2),
                  Text(
                    item.estimatedValue != null
                        ? '${item.condition.label} · ${Formatters.money(item.estimatedValue!)}'
                        : item.condition.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
