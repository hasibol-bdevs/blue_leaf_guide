// edit_goal_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/button.dart';
import '../../../../shared/widgets/text_field.dart' as CustomTextField;

class EditGoalDialog {
  static Future<bool?> show({
    required BuildContext context,
    required String currentTitle,
    required int currentTarget,
    required Future<void> Function(int newTarget) onSave,
  }) async {
    final targetController = TextEditingController(
      text: currentTarget.toString(),
    );

    return await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
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
              Text(
                'Edit Monthly Goal',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 20.h),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 280.w),
                child: Text(
                  currentTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary.withOpacity(0.7),
                  ),
                ),
              ),
              SizedBox(height: 4.h),
              CustomTextField.TextField(
                controller: targetController,
                label: '',
                hint: 'Enter target',
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              Button(
                onPressed: () async {
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
                  await onSave(target);
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
    );
  }
}
