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
              '',
              '''Last Updated: 12/10/2025 
                This Privacy Policy (“Policy”) describes how Blue Leaf Guide (“Company,” “we,” “our,” or “us”) collects, uses, discloses, retains, and protects your information when you access or use our cosmetology education mobile application and associated services (collectively, the “App”). By accessing or using the App, you acknowledge that you have read, understood, and agree to the terms of this Policy. 
    Your privacy is important to us. We are committed to maintaining the confidentiality, integrity, and security of your personal information.''',
            ),
            _buildSection(
              '1. Information We Collect',
              '''1.1  Personal Information Provided by You 
                We may collect personal information that you voluntarily provide when registering or interacting with the App, including but not limited to:

            Full name
            Email address
            Login credentials (encrypted)
        Subscription and plan selection
    Communications you send to our support team

        1.2 Automatically Collected Information

        When you access or use the App, we may automatically collect:

        Device identifiers, IP address, operating system, browser type
        App usage data, interaction logs, performance metrics
        Session duration, learning activity, course progress 
    1.3 Payment Information 
    All subscription and billing information is processed securely through third-party platforms (e.g., Apple App Store, Google Play Store, Stripe).  We do not store your full credit card number or sensitive financial information on our servers.''',
            ),
            SizedBox(height: 12.h),

            _buildSection(
              '2. How We Use Your Information',
              '''We may use your information for the following purposes:

To create, maintain, and secure your account
To provide access to educational modules, progress tracking, and subscription-based content
To manage billing, subscription status, and entitlement access
To analyze and enhance App performance, features, and user experience
To send administrative notices, updates, and customer support communications
To comply with legal responsibilities and enforce our Terms & Conditions

We do not sell or rent your personal information to third parties under any circumstances.''',
            ),
            SizedBox(height: 12.h),

            _buildSection(
              '3. Data Retention and Deletion',
              '''3.1 Retention Practices

We retain your data only for as long as it is reasonably necessary to:

Maintain your account
Provide educational services
Comply with legal, tax, or regulatory obligations
Fulfill internal business purposes

Educational progress, activity logs, and account information may be retained for record-keeping and service continuity even after subscription cancellation unless deletion is expressly requested.

3.2 Account Deletion

Upon receiving a verified deletion request:

Your account and associated personal information will be permanently deleted within 30 days
Some transactional or legally required records may be stored for compliance purposes''',
            ),
            SizedBox(height: 12.h),

            _buildSection(
              '4. Disclosure of Information to Third Parties',
              '''We may share information with trusted partners who provide services necessary to operate the App, including:

Payment processors
Cloud hosting providers
Email delivery services
Analytics and crash-reporting tools

Each provider is contractually obligated to protect your information and use it solely for the services they provide on our behalf.

We do not disclose your information to marketers.''',
            ),
            SizedBox(height: 12.h),

            _buildSection(
              '5. Security Measures',
              '''We implement commercially reasonable administrative, technical, and physical safeguards designed to protect your information from unauthorized access, disclosure, alteration, or destruction.
 Despite these measures, no system is entirely secure, and you acknowledge that you provide information at your own risk.''',
            ),
            SizedBox(height: 12.h),

            _buildSection(
              '6. User Rights and Choices',
              '''Depending on your jurisdiction, you may have the right to:

Access your personal information
Request corrections or updates
Request deletion of your information
Restrict or object to certain data processing activities
Request copies of your data in portable format 
All requests can be made by contacting: support@blgapp.com''',
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
