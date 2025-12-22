// monthly_goals_list.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/custom_popup_menu.dart';

class MonthlyGoalsList extends StatefulWidget {
  final String userId;
  final String monthKey;
  final VoidCallback onAddGoal;
  final Future<void> Function(String goalId, String title, int target)
  onEditGoal;
  final Future<void> Function(String goalId) onDeleteGoal;
  final Map<int, String> orderSuffixMap;

  /// Optional props for embedding in other scrollables
  final bool? shrinkWrap;
  final ScrollPhysics? physics;

  const MonthlyGoalsList({
    super.key,
    required this.userId,
    required this.monthKey,
    required this.onAddGoal,
    required this.onEditGoal,
    required this.onDeleteGoal,
    required this.orderSuffixMap,
    this.shrinkWrap,
    this.physics,
  });

  @override
  State<MonthlyGoalsList> createState() => _MonthlyGoalsListState();
}

class _MonthlyGoalsListState extends State<MonthlyGoalsList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isScrollable = !(widget.shrinkWrap ?? false);

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('monthly_goals')
        .where('isActive', isEqualTo: true);

    if (widget.monthKey != 'ALL') {
      query = query.where('month', isEqualTo: widget.monthKey);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(16.h),
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(16.h),
              child: const CircularProgressIndicator(),
            ),
          );
        }

        final goals = snapshot.data?.docs ?? [];

        // Sort by createdAt
        goals.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['createdAt'] as Timestamp?;
          final bTime = bData['createdAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return aTime.compareTo(bTime);
        });

        if (goals.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.track_changes,
                      size: 64.w,
                      color: AppColors.textPrimary.withOpacity(0.2),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'No goals yet',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary.withOpacity(0.5),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Add your first monthly goal',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textPrimary.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final listView = ListView.separated(
          padding: EdgeInsets.only(bottom: 44.h),
          controller: isScrollable ? _scrollController : null,
          shrinkWrap: widget.shrinkWrap ?? false,
          physics: widget.physics,
          itemCount: goals.length,
          separatorBuilder: (context, index) {
            if (index == goals.length - 1) return const SizedBox.shrink();
            return Column(
              children: [
                SizedBox(height: 12.h),
                Divider(
                  color: AppColors.textPrimary.withOpacity(0.05),
                  thickness: 1.h,
                ),
              ],
            );
          },
          itemBuilder: (context, index) {
            final goal = goals[index].data() as Map<String, dynamic>;
            final goalId = goals[index].id;
            final fullTitle = goal['fullTitle'] ?? '';
            final target = goal['targetNumber'] ?? 0;
            final progress = goal['currentProgress'] ?? 0;
            final progressPercentage = target > 0
                ? (progress / target).clamp(0.0, 1.0)
                : 0.0;

            final order = goal['order'] ?? 0;
            final suffix = widget.orderSuffixMap[order] ?? '';

            return Container(
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
                      Expanded(
                        child: Text(
                          fullTitle,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary.withOpacity(0.8),
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: index.isEven
                              ? AppColors.amber
                              : AppColors.timelinePrimary,
                          borderRadius: BorderRadius.circular(100.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Target ',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              target.toString(),
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16.w),
                      CustomPopupMenu(
                        customIcon: Icon(
                          Icons.more_vert,
                          size: 20.w,
                          color: AppColors.textPrimary.withOpacity(0.6),
                        ),
                        offset: Offset(-20.w, 0.h),
                        menuWidth: 140.w,
                        items: [
                          PopupMenuItemData(
                            text: 'Edit',
                            onPressed: () {
                              widget.onEditGoal(goalId, fullTitle, target);
                            },
                          ),
                          PopupMenuItemData(
                            text: 'Delete',
                            textColor: Colors.red,
                            onPressed: () {
                              widget.onDeleteGoal(goalId);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30.r),
                    child: LinearProgressIndicator(
                      value: progressPercentage,
                      minHeight: 8.h,
                      backgroundColor: AppColors.brand50,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progressPercentage >= 1.0
                            ? Colors.green
                            : AppColors.brand400,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '$progress $suffix',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            );
          },
        );

        // Only wrap with Scrollbar if the list is scrollable
        if (isScrollable) {
          return Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: listView,
          );
        }

        return listView;
      },
    );
  }
}
