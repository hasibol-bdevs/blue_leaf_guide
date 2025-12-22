import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/button.dart';
import '../../../../shared/widgets/custom_appbar.dart';
import '../../../../shared/widgets/custom_checkbox.dart';
import '../widgets/custom_stepper.dart';

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  bool _isLoading = true;

  List<bool> month1Checkboxes = [false, false, false];
  List<bool> month2Checkboxes = [false, false, false];
  List<bool> month3Checkboxes = [false, false, false, false];

  final month1Items = [
    "Finalize brand strategy, logo, and colors",
    "Create business cards and collateral",
    "Set up social media accounts",
  ];

  final month2Items = [
    "Launch website and implement SEO",
    "Begin consistent content posting",
    "Launch first email campaign",
  ];

  final month3Items = [
    "Partner with influencers",
    "Plan first event or pop-up",
    "Launch charitable initiative",
    "Analyse metrics and plan next 90 days",
  ];

  // Step titles for the stepper
  final List<String> stepTitles = [
    'Strategy',
    'Visual',
    'Marketing',
    'Planning',
  ];

  @override
  void initState() {
    super.initState();
    _loadPlanningData();
  }

  bool get hasAnyCheckboxSelected {
    return month1Checkboxes.any((e) => e) ||
        month2Checkboxes.any((e) => e) ||
        month3Checkboxes.any((e) => e);
  }

  /// Check if all checkboxes in all months are completed
  bool get areAllCheckboxesCompleted {
    return month1Checkboxes.every((e) => e) &&
        month2Checkboxes.every((e) => e) &&
        month3Checkboxes.every((e) => e);
  }

  Future<void> _loadPlanningData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('planning')
          .doc('data')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          month1Checkboxes = List<bool>.from(
            data['month1'] ?? [false, false, false],
          );
          month2Checkboxes = List<bool>.from(
            data['month2'] ?? [false, false, false],
          );
          month3Checkboxes = List<bool>.from(
            data['month3'] ?? [false, false, false, false],
          );
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading planning data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePlanningData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please login to save')));
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('planning')
          .doc('data')
          .set({
            'month1': month1Checkboxes,
            'month2': month2Checkboxes,
            'month3': month3Checkboxes,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saved successfully!',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.timelinePrimary,
        ),
      );
    } catch (e) {
      print('Error saving planning data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save. Please try again.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Widget _buildCheckboxSection(
    String title,
    List<String> items,
    List<bool> checkboxes,
    Function(int, bool) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary.withOpacity(0.7),
            height: 1.4,
          ),
        ),
        SizedBox(height: 12.h),
        ...List.generate(items.length, (index) {
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Row(
              children: [
                CustomCheckbox(
                  value: checkboxes[index],
                  onChanged: (value) => onChanged(index, value),
                  activeColor: AppColors.brand500,
                  borderColor: AppColors.iceBlue,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    items[index],
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textPrimary.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        SizedBox(height: 24.h),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: CustomAppBar(title: 'Build Brand'),
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(title: 'Build Brand'),
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.only(
          left: 18.w,
          right: 16.w,
          bottom: MediaQuery.of(context).padding.bottom + 16.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 24.h),
            // Add CustomStepper
            Padding(
              padding: EdgeInsets.only(left: 12.w, right: 20.w),
              child: CustomStepper(
                currentStep: 4, // Planning is step 4
                totalSteps: 4,
                titles: stepTitles,
                completedSteps: [
                  true, // Strategy - assuming completed if user reached planning
                  true, // Visual - assuming completed if user reached planning
                  true, // Marketing - assuming completed if user reached planning
                  areAllCheckboxesCompleted, // Planning
                ],
                onStepTap: (stepNumber) {
                  // Navigate back to BuildBrandScreen if tapping on previous steps
                  if (stepNumber < 4) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
            SizedBox(height: 32.h),
            Text(
              'Planning',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 24.h),
            Expanded(
              child: ListView(
                children: [
                  _buildCheckboxSection(
                    '1st Month Plan',
                    month1Items,
                    month1Checkboxes,
                    (index, value) {
                      setState(() {
                        month1Checkboxes[index] = value;
                      });
                    },
                  ),
                  _buildCheckboxSection(
                    '2nd Month Plan',
                    month2Items,
                    month2Checkboxes,
                    (index, value) {
                      setState(() {
                        month2Checkboxes[index] = value;
                      });
                    },
                  ),
                  _buildCheckboxSection(
                    '3rd Month Plan',
                    month3Items,
                    month3Checkboxes,
                    (index, value) {
                      setState(() {
                        month3Checkboxes[index] = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Button(
                  onPressed: hasAnyCheckboxSelected
                      ? () async {
                          // At least one checkbox selected - save
                          await _savePlanningData();
                          if (mounted) {
                            Navigator.of(context).pop({
                              'month1': month1Checkboxes,
                              'month2': month2Checkboxes,
                              'month3': month3Checkboxes,
                            });
                          }
                        }
                      : null,
                  text: 'Save',
                  height: 54.h,
                  borderRadius: BorderRadius.circular(32.r),
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  textColor: Colors.white,
                  backgroundColor: hasAnyCheckboxSelected
                      ? AppColors.brand500
                      : AppColors.brand500.withOpacity(0.3),
                ),
                SizedBox(height: 12.h),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
