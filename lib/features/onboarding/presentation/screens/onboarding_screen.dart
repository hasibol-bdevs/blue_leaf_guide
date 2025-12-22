import 'dart:io';

import 'package:blue_leaf_guide/app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/local_storage.dart';
import '../../../auth/providers/auth_provider.dart';
import '../widgets/onboarding_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      illustration:
          'assets/illustrations/onboarding/onboarding_intro_welcome.svg',
      title: 'Build Your Brand',
      subtitle:
          'Shape your identity with clarity and confidence. grow stronger with every step.',
    ),
    OnboardingData(
      illustration:
          'assets/illustrations/onboarding/onboarding_task_create.svg',
      title: 'View Your Roadmap',
      subtitle:
          'See every step of your journey in one simple view. stay focused on steady progress.',
    ),
    OnboardingData(
      illustration:
          'assets/illustrations/onboarding/onboarding_project_overview.svg',
      title: 'Add Your Daily Task',
      subtitle:
          'Stay consistent with small actions that build momentum. make productivity a daily habit.',
    ),
    OnboardingData(
      illustration:
          'assets/illustrations/onboarding/onboarding_notifications.svg',
      title: 'Your AI Tutor',
      subtitle:
          'Get instant guidance to learn, improve, and grow. supporting you at every stage.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    askNotificationPermission();
  }

  Future<void> askNotificationPermission() async {
    final plugin = FlutterLocalNotificationsPlugin();

    // Android 13+
    await plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    // iOS
    await plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) =>
                    _buildOnboardingPage(_pages[index]),
              ),
            ),

            // Bottom content
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  PageIndicator(
                    currentIndex: _currentPage,
                    totalPages: _pages.length,
                  ),
                  SizedBox(height: 32.h),

                  // Social login buttons
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return SocialButton(
                        icon: 'assets/icons/svg/google.svg',
                        text: authProvider.isGoogleLoading
                            ? 'Signing in...'
                            : 'Continue with Google',
                        onTap: () async {
                          await LocalStorageService.instance
                              .setOnboardingCompleted();
                          _handleGoogleSignIn();
                        },
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

                  const AlreadyHaveAccountText(),
                  SizedBox(height: 32.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingData data) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          SvgPicture.asset(
            data.illustration,
            width: 240.w,
            height: 240.h,
            fit: BoxFit.contain,
          ),

          SizedBox(height: 24.h),

          // Title
          OnboardingTitle(text: data.title),

          SizedBox(height: 4.h),

          // Subtitle
          OnboardingSubtitle(text: data.subtitle),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String illustration;
  final String title;
  final String subtitle;

  OnboardingData({
    required this.illustration,
    required this.title,
    required this.subtitle,
  });
}
