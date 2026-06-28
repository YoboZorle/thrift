import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/items_provider.dart';
import '../../providers/swipe_match_provider.dart';
import '../../services/service_locator.dart';
import '../../widgets/common_widgets.dart';
import '../listings/my_listings_screen.dart';
import '../saved/saved_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final items = context.watch<ItemsProvider>();
    final swipeMatch = context.watch<SwipeMatchProvider>();
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Edit profile',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _editProfile(context, user),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _header(user),
          const SizedBox(height: 24),
          _stats(
            myItems: items.myItemCount,
            matches: swipeMatch.matchCount,
            likesYou: swipeMatch.likesYouCount,
          ),
          const SizedBox(height: 28),
          _sectionLabel('Your stuff'),
          _tile(
            icon: Icons.inventory_2_outlined,
            title: 'My listings',
            subtitle: '${items.myItemCount} item(s) up for swap',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MyListingsScreen()),
            ),
          ),
          _tile(
            icon: Icons.bookmark_border_rounded,
            title: 'Saved',
            subtitle: 'Items you bookmarked while swiping',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SavedScreen()),
            ),
          ),
          const SizedBox(height: 20),
          _sectionLabel('Account'),
          _tile(
            icon: Icons.swap_horizontal_circle_outlined,
            title: 'Dev: switch persona',
            subtitle: 'Become another seeded user to test reciprocal matches',
            onTap: () => _switchAccount(context),
          ),
          _tile(
            icon: Icons.refresh,
            title: 'Reset demo data',
            subtitle: 'Restore the original seeded items & likes',
            onTap: () => _confirmReset(context),
          ),
          _tile(
            icon: Icons.logout_rounded,
            title: 'Sign out',
            subtitle: 'End this session',
            danger: true,
            onTap: () => _confirmSignOut(context),
          ),
        ],
      ),
    );
  }

  Widget _header(UserModel user) {
    return Column(
      children: [
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.15),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
              ? ItemImage(source: user.avatarUrl!)
              : Center(
                  child: Text(
                    user.name.isNotEmpty
                        ? user.name.characters.first.toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 34,
                        fontWeight: FontWeight.w800),
                  ),
                ),
        ),
        const SizedBox(height: 12),
        Text(
          user.name,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        if (user.location.isNotEmpty) ...[
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 15, color: AppColors.textHint),
              const SizedBox(width: 2),
              Text(user.location,
                  style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ],
        if ((user.phone != null && user.phone!.isNotEmpty) ||
            (user.email != null && user.email!.isNotEmpty)) ...[
          const SizedBox(height: 6),
          Text(
            user.phone?.isNotEmpty == true ? user.phone! : user.email!,
            style: const TextStyle(color: AppColors.textHint, fontSize: 13),
          ),
        ],
        if (user.bio.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            user.bio,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
        ],
      ],
    );
  }

  Widget _stats({
    required int myItems,
    required int matches,
    required int likesYou,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          _statItem('Listings', myItems),
          _divider(),
          _statItem('Matches', matches),
          _divider(),
          _statItem('Likes you', likesYou),
        ],
      ),
    );
  }

  Widget _statItem(String label, int value) {
    return Expanded(
      child: Column(
        children: [
          Text('$value',
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary)),
          const SizedBox(height: 2),
          Text(label,
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 36, color: AppColors.border);

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textHint,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      );

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool danger = false,
  }) {
    final color = danger ? AppColors.nope : AppColors.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: danger ? AppColors.nope : AppColors.textPrimary)),
        subtitle: Text(subtitle,
            style: const TextStyle(
                fontSize: 12.5, color: AppColors.textSecondary)),
        trailing: onTap == null
            ? null
            : const Icon(Icons.chevron_right, color: AppColors.textHint),
        onTap: onTap,
      ),
    );
  }

  // ---- Actions ----

  Future<void> _reloadFor(BuildContext context, String userId) async {
    await context.read<ItemsProvider>().loadMyItems(userId);
    if (!context.mounted) return;
    await context.read<SwipeMatchProvider>().refreshAll(userId);
  }

  Future<void> _switchAccount(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final accounts = await auth.demoAccounts();
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('Switch persona',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              ),
              ...accounts.map(
                (u) => ListTile(
                  leading: ClipOval(
                    child: SizedBox(
                      width: 42,
                      height: 42,
                      child: ItemImage(source: u.avatarUrl ?? ''),
                    ),
                  ),
                  title: Text(u.name),
                  subtitle: u.location.isNotEmpty ? Text(u.location) : null,
                  trailing: u.id == auth.currentUser?.id
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  onTap: () async {
                    Navigator.of(sheetCtx).pop();
                    await auth.devSwitchPersona(u.id);
                    if (!context.mounted) return;
                    await _reloadFor(context, u.id);
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset demo data?'),
        content: const Text(
          'This clears all items, swipes, matches and chats, then restores the '
          'original seeded demo. Cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ServiceLocator.repository.resetAll();
    if (!context.mounted) return;
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId != null) await _reloadFor(context, userId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demo data reset.')),
      );
    }
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You\'ll need to sign in again to swap.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.nope),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().signOut();
      // RootRouter returns to the welcome/auth flow automatically.
    }
  }

  Future<void> _editProfile(BuildContext context, UserModel user) async {
    final nameCtrl = TextEditingController(text: user.name);
    final locationCtrl = TextEditingController(text: user.location);
    final bioCtrl = TextEditingController(text: user.bio);

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 4,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Edit profile',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationCtrl,
                decoration: const InputDecoration(labelText: 'Location'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bioCtrl,
                decoration: const InputDecoration(labelText: 'Bio'),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(sheetCtx).pop(true),
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );

    if (saved == true && context.mounted) {
      await context.read<AuthProvider>().updateProfile(
            name: nameCtrl.text.trim(),
            location: locationCtrl.text.trim(),
            bio: bioCtrl.text.trim(),
          );
    }
    nameCtrl.dispose();
    locationCtrl.dispose();
    bioCtrl.dispose();
  }
}
