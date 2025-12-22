import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/button.dart';
import '../../../../shared/widgets/custom_appbar.dart';
import '../../../../shared/widgets/custom_checkbox.dart';
import '../../data/marketing_service.dart';
import '../../models/marketing_item.dart';

class MarketingItemDetailScreen extends StatefulWidget {
  final MarketingItem item;
  final String stepTitle;

  const MarketingItemDetailScreen({
    required this.item,
    required this.stepTitle,
    super.key,
  });

  @override
  State<MarketingItemDetailScreen> createState() =>
      _MarketingItemDetailScreenState();
}

class _MarketingItemDetailScreenState extends State<MarketingItemDetailScreen> {
  late MarketingItem editableItem;
  final MarketingService _marketingService = MarketingService();
  bool _isSaving = false;
  Map<int, List<TextEditingController>> _textControllers = {};

  @override
  void initState() {
    super.initState();
    editableItem = MarketingItem(
      id: widget.item.id,
      title: widget.item.title,
      sections: widget.item.sections
          .map(
            (s) => MarketingSection(
              subtitle: s.subtitle,
              checkboxOptions: s.checkboxOptions,
              isTextField: s.isTextField,
              fieldType: s.fieldType,
              hintText: s.hintText,
              userInputs: List.from(s.userInputs),
              checkboxStates: List.from(s.checkboxStates),
            ),
          )
          .toList(),
      isCompleted: widget.item.isCompleted,
    );

    // Initialize checkbox states
    for (var section in editableItem.sections) {
      if (section.fieldType == 'checkbox' && section.checkboxStates.isEmpty) {
        section.checkboxStates = List.filled(
          section.checkboxOptions.length,
          false,
        );
      }
    }
  }

  @override
  void dispose() {
    _textControllers.values.forEach((controllers) {
      for (var c in controllers) {
        c.dispose();
      }
    });
    super.dispose();
  }

  bool canSave() {
    bool hasAnyInput = false;

    for (var section in editableItem.sections) {
      if (section.isTextField) {
        if (section.fieldType == 'multi_text') {
          // For multi_text, at least one non-empty field is enough
          if (section.userInputs.any((e) => e.trim().isNotEmpty)) {
            hasAnyInput = true;
          }
        } else {
          // For single text fields, check if it's filled
          if (section.userInputs.isNotEmpty &&
              section.userInputs[0].trim().isNotEmpty) {
            hasAnyInput = true;
          }
        }
      } else if (section.fieldType == 'checkbox') {
        // Check if any checkbox is selected
        if (section.checkboxStates.any((checked) => checked)) {
          hasAnyInput = true;
        }
      }
    }

    return hasAnyInput;
  }

  Future<void> _saveItem() async {
    if (!canSave()) return; // Don't save if nothing is filled

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please login to save')));
      return;
    }

    setState(() => _isSaving = true);

    // Clean up empty inputs before saving
    for (var section in editableItem.sections) {
      if (section.fieldType == 'multi_text') {
        section.userInputs.removeWhere((input) => input.trim().isEmpty);
      }
    }

    editableItem.isCompleted = canSave();

    final success = await _marketingService.saveMarketingItem(
      userId,
      editableItem,
    );

    setState(() => _isSaving = false);

