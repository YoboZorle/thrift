import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/enums.dart';
import '../../models/item_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/service_locator.dart';
import '../../widgets/common_widgets.dart';
import '../listings/item_detail_screen.dart';

/// Browse all active listings from other swappers in a grid.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late Future<List<ItemModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<ItemModel>> _load() async {
    final me = context.read<AuthProvider>().currentUser?.id;
    final all = await ServiceLocator.repository.getAllItems();
    final list = all
        .where((i) => i.isActive && i.ownerId != me)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> _refresh() async {
    final list = await _load();
    if (mounted) setState(() => _future = Future.value(list));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore'), automaticallyImplyLeading: false),
      body: SafeArea(
        top: false,
        child: FutureBuilder<List<ItemModel>>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snap.data!;
            if (items.isEmpty) {
              return const EmptyState(
                icon: Icons.explore_outlined,
                title: 'Nothing here yet',
                message: 'New listings from other swappers will show up here.',
              );
            }
            return RefreshIndicator(
              onRefresh: _refresh,
              child: GridView.builder(
                padding: const EdgeInsets.all(14),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.72,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) => _ExploreTile(item: items[i]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ExploreTile extends StatelessWidget {
  const _ExploreTile({required this.item});
  final ItemModel item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ItemImage(source: item.primaryImage),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: TagChip(
                      label: '${item.category.emoji} ${item.category.label}',
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: AppColors.textHint),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          ServiceLocator.locationService.labelFor(item),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 11.5),
                        ),
                      ),
                    ],
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
