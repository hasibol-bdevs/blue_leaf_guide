import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/button.dart';
import '../../../../shared/widgets/custom_appbar.dart';

class ColorPalettePickerScreen extends StatefulWidget {
  final List<String> existingColors;

  const ColorPalettePickerScreen({this.existingColors = const [], super.key});

  @override
  State<ColorPalettePickerScreen> createState() =>
      _ColorPalettePickerScreenState();
}

class _ColorPalettePickerScreenState extends State<ColorPalettePickerScreen> {
  int? selectedPaletteIndex;

  // Predefined color palettes using your colors
  final List<List<String>> palettes = [
    // Palette 1
    ['FF6D24', '4F403B', '857671', 'E3DFD4'],
    // Palette 2
    ['824C97', '413467', 'FFAF50', 'ED743F'],
    // Palette 3
    ['2A2C5F', '393C83', '3FC3D0', '43D9E8'],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Color Palette'),
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: IntrinsicWidth(
            // ← Key: makes all children match the widest intrinsic width
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment
                  .stretch, // ← buttons fill the intrinsic width
              children: [
                SizedBox(height: 24.h),
                ...palettes.asMap().entries.map((entry) {
                  final index = entry.key;
                  final palette = entry.value;
                  final isSelected = selectedPaletteIndex == index;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Label outside the bordered container
                      Text(
                        'Palette ${index + 1}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary.withOpacity(0.8),
                        ),
                      ),
                      SizedBox(height: 8.h),

                      // Bordered container with centered colors + checkmark inside
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedPaletteIndex = index;
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.only(bottom: 16.h),
                          padding: EdgeInsets.symmetric(
                            vertical: 12.h,
                            horizontal: 12.w,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.textPrimary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(50.r),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.textPrimary.withOpacity(0.1)
                                  : Colors.white,
                              width: isSelected ? 1.5 : 0,
                            ),
                          ),
                          child: IntrinsicWidth(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Color circles
                                ...palette.map((colorHex) {
                                  return Container(
                                    width: 45.w,
                                    height: 45.w,
                                    margin: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Color(int.parse('0xff$colorHex')),
                                      shape: BoxShape.circle,
                                    ),
                                  );
                                }).toList(),

                                // Checkmark
                                SizedBox(width: 12.w),
                                Icon(
                                  Icons.check,
                                  color: isSelected
                                      ? AppColors.timelinePrimary
                                      : AppColors.textPrimary.withOpacity(0.1),
                                  size: 18.sp,
                                ),
                                SizedBox(width: 12.w),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),

                SizedBox(height: 24.h),

                // Button 1: Add as brand color
                Button(
                  onPressed: selectedPaletteIndex == null
                      ? null
                      : () {
                          Navigator.of(
                            context,
                          ).pop(palettes[selectedPaletteIndex!]);
                        },
                  text: 'Add as brand color',
                  height: 54.h,
                  borderRadius: BorderRadius.circular(32.r),
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  textColor: Colors.white,
                  backgroundColor: selectedPaletteIndex != null
                      ? AppColors.brand500
                      : AppColors.brand500.withOpacity(0.3),
                ),
                SizedBox(height: 12.h),

                // Button 2: Cancel
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
