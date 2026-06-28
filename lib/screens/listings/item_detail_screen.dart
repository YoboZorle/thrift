import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thrift/models/enums.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/items_provider.dart';
import '../../widgets/common_widgets.dart';

class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key, required this.item});
  final ItemModel item;

  @override
  Widget build(BuildContext context) {
    final isMine =
        item.ownerId == context.read<AuthProvider>().currentUser?.id;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 360,
            pinned: true,
            backgroundColor: AppColors.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: _ImageCarousel(images: item.images),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (item.estimatedValue != null)
                        TagChip(
                          label: '~${Formatters.money(item.estimatedValue!)}',
                          icon: Icons.sell_outlined,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      TagChip(
                        label: '${item.category.emoji} ${item.category.label}',
                      ),
                      TagChip(
                        label: item.condition.label,
                        icon: Icons.verified_outlined,
                        color: AppColors.like,
                      ),
                      TagChip(
                        label: item.isActive ? 'Active' : 'Paused',
                        icon: item.isActive
                            ? Icons.play_arrow
                            : Icons.pause,
                        color: item.isActive
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Description',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(
                    item.description.isEmpty
                        ? 'No description provided.'
                        : item.description,
                    style: const TextStyle(
                        color: AppColors.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Listed ${Formatters.timeAgo(item.createdAt)}',
                    style: const TextStyle(
                        color: AppColors.textHint, fontSize: 13),
                  ),
                  if (isMine) ...[
                    const SizedBox(height: 28),
                    _OwnerActions(item: item),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageCarousel extends StatelessWidget {
  const _ImageCarousel({required this.images});
  final List<String> images;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const ItemImage(source: '');
    }
    return PageView(
      children: images.map((src) => ItemImage(source: src)).toList(),
    );
  }
}

class _OwnerActions extends StatelessWidget {
  const _OwnerActions({required this.item});
  final ItemModel item;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ItemsProvider>();
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => provider.toggleActive(item),
            icon: Icon(item.isActive ? Icons.pause : Icons.play_arrow),
            label: Text(item.isActive ? 'Pause listing' : 'Reactivate listing'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.nope,
              side: const BorderSide(color: AppColors.nope),
            ),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete item?'),
                  content: const Text(
                      'This will remove the listing permanently.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete',
                          style: TextStyle(color: AppColors.nope)),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await provider.deleteItem(item);
                if (context.mounted) Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete listing'),
          ),
        ),
      ],
    );
  }
}
