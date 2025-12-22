// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';

// import '../../../../app/theme/app_colors.dart'; // Update path if needed

// class CustomStepper extends StatelessWidget {
//   final int currentStep; // 1-based index of currently selected step
//   final int totalSteps;
//   final List<String> titles;
//   final Function(int)? onStepTap;
//   final List<bool>?
//   completedSteps; // Optional: for future use (null = hide checkmarks)

//   const CustomStepper({
//     super.key,
//     required this.currentStep,
//     required this.totalSteps,
//     required this.titles,
//     this.onStepTap,
//     this.completedSteps, // Pass e.g. [true, true, false, false] later
//   });

//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final double stepSize = 20.r;
//         final double lineHeight = 2.w;
//         final double availableWidth = constraints.maxWidth;
//         final double totalStepWidth = stepSize * totalSteps;
//         final double totalLineWidth = availableWidth - totalStepWidth;
//         final double lineWidth = totalLineWidth / (totalSteps - 1);

//         final List<double> labelOffsets = [
//           -(lineWidth * 0.17),
//           lineWidth * 0.01,
//           lineWidth * 0.22,
//           lineWidth * 0.26,
//         ];

//         // Helper: is step completed? (fallback to false if not provided)
//         bool isCompleted(int stepIndex) {
//           if (completedSteps == null || stepIndex >= completedSteps!.length) {
//             return false;
//           }
//           return completedSteps![stepIndex];
//         }

//         return Column(
//           children: [
//             // Stepper: Dots + Lines
//             SizedBox(
//               height: stepSize,
//               child: Stack(
//                 children: [
//                   // Connector lines — color green if the step before is completed
//                   Positioned.fill(
//                     child: Row(
//                       children: List.generate(totalSteps * 2 - 1, (index) {
//                         if (index.isOdd) {
//                           // Line between step index/2 and step (index/2)+1
//                           final stepBefore = index ~/ 2;
//                           final isLinePassed = isCompleted(stepBefore);