    if (success) {
      Navigator.of(context).pop(editableItem);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saved successfully!',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.timelinePrimary,
        ),
      );
    } else {
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

  Widget _buildSection(MarketingSection section, int sectionIndex) {
    if (section.fieldType == 'checkbox') {
      return _buildCheckboxSection(section, sectionIndex);
    } else if (section.fieldType == 'multi_text') {
      return _buildMultiTextSection(section, sectionIndex);
    } else if (section.isTextField) {
      return _buildTextFieldSection(section, sectionIndex);
    }
    return SizedBox.shrink();
  }

  Widget _buildCheckboxSection(MarketingSection section, int sectionIndex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.subtitle.isNotEmpty) ...[
          Text(
            section.subtitle,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary.withOpacity(0.7),
              height: 1.4,
            ),
          ),
          SizedBox(height: 12.h),
        ],
        ...List.generate(section.checkboxOptions.length, (index) {
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Row(
              children: [
                CustomCheckbox(
                  activeColor: AppColors.brand500,
                  borderColor: AppColors.iceBlue,
                  value: section.checkboxStates[index],
                  onChanged: (value) {
                    setState(() {
                      section.checkboxStates[index] = value;
                    });
                  },
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    section.checkboxOptions[index],
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
        SizedBox(height: 12.h),
      ],
    );
  }

  Widget _buildTextFieldSection(MarketingSection section, int sectionIndex) {
    if (!_textControllers.containsKey(sectionIndex)) {
      _textControllers[sectionIndex] = [
        TextEditingController(
          text: section.userInputs.isNotEmpty ? section.userInputs[0] : '',
        ),
      ];
    }

    final controller = _textControllers[sectionIndex]![0];
    final isTextarea = section.fieldType == 'textarea';
    final borderRadius = isTextarea ? 16.r : 100.r;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.subtitle,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary.withOpacity(0.7),
            height: 1.4,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          maxLines: isTextarea ? 5 : 1,
          minLines: isTextarea ? 4 : 1,
          decoration: InputDecoration(
            hintText: section.hintText ?? "Enter text...",
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
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                color: AppColors.neutral50.withOpacity(0.05),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(color: AppColors.brand500, width: 1.5),
            ),
          ),
          onChanged: (value) {
            if (section.userInputs.isEmpty) {
              section.userInputs.add(value);
            } else {
              section.userInputs[0] = value;
            }
            setState(() {});
          },
        ),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget _buildMultiTextSection(MarketingSection section, int sectionIndex) {
    if (!_textControllers.containsKey(sectionIndex)) {
      final controllers = <TextEditingController>[];
      for (var i = 0; i < section.userInputs.length; i++) {
        controllers.add(TextEditingController(text: section.userInputs[i]));
      }
      if (controllers.isEmpty) {
        controllers.add(TextEditingController());
        section.userInputs.add("");
      }
      _textControllers[sectionIndex] = controllers;
    }

    final controllers = _textControllers[sectionIndex]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.subtitle,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary.withOpacity(0.7),
            height: 1.4,
          ),
        ),
        SizedBox(height: 8.h),
        ...List.generate(controllers.length, (index) {
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controllers[index],
                    decoration: InputDecoration(
                      hintText: 'Core pillar ${index + 1}',
                      hintStyle: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textPrimary.withOpacity(0.3),
                        fontWeight: FontWeight.w500,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.all(12.w),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(100.r),
                        borderSide: BorderSide(
                          color: AppColors.neutral50.withOpacity(0.05),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(100.r),
                        borderSide: BorderSide(
                          color: AppColors.brand500,
                          width: 1.5,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      section.userInputs[index] = value;
                      setState(() {});
                    },
                  ),
                ),
                SizedBox(width: 8.w),
                // Show Add button only on first field, Delete button on others
                if (index == 0)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        controllers.add(TextEditingController());
                        section.userInputs.add("");
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lightGrey,
                        borderRadius: BorderRadius.circular(100.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add,
                            color: AppColors.textPrimary.withOpacity(0.8),
                            size: 20.sp,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            "Add",
                            style: TextStyle(
                              fontSize: 15.sp,
                              color: AppColors.textPrimary.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        controllers[index].dispose();
                        controllers.removeAt(index);
                        section.userInputs.removeAt(index);
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(100.r),
                      ),
                      child: Icon(Icons.remove, color: Colors.red, size: 20.sp),
                    ),
                  ),
              ],
            ),
          );
        }),
        SizedBox(height: 12.h),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if Instagram and TikTok need to be side-by-side
    final isSocialMedia = editableItem.id == "social_media_marketing";

    return Scaffold(
      appBar: CustomAppBar(title: widget.stepTitle),
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                editableItem.title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            SizedBox(height: 24.h),
            Expanded(
              child: ListView.builder(
                itemCount: editableItem.sections.length,
                itemBuilder: (context, index) {
                  // Special handling for social media Instagram/TikTok row
                  if (isSocialMedia && index == 0) {
                    return _buildSocialMediaRow();
                  } else if (isSocialMedia && index == 1) {
                    return SizedBox.shrink(); // Skip TikTok, already rendered
                  }

                  return _buildSection(editableItem.sections[index], index);
                },
              ),
            ),
            Button(
              onPressed: canSave() ? _saveItem : null,
              text: _isSaving ? 'Saving...' : 'Save',
              height: 54.h,
              borderRadius: BorderRadius.circular(32.r),
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              textColor: Colors.white,
              backgroundColor: canSave()
                  ? AppColors.brand500
                  : AppColors.brand500.withOpacity(0.3),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: TextButton(
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialMediaRow() {
    final instagram = editableItem.sections[0];
    final tiktok = editableItem.sections[1];

    if (!_textControllers.containsKey(0)) {
      _textControllers[0] = [
        TextEditingController(
          text: instagram.userInputs.isNotEmpty ? instagram.userInputs[0] : '',
        ),
      ];
    }
    if (!_textControllers.containsKey(1)) {
      _textControllers[1] = [
        TextEditingController(
          text: tiktok.userInputs.isNotEmpty ? tiktok.userInputs[0] : '',
        ),
      ];
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    instagram.subtitle,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary.withOpacity(0.7),
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: _textControllers[0]![0],
                    decoration: InputDecoration(
                      hintText: instagram.hintText,
                      hintStyle: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textPrimary.withOpacity(0.3),
                        fontWeight: FontWeight.w500,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.all(14.w),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(100.r),
                        borderSide: BorderSide(
                          color: AppColors.neutral50.withOpacity(0.05),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(100.r),
                        borderSide: BorderSide(
                          color: AppColors.brand500,
                          width: 1.5,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      if (instagram.userInputs.isEmpty) {
                        instagram.userInputs.add(value);
                      } else {
                        instagram.userInputs[0] = value;
                      }
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tiktok.subtitle,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary.withOpacity(0.7),
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: _textControllers[1]![0],
                    decoration: InputDecoration(
                      hintText: tiktok.hintText,
                      hintStyle: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textPrimary.withOpacity(0.3),
                        fontWeight: FontWeight.w500,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.all(14.w),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(100.r),
                        borderSide: BorderSide(
                          color: AppColors.neutral50.withOpacity(0.05),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(100.r),
                        borderSide: BorderSide(
                          color: AppColors.brand500,
                          width: 1.5,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      if (tiktok.userInputs.isEmpty) {
                        tiktok.userInputs.add(value);
                      } else {
                        tiktok.userInputs[0] = value;
                      }
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 24.h),
      ],
    );
  }
}
