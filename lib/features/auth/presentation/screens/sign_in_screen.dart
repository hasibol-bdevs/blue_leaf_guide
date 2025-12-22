import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/button.dart';
import '../../../../shared/widgets/text_field.dart' as CustomTextField;
import '../../../onboarding/presentation/widgets/onboarding_widgets.dart';
import '../../providers/auth_provider.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _obscurePassword = true;

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      // If any field has error, it will show below TextField
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.signIn(
      email: emailController.text.trim(),
      password: passwordController.text,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Signed in successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/home');
    } else if (mounted) {
      // Only network/server error
      _showError(authProvider.errorMessage ?? 'Failed to sign in');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final success = await authProvider.signInWithGoogle();

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signed in with Google successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        context.go('/home');
      } else if (mounted) {
        if (authProvider.errorMessage != null &&
            authProvider.errorMessage != 'Sign in cancelled') {
          _showError(
            authProvider.errorMessage ?? 'Failed to sign in with Google',
          );
        }
      }
    } catch (e, stackTrace) {
      print('❌ Google sign-in error: $e');
      print(stackTrace);
      if (mounted) {
        _showError('An unexpected error occurred during Google sign-in.');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 36.w,
                    vertical: 32.h,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const OnboardingTitle(text: 'Sign In'),
                        SizedBox(height: 32.h),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              CustomTextField.TextField(
                                controller: emailController,
                                label: '',
                                hint: 'Email',
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                prefixIconSvg: 'assets/icons/svg/mail.svg',
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!RegExp(
                                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                  ).hasMatch(value)) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 12.h),
                              CustomTextField.TextField(
                                controller: passwordController,
                                label: '',
                                hint: 'Password',
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                prefixIconSvg: 'assets/icons/svg/lock.svg',
                                suffixIconSvg: _obscurePassword
                                    ? 'assets/icons/svg/eye-closed.svg'
                                    : null,
                                onSuffixIconTap: () {
                                  setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  );
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),

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
                                height: 1.40,
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
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            return Button(
                              onPressed: _handleSignIn,
                              text: authProvider.isLoading
                                  ? 'Signing In...'
                                  : 'Sign In',
                              height: 54.h,
                              borderRadius: BorderRadius.circular(32.r),
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              textColor: Colors.white,
                              backgroundColor: AppColors.textPrimary
                                  .withOpacity(0.8),
                              isLoading: authProvider.isLoading,
                            );
                          },
                        ),
                        SizedBox(height: 32.h),
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: AppColors.textPrimary.withOpacity(0.05),
                                thickness: 1.w,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10.w),
                              child: Text(
                                'or',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: AppColors.textPrimary.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: AppColors.textPrimary.withOpacity(0.05),
                                thickness: 1.w,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 32.h),
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            return SocialButton(
                              icon: 'assets/icons/svg/google.svg',
                              text: authProvider.isGoogleLoading
                                  ? 'Signing in...'
                                  : 'Continue with Google',
                              onTap: _handleGoogleSignIn,
                              isLoading: authProvider.isGoogleLoading,
                            );
                          },
                        ),
                        SizedBox(height: 12.h),
                        if (!Platform.isAndroid)
                          Column(
                            children: [
                              SocialButton(
                                icon: 'assets/icons/svg/apple.svg',
                                text: 'Continue with Apple',
                                backgroundColor: AppColors.brand500,
                                textColor: Colors.white,
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Coming Soon!'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: 12.h),
                            ],
                          ),
                        AlreadyHaveAccountText(
                          firstText: "Need an account? ",
                          secondText: "Sign up",
                          onSecondTextTap: () {
                            context.push('/sign-up');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