//                           return Container(
//                             width: lineWidth,
//                             height: lineHeight,
//                             margin: EdgeInsets.symmetric(
//                               vertical: (stepSize - lineHeight) / 2,
//                             ),
//                             color: isLinePassed
//                                 ? AppColors.timelinePrimary
//                                 : AppColors.timelineBorder,
//                           );
//                         } else {
//                           return SizedBox(width: stepSize);
//                         }
//                       }),
//                     ),
//                   ),
//                   // Step indicators (dots)
//                   Positioned.fill(
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: List.generate(totalSteps, (index) {
//                         final stepNumber = index + 1;
//                         final isSelected = currentStep == stepNumber;
//                         final isComp = isCompleted(index);

//                         Color borderColor;
//                         double borderWidth;
//                         Color fillColor = Colors.transparent;
//                         Widget? child;

//                         if (isComp) {
//                           // Completed: filled with primary color + check
//                           borderColor = AppColors.timelinePrimary;
//                           borderWidth = 0; // No border needed if filled
//                           fillColor = AppColors.timelinePrimary;
//                           child = Icon(
//                             Icons.check,
//                             size: 12.sp,
//                             color: Colors.white,
//                           );
//                         } else if (isSelected) {
//                           // Selected but not completed: thick border, no fill
//                           borderColor = AppColors.timelinePrimary;
//                           borderWidth = 4.w;
//                           fillColor = Colors.transparent;
//                           child = null;
//                         } else {
//                           // Default
//                           borderColor = AppColors.timelineBorder;
//                           borderWidth = 2.w;
//                           fillColor = Colors.transparent;
//                           child = null;
//                         }

//                         return GestureDetector(
//                           onTap: () => onStepTap?.call(stepNumber),
//                           child: Container(
//                             width: stepSize,
//                             height: stepSize,
//                             decoration: BoxDecoration(
//                               shape: BoxShape.circle,
//                               border: Border.all(
//                                 color: borderColor,
//                                 width: borderWidth,
//                               ),
//                               color: fillColor,
//                             ),
//                             child: child,
//                           ),
//                         );
//                       }),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: List.generate(totalSteps, (index) {
//                 final stepNumber = index + 1;
//                 final isSelected = currentStep == stepNumber;
//                 final isComp = isCompleted(index);

//                 return GestureDetector(
//                   behavior: HitTestBehavior.translucent,
//                   onTap: () => onStepTap?.call(stepNumber),
//                   child: Column(
//                     children: [
//                       SizedBox(height: 12.h),
//                       Transform.translate(
//                         offset: Offset(labelOffsets[index], 0.h),
//                         child: Text(
//                           titles[index],
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             fontSize: 12.sp,
//                             fontWeight: FontWeight.w600,
//                             color: (isSelected || isComp)
//                                 ? AppColors.textPrimary.withOpacity(0.8)
//                                 : AppColors.textPrimary.withOpacity(0.3),
//                             height: 1.3,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               }),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_colors.dart'; // Update path if needed

class CustomStepper extends StatelessWidget {
  final int currentStep; // 1-based index of currently selected step
  final int totalSteps;
  final List<String> titles;
  final Function(int)? onStepTap;
  final List<bool>?
  completedSteps; // Optional: for future use (null = hide checkmarks)

  const CustomStepper({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.titles,
    this.onStepTap,
    this.completedSteps, // Pass e.g. [true, true, false, false] later
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double stepSize = 20.r;
        final double lineHeight = 2.w;
        final double availableWidth = constraints.maxWidth;
        final double totalStepWidth = stepSize * totalSteps;
        final double totalLineWidth = availableWidth - totalStepWidth;
        final double lineWidth = totalLineWidth / (totalSteps - 1);

        final List<double> labelOffsets = [
          -(lineWidth * 0.17),
          lineWidth * 0.01,
          lineWidth * 0.22,
          lineWidth * 0.26,
        ];

        // Helper: is step completed? (fallback to false if not provided)
        bool isCompleted(int stepIndex) {
          if (completedSteps == null || stepIndex >= completedSteps!.length) {
            return false;
          }
          return completedSteps![stepIndex];
        }

        return Column(
          children: [
            // Stepper: Dots + Lines
            SizedBox(
              height: stepSize,
              child: Stack(
                children: [
                  // Connector lines — color green if the step before is completed
                  Positioned.fill(
                    child: Row(
                      children: List.generate(totalSteps * 2 - 1, (index) {
                        if (index.isOdd) {
                          // This line leads into step number = (index ~/ 2) + 2
                          final int targetStep = (index ~/ 2) + 2;
                          final bool isLinePassed = targetStep <= currentStep;

                          return Container(
                            width: lineWidth,
                            height: lineHeight,
                            margin: EdgeInsets.symmetric(
                              vertical: (stepSize - lineHeight) / 2,
                            ),
                            color: isLinePassed
                                ? AppColors.timelinePrimary
                                : AppColors.timelineBorder,
                          );
                        } else {
                          return SizedBox(width: stepSize);
                        }
                      }),
                    ),
                  ),
                  // Step indicators (dots)
                  Positioned.fill(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(totalSteps, (index) {
                        final stepNumber = index + 1;
                        final isSelected = currentStep == stepNumber;
                        final isComp = isCompleted(index);

                        Color borderColor;
                        double borderWidth;
                        Color fillColor = Colors.transparent;
                        Widget? child;

                        if (isComp) {
                          // Completed: filled with primary color + check
                          borderColor = AppColors.timelinePrimary;
                          borderWidth = 0; // No border needed if filled
                          fillColor = AppColors.timelinePrimary;
                          child = Icon(
                            Icons.check,
                            size: 12.sp,
                            color: Colors.white,
                          );
                        } else if (isSelected) {
                          // Selected but not completed: thick border, no fill
                          borderColor = AppColors.timelinePrimary;
                          borderWidth = 4.w;
                          fillColor = Colors.transparent;
                          child = null;
                        } else {
                          // Default
                          borderColor = AppColors.timelineBorder;
                          borderWidth = 2.w;
                          fillColor = Colors.transparent;
                          child = null;
                        }

                        return GestureDetector(
                          onTap: () => onStepTap?.call(stepNumber),
                          child: Container(
                            width: stepSize,
                            height: stepSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: borderColor,
                                width: borderWidth,
                              ),
                              color: fillColor,
                            ),
                            child: child,
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(totalSteps, (index) {
                final stepNumber = index + 1;
                final isSelected = currentStep == stepNumber;
                final isComp = isCompleted(index);

                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => onStepTap?.call(stepNumber),
                  child: Column(
                    children: [
                      SizedBox(height: 12.h),
                      Transform.translate(
                        offset: Offset(labelOffsets[index], 0.h),
                        child: Text(
                          titles[index],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: (isSelected || isComp)
                                ? AppColors.textPrimary.withOpacity(0.8)
                                : AppColors.textPrimary.withOpacity(0.3),
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}
