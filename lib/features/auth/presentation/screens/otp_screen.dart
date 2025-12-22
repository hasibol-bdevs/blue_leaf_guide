import 'dart:async';

import 'package:flutter/material.dart' hide BackButtonIcon;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/back_button_icon.dart';
import '../../../../shared/widgets/button.dart';
import '../../../onboarding/presentation/widgets/onboarding_widgets.dart';
import '../../providers/auth_provider.dart';

class OTPScreen extends StatefulWidget {
  final String? nextRoute;

  const OTPScreen({super.key, this.nextRoute});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final pinController = TextEditingController();
  Timer? _timer;
  int _secondsRemaining = 300; // 5 minutes

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    pinController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _handleContinue() async {
    if (pinController.text.length != 4) {
      _showError('Please enter the 4-digit code');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.verifyOTP(pinController.text);

    if (success && mounted) {
      context.push(widget.nextRoute ?? '/setup-account');
    } else if (mounted) {
      _showError(authProvider.errorMessage ?? 'Invalid OTP');
    }
  }

  Future<void> _handleResend() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.pendingEmail == null) {
      _showError('Email not found. Please start again.');
      return;
    }

    final success = await authProvider.sendSignUpOTP(
      authProvider.pendingEmail!,
    );

    if (success && mounted) {
      setState(() {
        _secondsRemaining = 300;
        pinController.clear();
      });
      _startTimer();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP sent successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      _showError('Failed to resend OTP');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    final defaultPinTheme = PinTheme(
      width: 45.w,
      height: 45.w,
      textStyle: TextStyle(
        fontSize: 24.sp,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.textSecondary.withOpacity(0.05),
          width: 1.25,
        ),
        borderRadius: BorderRadius.circular(22.5.r),
      ),
    );

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
                child: const OnboardingTitle(text: 'Enter Code'),
              ),
              SizedBox(height: 2.h),
              Center(
                child: Text(
                  'Enter the security code we sent to ${authProvider.pendingEmail ?? "your email"}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary.withOpacity(0.8),
                    height: 1.3,
                    letterSpacing: -0.01 * 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 32.h),
              Center(
                child: Pinput(
                  controller: pinController,
                  length: 4,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: defaultPinTheme.copyWith(
                    decoration: defaultPinTheme.decoration!.copyWith(
                      border: Border.all(color: AppColors.brand500, width: 1.5),
                    ),
                  ),
                  submittedPinTheme: defaultPinTheme,
                  onCompleted: (pin) {
                    _handleContinue();
                  },
                ),
              ),
              SizedBox(height: 12.h),
              Center(
                child: Text(
                  _formatTime(_secondsRemaining),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: _secondsRemaining > 0
                        ? AppColors.textPrimary.withOpacity(0.7)
                        : Colors.red,
                    height: 1.3,
                    letterSpacing: -0.01 * 14,
                  ),
                ),
              ),
              SizedBox(height: 32.h),
              Center(
                child: TextButton(
                  onPressed: () {
                    if (_secondsRemaining > 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Please wait ${_secondsRemaining}s before requesting a new code.',
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    } else {
                      _handleResend();
                    }
                  },
                  child: Text(
                    "Didn't receive a code?",
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary.withOpacity(0.7),
                      height: 1.4,
                      letterSpacing: -0.01 * 14,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              Button(
                onPressed: _handleContinue,
                text: authProvider.isLoading ? 'Verifying...' : 'Continue',
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
