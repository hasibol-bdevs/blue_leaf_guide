import 'package:blue_leaf_guide/app/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/custom_title_subtitle_appbar.dart';
import '../../../../shared/widgets/dual_radial_gradient_painter.dart';

class GrowthScreen extends StatefulWidget {
  const GrowthScreen({Key? key}) : super(key: key);

  @override
  State<GrowthScreen> createState() => _GrowthScreenState();
}

class _GrowthScreenState extends State<GrowthScreen>
    with SingleTickerProviderStateMixin {
  late Future<double> _brandBuilderFuture;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _brandBuilderFuture = _calculateBrandBuilderCompletion();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<double> _calculateBrandBuilderCompletion() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0.0;

    final uid = user.uid;
    final db = FirebaseFirestore.instance;

    int completedCount = 0;
    int totalCount = 0;

    try {
      // === 1. Strategy Items (5 items) ===
      final strategyDoc = await db
          .collection('users')
          .doc(uid)
          .collection('strategy')
          .doc('items')
          .get();

      totalCount += 5;
      if (strategyDoc.exists && strategyDoc.data() != null) {
        final data = strategyDoc.data()!;
        final List<dynamic>? items = data['items'];
        if (items != null) {
          completedCount += items
              .where((item) => (item as Map)['isCompleted'] == true)
              .length;
        }
      }

      // === 2. Visual Items (4 items) ===
      final visualDoc = await db
          .collection('users')
          .doc(uid)
          .collection('visual')
          .doc('items')
          .get();

      totalCount += 4;
      if (visualDoc.exists && visualDoc.data() != null) {
        final data = visualDoc.data()!;
        final List<dynamic>? items = data['items'];
        if (items != null) {
          completedCount += items
              .where((item) => (item as Map)['isCompleted'] == true)
              .length;
        }
      }

      // === 3. Marketing Items (6 items) ===
      final marketingDoc = await db
          .collection('users')
          .doc(uid)
          .collection('marketing')
          .doc('items')
          .get();

      totalCount += 6;
      if (marketingDoc.exists && marketingDoc.data() != null) {
        final data = marketingDoc.data()!;
        final List<dynamic>? items = data['items'];
        if (items != null) {
          completedCount += items
              .where((item) => (item as Map)['isCompleted'] == true)
              .length;
        }
      }

      // === 4. Planning Checkboxes (10 total) ===
      final planningDoc = await db
          .collection('users')
          .doc(uid)
          .collection('planning')
          .doc('data') // 👈 CORRECT DOC ID
          .get();

      totalCount += 10; // 3 + 3 + 4
      if (planningDoc.exists && planningDoc.data() != null) {
        final data = planningDoc.data()!;

        final List<dynamic>? month1 = data['month1'];
        final List<dynamic>? month2 = data['month2'];
        final List<dynamic>? month3 = data['month3'];

        if (month1 != null) {
          completedCount += month1.where((e) => e == true).length;
        }
        if (month2 != null) {
          completedCount += month2.where((e) => e == true).length;
        }
        if (month3 != null) {
          completedCount += month3.where((e) => e == true).length;
        }
      }

      return totalCount > 0 ? completedCount / totalCount : 0.0;
    } catch (e) {
      print('Error calculating brand builder completion: $e');
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomTitleSubtitleAppbar(
        title: 'Growth',
        subtitle: 'Develop your brand and mindset',
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(21.5.r),
                child: CustomPaint(
                  painter: DualRadialGradientPainter(),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(21.5.r),
                      border: Border.all(
                        color: AppColors.textPrimary.withOpacity(0.05),
                        width: 1,
                      ),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 32.0),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(
                                'assets/icons/svg/star.svg',
                                width: 16.sp,
                                height: 16.sp,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                'AFFIRMATION OF THE DAY',
                                style: TextStyle(
                                  color: AppColors.brand500,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16.h),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 300.w),
                          child: Text(
                            'You are mastering your craft building your future',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.primaryDark,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            // Growth Areas Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                'Growth Areas',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 12.h),
            // Brand Builder Card
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                children: [
                  FutureBuilder<double>(
                    future: _brandBuilderFuture,
                    builder: (context, snapshot) {
                      bool isLoading =
                          snapshot.connectionState != ConnectionState.done;
                      double progress = snapshot.data ?? 0.0;

                      // Animate progress when data arrives
                      if (!isLoading && progress > 0) {
                        _progressController.forward(from: 0.0);
                      }

                      return _buildGrowthCard(
                        title: 'Brand Builder',
                        subtitle: 'Create your professional identity',
                        progress: progress,
                        isLoadingProgress: isLoading,
                        progressController: _progressController,
                        showProgress: true,
                        backgroundColor: AppColors.lightGrey,
                        svgPath: 'assets/icons/svg/building.svg',
                        onTap: () {
                          context.push('/build-brand');
                        },
                      );
                    },
                  ),

                  SizedBox(height: 12.h),
                  // Progress & Rewards Card
                  _buildGrowthCard(
                    title: 'Progress & Rewards',
                    subtitle: 'Track achievement & celebrate wins',
                    backgroundColor: AppColors.bgLight,
                    svgPath: 'assets/icons/svg/cup.svg',
                    onTap: () {
                      context.push('/rewards');
                    },
                  ),
                  SizedBox(height: 12.h),
                  // Learning Guides Card
                  _buildGrowthCard(
                    title: 'Learning Guides',
                    subtitle: 'Tutorials, tips, and industry insights',
                    badge: 'Coming Soon',
                    backgroundColor: AppColors.lightGrey,
                    showChevron: false,
                    svgPath: 'assets/icons/svg/book.svg',
                  ),
                  SizedBox(height: 12.h),
                  // Interview Practices Card
                  _buildGrowthCard(
                    title: 'Interview Practices',
                    subtitle: 'Get ready for salon interviews',
                    badge: 'Coming Soon',
                    backgroundColor: AppColors.bgLight,
                    showChevron: false,
                    svgPath: 'assets/icons/svg/user-black.svg',
                  ),
                  SizedBox(height: 80.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrowthCard({
    required String svgPath,
    required String title,
    required String subtitle,
    double? progress,
    bool showProgress = false,
    bool isLoadingProgress = false,
    AnimationController? progressController,
    String? badge,
    required Color backgroundColor,
    bool showChevron = true,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.w, horizontal: 16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SVG Icon - vertically centered using FittedBox + Center
                    Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 12.w,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(100.r),
                        ),
                        child: SvgPicture.asset(
                          svgPath,
                          width: 20.sp,
                          height: 20.sp,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    // Title & Subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (badge != null) ...[
                                SizedBox(width: 8.w),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 4.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.amber,
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Text(
                                    badge,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                              if (showChevron) ...[
                                Spacer(),
                                Icon(
                                  Icons.chevron_right,
                                  color: AppColors.textPrimary.withOpacity(0.8),
                                  size: 24.sp,
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: AppColors.textPrimary.withOpacity(0.7),
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (showProgress && progress != null) ...[
                SizedBox(height: 12.h),
                Row(
                  children: [
                    SizedBox(width: 56.w),
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progress',
                                style: TextStyle(
                                  color: AppColors.textPrimary.withOpacity(0.7),
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (isLoadingProgress)
                                SizedBox(
                                  width: 40.w,
                                  height: 16.h,
                                  child: const LinearProgressIndicator(
                                    backgroundColor: Color(0xFFF0F0F0),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFFEEEEEE),
                                    ),
                                    minHeight: 4,
                                  ),
                                )
                              else if (progressController != null)
                                AnimatedBuilder(
                                  animation: progressController,
                                  builder: (context, child) {
                                    return Text(
                                      '${(progress * progressController.value * 100).toInt()}%',
                                      style: TextStyle(
                                        color: AppColors.brand500,
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    );
                                  },
                                )
                              else
                                Text(
                                  '${(progress * 100).toInt()}%',
                                  style: TextStyle(
                                    color: AppColors.brand500,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          if (isLoadingProgress)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10.r),
                              child: LinearProgressIndicator(
                                backgroundColor: AppColors.brand100,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFFEEEEEE),
                                ),
                                minHeight: 6.h,
                              ),
                            )
                          else if (progressController != null)
                            AnimatedBuilder(
                              animation: progressController,
                              builder: (context, child) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(10.r),
                                  child: LinearProgressIndicator(
                                    value: progress * progressController.value,
                                    backgroundColor: AppColors.brand100,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          AppColors.brand500,
                                        ),
                                    minHeight: 6.h,
                                  ),
                                );
                              },
                            )
                          else
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10.r),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: AppColors.brand100,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.brand500,
                                ),
                                minHeight: 6.h,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (showChevron) SizedBox(width: 12.w),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
