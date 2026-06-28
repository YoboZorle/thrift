import 'package:dropdown_flutter/custom_dropdown.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';

/// A [CustomDropdownDecoration] that matches the app's text inputs (same fill,
/// border, radius and text colors) so `dropdown_flutter` selects look native.
CustomDropdownDecoration appDropdownDecoration() => CustomDropdownDecoration(
      closedFillColor: AppColors.surfaceAlt,
      expandedFillColor: AppColors.surfaceAlt,
      closedShadow: const [],
      closedBorder: Border.all(color: AppColors.border),
      closedBorderRadius: BorderRadius.circular(14),
      expandedBorder: Border.all(color: AppColors.border),
      expandedBorderRadius: BorderRadius.circular(14),
      hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 15),
      headerStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      listItemStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      closedSuffixIcon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: AppColors.textSecondary),
      expandedSuffixIcon: const Icon(Icons.keyboard_arrow_up_rounded,
          color: AppColors.textSecondary),
      listItemDecoration: const ListItemDecoration(
        selectedColor: AppColors.surfaceAlt,
        highlightColor: AppColors.surfaceAlt,
        splashColor: AppColors.surfaceAlt,
      ),
    );
