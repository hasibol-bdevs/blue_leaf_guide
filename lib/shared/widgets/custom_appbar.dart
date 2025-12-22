import 'package:flutter/material.dart' hide BackButtonIcon;
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/app_colors.dart';
import 'back_button_icon.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final bool hideBackButton;

  // NEW RIGHT ICON PROPS
  final String? rightIconPath; // SVG for right icon
  final VoidCallback? onRightTap;
  final bool hideRightIcon;

  const CustomAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.hideBackButton = false,
    this.rightIconPath,
    this.onRightTap,
    this.hideRightIcon = true,
  });

  @override
  Size get preferredSize => Size.fromHeight(55.h);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: preferredSize.height,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        color: Colors.white,
        child: Stack(
          alignment: Alignment.center,
          children: [
            /// LEFT BACK BUTTON
            if (!hideBackButton)
              Align(
                alignment: Alignment.centerLeft,
                child: BackButtonIcon(
                  onTap: onBack ?? () => Navigator.of(context).pop(),
                ),
              ),

            /// CENTER TITLE
            Center(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  letterSpacing: -0.01 * 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            /// RIGHT ICON (same style as BackButtonIcon)
            if (!hideRightIcon && rightIconPath != null)
              Align(
                alignment: Alignment.centerRight,
                child: BackButtonIcon(
                  iconPath: rightIconPath, // <-- different icon but same style
                  onTap: onRightTap,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
