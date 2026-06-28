import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/enums.dart';
import '../../models/item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/swipe_match_provider.dart';
import '../../widgets/common_widgets.dart';
import '../listings/item_detail_screen.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  late Future<List<ItemModel>> _future;

  @override
  void initState() {
    super.initState();
    final userId = context.read<AuthProvider>().currentUser!.id;
    _future = context.read<SwipeMatchProvider>().savedItems(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved')),
      body: FutureBuilder<List<ItemModel>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.bookmark_border_rounded,
              title: 'Nothing saved',
              message:
                  'Tap the bookmark on a card to save items you want to revisit.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(14),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final it = items[i];
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => ItemDetailScreen(item: it)),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Row(
                    children: [
                      SizedBox(
                          width: 92,
                          height: 92,
                          child: ItemImage(source: it.primaryImage)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(it.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15)),
                            const SizedBox(height: 4),
                            Text('${it.category.emoji} ${it.category.label}',
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12.5)),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Icon(Icons.chevron_right,
                            color: AppColors.textHint),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
