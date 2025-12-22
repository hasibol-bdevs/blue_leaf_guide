import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/client_service.dart';
import '../../providers/navigation_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Helper: Get last day of a given month
  DateTime _lastDayOfMonth(DateTime date) {
    final nextMonth = DateTime(date.year, date.month + 1, 1);
    return nextMonth.subtract(const Duration(days: 1));
  }

  Future<int> _countCompletedMonths(String userId) async {
    try {
      // Fetch all ACTIVE monthly goals
      final goalsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('monthly_goals')
          .where('isActive', isEqualTo: true)
          .get();

      if (goalsSnapshot.docs.isEmpty) return 0;

      // Group goals by month (e.g., "2025-01")
      final Map<String, List<Map<String, dynamic>>> goalsByMonth = {};

      for (final doc in goalsSnapshot.docs) {
        final data = doc.data();
        final String? monthKey = data['month'] as String?;
        if (monthKey == null) continue;

        final int target = (data['targetNumber'] as num?)?.toInt() ?? 0;
        final int progress = (data['currentProgress'] as num?)?.toInt() ?? 0;

        goalsByMonth.putIfAbsent(monthKey, () => []);
        goalsByMonth[monthKey]!.add({'target': target, 'progress': progress});
      }

      // Today at start of day (for fair comparison)
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      int completedCount = 0;

      for (final entry in goalsByMonth.entries) {
        final String monthKey = entry.key;
        final List<Map<String, dynamic>> goals = entry.value;

        // Parse "2025-01" → DateTime(2025, 1, 1)
        final DateTime monthStart;
        try {
          monthStart = DateFormat('yyyy-MM').parse(monthKey);
        } catch (e) {
          continue; // skip invalid month keys
        }

        // Get last day of this month (e.g., Jan 31)
        final DateTime lastDay = _lastDayOfMonth(monthStart);

        // 🔑 CRITICAL: Only count if month is FULLY in the past
        if (today.compareTo(lastDay) <= 0) {
          // Today is still within this month (or it's future) → skip
          continue;
        }

        // Check if ALL goals in this PAST month are completed
        final bool allCompleted = goals.every((goal) {
          return (goal['progress'] as int) >= (goal['target'] as int);
        });

        if (allCompleted) {
          completedCount++;
        }
      }

      return completedCount;
    } catch (e) {
      print('Error counting completed months: $e');
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Inside your HomeScreen build method, replace the header Row
    final userData = context.watch<AuthProvider>().userData;
    final firstName = userData?['firstName'] ?? 'User';
    final photoURL = userData?['photoURL'];

    print('🟨 Photo URL $photoURL');

    String _getGreeting() {
      final hour = DateTime.now().hour;
      if (hour < 12) return "Good Morning";
      if (hour < 18) return "Good Afternoon";
      return "Good Evening";
    }

    String _formatNumber(int number) {
      if (number >= 1000000) {
        double value = number / 1000000;
        return (value % 1 == 0)
            ? '${value.toStringAsFixed(0)}M'
            : '${value.toStringAsFixed(1)}M';
      }

      if (number >= 1000) {
        double value = number / 1000;
        return (value % 1 == 0)
            ? '${value.toStringAsFixed(0)}K'
            : '${value.toStringAsFixed(1)}K';
      }

      return number.toString();
    }

    // Current authenticated user (may be null)
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Row(
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: () {
                      context.push('/profile');
                    },
                    child: Container(
                      width: 45.w,
                      height: 45.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.lightGrey,
                        image: (photoURL != null && photoURL.isNotEmpty)
                            ? DecorationImage(
                                image: (photoURL.startsWith('http'))
                                    ? NetworkImage(photoURL)
                                    : MemoryImage(base64Decode(photoURL))
                                        as ImageProvider,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: (photoURL == null || photoURL.isEmpty)
                          ? Center(
                              child: Text(
                                firstName.isNotEmpty
                                    ? firstName[0].toUpperCase()
                                    : '',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),

                  SizedBox(width: 12.w),
                  // Greeting Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, $firstName',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          _getGreeting(),
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary.withOpacity(0.5),
                            height: 1.3,
                            letterSpacing: 12 * 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      context.push('/notification-list');
                    },
                    child: ClipOval(
                      child: SvgPicture.asset(
                        'assets/icons/svg/bell.svg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16.h),

              // Subtitle
              Text(
                "Let's make today count",
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary.withOpacity(0.8),
                ),
              ),

              SizedBox(height: 20.h),

              // (currentUser will be declared above to keep build's widget list clean)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Total Clients: show a placeholder when not authenticated
                  if (currentUser == null)
                    _buildStatsCard(
                      svgPath: 'assets/icons/svg/multi-user.svg',
                      label: 'Total Client',
                      value: '0',
                      gradientColors: [
                        Colors.white.withOpacity(0),
                        const Color(0xFF24AC69).withOpacity(0.4),
                        const Color(0xFF24AC69),
                      ],
                      onTap: () {
                        // If not authenticated, navigate to login or show message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please log in to view clients'),
                          ),
                        );
                      },
                    )
                  else
                    StreamBuilder<QuerySnapshot>(
                      stream: ClientService().getClientsStream(),
                      builder: (context, snapshot) {
                        int totalClients = 0;
                        if (snapshot.hasData) {
                          totalClients = snapshot.data?.docs.length ?? 0;
                        }

                        return _buildStatsCard(
                          svgPath: 'assets/icons/svg/multi-user.svg',
                          label: 'Total Client',
                          value:
                              '$totalClients', // dynamically show total clients
                          gradientColors: [
                            Colors.white.withOpacity(0),
                            const Color(0xFF24AC69).withOpacity(0.4),
                            const Color(0xFF24AC69),
                          ],
                          onTap: () {
                            context.push('/total-clients');
                          },
                        );
                      },
                    ),

                  // Total Earned: guard currentUser before subscribing
                  if (currentUser == null)
                    _buildStatsCard(
                      svgPath: 'assets/icons/svg/dollar.svg',
                      label: 'Total Earned',
                      value: '--',
                      gradientColors: [
                        Colors.white.withOpacity(0),
                        const Color(0xFF2C63FD).withOpacity(0.4),
                        const Color(0xFF2C63FD),
                      ],
                      onTap: () {},
                    )
                  else
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUser.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return _buildStatsCard(
                            svgPath: 'assets/icons/svg/dollar.svg',
                            label: 'Total Earned',
                            value: '--',
                            gradientColors: [
                              Colors.white.withOpacity(0),
                              const Color(0xFF2C63FD).withOpacity(0.4),
                              const Color(0xFF2C63FD),
                            ],
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Loading...')),
                              );
                            },
                          );
                        }

                        if (snapshot.hasError) {
                          return _buildStatsCard(
                            svgPath: 'assets/icons/svg/dollar.svg',
                            label: 'Total Earned',
                            value: 'Err',
                            gradientColors: [
                              Colors.white.withOpacity(0),
                              const Color(0xFF2C63FD).withOpacity(0.4),
                              const Color(0xFF2C63FD),
                            ],
                            onTap: () {},
                          );
                        }

                        final data =
                            snapshot.data?.data() as Map<String, dynamic>?;
                        final numValue = data?['stats']?['totalEarned'] as num?;
                        final intValue = numValue?.toInt() ?? 0;
                        final totalEarned = _formatNumber(intValue);
                        return _buildStatsCard(
                          svgPath: 'assets/icons/svg/dollar.svg',
                          label: 'Total Earned',
                          value: '\$${totalEarned}',
                          gradientColors: [
                            Colors.white.withOpacity(0),
                            const Color(0xFF2C63FD).withOpacity(0.4),
                            const Color(0xFF2C63FD),
                          ],
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Total Earned: $totalEarned'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        );
                      },
                    ),

                  FutureBuilder<int>(
                    future: FirebaseAuth.instance.currentUser != null
                        ? _countCompletedMonths(
                            FirebaseAuth.instance.currentUser!.uid,
                          )
                        : Future.value(0),
                    builder: (context, snapshot) {
                      String displayValue = '--';
                      int count = 0;

                      if (snapshot.connectionState == ConnectionState.done) {
                        count = snapshot.data ?? 0;
                        displayValue = '${count}m';
                      }

                      return _buildStatsCard(
                        svgPath: 'assets/icons/svg/goal.svg',
                        label: 'Goal Completed',
                        value: displayValue,
                        gradientColors: [
                          Colors.white.withOpacity(0),
                          const Color(0xFF6628EA).withOpacity(0.4),
                          const Color(0xFF6628EA),
                        ],
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'You’ve fully completed $count month(s)!',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),

              SizedBox(height: 16.h),

              // Quick Action Section
              Text(
                'Quick Action',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary.withOpacity(0.8),
                ),
              ),

              SizedBox(height: 16.h),

              // Roadmap Cards
              _buildRoadmapCard(
                title: 'View Roadmap',
                subtitle: 'The Blue Leaf Roadmap to Get Success',
                svgPath: 'assets/icons/svg/card-two.svg',
                color: AppColors.lightBlue40.withOpacity(0.25),
                textColor: AppColors.timelinePrimary,
                onTap: () {
                  // Use provider to switch to Roadmap tab (index 2)
                  context.read<NavigationProvider>().setTab(2);
                },
              ),
              SizedBox(height: 8.h),
              _buildRoadmapCard(
                title: 'Build Brand',
                subtitle: 'Build your brand step by step',
                svgPath: 'assets/icons/svg/card-one.svg',
                color: AppColors.lightPurple40.withOpacity(0.25),
                textColor: AppColors.brand500,
                onTap: () {
                  context.push('/build-brand');
                },
              ),
              SizedBox(height: 8.h),
              _buildRoadmapCard(
                title: 'View Daily Task',
                subtitle: 'Track your daily activities and monthly goals',
                svgPath: 'assets/icons/svg/card-three.svg',
                color: AppColors.lightPink33.withOpacity(0.2),
                textColor: AppColors.brightPurple,
                onTap: () {
                  context.read<NavigationProvider>().setTab(3);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard({
    required String svgPath,
    required String label,
    required String value,
    required List<Color> gradientColors,
    List<double>? gradientStops,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12.r), // match card's radius
      onTap: onTap,
      child: Container(
        width: 109.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: RadialGradient(
            center: const Alignment(-0.9, 0.9), // bottom-left glow
            radius: 2.5,
            colors: gradientColors,
            stops: gradientStops ?? const [0.0, 0.3, 1.0],
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      svgPath,
                      width: 24.w,
                      height: 24.h,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoadmapCard({
    required String title,
    required String subtitle,
    required String svgPath, // path of your SVG asset
    required Color color,
    required Color textColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 24.w),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 4.h),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 200.w),
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(),

            SvgPicture.asset(
              svgPath,
              width: 80.w,
              height: 80.h,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}

// Main app wrapper with ScreenUtil initialization
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Home Screen',
          theme: ThemeData(primarySwatch: Colors.green, fontFamily: 'Roboto'),
          home: child,
        );
      },
      child: const HomeScreen(),
    );
  }
}
