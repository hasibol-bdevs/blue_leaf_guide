// lib/shared/widgets/back_button_icon.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/theme/app_colors.dart';

class BackButtonIcon extends StatelessWidget {
  final VoidCallback? onTap;
  final String? iconPath;

  // Default icon path
  static const String defaultIcon = 'assets/icons/svg/right-icon.svg';

  const BackButtonIcon({super.key, this.iconPath, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () => Navigator.of(context).pop(),
      borderRadius: BorderRadius.circular(48.r),
      child: Container(
        width: 45.w,
        height: 45.h,
        decoration: BoxDecoration(
          color: AppColors.textPrimary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(48.r),
        ),
        child: Center(
          child: SvgPicture.asset(
            iconPath ?? defaultIcon,
            width: 24.w,
            height: 24.h,
            colorFilter: ColorFilter.mode(
              AppColors.textPrimary, // Apply the icon color
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}
