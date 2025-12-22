import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/button.dart';
import '../../../../shared/widgets/custom_appbar.dart';

class ColorPickerScreen extends StatefulWidget {
  final List<String> existingColors;

  const ColorPickerScreen({this.existingColors = const [], super.key});

  @override
  State<ColorPickerScreen> createState() => _ColorPickerScreenState();
}

class _ColorPickerScreenState extends State<ColorPickerScreen> {
  Color currentColor = Colors.blue;
  List<String> selectedColors = [];

  @override
  void initState() {
    super.initState();
    selectedColors = List.from(widget.existingColors);
  }

  void _addColor() {
    if (selectedColors.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Maximum 4 colors allowed',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final colorHex = currentColor.value.toRadixString(16).substring(2);
    if (!selectedColors.contains(colorHex)) {
      setState(() {
        selectedColors.add(colorHex);
      });
    }
  }

  void _removeColor(String colorHex) {
    setState(() {
      selectedColors.remove(colorHex);
    });
  }

  Color currentColors = Colors.red;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Custom Color'),
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 24.h),
                    SizedBox(
                      width: 254.w, // or double.infinity
                      height: 254.w, // controls the wheel size
                      child: ColorPickerArea(HSVColor.fromColor(currentColor), (
                        HSVColor hsvColor,
                      ) {
                        setState(() {
                          currentColor = hsvColor.toColor();
                        });
                      }, PaletteType.hueWheel),
                    ),

                    SizedBox(height: 48.h),

                    // Color preview section with selected colors
                    Wrap(
                      spacing: 12.w,
                      runSpacing: 12.h,
                      alignment: WrapAlignment.center,
                      children: [
                        // Current color preview
                        Container(
                          width: 45.w,
                          height: 45.w,
                          decoration: BoxDecoration(
                            color: currentColor,
                            shape: BoxShape.circle,
                          ),
                        ),

                        // Selected colors with remove button
                        ...selectedColors.map((colorHex) {
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 45.w,
                                height: 45.w,
                                decoration: BoxDecoration(
                                  color: Color(int.parse('0xff$colorHex')),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Positioned(
                                top: -5,
                                right: -5,
                                child: GestureDetector(
                                  onTap: () => _removeColor(colorHex),
                                  child: Container(
                                    width: 24.w,
                                    height: 24.w,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16.sp,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),

                        // Add button
                        if (selectedColors.length < 4)
                          GestureDetector(
                            onTap: _addColor,
                            child: Container(
                              width: 45.w,
                              height: 45.w,
                              decoration: BoxDecoration(
                                color: AppColors.textPrimary.withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.add,
                                color: AppColors.textPrimary,
                                size: 24.sp,
                              ),
                            ),
                          ),
                      ],
                    ),

                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),

            Button(
              onPressed: selectedColors.isEmpty
                  ? null
                  : () {
                      Navigator.of(context).pop(selectedColors);
                    },
              text: 'Save as brand color',
              height: 54.h,
              borderRadius: BorderRadius.circular(32.r),
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              textColor: Colors.white,
              backgroundColor: selectedColors.isNotEmpty
                  ? AppColors.brand500
                  : AppColors.brand500.withOpacity(0.3),
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
    );
  }
}
