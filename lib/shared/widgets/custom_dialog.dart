import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_colors.dart';
import 'button.dart'; // Your custom Button widget

class CustomDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final String primaryButtonText;
  final VoidCallback? primaryButtonOnPressed;
  final String secondaryButtonText;
  final VoidCallback? secondaryButtonOnPressed;
  final bool isLoading;

  const CustomDialog({
    super.key,
    this.title = 'Delete Account',
    this.subtitle =
        'Deleting your account will permanently remove all your data and progress.',
    this.primaryButtonText = 'Delete',
    this.primaryButtonOnPressed,
    this.secondaryButtonText = 'Cancel',
    this.secondaryButtonOnPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36.r)),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),

            SizedBox(height: 12.h),

            /// Subtitle
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 280.w,
              ), // set your desired max width
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary.withOpacity(0.7),
                ),
              ),
            ),

            SizedBox(height: 20.h),

            /// Primary Button
            Button(
              onPressed:
                  primaryButtonOnPressed ??
                  () {
                    Navigator.of(context).pop();
                  },
              text: primaryButtonText,
              height: 54.h,
              borderRadius: BorderRadius.circular(32.r),
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              textColor: Colors.white,
              backgroundColor: AppColors.errorRed,
              isLoading: isLoading,
            ),

            SizedBox(height: 12.h),

            /// Secondary Button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed:
                    secondaryButtonOnPressed ??
                    () {
                      Navigator.of(context).pop();
                    },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32.r),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                ),
                child: Text(
                  secondaryButtonText,
                  style: TextStyle(
                    color: AppColors.textPrimary.withOpacity(0.5),
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
