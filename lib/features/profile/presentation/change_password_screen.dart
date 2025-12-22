import 'package:blue_leaf_guide/shared/widgets/custom_appbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/button.dart';
import '../../../shared/widgets/text_field.dart' as CustomTextField;

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  Future<void> _handleContinue() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return; // Inline error shown
    }

    final currentPassword = passwordController.text.trim();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.email == null) {
      _showError('Session expired. Please log in again.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      context.push(
        '/confirm-change-password',
        extra: {'currentPassword': currentPassword},
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        _showError('Incorrect current password');
      } else {
        _showError(e.message ?? 'Password verification failed');
      }
    } catch (_) {
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Change Password'),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Password Field
              Form(
                key: _formKey,
                child: CustomTextField.TextField(
                  controller: passwordController,
                  label: '',
                  hint: 'Current Password',
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  prefixIconSvg: 'assets/icons/svg/lock.svg',
                  suffixIconSvg: _obscurePassword
                      ? 'assets/icons/svg/eye-closed.svg'
                      : null,
                  onSuffixIconTap: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your current password';
                    }
                    return null;
                  },
                ),
              ),

              // Forgot Password
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () {
                    context.push('/forgot-password');
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size(0, 24.h),
                  ),
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: AppColors.textPrimary.withOpacity(0.7),
                      fontSize: 14.sp,
                      height: 1.4,
                      letterSpacing: -0.01 * 14,
                      decoration: TextDecoration.underline,
                      decorationStyle: TextDecorationStyle.solid,
                      decorationThickness: 0.07 * 14,
                      decorationColor: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 32.h),

              // Continue Button
              Button(
                onPressed: _handleContinue,
                text: 'Continue',
                height: 54.h,
                borderRadius: BorderRadius.circular(32.r),
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                textColor: Colors.white,
                backgroundColor: AppColors.brand500,
                isLoading: _isLoading,
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
