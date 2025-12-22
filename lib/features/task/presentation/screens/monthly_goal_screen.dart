import 'package:blue_leaf_guide/shared/widgets/month_year_picker_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/button.dart';
import '../../../../shared/widgets/custom_dialog.dart';
import '../../../../shared/widgets/text_field.dart' as CustomTextField;
import '../widgets/edit_goal_dialog.dart';
import '../widgets/monthly_goals_list.dart';

class MonthlyGoalScreen extends StatefulWidget {
  const MonthlyGoalScreen({super.key});

  @override
  State<MonthlyGoalScreen> createState() => _MonthlyGoalScreenState();
}

class _MonthlyGoalScreenState extends State<MonthlyGoalScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DateTime _selectedDate = DateTime.now();
  bool _isAllYear = false;
  List<Map<String, dynamic>> _goalTemplates = [];
  bool _isLoadingTemplates = true;

  @override
  void initState() {
    super.initState();
    _loadGoalTemplates();
  }

  final Map<int, String> orderSuffixMap = {
    1: 'distributed',
    2: 'acquired',
    3: 'earned',
    4: 'posted',
    5: 'attended',
  };

  final GlobalKey _goalTemplateKey = GlobalKey();

  void _showGoalTemplateMenu(Function(String) onSelected) {
    final overlayScrollController = ScrollController();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final menuWidth = 240.w;
    final menuHeight = 250.h;

    // Calculate centered position
    double leftPosition = (screenWidth - menuWidth) / 2;
    double topPosition = (screenHeight - menuHeight) / 2;

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
              top: topPosition,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: menuWidth,
                  constraints: BoxConstraints(maxHeight: menuHeight),
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
                          children: List.generate(_goalTemplates.length, (
                            index,
                          ) {
                            final template = _goalTemplates[index];
                            final isLast = index == _goalTemplates.length - 1;

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () {
                                    overlayEntry?.remove();
                                    onSelected(template['id'] as String);
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 12.h,
                                    ),
                                    child: Row(
                                      children: [
                                        SvgPicture.asset(
                                          'assets/icons/svg/goal-picker.svg',
                                          width: 16.w,
                                          height: 16.h,
                                        ),
                                        SizedBox(width: 12.w),
                                        Expanded(
                                          child: Text(
                                            template['fullTitle'] as String,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14.sp,
                                              color: AppColors.textPrimary
                                                  .withOpacity(0.8),
                                            ),
                                          ),
                                        ),
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

  String _getMonthKey(DateTime date) {
    return DateFormat('yyyy-MM').format(date);
  }

  Future<void> _loadGoalTemplates() async {
    try {
      final templatesSnapshot = await _firestore
          .collection('goal_templates')
          .orderBy('order')
          .get();

      _goalTemplates = templatesSnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'fullTitle': doc.data()['fullTitle'] ?? '',
          'shortTitle': doc.data()['shortTitle'] ?? '',
          'order': doc.data()['order'] ?? 0, // ADD THIS LINE
        };
      }).toList();

      setState(() => _isLoadingTemplates = false);
    } catch (e) {
      print('Error loading goal templates: $e');
      setState(() => _isLoadingTemplates = false);
    }
  }

  Future<void> _showAddGoalDialog() async {
    if (_isLoadingTemplates) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading goal templates...')),
      );
      return;
    }

    if (!_isAllYear) {
      final now = DateTime.now();
      final currentMonthKey = _getMonthKey(now);
      final selectedMonthKey = _getMonthKey(_selectedDate);

      if (selectedMonthKey.compareTo(currentMonthKey) < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Oops! Goals can’t be set for past dates. Try setting one for today.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }
    }

    String? selectedTemplateId;
    final targetController = TextEditingController();

    await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 16.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// Title
                Text(
                  'Add New Goal',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  'Type Goal Name and Number of Target',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary.withOpacity(0.7),
                  ),
                ),

                SizedBox(height: 12.h),

                GestureDetector(
                  onTap: () {
                    _showGoalTemplateMenu((templateId) {
                      setDialogState(() {
                        selectedTemplateId = templateId;
                      });
                    });
                  },
                  child: Container(
                    key: _goalTemplateKey,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100.r),
                      border: Border.all(
                        color: AppColors.neutral50.withOpacity(0.05),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 14.h,
                    ),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/svg/goal-picker.svg',
                          width: 20.w,
                          height: 20.h,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            selectedTemplateId == null
                                ? 'Goal Name'
                                : _goalTemplates.firstWhere(
                                        (t) => t['id'] == selectedTemplateId,
                                        orElse: () => {
                                          'fullTitle': 'Goal Name',
                                        },
                                      )['fullTitle']
                                      as String,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: selectedTemplateId == null
                                  ? AppColors.textPrimary.withOpacity(0.3)
                                  : AppColors.textPrimary.withOpacity(0.8),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 20.sp,
                          color: AppColors.textPrimary.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 12.h),

                /// Target Number Field
                CustomTextField.TextField(
                  controller: targetController,
                  label: '',
                  hint: 'Monthly target',
                  keyboardType: TextInputType.number,
                  prefixIconSvg: 'assets/icons/svg/target.svg',
                ),
                SizedBox(height: 24.h),

                /// Save Button
                Button(
                  onPressed: () async {
                    if (selectedTemplateId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please select a goal',
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: AppColors.danger,
                        ),
                      );
                      return;
                    }

                    final target = int.tryParse(targetController.text);
                    if (target == null || target <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter a valid target number',
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: AppColors.danger,
                        ),
                      );
                      return;
                    }

                    Navigator.pop(context, true);
                    await _addGoal(selectedTemplateId!, target);
                  },
                  text: 'Save',
                  height: 54.h,
                  borderRadius: BorderRadius.circular(32.r),
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  textColor: Colors.white,
                  backgroundColor: AppColors.brand500,
                ),
                SizedBox(height: 12.h),

                /// Cancel Button
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.textPrimary.withOpacity(0.5),
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addGoal(String templateId, int target) async {
    if (_auth.currentUser == null) return;

    try {
      final userId = _auth.currentUser!.uid;
      final monthKey = _getMonthKey(_selectedDate);

      final template = _goalTemplates.firstWhere((t) => t['id'] == templateId);

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('monthly_goals')
          .add({
            'templateId': templateId,
            'fullTitle': template['fullTitle'],
            'shortTitle': template['shortTitle'],
            'order': template['order'], // ADD THIS LINE
            'targetNumber': target,
            'currentProgress': 0,
            'month': monthKey,
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Goal added successfully!',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.timelinePrimary,
        ),
      );
    } catch (e) {
      print('Error adding goal: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to add goal: $e',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.danger,
        ),
      );
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

  void _showMonthYearPicker() async {
    final now = DateTime.now();

    final result = await showDialog<PickerResult>(
      context: context,
      builder: (context) => MonthYearPickerDialog(
        initialDate: _selectedDate,
        maxYear: now.year,
        maxMonth: now.month,
      ),
    );

    if (result != null) {
      setState(() {
        _isAllYear = result.year == -1;
        _selectedDate = DateTime(result.year, result.month ?? 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_auth.currentUser == null) {
      return const Center(child: Text('Please log in to view goals'));
    }

    final userId = _auth.currentUser!.uid;
    // If all year, send special key? Or modify MonthlyGoalsList?
    // Let's use "ALL" as key if all year.
    final monthKey = _isAllYear ? "ALL" : _getMonthKey(_selectedDate!);

    return Column(
      children: [
        // Header with date and filter
        Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isAllYear
                        ? "All Goals"
                        : DateFormat('MMMM, yyyy').format(_selectedDate!),
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _showMonthYearPicker,
                child: Container(
                  width: 45.w,
                  height: 45.h,
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(100.r),
                  ),
                  padding: EdgeInsets.all(10.w),
                  child: SvgPicture.asset(
                    // Removed const
                    'assets/icons/svg/filter.svg',
                    width: 24.w,
                    height: 24.w,
                    colorFilter: ColorFilter.mode(
                      AppColors.textPrimary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Reusable goals list
        Expanded(
          child: MonthlyGoalsList(
            userId: userId,
            monthKey: monthKey,
            onAddGoal: _showAddGoalDialog,
            onEditGoal: (goalId, title, target) async {
              await _showEditGoalDialog(goalId, title, target);
            },
            onDeleteGoal: _deleteGoal,
            orderSuffixMap: orderSuffixMap,
          ),
        ),

        // Add Goal Button
        Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 16.h,
          ),
          child: Button(
            onPressed: _showAddGoalDialog,
            text: 'Add New Goal',
            height: 54.h,
            borderRadius: BorderRadius.circular(32.r),
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            textColor: Colors.white,
            backgroundColor: AppColors.brand500,
          ),
        ),
      ],
    );
  }
}
