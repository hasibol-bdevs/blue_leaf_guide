import 'package:blue_leaf_guide/shared/widgets/custom_appbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/widgets/button.dart';
import '../../../../shared/widgets/custom_checkbox.dart';
import '../../../../shared/widgets/profile_list_item.dart';
import '../../data/marketing_service.dart';
import '../../data/planning_service.dart';
import '../../data/strategy_service.dart';
import '../../data/visual_service.dart';
import '../../models/marketing_item.dart';
import '../../models/strategy_item.dart';
import '../../models/visual_item.dart';
import '../widgets/custom_stepper.dart';

class StepData {
  final String title;
  final List<String> items;

  StepData({required this.title, required this.items});
}

class BuildBrandScreen extends StatefulWidget {
  const BuildBrandScreen({super.key});

  @override
  State<BuildBrandScreen> createState() => _BuildBrandScreenState();
}

class _BuildBrandScreenState extends State<BuildBrandScreen> {
  int currentStep = 1;
  final StrategyService _strategyService = StrategyService();
  final MarketingService _marketingService = MarketingService();
  final PlanningService _planningService = PlanningService();
  final NotificationService _notificationService = NotificationService();

  List<StrategyItem> strategyItems = [];
  List<MarketingItem> marketingItems = [];
  final VisualService _visualService = VisualService();
  List<VisualItem> visualItems = [];

  // Planning data
  List<bool> planningMonth1 = [false, false, false];
  List<bool> planningMonth2 = [false, false, false];
  List<bool> planningMonth3 = [false, false, false, false];

  bool _isLoading = true;

  final List<StepData> stepData = [
    StepData(
      title: "Strategy",
      items: [
        "Branding Basics",
        "Vision & Mission",
        "Target Audience",
        "Brand Personality",
        "Brand Story",
      ],
    ),
    StepData(
      title: "Visual",
      items: ["Business Name", "Color Palette", "Logo Design", "Business Card"],
    ),
    StepData(
      title: "Marketing",
      items: [
        "Marketing Collateral",
        "Email Marketing",
        "Social Media Marketing",
        "Website",
        "SEO & Content Strategy",
        "Offline Marketing & Social Impact",
      ],
    ),
    StepData(title: "Planning", items: []),
  ];

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _maybeAdvanceStep() async {
    if (!mounted) return;

    if (currentStep == 1) {
      final allDone =
          strategyItems.isNotEmpty && strategyItems.every((s) => s.isCompleted);
      if (allDone && currentStep < stepData.length) {
        setState(() => currentStep = 2);
      }
    } else if (currentStep == 2) {
      final allDone =
          visualItems.isNotEmpty && visualItems.every((v) => v.isCompleted);
      if (allDone && currentStep < stepData.length) {
        setState(() => currentStep = 3);
      }
    } else if (currentStep == 3) {
      final allDone =
          marketingItems.isNotEmpty &&
          marketingItems.every((m) => m.isCompleted);
      if (allDone && currentStep < stepData.length) {
        setState(() => currentStep = 4);
      }
    }
  }

  bool get hasAnyCheckboxSelected {
    return planningMonth1.any((e) => e) ||
        planningMonth2.any((e) => e) ||
        planningMonth3.any((e) => e);
  }

