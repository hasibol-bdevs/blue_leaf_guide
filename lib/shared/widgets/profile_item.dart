import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../app/theme/app_colors.dart';

class ProfileItem extends StatelessWidget {
  final String svgIconPath;
  final Color iconBackgroundColor;
  final String title;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool showDivider;
  final bool isEditable;
  final String? trailingIconPath;
  final VoidCallback? onTrailingIconTap;
  const ProfileItem({
    super.key,
    required this.svgIconPath,
    required this.iconBackgroundColor,
    required this.title,
    required this.value,
    this.onChanged,
    this.showDivider = true,
    this.isEditable = true,
    this.trailingIconPath,
    this.onTrailingIconTap,
  });

  @override
  Widget build(BuildContext context) {
    final item = Opacity(
      opacity: isEditable ? 1 : 0.4,

      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          children: [
            SvgPicture.asset(svgIconPath, width: 32.sp, height: 32.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimary.withOpacity(0.8),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  letterSpacing: -0.01 * 14,
                ),
              ),
            ),
            CustomSwitch(
              value: value,
              onChanged: onChanged,
              isEnabled: isEditable,
            ),
            if (trailingIconPath != null) ...[
              SizedBox(width: 16.w),
              GestureDetector(
                onTap: onTrailingIconTap,
                child: SvgPicture.asset(
                  trailingIconPath!,
                  width: 24.w,
                  height: 24.w,
                  colorFilter: ColorFilter.mode(
                    AppColors.textPrimary.withOpacity(0.8),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (showDivider) {
      return Column(
        children: [
          item,
          Divider(color: AppColors.neutral50, thickness: 1.w, height: 1.h),
        ],
      );
    } else {
      return item;
    }
  }
}

class CustomSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged; // nullable
  final bool isEnabled; // new

  const CustomSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled && onChanged != null
          ? () => onChanged!(!value)
          : null, // disable tap
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44.w,
        height: 26.h,
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: value
              ? AppColors.brand500
              : AppColors.textPrimary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(50.r),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 20.w,
                height: 20.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x16330014),
                      offset: Offset(0, 1),
                      blurRadius: 2,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: value
                    ? Center(
                        child: Icon(
                          Icons.check,
                          color: AppColors.brand500,
                          size: 16.sp,
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
