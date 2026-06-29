import 'package:dropdown_flutter/custom_dropdown.dart';
import '../../core/theme/dropdown_styles.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/ng_states.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  String? _gender;
  String? _state;
  DateTime? _dob;
  bool _saving = false;

  static const _genders = ['Male', 'Female'];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      if (user.name.isNotEmpty) _nameCtrl.text = user.name;
      _cityCtrl.text = user.city;
      _gender = user.gender;
      _state = user.state.isEmpty ? null : user.state;
      _dob = user.dob;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final eighteen = DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? eighteen,
      firstDate: DateTime(now.year - 100),
      // You must be at least 18 — can't pick a date more recent than this.
      lastDate: eighteen,
      helpText: 'Select your date of birth (18+)',
    );
    if (picked != null) setState(() => _dob = picked);
  }

  bool _isAtLeast18(DateTime dob) {
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age >= 18;
  }

  String? _validate() {
    if (_nameCtrl.text.trim().isEmpty) return 'Please add your name.';
    if (_gender == null) return 'Please select your gender.';
    if (_dob == null) return 'Please select your date of birth.';
    if (!_isAtLeast18(_dob!)) return 'You must be 18 or older to use ThriftSwap.';
    if (_state == null) return 'Please select your state.';
    if (_cityCtrl.text.trim().isEmpty) return 'Please add your city.';
    return null;
  }

  Future<void> _save() async {
    final err = _validate();
    if (err != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    setState(() => _saving = true);
    await context.read<AuthProvider>().completeProfileSetup(
          name: _nameCtrl.text.trim(),
          city: _cityCtrl.text.trim(),
          state: _state!,
          gender: _gender!,
          dob: _dob!,
        );
    // RootRouter advances automatically once setup is complete.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Set up your profile'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 18),
              child: Text(
                "Tell us about yourself. You'll add photos of yourself in the "
                'next step (verification) — your first photo becomes your '
                'profile picture.',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13.5, height: 1.4),
              ),
            ),
            _label('Display name'),
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'e.g. Alex'),
            ),
            const SizedBox(height: 18),
            _label('Gender'),
            DropdownFlutter<String>(
              decoration: appDropdownDecoration(),
              hintText: 'Select gender',
              items: _genders,
              initialItem: _gender,
              onChanged: (value) => setState(() => _gender = value),
            ),
            const SizedBox(height: 18),
            _label('Date of birth'),
            InkWell(
              onTap: _pickDob,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cake_outlined,
                        size: 20, color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Text(
                      _dob == null
                          ? 'Select your date of birth'
                          : DateFormat('MMMM d, yyyy').format(_dob!),
                      style: TextStyle(
                        color: _dob == null
                            ? AppColors.textHint
                            : AppColors.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            _label('State'),
            DropdownFlutter<String>(
              decoration: appDropdownDecoration(),
              hintText: 'Select state',
              items: nigerianStates,
              initialItem: _state,
              onChanged: (value) => setState(() => _state = value),
            ),
            const SizedBox(height: 18),
            _label('City'),
            TextField(
              controller: _cityCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'e.g. Lekki'),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4, color: Colors.black),
                      )
                    : const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: Text(text,
            style: const TextStyle(
                color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      );
}
