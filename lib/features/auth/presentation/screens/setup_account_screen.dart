import 'package:flutter/material.dart' hide BackButtonIcon;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/back_button_icon.dart';
import '../../../../shared/widgets/button.dart';
import '../../../../shared/widgets/text_field.dart' as CustomTextField;
import '../../../onboarding/presentation/widgets/onboarding_widgets.dart';
import '../../providers/auth_provider.dart';

class SetupAccountScreen extends StatefulWidget {
  const SetupAccountScreen({super.key});

  @override
  State<SetupAccountScreen> createState() => _SetupAccountScreenState();
}

class _SetupAccountScreenState extends State<SetupAccountScreen> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final passwordController = TextEditingController();
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleDone() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return; // Validation errors will show under each field automatically
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.completeSignUp(
      firstName: firstNameController.text.trim(),
      lastName: lastNameController.text.trim(),
      password: passwordController.text,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/sign-in');
    } else if (mounted) {
      _showError(authProvider.errorMessage ?? 'Failed to create account');
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
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BackButtonIcon(onTap: () => context.pop()),
              SizedBox(height: 32.h),
              Align(
                alignment: Alignment.center,
                child: const OnboardingTitle(text: 'Setup Account'),
              ),
              SizedBox(height: 32.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  children: [
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          CustomTextField.TextField(
                            controller: firstNameController,
                            label: 'First Name',
                            hint: 'First Name',
                            keyboardType: TextInputType.name,
                            textInputAction: TextInputAction.next,
                            prefixIconSvg: 'assets/icons/svg/user.svg',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your first name';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 12.h),
                          CustomTextField.TextField(
                            controller: lastNameController,
                            label: 'Last Name',
                            hint: 'Last Name',
                            keyboardType: TextInputType.name,
                            textInputAction: TextInputAction.next,
                            prefixIconSvg: 'assets/icons/svg/user.svg',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your last name';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 12.h),
                          CustomTextField.TextField(
                            controller: passwordController,
                            label: 'Password',
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
                                return 'Please enter a password';
                              }
                              if (value.length < 4) {
                                return 'Password must be at least 4 characters';
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
                    SizedBox(height: 14.h),
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return Button(
                          onPressed: _handleDone,
                          text: authProvider.isLoading ? 'Creating...' : 'Done',
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
