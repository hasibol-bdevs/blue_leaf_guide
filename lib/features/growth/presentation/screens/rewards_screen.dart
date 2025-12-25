import 'package:blue_leaf_guide/shared/widgets/custom_appbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/custom_dialog.dart';
import '../../../task/presentation/widgets/edit_goal_dialog.dart';
import '../../../task/presentation/widgets/monthly_goals_list.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({Key? key}) : super(key: key);

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _selectedTaskYear = DateTime.now().year;
  int _selectedTaskMonth = DateTime.now().month;

  final Map<int, String> orderSuffixMap = {
    1: 'distributed',
    2: 'acquired',
    3: 'earned',
    4: 'posted',
    5: 'attended',
  };

  DateTime _selectedDate = DateTime.now();

  // Add these new state variables at the top of _RewardsScreenState class
  int _selectedYear = DateTime.now().year;
  bool _isLoadingChartData = false;
  List<double> _chartValues = List.filled(12, 0.0);

  // Cache the brand build future to prevent flickering
  late Future<bool> _brandBuildFuture;
  late Future<int> _completedMonthsFuture;

  @override
  void initState() {
    super.initState(); // Always call super.initState() first or last.
    _selectedTaskMonth = DateTime.now().month;
    _selectedTaskYear = DateTime.now().year;
    _fetchYearlyChartData();

    // Initialize cached futures
    _brandBuildFuture = _isBrandBuildCompleted();
    _completedMonthsFuture = FirebaseAuth.instance.currentUser != null
        ? _countCompletedMonths(FirebaseAuth.instance.currentUser!.uid)
        : Future.value(0);
  }

  // Add Keys for anchoring menus
  final GlobalKey _taskYearKey = GlobalKey();
  final GlobalKey _taskMonthKey = GlobalKey();

  // Helper method to show inline custom menu
  void _showInlineMenu({
    required GlobalKey key,
    required List<Map<String, dynamic>> items,
    required Function(dynamic value) onSelected,
    double? width,
  }) {
    final overlayScrollController = ScrollController();
    final RenderBox renderBox =
        key.currentContext?.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final screenWidth = MediaQuery.of(context).size.width;
    final menuWidth = width ?? 140.w;

    // Calculate left position
    double leftPosition = offset.dx;
    if (leftPosition + menuWidth > screenWidth - 16.w) {
      leftPosition = screenWidth - menuWidth - 16.w;
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final estimatedMenuHeight = 250.h; // This matches your maxHeight constraint
    // 2. Check if there is enough space below. If not, show it ABOVE the button.
    bool showAbove = (offset.dy + size.height + estimatedMenuHeight) > screenHeight - 16.h;
    double topPosition = showAbove
    ? offset.dy - estimatedMenuHeight - 4.h // Position above
        : offset.dy + size.height + 4.h;        // Position below (original logic)
// 3. Prevent it from going off the top of the screen on very small devices
    if (topPosition < 16.h) topPosition = 16.h;
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          overlayEntry?.remove();
        },
        child: Stack(
          children: [
            Positioned.fill(child: Container(color: Colors.transparent)),
            Positioned(
              left: leftPosition,
              // top: offset.dy + size.height + 4.h,
              top: topPosition,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: menuWidth,
                  constraints: BoxConstraints(maxHeight: 250.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: Scrollbar(
                      controller: overlayScrollController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: overlayScrollController,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(items.length, (index) {
                            final item = items[index];
                            final isLast = index == items.length - 1;
                            final isSelected = item['isSelected'] as bool;
                            final isDisabled =
                                item['isDisabled'] as bool? ?? false;

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: isDisabled
                                      ? null
                                      : () {
                                          overlayEntry?.remove();
                                          onSelected(item['value']);
                                        },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 12.h,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          item['text'] as String,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14.sp,
                                            color: isDisabled
                                                ? Colors.black
                                                : AppColors.textPrimary
                                                      .withOpacity(0.8),
                                          ),
                                        ),
                                        if (isSelected)
                                          SvgPicture.asset(
                                            'assets/icons/svg/tick.svg',
                                            width: 16.w,
                                            height: 16.h,
                                          )
                                        else
                                          SizedBox(width: 16.w),
                                      ],
                                    ),
                                  ),
                                ),
                                if (!isLast)
                                  Divider(
                                    height: 1.h,
                                    thickness: 1.h,
                                    color: AppColors.textPrimary.withOpacity(
                                      0.05,
                                    ),
                                    indent: 0,
                                    endIndent: 0,
                                  ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
  }

  void _showTaskMonthPicker() {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final items = [
      {'text': 'Select', 'value': 0, 'isSelected': false, 'isDisabled': true},
      ...List.generate(months.length, (index) {
        return {
          'text': months[index],
          'value': index + 1,
          'isSelected': (index + 1) == _selectedTaskMonth,
          'isDisabled': false,
        };
      }),
    ];

    _showInlineMenu(
      key: _taskMonthKey,
      items: items,
      width: 160.w,
      onSelected: (value) {
        if (value != _selectedTaskMonth) {
          setState(() {
            _selectedTaskMonth = value as int;
            _selectedDate = DateTime(_selectedTaskYear, _selectedTaskMonth, 1);
          });
        }
      },
    );
  }

  void _showTaskYearPicker() {
    final currentYear = DateTime.now().year;
    final years = List.generate(10, (index) => currentYear - index);

    final List<Map<String, dynamic>> items = [
      {'text': 'All Year', 'value': -1, 'isSelected': _selectedTaskYear == -1},
      ...years.map(
        (year) => {
          'text': year.toString(),
          'value': year,
          'isSelected': year == _selectedTaskYear,
        },
      ),
    ];

    _showInlineMenu(
      key: _taskYearKey,
      items: items,
      width: 140.w,
      onSelected: (value) {
        if (value != _selectedTaskYear) {
          setState(() {
            _selectedTaskYear = value as int;
            if (_selectedTaskYear != -1) {
              _selectedDate = DateTime(
                _selectedTaskYear,
                _selectedTaskMonth,
                1,
              );
            }
          });
        }
      },
    );
  }

  // Add this method to fetch chart data
  Future<void> _fetchYearlyChartData() async {
    if (_auth.currentUser == null) return;

    setState(() => _isLoadingChartData = true);

    try {
      final userId = _auth.currentUser!.uid;

      // Initialize monthly completion rates (12 months)
      List<double> monthlyRates = List.filled(12, 0.0);

      // Fetch all active goals for the selected year
      for (int month = 1; month <= 12; month++) {
        final monthKey = '${_selectedYear}-${month.toString().padLeft(2, '0')}';

        final goalsSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('monthly_goals')
            .where('month', isEqualTo: monthKey)
            .where('isActive', isEqualTo: true)
            .get();

        if (goalsSnapshot.docs.isEmpty) {
          monthlyRates[month - 1] = 0.0;
          continue;
        }

        int totalGoals = 0;
        int completedGoals = 0;

        for (final doc in goalsSnapshot.docs) {
          final data = doc.data();
          final int target = (data['targetNumber'] as num?)?.toInt() ?? 0;
          final int progress = (data['currentProgress'] as num?)?.toInt() ?? 0;

          if (target > 0) {
            totalGoals++;
            if (progress >= target) {
              completedGoals++;
            }
          }
        }

        if (totalGoals > 0) {
          monthlyRates[month - 1] = completedGoals / totalGoals;
        } else {
          monthlyRates[month - 1] = 0.0;
        }
      }

      setState(() {
        _chartValues = monthlyRates;
      });
    } catch (e) {
      print('Error fetching chart data: $e');
    } finally {
      setState(() => _isLoadingChartData = false);
    }
  }

  // Add Key for anchoring year picker menu
  final GlobalKey _chartYearKey = GlobalKey();

  // Add this method to show year picker dialog
  void _showYearPicker() {
    final currentYear = DateTime.now().year;
    final years = List.generate(10, (index) => currentYear - index);

    final List<Map<String, dynamic>> items = years.map((year) {
      return {
        'text': year.toString(),
        'value': year,
        'isSelected': year == _selectedYear,
      };
    }).toList();

    _showInlineMenu(
      key: _chartYearKey,
      items: items,
      width: 140.w,
      onSelected: (value) async {
        if (value != _selectedYear) {
          setState(() {
            _selectedYear = value as int;
          });
          await _fetchYearlyChartData();
        }
      },
    );
  }

  Future<bool> _isBrandBuildCompleted() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final uid = user.uid;
    final db = FirebaseFirestore.instance;

    try {
      int completedCount = 0;
      int totalCount = 25; // 5 + 4 + 6 + 10

      // === Strategy (5) ===
      final strategyDoc = await db
          .collection('users')
          .doc(uid)
          .collection('strategy')
          .doc('items')
          .get();
      if (strategyDoc.exists && strategyDoc.data() != null) {
        final data = strategyDoc.data()!;
        final List<dynamic>? items = data['items'];
        if (items != null) {
          completedCount += items
              .where((item) => (item as Map)['isCompleted'] == true)
              .length;
        }
      }

      // === Visual (4) ===
      final visualDoc = await db
          .collection('users')
          .doc(uid)
          .collection('visual')
          .doc('items')
          .get();
      if (visualDoc.exists && visualDoc.data() != null) {
        final data = visualDoc.data()!;
        final List<dynamic>? items = data['items'];
        if (items != null) {
          completedCount += items
              .where((item) => (item as Map)['isCompleted'] == true)
              .length;
        }
      }

      // === Marketing (6) ===
      final marketingDoc = await db
          .collection('users')
          .doc(uid)
          .collection('marketing')
          .doc('items')
          .get();
      if (marketingDoc.exists && marketingDoc.data() != null) {
        final data = marketingDoc.data()!;
        final List<dynamic>? items = data['items'];
        if (items != null) {
          completedCount += items
              .where((item) => (item as Map)['isCompleted'] == true)
              .length;
        }
      }

      // === Planning (10) ===
      final planningDoc = await db
          .collection('users')
          .doc(uid)
          .collection('planning')
          .doc('data')
          .get();
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

      return completedCount == totalCount;
    } catch (e) {
      print('Error checking brand build completion: $e');
      return false;
    }
  }

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

  Future<void> _showEditGoalDialog(
    String goalId,
    String currentTitle,
    int currentTarget,
  ) async {
    await EditGoalDialog.show(
      context: context,
      currentTitle: currentTitle,
      currentTarget: currentTarget,
      onSave: (newTarget) async {
        await _updateGoal(goalId, newTarget);
      },
    );
  }

  Future<void> _updateGoal(String goalId, int newTarget) async {
    if (_auth.currentUser == null) return;

    try {
      final userId = _auth.currentUser!.uid;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('monthly_goals')
          .doc(goalId)
          .update({
            'targetNumber': newTarget,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Goal updated successfully!',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.timelinePrimary,
        ),
      );
    } catch (e) {
      print('Error updating goal: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update goal: $e',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _deleteGoal(String goalId) async {
    if (_auth.currentUser == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => CustomDialog(
        title: 'Delete Goal',
        subtitle: 'Are you sure you want to delete this goal?',
        primaryButtonText: 'Delete',
        primaryButtonOnPressed: () => Navigator.pop(context, true),
        secondaryButtonText: 'Cancel',
        secondaryButtonOnPressed: () => Navigator.pop(context, false),
      ),
    );

    if (confirm != true) return;

    try {
      final userId = _auth.currentUser!.uid;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('monthly_goals')
          .doc(goalId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Goal deleted successfully!',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.timelinePrimary,
        ),
      );
    } catch (e) {
      print('Error deleting goal: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete goal: $e',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  String _getMonthKey(DateTime date) {
    return DateFormat('yyyy-MM').format(date);
  }

  // ignore: unused_element
  // void _showMonthYearPicker() async {
  //   final result = await showDialog<PickerResult>(
  //     context: context,
  //     builder: (context) => MonthYearPickerDialog(initialDate: _selectedDate),
  //   );

  //   if (result != null) {
  //     setState(() {
  //       // If "All Year" (-1), let's just default to now or ignore for this unused method.
  //       if (result.year != -1 && result.month != null) {
  //         _selectedDate = DateTime(result.year, result.month!);
  //       }
  //     });
  //   }
  // }

  double _calculateAverage(List<double> values) {
    final validValues = values.where((v) => v >= 0).toList();
    if (validValues.isEmpty) return 0.0;
    final sum = validValues.reduce((a, b) => a + b);
    return sum / validValues.length;
  }

  String _formatPercentage(double value) {
    // Clamp between 0 and 1 for safety
    final clamped = value.clamp(0.0, 1.0);
    // Convert to percentage with 1 decimal: 0.583 → "58.3%"
    return '${(clamped * 100).toStringAsFixed(1)}%';
  }


  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser!.uid;
    final monthKey = _selectedTaskYear == -1
        ? "ALL"
        : _getMonthKey(_selectedDate);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(title: 'Progress & Rewards'),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16.h),
            // Stats Cards Grid
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      svgPath: 'assets/icons/svg/fire.svg',
                      title: 'Current Streak',
                      value: '0 days',
                      backgroundColor: AppColors.backgroundLight,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: FutureBuilder(
                      future: _completedMonthsFuture,
                      builder: (context, snapshot) {
                        bool isLoading =
                            snapshot.connectionState != ConnectionState.done;
                        int count = 0;

                        if (snapshot.connectionState == ConnectionState.done) {
                          count = snapshot.data ?? 0;
                        }

                        return _buildStatCard(
                          svgPath: 'assets/icons/svg/stats-target.svg',
                          title: 'Goal Completed',
                          value: isLoading ? '' : '${count} months',
                          isLoading: isLoading,
                          backgroundColor: AppColors.brand50,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  Expanded(
                    child: FutureBuilder<bool>(
                      future: _brandBuildFuture,
                      builder: (context, snapshot) {
                        bool isCompleted = false;
                        bool isLoading =
                            snapshot.connectionState != ConnectionState.done;

                        if (snapshot.connectionState == ConnectionState.done) {
                          isCompleted = snapshot.data ?? false;
                        }

                        return _buildStatCard(
                          svgPath: 'assets/icons/svg/stats-check.svg',
                          title: 'Brand Build',
                          value: isLoading
                              ? ''
                              : (isCompleted ? 'Completed' : 'None'),
                          isLoading: isLoading,
                          backgroundColor: isLoading
                              ? AppColors.backgroundLight
                              : (isCompleted
                                    ? AppColors.backgroundGreenLight
                                    : AppColors.backgroundLight),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseAuth.instance.currentUser != null
                          ? FirebaseFirestore.instance
                                .collection('users')
                                .doc(FirebaseAuth.instance.currentUser!.uid)
                                .snapshots()
                          : const Stream.empty(),
                      builder: (context, snapshot) {
                        String clientServed = '0';

                        if (snapshot.hasData && snapshot.data!.exists) {
                          final data =
                              snapshot.data!.data() as Map<String, dynamic>?;
                          final numValue =
                              data?['stats']?['totalAcquired'] as num?;
                          clientServed = numValue?.toString() ?? '0';
                        } else if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          clientServed = '--';
                        }

                        return _buildStatCard(
                          svgPath: 'assets/icons/svg/stats-user.svg',
                          title: 'Client Served',
                          value: clientServed,
                          backgroundColor: AppColors.backgroundPurpleLight,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 27.h),
            // Goal Completion Rate Section
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              padding: EdgeInsets.all(0.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Goal completion rate',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      GestureDetector(
                        onTap: _showYearPicker,
                        child: Container(
                          key: _chartYearKey,
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 9.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: AppColors.textPrimary.withOpacity(0.05),
                            ),
                            borderRadius: BorderRadius.circular(100.r),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _selectedYear.toString(),
                                style: TextStyle(
                                  color: AppColors.textPrimary.withOpacity(0.8),
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Icon(
                                Icons.keyboard_arrow_down,
                                size: 16.sp,
                                color: Colors.black,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  SizedBox(height: 20.h),
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: const Color(
                          0x090F050D,
                        ), // your neutral 5% opacity border
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'Average goal completion rate',
                                style: TextStyle(
                                  color: AppColors.textPrimary.withOpacity(0.7),
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              _isLoadingChartData
                                  ? const CircularProgressIndicator()
                                  : Text(
                                      _formatPercentage(
                                        _calculateAverage(_chartValues),
                                      ),
                                      style: TextStyle(
                                        color: AppColors.textPrimary
                                            .withOpacity(0.8),
                                        fontSize: 20.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24.h),
                        _buildBarChart(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 27.h),
            // Task Completion Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Task completion',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _showTaskYearPicker,

                        child: _buildDropdown(
                          key: _taskYearKey,
                          _selectedTaskYear == -1
                              ? "All Year"
                              : _selectedTaskYear.toString(),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      IgnorePointer(
                        ignoring: _selectedTaskYear == -1,
                        child: GestureDetector(
                          onTap: _showTaskMonthPicker,
                          child: _buildDropdown(
                            key: _taskMonthKey,
                            isDisabled: _selectedTaskYear == -1,
                            _selectedTaskYear == -1
                                ? "Select"
                                : DateFormat('MMMM').format(
                                    DateTime(
                                      _selectedTaskYear,
                                      _selectedTaskMonth,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: MonthlyGoalsList(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                userId: userId,
                monthKey: monthKey,
                onAddGoal: () {},
                onEditGoal: (goalId, title, target) async {
                  await _showEditGoalDialog(goalId, title, target);
                },
                onDeleteGoal: _deleteGoal,
                orderSuffixMap: orderSuffixMap,
              ),
            ),
            SizedBox(height: 80.h),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String svgPath,
    required String title,
    required String value,
    required Color backgroundColor,
    Color? iconColor,
    bool isLoading = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          if (iconColor != null)
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: iconColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  svgPath,
                  width: 20.w,
                  height: 20.w,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            )
          else
            SvgPicture.asset(svgPath, width: 40.w, height: 40.w),
          SizedBox(height: 12.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary.withOpacity(0.7),
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          if (isLoading)
            SizedBox(
              width: 20.w,
              height: 20.w,
              child: CircularProgressIndicator(
                strokeWidth: 2.w,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.textPrimary.withOpacity(0.5),
                ),
              ),
            )
          else
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary.withOpacity(0.8),
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    if (_isLoadingChartData) {
      return SizedBox(
        height: 180.h,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return SizedBox(
      height: 200.h, // Increased height to accommodate rotated text
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Y-axis labels
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildAxisLabel('100%'),
              _buildAxisLabel('75%'),
              _buildAxisLabel('50%'),
              _buildAxisLabel('25%'),
              _buildAxisLabel('0%'),
            ],
          ),
          SizedBox(width: 6.w),
          // Bars
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(months.length, (index) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 16.w,
                          height: 150.h * _chartValues[index],
                          decoration: BoxDecoration(color: AppColors.brand500),
                        ),
                        SizedBox(height: 8.h),
                        Transform.rotate(
                          angle: -1.2217,
                          child: Text(
                            months[index],
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAxisLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: Colors.grey[600],
        fontSize: 11.sp,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _buildDropdown(String text, {Key? key, bool isDisabled = false}) {
    return Container(
      key: key,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: isDisabled
              ? AppColors.textPrimary.withOpacity(0.05) // 10% opacity border
              : AppColors.textPrimary.withOpacity(0.05),
        ),
        borderRadius: BorderRadius.circular(100.r),
      ),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              color: isDisabled
                  ? AppColors.textPrimary.withOpacity(0.1) // 10% opacity text
                  : AppColors.textPrimary.withOpacity(0.8),
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 4.w),
          Icon(
            Icons.keyboard_arrow_down,
            size: 16.sp,
            color: isDisabled
                ? AppColors.textPrimary.withOpacity(0.1) // 10% opacity icon
                : Colors.black,
          ),
        ],
      ),
    );
  }
}
