import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../app/theme/app_colors.dart';

class ProfileListItem extends StatelessWidget {
  final String title;
  final bool showDivider;
  final bool showCheckmark;
  final VoidCallback? onTap;

  const ProfileListItem({
    super.key,
    required this.title,
    this.showDivider = true,
    this.showCheckmark = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final item = InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 19.h),
        child: Row(
          children: [
            // Title
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  letterSpacing: -0.01 * 16,
                ),
              ),
            ),

            // Optional checkmark + arrow
            Row(
              children: [
                if (showCheckmark)
                  SvgPicture.asset(
                    'assets/icons/svg/tick.svg', // path to your SVG
                    height: 24.sp,
                    width: 24.sp,
                  ),
                if (showCheckmark)
                  SizedBox(width: 20.w), // space between checkmark & arrow
                Icon(
                  Icons.arrow_forward_ios,
                  size: 18.sp,
                  color: AppColors.textPrimary.withOpacity(0.8),
                ),
              ],
            ),
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
