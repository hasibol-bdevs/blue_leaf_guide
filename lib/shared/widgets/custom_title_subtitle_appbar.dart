import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/app_colors.dart';

class CustomTitleSubtitleAppbar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final Color backgroundColor;

  const CustomTitleSubtitleAppbar({
    super.key,
    required this.title,
    required this.subtitle,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: Size.fromHeight(80.h),
      child: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: backgroundColor,
        scrolledUnderElevation: 0.0,
        elevation: 0,
        flexibleSpace: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20.h), // optional top spacing
            Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textPrimary.withOpacity(0.7),
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(80.h);
}
