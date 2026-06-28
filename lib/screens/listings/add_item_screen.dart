import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../providers/items_provider.dart';
import '../../providers/swipe_match_provider.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  final _picker = ImagePicker();

  ItemCategory _category = ItemCategory.clothing;
  ItemCondition _condition = ItemCondition.good;
  final List<String> _images = [];
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _images.add(picked.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick image: $e')),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final userId = context.read<AuthProvider>().currentUser!.id;
    final value =
        _valueCtrl.text.trim().isEmpty ? null : double.tryParse(_valueCtrl.text.trim());

    // Fallback to a generated placeholder image if none picked, so the card
    // always renders. Swap for a real image upload when a backend is added.
    final images = _images.isNotEmpty
        ? List<String>.from(_images)
        : ['https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/800/1000'];

    await context.read<ItemsProvider>().addItem(
          ownerId: userId,
          title: _titleCtrl.text,
          description: _descCtrl.text,
          category: _category,
          condition: _condition,
          images: images,
          estimatedValue: value,
        );

    // Refresh so the new listing is reflected app-wide.
    await context.read<SwipeMatchProvider>().loadDeck(userId);

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item listed! Ready to swap.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('List an item')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _imagePickerSection(),
            const SizedBox(height: 20),
            const _Label('Title'),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(hintText: 'e.g. Nike Air Sneakers'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),
            const _Label('Description'),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                  hintText: 'Condition details, size, why you\'re swapping...'),
            ),
            const SizedBox(height: 16),
            const _Label('Category'),
            _categoryPicker(),
            const SizedBox(height: 16),
            const _Label('Condition'),
            _conditionPicker(),
            const SizedBox(height: 16),
            const _Label('Estimated value (optional)'),
            TextFormField(
              controller: _valueCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Helps gauge a fair swap',
                prefixText: '\$ ',
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('List item'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePickerSection() {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary, width: 1.4),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, color: AppColors.primary),
                  SizedBox(height: 6),
                  Text('Add photo',
                      style: TextStyle(color: AppColors.primary, fontSize: 12)),
                ],
              ),
            ),
          ),
          ..._images.asMap().entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(e.value),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() => _images.removeAt(e.key)),
                      child: const CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _categoryPicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ItemCategory.values.map((c) {
        final selected = c == _category;
        return ChoiceChip(
          label: Text('${c.emoji} ${c.label}'),
          selected: selected,
          onSelected: (_) => setState(() => _category = c),
          selectedColor: AppColors.primary.withValues(alpha: 0.15),
          labelStyle: TextStyle(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        );
      }).toList(),
    );
  }

  Widget _conditionPicker() {
    return Wrap(
      spacing: 8,
      children: ItemCondition.values.map((c) {
        final selected = c == _condition;
        return ChoiceChip(
          label: Text(c.label),
          selected: selected,
          onSelected: (_) => setState(() => _condition = c),
          selectedColor: AppColors.primary.withValues(alpha: 0.15),
          labelStyle: TextStyle(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        );
      }).toList(),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
