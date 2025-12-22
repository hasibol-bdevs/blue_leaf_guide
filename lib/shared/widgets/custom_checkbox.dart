import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/app_colors.dart';

class CustomCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final double size;
  final Color? activeColor;
  final Color? checkColor;
  final Color? borderColor;
  final double borderRadius;

  const CustomCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 20.0, // width & height
    this.activeColor,
    this.checkColor,
    this.borderColor,
    this.borderRadius = 7.0, // border-radius
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: size.w,
        height: size.h,
        decoration: BoxDecoration(
          color: value
              ? (activeColor ?? AppColors.iceBlue)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius.r),
          border: Border.all(
            color: value
                ? (activeColor ?? AppColors.iceBlue)
                : (borderColor ??
                      AppColors.iceBlue.withOpacity(1.0)), // full opacity
            width: 1.5.w, // border-width 1.5
          ),
        ),
        child: value
            ? Icon(
                Icons.check,
                color: checkColor ?? Colors.white,
                size: size * 0.6.w,
              )
            : null,
      ),
    );
  }
}
