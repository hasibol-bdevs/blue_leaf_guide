import 'package:blue_leaf_guide/shared/widgets/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Privacy Policy',
        hideBackButton: false, // shows back button
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 300.w, // set your desired max width
              ),
              child: Text(
                'We protect your information with care so you can use the app confidently.',
                style: TextStyle(
                  fontWeight: FontWeight.w500, // Medium
                  fontSize: 12.sp,
                  height: 1.4, // line-height 140%
                  letterSpacing: 0,
                  color: AppColors.textPrimary.withOpacity(0.7),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            _buildSection(
              '1. Privacy & Safety',
              'Your personal details stay secure through strong protection and responsible handling.',
            ),
            SizedBox(height: 12.h),

            _buildSection(
              '2. Data We Use',
              'We only collect the essentials to improve your experience and deliver smarter features.',
            ),
            SizedBox(height: 12.h),

            _buildSection(
              '3. Your Control',
              'You can review, update, or delete your account and data whenever it suits you best.',
            ),
            SizedBox(height: 12.h),

            _buildSection(
              '4. Secure Systems',
              'Advanced safeguards keep your activity private and prevent unauthorized access.',
            ),
            SizedBox(height: 12.h),

            _buildSection(
              '5. Transparency Always',
              'You’ll be informed about any updates so you always know how your information is handled.',
            ),
            SizedBox(height: 12.h),

            _buildSection(
              '6. Contact',
              'For any concerns or support, reach us at: support@blueleafguide.com',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 340.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12.sp,
              height: 1.4,
              letterSpacing: 0,
              color: AppColors.textPrimary.withOpacity(0.8),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            content,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12.sp,
              height: 1.4,
              letterSpacing: 0,
              color: AppColors.textPrimary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