  Future<void> _checkAndTriggerCompletionNotification() async {
    // Check if ALL 4 steps are completed
    if (_isStepCompleted(1) &&
        _isStepCompleted(2) &&
        _isStepCompleted(3) &&
        _isStepCompleted(4)) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        // Check if notification was already sent
        final prefs = await SharedPreferences.getInstance();
        final notificationSent =
            prefs.getBool('build_brand_notification_sent') ?? false;

        if (!notificationSent) {
          await _notificationService.showBuildBrandCompleteNotification(userId);
          // Mark as sent so it doesn't show again
          await prefs.setBool('build_brand_notification_sent', true);
        }
      }
    }
  }

  Future<void> _loadData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final strategy = await _strategyService.getUserStrategyItems(userId);
      final marketing = await _marketingService.getUserMarketingItems(userId);
      final visual = await _visualService.getUserVisualItems(userId);
      final planning = await _planningService.getPlanningData(userId);

      setState(() {
        strategyItems = strategy;
        marketingItems = marketing;
        visualItems = visual;
        planningMonth1 = planning['month1'] ?? [false, false, false];
        planningMonth2 = planning['month2'] ?? [false, false, false];
        planningMonth3 = planning['month3'] ?? [false, false, false, false];
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  bool _isStepCompleted(int stepNumber) {
    // Step numbers are 1-based
    switch (stepNumber) {
      case 1: // Strategy
        return strategyItems.isNotEmpty &&
            strategyItems.every((item) => item.isCompleted);
      case 2: // Visual
        return visualItems.isNotEmpty &&
            visualItems.every((item) => item.isCompleted);
      case 3: // Marketing
        return marketingItems.isNotEmpty &&
            marketingItems.every((item) => item.isCompleted);
      case 4: // Planning - check if all checkboxes are completed
        return _planningService.isAllCheckboxesCompleted(
          planningMonth1,
          planningMonth2,
          planningMonth3,
        );
      default:
        return false;
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
            'month1': planningMonth1,
            'month2': planningMonth2,
            'month3': planningMonth3,
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

      // Check if all steps are now completed and trigger notification
      await _checkAndTriggerCompletionNotification();
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
    final List<String> currentItems = stepData[currentStep - 1].items;

    if (_isLoading) {
      return Scaffold(
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
            Padding(
              padding: EdgeInsets.only(left: 12.w, right: 20.w),
              child: CustomStepper(
                currentStep: currentStep,
                totalSteps: stepData.length,
                titles: stepData.map((d) => d.title).toList(),
                completedSteps: [
                  _isStepCompleted(1),
                  _isStepCompleted(2),
                  _isStepCompleted(3),
                  _isStepCompleted(4),
                ],
                onStepTap: (stepNumber) {
                  // If tapping on current step, do nothing
                  if (stepNumber == currentStep) {
                    return;
                  }

                  // Allow going back to any previous step
                  if (stepNumber < currentStep) {
                    setState(() {
                      currentStep = stepNumber;
                    });
                    return;
                  }

                  // Going forward: check if all steps up to target are completed
                  bool canNavigate = true;
                  for (int i = currentStep; i < stepNumber; i++) {
                    if (!_isStepCompleted(i)) {
                      canNavigate = false;
                      break;
                    }
                  }

                  if (canNavigate) {
                    setState(() {
                      currentStep = stepNumber;
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please complete all previous steps first.',
                          style: TextStyle(color: Colors.white),
                        ),
                        duration: Duration(seconds: 2),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                  }
                },
              ),
            ),
            SizedBox(height: 32.h),
            Expanded(
              child: currentStep == 4
                  ? ListView(
                      children: [
                        _buildCheckboxSection(
                          '1st Month Plan',
                          month1Items,
                          planningMonth1,
                          (index, value) {
                            setState(() {
                              planningMonth1[index] = value;
                            });
                          },
                        ),
                        _buildCheckboxSection(
                          '2nd Month Plan',
                          month2Items,
                          planningMonth2,
                          (index, value) {
                            setState(() {
                              planningMonth2[index] = value;
                            });
                          },
                        ),
                        _buildCheckboxSection(
                          '3rd Month Plan',
                          month3Items,
                          planningMonth3,
                          (index, value) {
                            setState(() {
                              planningMonth3[index] = value;
                            });
                          },
                        ),
                      ],
                    )
                  : ListView.builder(
                      itemCount: currentItems.length,
                      itemBuilder: (context, index) {
                        if (currentStep == 1) {
                          // Strategy items
                          StrategyItem? item;
                          if (index < strategyItems.length) {
                            item = strategyItems[index];
                          }

                          return ProfileListItem(
                            key: ValueKey(item?.id ?? index),
                            title: currentItems[index],
                            showCheckmark: item?.isCompleted ?? false,
                            onTap: () async {
                              if (item == null) return;

                              final updatedItem = await context
                                  .push<StrategyItem>(
                                    '/strategy_item/${item.id}',
                                    extra: {
                                      'item': item,
                                      'stepTitle':
                                          stepData[currentStep - 1].title,
                                    },
                                  );

                              if (updatedItem != null && mounted) {
                                setState(() {
                                  final itemIndex = strategyItems.indexWhere(
                                    (e) => e.id == updatedItem.id,
                                  );
                                  if (itemIndex != -1) {
                                    strategyItems[itemIndex] = updatedItem;
                                  }
                                });
                              }
                            },
                          );
                        } else if (currentStep == 2) {
                          // Visual items
                          VisualItem? item;
                          if (index < visualItems.length) {
                            item = visualItems[index];
                          }

                          return ProfileListItem(
                            key: ValueKey(item?.id ?? index),
                            title: currentItems[index],
                            showCheckmark: item?.isCompleted ?? false,
                            onTap: () async {
                              if (item != null) {
                                final updatedItem = await context
                                    .push<VisualItem>(
                                      '/visual_item/${item.id}',
                                      extra: {
                                        'item': item,
                                        'stepTitle':
                                            stepData[currentStep - 1].title,
                                      },
                                    );

                                if (updatedItem != null && mounted) {
                                  setState(() {
                                    final itemIndex = visualItems.indexWhere(
                                      (e) => e.id == updatedItem.id,
                                    );
                                    if (itemIndex != -1) {
                                      visualItems[itemIndex] = updatedItem;
                                    }
                                  });
                                }
                              }
                            },
                          );
                        } else if (currentStep == 3) {
                          // Marketing items
                          MarketingItem? item;
                          if (index < marketingItems.length) {
                            item = marketingItems[index];
                          }

                          return ProfileListItem(
                            key: ValueKey(item?.id ?? index),
                            title: currentItems[index],
                            showCheckmark: item?.isCompleted ?? false,
                            onTap: () async {
                              if (item != null) {
                                final updatedItem = await context
                                    .push<MarketingItem>(
                                      '/marketing_item/${item.id}',
                                      extra: {
                                        'item': item,
                                        'stepTitle':
                                            stepData[currentStep - 1].title,
                                      },
                                    );

                                if (updatedItem != null) {
                                  setState(() {
                                    final itemIndex = marketingItems.indexWhere(
                                      (e) => e.id == updatedItem.id,
                                    );
                                    if (itemIndex != -1) {
                                      marketingItems[itemIndex] = updatedItem;
                                    }
                                  });
                                }
                              }
                            },
                          );
                        } else {
                          return ProfileListItem(
                            key: ValueKey(index),
                            title: currentItems[index],
                            showCheckmark: false,
                            onTap: () {},
                          );
                        }
                      },
                    ),
            ),
            Column(
              children: [
                Button(
                  onPressed: () {
                    if (currentStep == 4) {
                      // Save planning data
                      if (hasAnyCheckboxSelected) {
                        _savePlanningData();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please select at least one checkbox.',
                              style: TextStyle(color: Colors.white),
                            ),
                            duration: Duration(seconds: 2),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                      }
                    } else if (currentStep < stepData.length) {
                      if (!_isStepCompleted(currentStep)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please complete all items in the current step first.',
                              style: TextStyle(color: Colors.white),
                            ),
                            duration: Duration(seconds: 2),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                        return;
                      }

                      setState(() {
                        currentStep++;
                      });
                    }
                  },
                  text: currentStep == 4
                      ? 'Save'
                      : 'Next ${stepData[currentStep].title}',
                  height: 54.h,
                  borderRadius: BorderRadius.circular(32.r),
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  textColor: Colors.white,
                  backgroundColor: currentStep == 4
                      ? (hasAnyCheckboxSelected
                            ? AppColors.brand500
                            : AppColors.brand500.withOpacity(0.3))
                      : (_isStepCompleted(currentStep)
                            ? AppColors.brand500
                            : AppColors.brand500.withOpacity(0.3)),
                ),
                SizedBox(height: 12.h),
                if (currentStep < 4)
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          currentStep++;
                        });
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                      ),
                      child: Text(
                        'Skip',
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
          ],
        ),
      ),
    );
  }
}
