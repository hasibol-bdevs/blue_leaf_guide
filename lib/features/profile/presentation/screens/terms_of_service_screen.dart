import 'package:blue_leaf_guide/shared/widgets/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_colors.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Terms of Service'),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header / Subtitle
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 300.w, // set your desired max width
              ),
              child: Text(
                'Empowering everyday experiences through smart, simple, and secure solutions.',
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

            // 1. Using the App
            _buildSection(
              title: '1. Using the App',
              content:
                  'You agree to use all features in a lawful and respectful way while following our rules.',
            ),

            // 2. Account Responsibility
            _buildSection(
              title: '2. Account Responsibility',
              content:
                  'You’re responsible for keeping your login details secure and managing activity under your account.',
            ),

            // 3. Content & AI Responses
            _buildSection(
              title: '3. Content & AI Responses',
              content:
                  'AI-generated answers are for guidance only, and you’re encouraged to use your own judgment.',
            ),

            // 4. Updates & Changes
            _buildSection(
              title: '4. Updates & Changes',
              content:
                  'We may improve or modify features over time, and you’ll be notified whenever important terms change.',
            ),

            // 5. Limitations
            _buildSection(
              title: '5. Limitations',
              content:
                  'We work to provide a smooth experience, but we’re not liable for interruptions, errors, or third-party issues.',
            ),

            // 6. Contact
            _buildSection(
              title: '6. Contact',
              content:
                  'For any concerns or support, reach us at: support@blueleafguide.com',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12.sp,
              height: 1.4,
              color: AppColors.textPrimary.withOpacity(0.8),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            content,
            style: TextStyle(
              fontWeight: FontWeight.w500, // Medium
              fontSize: 12.sp,
              height: 1.4,
              letterSpacing: 0,
              color: AppColors.textSecondary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
