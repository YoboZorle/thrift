import 'package:dropdown_flutter/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/dropdown_styles.dart';
import '../../core/utils/support.dart';
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_widgets.dart';

enum _VStep { photos, id, reviewing, rejected }

/// Manual identity verification: the user uploads several photos of themselves
/// and a government ID, the submission is "reviewed", and they either pass and
/// continue or are rejected (with retry / contact-support).
class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _picker = ImagePicker();
  final List<String> _photos = [];
  String? _idType;
  String? _idImage;
  late _VStep _step;

  static const _idTypes = [
    'NIN card',
    'International passport',
    "Voter's card",
    'National ID card',
    "Driver's license",
  ];

  @override
  void initState() {
    super.initState();
    // Land straight on the rejection screen if a prior attempt was rejected.
    final status = context.read<AuthProvider>().verificationStatus;
    _step = status == VerificationStatus.rejected ? _VStep.rejected : _VStep.photos;
  }

  Future<void> _addPhotos() async {
    try {
      final picked = await _picker.pickMultiImage(imageQuality: 70);
      if (picked.isNotEmpty) {
        setState(() => _photos.addAll(picked.map((x) => x.path)));
      }
    } catch (_) {}
  }

  Future<void> _pickId() async {
    try {
      final picked =
          await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (picked != null) setState(() => _idImage = picked.path);
    } catch (_) {}
  }

  Future<void> _submit() async {
    setState(() => _step = _VStep.reviewing);
    final auth = context.read<AuthProvider>();
    // Simulate a review pass; the decision itself is configured/manual.
    await Future.delayed(const Duration(milliseconds: 2200));
    final approved = await auth.submitVerification(
      photos: List<String>.from(_photos),
      idType: _idType!,
      idImage: _idImage!,
    );
    if (!mounted) return;
    // On approval, RootRouter advances to the app automatically; otherwise
    // show the rejection screen.
    if (!approved) setState(() => _step = _VStep.rejected);
  }

  void _retry() {
    context.read<AuthProvider>().resetVerification();
    setState(() {
      _photos.clear();
      _idType = null;
      _idImage = null;
      _step = _VStep.photos;
    });
  }

  Future<void> _contactSupport() async {
    final ok = await Support.contactAdmin(
        message:
            'Hi ${AppConfig.supportName}, my ThriftSwap verification was rejected '
            'and I would like help.');
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Couldn\'t open WhatsApp. Please install it or try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Verify your identity'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: switch (_step) {
          _VStep.photos => _photosStep(),
          _VStep.id => _idStep(),
          _VStep.reviewing => _reviewingStep(),
          _VStep.rejected => _rejectedStep(),
        },
      ),
    );
  }

  Widget _stepHeader(int step, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step $step of 2',
            style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 0.4)),
        const SizedBox(height: 6),
        Text(title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(subtitle,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 14, height: 1.4)),
      ],
    );
  }

  Widget _photosStep() {
    final enough = _photos.length >= AppConfig.minVerificationPhotos;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _stepHeader(
                1,
                'Add photos of yourself',
                'Upload at least ${AppConfig.minVerificationPhotos} clear, recent '
                    'photos of your face. This keeps the community safe from '
                    'fakes and scams — your photos are checked against your ID. '
                    'Your first photo becomes your profile picture.',
              ),
              const SizedBox(height: 18),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  for (int i = 0; i < _photos.length; i++)
                    _thumb(
                      _photos[i],
                      onRemove: () => setState(() => _photos.removeAt(i)),
                    ),
                  _addTile(_addPhotos),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${_photos.length} / ${AppConfig.minVerificationPhotos} minimum',
                style: TextStyle(
                  color: enough ? AppColors.like : AppColors.textHint,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
        _bottomBar(
          label: 'Continue',
          enabled: enough,
          onTap: () => setState(() => _step = _VStep.id),
        ),
      ],
    );
  }

  Widget _idStep() {
    final ready = _idType != null && _idImage != null;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _stepHeader(
                2,
                'Submit a valid ID',
                'Upload one government-issued ID showing your photo and details. '
                    'We match it against the photos you uploaded.',
              ),
              const SizedBox(height: 18),
              const Text('ID type',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13.5)),
              const SizedBox(height: 8),
              DropdownFlutter<String>(
                decoration: appDropdownDecoration(),
                hintText: 'Select your ID',
                items: _idTypes,
                initialItem: _idType,
                onChanged: (v) => setState(() => _idType = v),
              ),
              const SizedBox(height: 20),
              const Text('ID photo',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13.5)),
              const SizedBox(height: 8),
              if (_idImage == null)
                GestureDetector(
                  onTap: _pickId,
                  child: Container(
                    height: 170,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.badge_outlined,
                            color: AppColors.textHint, size: 34),
                        SizedBox(height: 8),
                        Text('Tap to upload your ID',
                            style: TextStyle(color: AppColors.textHint)),
                      ],
                    ),
                  ),
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      SizedBox(
                        height: 200,
                        width: double.infinity,
                        child: ItemImage(source: _idImage!, fit: BoxFit.cover),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: GestureDetector(
                          onTap: _pickId,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('Change',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () => setState(() => _step = _VStep.photos),
                child: const Text('Back to photos'),
              ),
            ],
          ),
        ),
        _bottomBar(
          label: 'Submit for verification',
          enabled: ready,
          onTap: _submit,
        ),
      ],
    );
  }

  Widget _reviewingStep() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(strokeWidth: 3)),
            SizedBox(height: 22),
            Text('Reviewing your submission…',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            SizedBox(height: 8),
            Text(
              'We\'re matching your photos with your ID. This only takes a moment.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rejectedStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppColors.nope.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.gpp_bad_outlined,
                color: AppColors.nope, size: 44),
          ),
          const SizedBox(height: 20),
          const Text('Verification unsuccessful',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          const Text(
            'After reviewing the photos you uploaded, they did not match your ID '
            'and the submission was rejected by the system. You can\'t continue '
            'until you\'re verified.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 14.5, height: 1.5),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _retry,
              child: const Text('Retry verification'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _contactSupport,
              icon: const Icon(Icons.support_agent_rounded),
              label: const Text('Contact support'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumb(String path, {required VoidCallback onRemove}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ItemImage(source: path, fit: BoxFit.cover),
        ),
        Positioned(
          right: 4,
          top: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _addTile(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: AppColors.textHint),
            SizedBox(height: 4),
            Text('Add', style: TextStyle(color: AppColors.textHint, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar({
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: enabled ? onTap : null,
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
