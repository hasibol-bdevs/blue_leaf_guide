import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/app_colors.dart';
import 'button.dart';

class PickerResult {
  final int year;
  final int? month; // null if "All Year"

  const PickerResult({required this.year, this.month});
}

class MonthYearPickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final int? maxYear;
  final int? maxMonth;

  const MonthYearPickerDialog({
    required this.initialDate,
    this.maxYear,
    this.maxMonth,
  });

  @override
  State<MonthYearPickerDialog> createState() => MonthYearPickerDialogState();
}

class MonthYearPickerDialogState extends State<MonthYearPickerDialog> {
  late int selectedYear;
  late int selectedMonth;
  bool isAllYear = false;

  @override
  void initState() {
    super.initState();
    selectedYear = widget.initialDate.year;
    selectedMonth = widget.initialDate.month;
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = widget.maxYear ?? DateTime.now().year;
    final currentMonth = widget.maxMonth ?? DateTime.now().month;

    // Years: allow up to maxYear only
    final years = List.generate(
      10,
      (index) => currentYear - 5 + index,
    ).where((y) => y <= currentYear).toList();

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

    // final yearItems = ["All Year", ...years.map((y) => y.toString())];
    final yearItems = years.map((y) => y.toString()).toList();

    // initial year index
    int initialYearIndex;
    if (isAllYear) {
      initialYearIndex = 0;
    } else {
      final yIndex = years.indexOf(selectedYear);
      initialYearIndex = yIndex >= 0 ? yIndex + 1 : 1;
    }

    // Max selectable month if selected year is maxYear
    final maxSelectableMonth = selectedYear == currentYear ? currentMonth : 12;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Container(
        height: 320.h,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Column(
          children: [
            Text(
              "Select Month & Year",
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 12.h),
            Expanded(
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 12.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    /// MONTH PICKER
                    SizedBox(
                      width: 120.w,
                      child: IgnorePointer(
                        ignoring: isAllYear,
                        child: CupertinoPicker(
                          itemExtent: 32.h,
                          scrollController: FixedExtentScrollController(
                            initialItem: selectedMonth - 1,
                          ),
                          onSelectedItemChanged: (index) {
                            if (index + 1 <= maxSelectableMonth) {
                              setState(() => selectedMonth = index + 1);
                            }
                          },
                          children: months.asMap().entries.map((entry) {
                            final monthIndex = entry.key + 1;
                            final isDisabled = monthIndex > maxSelectableMonth;
                            return Center(
                              child: Text(
                                entry.value,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isDisabled
                                      ? AppColors.textPrimary.withOpacity(0.3)
                                      : AppColors.textPrimary,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    Text(
                      ":",
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    /// YEAR PICKER
                    SizedBox(
                      width: 80.w,
                      child: CupertinoPicker(
                        itemExtent: 32.h,
                        scrollController: FixedExtentScrollController(
                          initialItem: initialYearIndex,
                        ),
                        onSelectedItemChanged: (index) {
                          setState(() {
                            if (index == 0) {
                              // "All Year" selected
                              isAllYear = true;
                            } else {
                              isAllYear = false;
                              selectedYear = years[index - 1];
                              // Clamp month if maxYear selected
                              if (selectedYear == currentYear &&
                                  selectedMonth > currentMonth) {
                                selectedMonth = currentMonth;
                              }
                            }
                          });
                        },
                        children: yearItems.map((item) {
                          return Center(
                            child: Text(
                              item,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10.h),
            Padding(
              padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 12.h),
              child: Column(
                children: [
                  Button(
                    // onPressed: () {
                    //   if (isAllYear) {
                    //     Navigator.pop(
                    //       context,
                    //       const PickerResult(year: -1, month: null),
                    //     );
                    //   } else {
                    //     Navigator.pop(
                    //       context,
                    //       PickerResult(
                    //         year: selectedYear,
                    //         month: selectedMonth,
                    //       ),
                    //     );
                    //   }
                    // },
                    onPressed: () {
                      Navigator.pop(
                        context,
                        PickerResult(year: selectedYear, month: selectedMonth),
                      );
                    },
                    text: 'View Month Goal',
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
          ],
        ),
      ),
    );
  }
}
