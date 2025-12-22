import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/widgets/button.dart';
import '../../../../shared/widgets/custom_appbar.dart';
import '../../../../shared/widgets/custom_checkbox.dart';
import '../../data/roadmap_service.dart';

class RoadmapDetailsScreen extends StatefulWidget {
  final String roadmapId;

  const RoadmapDetailsScreen({super.key, required this.roadmapId});

  @override
  State<RoadmapDetailsScreen> createState() => _RoadmapDetailsScreenState();
}

class _RoadmapDetailsScreenState extends State<RoadmapDetailsScreen> {
  final RoadmapService _roadmapService = RoadmapService();
  final NotificationService _notificationService = NotificationService();

  Map<String, dynamic>? roadmap;
  Map<String, dynamic>? progress;

  List<bool> checklistStates = [];
  Map<String, TextEditingController> reflectionControllers = {};

  bool isLoading = true;
  bool isSaving = false;

  StreamSubscription? _progressSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _listenToProgressUpdates();
  }

  void _listenToProgressUpdates() {
    if (_roadmapService.currentUserId == null) return;

    _progressSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(_roadmapService.currentUserId)
        .collection('roadmapProgress')
        .doc(widget.roadmapId)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists && mounted) {
            final data = snapshot.data()!;
            final completedChecklist = List<int>.from(
              data['completedChecklist'] ?? [],
            );

            setState(() {
              checklistStates = List.generate(
                checklistStates.length,
                (index) => completedChecklist.contains(index),
              );

              // Update reflections if needed
              final savedReflections = Map<String, String>.from(
                data['reflections'] ?? {},
              );
              reflectionControllers.forEach((label, controller) {
                controller.text = savedReflections[label] ?? '';
              });
            });
          }
        });
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    reflectionControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    final fetchedRoadmap = await _roadmapService.fetchRoadmapById(
      widget.roadmapId,
    );
    final fetchedProgress = await _roadmapService.fetchRoadmapProgress(
      widget.roadmapId,
    );

    if (fetchedRoadmap != null) {
      final actionChecklist = List<String>.from(
        fetchedRoadmap["actionChecklist"] ?? [],
      );
      final completedChecklist = List<int>.from(
        fetchedProgress?['completedChecklist'] ?? [],
      );

      // Initialize checklist states
      checklistStates = List.generate(
        actionChecklist.length,
        (index) => completedChecklist.contains(index),
      );

      // Initialize reflection controllers
      final milestoneReflection = List<Map<String, dynamic>>.from(
        fetchedRoadmap["milestoneReflection"] ?? [],
      );
      final savedReflections = Map<String, String>.from(
        fetchedProgress?['reflections'] ?? {},
      );

      for (var field in milestoneReflection) {
        final label = field["label"] as String;
        reflectionControllers[label] = TextEditingController(
          text: savedReflections[label] ?? '',
        );
      }
    }

    setState(() {
      roadmap = fetchedRoadmap;
      progress = fetchedProgress;
      isLoading = false;
    });
  }

  Future<void> _saveProgress() async {
    if (roadmap == null) return;

    setState(() => isSaving = true);

    // Get completed checklist indexes
    final completedIndexes = <int>[];
    for (int i = 0; i < checklistStates.length; i++) {
      if (checklistStates[i]) {
        completedIndexes.add(i);
      }
    }

    // Get reflections
    final reflections = <String, String>{};
    reflectionControllers.forEach((label, controller) {
      reflections[label] = controller.text.trim();
    });

    // Check if roadmap is completed (ALL checklist items checked)
    final totalItems = checklistStates.length;
    final completedItems = completedIndexes.length;
    final isCompleted = completedItems == totalItems;

    // Check if this is a NEW completion (wasn't completed before)
    final wasCompletedBefore = progress?['completed'] ?? false;
    final isNewCompletion = isCompleted && !wasCompletedBefore;

    final success = await _roadmapService.saveRoadmapProgress(
      roadmapId: widget.roadmapId,
      completedChecklist: completedIndexes,
      reflections: reflections,
      completed: isCompleted,
    );

    setState(() => isSaving = false);

    if (success) {
      // If this roadmap is newly completed, check if ALL roadmaps are now completed
      if (isNewCompletion && _roadmapService.currentUserId != null) {
        // Check if all roadmaps are completed
        await _checkAndNotifyAllRoadmapsComplete();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Progress saved successfully',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.timelinePrimary,
          ),
        );

        Navigator.of(context).pop();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to save progress',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _checkAndNotifyAllRoadmapsComplete() async {
    if (_roadmapService.currentUserId == null) return;

    try {
      // Fetch all roadmaps
      final allRoadmaps = await _roadmapService.fetchRoadmaps();

      // Fetch all user progress
      final allProgress = await _roadmapService.fetchUserProgress();

      // Check if ALL roadmaps are completed
      bool allCompleted = true;
      for (var roadmap in allRoadmaps) {
        final roadmapId = roadmap['id'] as String;
        final progress = allProgress[roadmapId];
        final completed = progress?['completed'] ?? false;

        if (!completed) {
          allCompleted = false;
          break;
        }
      }

      // If all roadmaps are completed, show notification
      if (allCompleted && allRoadmaps.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final notificationKey = 'all_roadmaps_notification';
        final notificationSent = prefs.getBool(notificationKey) ?? false;

        if (!notificationSent) {
          await _notificationService.showAllRoadmapsCompleteNotification(
            _roadmapService.currentUserId!,
          );

          // Mark as sent
          await prefs.setBool(notificationKey, true);
        }
      }
    } catch (e) {
      print('Error checking all roadmaps completion: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(title: ''),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (roadmap == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(title: ''),
        body: const Center(child: Text('Roadmap not found')),
      );
    }

    final description = roadmap!["description"] as String? ?? "";
    final focusGoals = List<String>.from(roadmap!["focusGoals"] ?? []);
    final actionChecklist = List<String>.from(
      roadmap!["actionChecklist"] ?? [],
    );
    final milestoneReflection = List<Map<String, dynamic>>.from(
      roadmap!["milestoneReflection"] ?? [],
    );
    final roadmapTitle = roadmap!['title'] as String? ?? "";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: roadmapTitle),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          // Section 1: Description
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppColors.lightGrey,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  "assets/icons/svg/quotes-right.svg",
                  width: 20.w,
                ),
                SizedBox(height: 12.h),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary.withOpacity(0.8),
                  ),
                ),
                SizedBox(height: 12.h),
                SvgPicture.asset(
                  "assets/icons/svg/quotes-left.svg",
                  width: 20.w,
                ),
              ],
            ),
          ),

          SizedBox(height: 20.h),

          // Section 2: Focus Goals
          Text(
            "Focus Goals",
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.lightGrey,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: focusGoals.asMap().entries.map((entry) {
                final index = entry.key;
                final goal = entry.value;

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == focusGoals.length - 1 ? 0 : 10.h,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "•",
                        style: TextStyle(
                          fontSize: 18.sp,
                          height: 1.2,
                          color: AppColors.textPrimary.withOpacity(0.6),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          goal,
                          style: TextStyle(
                            fontSize: 14.sp,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 20.h),

          // Section 3: Action Checklist
          Text(
            "Action Checklist",
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          ...actionChecklist.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            return Padding(
              padding: EdgeInsets.only(
                bottom: index == actionChecklist.length - 1 ? 0 : 12.h,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomCheckbox(
                    value: checklistStates[index],
                    onChanged: (val) {
                      setState(() {
                        checklistStates[index] = val;
                      });
                    },
                    size: 20,
                    activeColor: AppColors.brand500,
                    borderColor: AppColors.iceBlue,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textPrimary.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          SizedBox(height: 20.h),

          // Section 4: Milestone Reflection
          Text(
            "Milestone Reflection",
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),

          ...milestoneReflection.map((field) {
            final label = field["label"] as String;
            return Padding(
              padding: EdgeInsets.only(bottom: 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary.withOpacity(0.7),
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: reflectionControllers[label],
                    maxLines: 5,
                    minLines: 4,
                    decoration: InputDecoration(
                      hintText: "Write your reflection here...",
                      hintStyle: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textPrimary.withOpacity(0.3),
                        fontWeight: FontWeight.w500,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      alignLabelWithHint: true,
                      contentPadding: EdgeInsets.all(14.w),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide(
                          color: AppColors.neutral50.withOpacity(0.05),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide(
                          color: AppColors.brand500,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          SizedBox(height: 10.h),

          Button(
            onPressed: _saveProgress,
            text: isSaving ? 'Saving...' : 'Save',
            height: 54.h,
            borderRadius: BorderRadius.circular(32.r),
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            textColor: Colors.white,
            backgroundColor: AppColors.brand500,
            isLoading: isSaving,
          ),

          SizedBox(height: 12.h),

          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pop();
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
    );
  }
}
