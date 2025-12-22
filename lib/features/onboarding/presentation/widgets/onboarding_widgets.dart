import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/local_storage.dart';

// Shared Title Widget
class OnboardingTitle extends StatelessWidget {
  final String text;

  const OnboardingTitle({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 24.sp,
        height: 1.3,
        letterSpacing: 24.sp * -0.01,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class OnboardingSubtitle extends StatelessWidget {
  final String text;

  const OnboardingSubtitle({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final double fontSize = 14.sp;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 300.w),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            height: 1.4,
            letterSpacing: fontSize * -0.01,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// Page Indicator Widget
class PageIndicator extends StatelessWidget {
  final int currentIndex;
  final int totalPages;

  const PageIndicator({
    super.key,
    required this.currentIndex,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalPages,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          width: index == currentIndex ? 70.w : 70.w,
          height: 4.h,
          decoration: BoxDecoration(
            color: index == currentIndex
                ? AppColors.brand500
                : AppColors.brand50,
            borderRadius: BorderRadius.circular(100.r),
          ),
        ),
      ),
    );
  }
}

class SocialButton extends StatelessWidget {
  final String icon;
  final String text;
  final VoidCallback? onTap; // Changed to nullable
  final Color? textColor;
  final Color? backgroundColor;
  final bool isLoading; // NEW

  const SocialButton({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
    this.textColor,
    this.backgroundColor,
    this.isLoading = false, // NEW
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap, // Disable when loading
      borderRadius: BorderRadius.circular(32.r),
      child: Container(
        width: double.infinity,
        height: 52.h,
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.neutral50,
          borderRadius: BorderRadius.circular(32.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 20.w,
                height: 20.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    textColor ?? AppColors.textPrimary,
                  ),
                ),
              )
            else
              SvgPicture.asset(icon, width: 24.w, height: 24.h),
            SizedBox(width: 12.w),
            Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15.sp,
                height: 1.3,
                letterSpacing: 15.sp * -0.01, // Letter spacing -1%
                color: textColor ?? AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Already Have Account Text Widget
class AlreadyHaveAccountText extends StatelessWidget {
  final String firstText;
  final String secondText;
  final TextStyle? firstTextStyle;
  final TextStyle? secondTextStyle;
  final VoidCallback? onSecondTextTap;

  const AlreadyHaveAccountText({
    super.key,
    this.firstText = 'Already have an account? ',
    this.secondText = 'Sign in',
    this.firstTextStyle,
    this.secondTextStyle,
    this.onSecondTextTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          firstText,
          style:
              firstTextStyle ??
              TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                height: 1.5, // Line height 150%
                letterSpacing: 14.sp * -0.015, // Letter spacing -1.5%
                color: AppColors.textPrimary.withOpacity(0.8),
              ),
        ),
        InkWell(
          onTap:
              onSecondTextTap ??
              () async {
                await LocalStorageService.instance.setOnboardingCompleted();
                // Default navigation
                context.go('/sign-in');
              },
          child: Text(
            secondText,
            style:
                secondTextStyle ??
                TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.3, // Line height 130%
                  letterSpacing: 14.sp * -0.01, // Letter spacing -1%
                  color: AppColors.textPrimary,
                ),
          ),
        ),
      ],
    );
  }
}
