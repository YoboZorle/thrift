import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thrift/models/enums.dart';

import '../../core/theme/app_colors.dart';
import '../../models/item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/items_provider.dart';
import '../../widgets/common_widgets.dart';
import 'add_item_screen.dart';
import 'item_detail_screen.dart';

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final itemsProvider = context.watch<ItemsProvider>();
    final items = itemsProvider.myItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddItemScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddItemScreen()),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('List item', style: TextStyle(color: Colors.white)),
      ),
      body: itemsProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'No items yet',
                  message:
                      'List something you want to declutter and start matching for swaps.',
                  action: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AddItemScreen()),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('List your first item'),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.74,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, i) => _ListingCard(item: items[i]),
                ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.item});
  final ItemModel item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
                  if (!item.isActive)
                    Container(
                      color: Colors.black.withValues(alpha: 0.5),
                      child: const Center(
                        child: TagChip(
                          label: 'Paused',
                          icon: Icons.pause,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.category.emoji} ${item.category.label} · ${item.condition.label}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
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
