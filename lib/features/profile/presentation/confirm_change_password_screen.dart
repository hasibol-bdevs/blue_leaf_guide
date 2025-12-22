import 'package:blue_leaf_guide/shared/widgets/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/button.dart';
import '../../../shared/widgets/text_field.dart' as CustomTextField;
import '../../auth/providers/auth_provider.dart';

class ConfirmChangePasswordScreen extends StatefulWidget {
  final String currentPassword;

  const ConfirmChangePasswordScreen({super.key, required this.currentPassword});

  @override
  State<ConfirmChangePasswordScreen> createState() =>
      _ConfirmChangePasswordScreenState();
}

class _ConfirmChangePasswordScreenState
    extends State<ConfirmChangePasswordScreen> {
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  final _formKey = GlobalKey<FormState>();

  Future<void> _handleContinue() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return; // Inline validation failed
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.changePassword(
      currentPassword: widget.currentPassword,
      newPassword: newPasswordController.text,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).popUntil(
        (route) => route.isFirst || route.settings.name == '/my-account',
      );
    } else if (mounted) {
      _showError(authProvider.errorMessage ?? 'Failed to change password');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Confirm Change Password'),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // New Password Field
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // New Password
                    CustomTextField.TextField(
                      controller: newPasswordController,
                      label: '',
                      hint: 'Create New Password',
                      obscureText: _obscureNewPassword,
                      textInputAction: TextInputAction.next,
                      prefixIconSvg: 'assets/icons/svg/lock.svg',
                      suffixIconSvg: _obscureNewPassword
                          ? 'assets/icons/svg/eye-closed.svg'
                          : null,
                      onSuffixIconTap: () {
                        setState(() {
                          _obscureNewPassword = !_obscureNewPassword;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a new password';
                        }
                        if (value.length < 4) {
                          return 'Password must be at least 4 characters';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 16.h),

                    // Confirm Password
                    CustomTextField.TextField(
                      controller: confirmPasswordController,
                      label: '',
                      hint: 'Confirm New Password',
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      prefixIconSvg: 'assets/icons/svg/lock.svg',
                      suffixIconSvg: _obscureConfirmPassword
                          ? 'assets/icons/svg/eye-closed.svg'
                          : null,
                      onSuffixIconTap: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please confirm your new password';
                        }
                        if (value != newPasswordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ],
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
                    letterSpacing: 0,
                    color: AppColors.textSecondary.withOpacity(0.7),
                  ),
                ),
              ),
              SizedBox(height: 32.h),

              // Continue Button
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return Button(
                    onPressed: _handleContinue,
                    text: authProvider.isLoading ? 'Changing...' : 'Continue',
                    height: 54.h,
                    borderRadius: BorderRadius.circular(32.r),
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    textColor: Colors.white,
                    backgroundColor: AppColors.brand500,
                    isLoading: authProvider.isLoading,
                  );
                },
              ),

              SizedBox(height: 12.h),

              // Cancel Button
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  minimumSize: Size(double.infinity, 54.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32.r),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: AppColors.textPrimary.withOpacity(0.8),
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
