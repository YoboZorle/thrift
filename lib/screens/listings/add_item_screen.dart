import 'dart:io';
import 'package:dropdown_flutter/custom_dropdown.dart';
import '../../core/theme/dropdown_styles.dart';
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
  final _defectCtrl = TextEditingController();
  final _picker = ImagePicker();

  ItemCategory _category = ItemCategory.clothing;
  ItemCondition _condition = ItemCondition.good;
  final List<String> _images = [];
  bool _saving = false;

  late final Map<String, ItemCategory> _categoryByLabel = {
    for (final c in ItemCategory.values) '${c.emoji} ${c.label}': c,
  };
  late final Map<String, ItemCondition> _conditionByLabel = {
    for (final c in ItemCondition.values) c.label: c,
  };

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _valueCtrl.dispose();
    _defectCtrl.dispose();
    super.dispose();
  }

  /// Multi-select: pick several photos at once.
  Future<void> _pickImages() async {
    try {
      final picked = await _picker.pickMultiImage(
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (picked.isNotEmpty) {
        setState(() => _images.addAll(picked.map((x) => x.path)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick images: $e')),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_condition == ItemCondition.faulty &&
        _defectCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the fault/defect.')),
      );
      return;
    }
    setState(() => _saving = true);

    final user = context.read<AuthProvider>().currentUser!;
    final value = _valueCtrl.text.trim().isEmpty
        ? null
        : double.tryParse(_valueCtrl.text.trim());

    // Fallback to a generated placeholder if none picked, so the card always
    // renders. Swap for a real image upload when a backend is added.
    final images = _images.isNotEmpty
        ? List<String>.from(_images)
        : ['https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/800/1000'];

    await context.read<ItemsProvider>().addItem(
          ownerId: user.id,
          title: _titleCtrl.text,
          description: _descCtrl.text,
          category: _category,
          condition: _condition,
          images: images,
          estimatedValue: value,
          city: user.city,
          state: user.state,
          defectNote: _condition == ItemCondition.faulty
              ? _defectCtrl.text
              : '',
        );

    // Refresh so the new listing (and any admirers it attracts) shows up.
    await context.read<SwipeMatchProvider>().refreshAll(user.id);

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
            const _Label('Photos'),
            const SizedBox(height: 8),
            _imagePickerSection(),
            const SizedBox(height: 20),
            const _Label('Title'),
            TextFormField(
              controller: _titleCtrl,
              decoration:
                  const InputDecoration(hintText: 'e.g. Nike Air Sneakers'),
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
            DropdownFlutter<String>(
              decoration: appDropdownDecoration(),
              hintText: 'Select category',
              items: _categoryByLabel.keys.toList(),
              initialItem: '${_category.emoji} ${_category.label}',
              onChanged: (value) {
                if (value != null) {
                  setState(() => _category = _categoryByLabel[value]!);
                }
              },
            ),
            const SizedBox(height: 16),
            const _Label('Condition'),
            DropdownFlutter<String>(
              decoration: appDropdownDecoration(),
              hintText: 'Select condition',
              items: _conditionByLabel.keys.toList(),
              initialItem: _condition.label,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _condition = _conditionByLabel[value]!);
                }
              },
            ),
            if (_condition == ItemCondition.faulty) ...[
              const SizedBox(height: 16),
              const _Label('Describe the fault'),
              TextFormField(
                controller: _defectCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'What exactly is the defect? Be honest with swappers.',
                ),
              ),
            ],
            const SizedBox(height: 16),
            const _Label('Estimated value (optional)'),
            TextFormField(
              controller: _valueCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Helps gauge a fair swap',
                prefixText: '₦ ',
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
                            color: Colors.black, strokeWidth: 2),
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
            onTap: _pickImages,
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
                  Text('Add photos',
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
                      errorBuilder: (_, __, ___) => Container(
                        width: 100,
                        height: 100,
                        color: AppColors.surfaceAlt,
                        child: const Icon(Icons.broken_image_outlined,
                            color: AppColors.textHint),
                      ),
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
