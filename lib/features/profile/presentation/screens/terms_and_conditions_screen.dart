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
      appBar: const CustomAppBar(title: 'Terms & Conditions'),
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

            _buildSection(
              title: "",
              content: '''Last Updated: 12/10/2025

These Terms & Conditions (“Terms”) govern your access to and use of the cosmetology education mobile application provided by Blue Leaf Guide (“Company,” “we,” “our,” or “us”). By creating an account, subscribing to the App, or using any portion of the service, you agree to be legally bound by these Terms.''',
            ),

            // 1. Using the App
            _buildSection(
              title: '1. Acceptance of Terms',
              content: '''By accessing or using the App, you affirm that: 
                You are at least 18 years old, or of legal age to form a binding contract
            You have read and understood these Terms
            You will comply with all applicable laws and regulations 
                If you do not agree, you must discontinue use immediately.''',
            ),

            // 2. Account Responsibility
            _buildSection(
              title: '2. Description of Services',
              content:
                  'The App provides digital educational tools, study modules, and progress-tracking features designed to support cosmetology students in their coursework. The App is not a substitute for formal schooling, professional training, or state licensure preparation, and we make no guarantees regarding academic or professional outcomes.',
            ),

            // 3. Content & AI Responses
            _buildSection(
              title: '3. User Accounts',
              content: '''3.1 Registration 
                To access core features, you must create an account. You agree to: 
            Provide accurate and complete information
            Maintain the confidentiality of your login credentials
            Be responsible for all activities conducted under your account 
            3.2 Unauthorized Use 
            Sharing login credentials or allowing others to access your account is strictly prohibited and may result in termination.''',
            ),

            // 4. Updates & Changes
            _buildSection(
              title: '4. Subscriptions, Billing, and Payment Terms',
              content: '''4.1 Subscription Access 
                Access to premium content and advanced modules requires a paid subscription. Subscription tiers and pricing are displayed at the time of purchase. 
            4.2 Billing 
            All payments are processed via Apple, Google, Stripe, or other approved billing partners
            We do not control or store payment credentials
            Subscriptions automatically renew unless cancelled in advance 
            4.3 Refund Policy 
            All subscription fees are non-refundable except where required by applicable law or app store policy.''',
            ),

            // 5. Limitations
            _buildSection(
              title: '5. Intellectual Property Rights',
              content:
                  '''WAll content, including educational materials, text, images, audio, video, software, logos, trademarks, and design elements, are the exclusive property of the Company or its licensors. You receive a limited, non-transferable, non-sublicensable, revocable license to use the App for personal, educational purposes only.  You may not: 
                Copy, reproduce, or distribute content
            Modify or create derivative works
            Reverse engineer or attempt to access source code
            Use the App or its content for commercial purposes''',
            ),

            // 6. Contact
            _buildSection(
              title: '6. Acceptable Use Policy',
              content: '''You agree not to: 
                Circumvent security or access-control mechanisms
            Attempt unauthorized access to the App or related systems
            Use automated tools (bots, scrapers, scripts) to extract data
        Interfere with service integrity, availability, or performance
        Upload malicious code or engage in fraudulent behaviour 
        Violation may result in immediate suspension or termination.''',
            ),
            // 7
            _buildSection(
              title: '''Service Modifications and Availability
              We reserve the right to:''',
              content: '''Update, improve, or modify the App at any time
Discontinue features or functionalities
Perform maintenance that may result in temporary service interruptions

We are not liable for any such interruptions.''',
            ),
            // 8
            _buildSection(
              title: '8. Disclaimer of Warranties',
              content:
                  '''The App is provided on an “as is” and “as available” basis without warranties of any kind, express or implied.   We specifically disclaim any warranties regarding: 
Accuracy, reliability, or completeness of educational content
Fitness for a particular purpose
Guaranteed academic or professional outcomes
Uninterrupted or error-free service''',
            ),
            // 8
            _buildSection(
              title: '9. Limitation of Liability',
              content:
                  '''o the fullest extent permitted by law, the Company shall not be liable for:

Indirect, incidental, special, punitive, or consequential damages
Loss of data, revenue, profits, or business opportunities
Errors, interruptions, or inability to access the App
 In no event shall our total liability exceed the amount paid by you in the preceding 90 days of subscription fees.''',
            ),
            // 9
            _buildSection(
              title: '10. Termination',
              content:
                  '''We may suspend or terminate your account at our discretion for:

Violations of these Terms
Fraudulent or suspicious activity
Abuse of the App or its resources

Upon termination:

Access to premium content is revoked
No refunds will be issued
Certain obligations (intellectual property restrictions, limitations of liability) will survive termination''',
            ),
            // 11
            _buildSection(
              title: "11. Governing Law and Dispute Resolution",
              content:
                  '''These Terms shall be governed by and interpreted in accordance with the laws of the State of Florida, without regard to conflict-of-law principles.

                Any dispute arising from these Terms or your use of the App shall be resolved through binding arbitration or small claims court, unless otherwise prohibited by law.''',
            ),
            // 12
            _buildSection(
              title: "12. Changes to Terms",
              content:
                  '''We reserve the right to modify these Terms at any time. Updates are effective upon posting within the App. Continued use constitutes acceptance of the updated Terms. ''',
            ),
            // 13
            _buildSection(
              title: "13. Contact Information",
              content:
                  '''If you have questions about these Terms, subscriptions, or account issues, contact us at: support@blgapp.com''',
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
