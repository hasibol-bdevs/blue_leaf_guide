import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/button.dart';
import '../../../../shared/widgets/custom_appbar.dart';
import '../../../../shared/widgets/text_field.dart' as CustomTextField;
import '../../providers/auth_provider.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String resetCode;

  const ResetPasswordScreen({super.key, required this.resetCode});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isVerifying = true;
  String? _verifiedEmail;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verifyResetCode();
    });
  }

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _verifyResetCode() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = await authProvider.verifyPasswordResetCode(widget.resetCode);

    if (mounted) {
      setState(() {
        _isVerifying = false;
        _verifiedEmail = email;
      });

      if (email == null) {
        _showErrorDialog(
          authProvider.errorMessage ??
              'Invalid or expired reset link. Please request a new one.',
        );
      }
    }
  }

  Future<void> _handleResetPassword() async {
    FocusScope.of(context).unfocus();

    // Validate form first
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final password = passwordController.text;

    final success = await authProvider.confirmPasswordReset(
      code: widget.resetCode,
      newPassword: password,
    );

    if (success && mounted) {
      _showSuccessDialog();
    } else if (mounted) {
      _showError(authProvider.errorMessage ?? 'Failed to reset password');
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
            Icon(Icons.check_circle, size: 64.sp, color: Colors.green),
            SizedBox(height: 16.h),
            Text(
              'Password Reset!',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Your password has been reset successfully. You can now sign in with your new password.',
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
                context.go('/sign-in');
              },
              text: 'Go to Sign In',
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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Column(
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
            SizedBox(height: 16.h),
            Text(
              'Invalid Link',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          message,
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
                context.go('/forgot-password');
              },
              text: 'Request New Link',
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

  void _togglePasswordVisibility() {
    setState(() => _obscurePassword = !_obscurePassword);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final canPop = GoRouter.of(context).canPop();

    if (_isVerifying) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.brand500),
              SizedBox(height: 16.h),
              Text(
                'Verifying reset link...',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_verifiedEmail == null) {
      return const SizedBox();
    }

    // Wrap with PopScope to handle hardware back button
    return PopScope(
      canPop: canPop,
      onPopInvoked: (didPop) async {
        if (!didPop && !canPop) {
          // Hardware back was pressed but can't pop, navigate to sign-in
          context.go('/sign-in');
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(title: 'Reset Password', hideBackButton: !canPop),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 36.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 60.h),
                  Center(
                    child: Text(
                      'Create New Password',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                  ),
                  SizedBox(height: 32.h),
                  Form(
                    key: _formKey,
                    child: CustomTextField.TextField(
                      controller: passwordController,
                      label: '',
                      hint: 'Create New Password',
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      prefixIconSvg: 'assets/icons/svg/lock.svg',
                      suffixIconSvg: _obscurePassword
                          ? 'assets/icons/svg/eye-closed.svg'
                          : null,
                      onSuffixIconTap: _togglePasswordVisibility,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 4) {
                          return 'Password must be at least 4 characters';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Create a password with at least 4 characters',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                        color: AppColors.textSecondary.withOpacity(0.7),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Button(
                    onPressed: _handleResetPassword,
                    text: 'Done',
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
        ),
      ),
    );
  }
}
