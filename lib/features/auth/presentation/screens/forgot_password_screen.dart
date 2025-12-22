import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/button.dart';
import '../../../../shared/widgets/custom_appbar.dart';
import '../../../../shared/widgets/text_field.dart' as CustomTextField;
import '../../../onboarding/presentation/widgets/onboarding_widgets.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendResetEmail() async {
    FocusScope.of(context).unfocus();

    // Validate form first
    if (!_formKey.currentState!.validate()) {
      return; // Errors will show under the TextField automatically
    }

    final email = emailController.text.trim();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final emailExists = await authProvider.checkEmailExists(email);

    if (!emailExists && mounted) {
      _showError('Email does not exist. Please sign up.');
      return;
    }

    final success = await authProvider.sendPasswordResetEmail(email);

    if (success && mounted) {
      _showSuccessDialog();
    } else if (mounted) {
      // Only show SnackBar for network/server errors
      _showError(authProvider.errorMessage ?? 'Failed to send reset email');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Column(
          children: [
            Icon(Icons.mark_email_read, size: 64.sp, color: AppColors.brand500),
            SizedBox(height: 16.h),
            Text(
              'Check Your Email',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'We\'ve sent a password reset link to ${emailController.text}.\n\nClick the link in the email to reset your password. The link will open this app automatically.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.sp,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Button(
              onPressed: () {
                context.pop(); // Close dialog
                context.pop(); // Go back to previous screen
              },
              text: 'Got It',
              height: 48.h,
              borderRadius: BorderRadius.circular(24.r),
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              textColor: Colors.white,
              backgroundColor: AppColors.brand500,
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(title: 'Reset Password'),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 40.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.center,
                child: const OnboardingTitle(text: 'Reset Password'),
              ),
              SizedBox(height: 8.h),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 300.w),
                  child: Text(
                    'Enter your registered email address and we\'ll send you a link to reset your password.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      letterSpacing: -0.01 * 14,
                      color: AppColors.textPrimary.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 32.h),
              Form(
                key: _formKey,
                child: CustomTextField.TextField(
                  controller: emailController,
                  label: '',
                  hint: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  prefixIconSvg: 'assets/icons/svg/mail.svg',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email address';
                    }
                    final emailRegex = RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    );
                    if (!emailRegex.hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: 24.h),
              Button(
                onPressed: _handleSendResetEmail,
                text: 'Reset',
                height: 54.h,
                borderRadius: BorderRadius.circular(32.r),
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                textColor: Colors.white,
                backgroundColor: AppColors.brand500,
                isLoading: authProvider.isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
