import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/custom_date_picker_dialog.dart';
import '../../../../shared/widgets/button.dart';
import '../../../../shared/widgets/text_field.dart' as CustomTextField;

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isSaving = false;
  List<Map<String, dynamic>> _dynamicGoals = [];

  // Static reflection controllers
  final Map<String, TextEditingController> reflectionControllers = {
    'todaysWin': TextEditingController(),
    'challengesAndLessons': TextEditingController(),
    'additionalNotes': TextEditingController(),
  };

  final Map<String, String> reflectionKeys = {
    'todaysWin': "Today's win",
    'challengesAndLessons': 'Challenges and lessons',
    'additionalNotes': 'Additional notes',
  };

  final Map<String, String> reflectionHints = {
    'todaysWin': 'What went well today? What are you proud of?',
    'challengesAndLessons': 'What didn\'t go as planned? What did you learn?',
    'additionalNotes': 'Any other thoughts or reminders?',
  };

  // Dynamic goal controllers
  Map<String, TextEditingController> dynamicControllers = {};

  // New Static Fields Controllers
  final TextEditingController _attendHairShowController =
      TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _salonNameController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    for (var controller in reflectionControllers.values) {
      controller.dispose();
    }
    _attendHairShowController.dispose();
    _locationController.dispose();
    _salonNameController.dispose();
    for (var controller in dynamicControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _getDateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  bool _isToday() {
    final today = DateTime.now();
    return _selectedDate.year == today.year &&
        _selectedDate.month == today.month &&
        _selectedDate.day == today.day;
  }

  Future<void> _loadData() async {
    if (_auth.currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      final userId = _auth.currentUser!.uid;
      final dateKey = _getDateKey(_selectedDate);

      final currentMonth = DateFormat('yyyy-MM').format(_selectedDate);

      final goalsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('monthly_goals')
          .where('month', isEqualTo: currentMonth)
          .where('isActive', isEqualTo: true)
          .get();

      _dynamicGoals = goalsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'shortTitle': doc.data()['shortTitle'] ?? '',
          'fullTitle': doc.data()['fullTitle'] ?? '',
          'order': data['order'] ?? -1, // 👈 ADD ORDER
        };
      }).toList();

      dynamicControllers.clear();
      for (var goal in _dynamicGoals) {
        dynamicControllers[goal['id']] = TextEditingController();
      }

      final checkInDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('check_ins')
          .doc(dateKey)
          .get();

      if (checkInDoc.exists) {
        final data = checkInDoc.data()!;

        reflectionControllers['todaysWin']?.text = data['todaysWin'] ?? '';
        reflectionControllers['challengesAndLessons']?.text =
            data['challengesAndLessons'] ?? '';
        reflectionControllers['additionalNotes']?.text =
            data['additionalNotes'] ?? '';

        _attendHairShowController.text = (data['attendHairShow'] ?? '')
            .toString();
        _locationController.text = data['location'] ?? '';
        _salonNameController.text = data['salonName'] ?? '';

        final dynamicData =
            data['dynamicFields'] as Map<String, dynamic>? ?? {};
        for (var entry in dynamicData.entries) {
          if (dynamicControllers.containsKey(entry.key)) {
            dynamicControllers[entry.key]?.text = entry.value.toString();
          }
        }
      } else {
        for (var controller in reflectionControllers.values) {
          controller.clear();
        }
        _attendHairShowController.clear();
        _locationController.clear();
        _salonNameController.clear();
        for (var controller in dynamicControllers.values) {
          controller.clear();
        }
      }
    } catch (e) {
      print('Error loading check-in data: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveCheckIn() async {
    if (_auth.currentUser == null || !_isToday()) return;

    setState(() => _isSaving = true);

    try {
      final userId = _auth.currentUser!.uid;
      final dateKey = _getDateKey(_selectedDate);

      // Parse dynamic fields (user input for goals)
      Map<String, dynamic> dynamicFieldsData = {};
      for (var entry in dynamicControllers.entries) {
        final value = int.tryParse(entry.value.text) ?? 0;
        dynamicFieldsData[entry.key] = value;
      }

      // Save check-in document
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('check_ins')
          .doc(dateKey)
          .set({
            'todaysWin': reflectionControllers['todaysWin']?.text ?? '',
            'challengesAndLessons':
                reflectionControllers['challengesAndLessons']?.text ?? '',
            'additionalNotes':
                reflectionControllers['additionalNotes']?.text ?? '',
            'attendHairShow': int.tryParse(_attendHairShowController.text) ?? 0,
            'location': _locationController.text.trim(),
            'salonName': _salonNameController.text.trim(),
            'dynamicFields': dynamicFieldsData,
            'date': _selectedDate,
            'createdAt': FieldValue.serverTimestamp(),
          });

      // 🔥 NEW: Calculate total "earned" from today's input
      int totalEarnedToday = 0;
      int totalAcquiredToday = 0;

      // Update monthly goal progress AND check for "earned"
      for (var entry in dynamicFieldsData.entries) {
        final goalId = entry.key;
        final value = entry.value as int;

        if (value > 0) {
          // Update monthly goal
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('monthly_goals')
              .doc(goalId)
              .update({
                'currentProgress': FieldValue.increment(value),
                'updatedAt': FieldValue.serverTimestamp(),
              });

          final goal = _dynamicGoals.firstWhere(
            (g) => g['id'] == goalId,
            orElse: () => {'order': -1},
          );

          if (goal['order'] == 3) {
            totalEarnedToday += value;
          } else if (goal['order'] == 2) {
            totalAcquiredToday += value;
          }
        }
      }

      if (totalEarnedToday > 0) {
        await _firestore.collection('users').doc(userId).update({
          'stats.totalEarned': FieldValue.increment(totalEarnedToday),
        });
      }

      if (totalAcquiredToday > 0) {
        await _firestore.collection('users').doc(userId).update({
          'stats.totalAcquired': FieldValue.increment(totalAcquiredToday),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Check-in saved successfully!',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.timelinePrimary,
        ),
      );
    } catch (e) {
      print('Error saving check-in: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save: $e',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  String getPrefixIconForShortTitle(String shortTitle) {
    print('Money Earned -- $shortTitle');
    switch (shortTitle) {
      case 'Money Earned':
        return 'assets/icons/svg/dollar-new.svg'; // single icon

      case 'Cards Passed Out':
        return 'assets/icons/svg/business-card.svg';

      case 'Client Serve':
        return 'assets/icons/svg/user.svg';

      default:
        return 'assets/icons/svg/default.svg'; // fallback icon
    }
  }

  Widget _buildDynamicFields() {
    if (_dynamicGoals.isEmpty) {
      return const SizedBox.shrink();
    }

    List<Widget> rows = [];

    for (int i = 0; i < _dynamicGoals.length; i += 2) {
      if (i + 1 < _dynamicGoals.length) {
        rows.add(
          Row(
            children: [
              Expanded(
                child: CustomTextField.TextField(
                  controller: dynamicControllers[_dynamicGoals[i]['id']]!,
                  label: _dynamicGoals[i]['shortTitle'],
                  hint: '0',
                  enabled: _isToday(),
                  keyboardType: TextInputType.number,
                  prefixIconSvg: getPrefixIconForShortTitle(
                    _dynamicGoals[i]['shortTitle'],
                  ),
                ),
              ),

              SizedBox(width: 12.w),
              Expanded(
                child: CustomTextField.TextField(
                  controller: dynamicControllers[_dynamicGoals[i + 1]['id']]!,
                  label: _dynamicGoals[i + 1]['shortTitle'],
                  hint: '0',
                  enabled: _isToday(),
                  keyboardType: TextInputType.number,
                  prefixIconSvg: getPrefixIconForShortTitle(
                    _dynamicGoals[i + 1]['shortTitle'],
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        rows.add(
          CustomTextField.TextField(
            controller: dynamicControllers[_dynamicGoals[i]['id']]!,
            label: _dynamicGoals[i]['shortTitle'],
            hint: '0',
            enabled: _isToday(),
            keyboardType: TextInputType.number,
            prefixIconSvg: getPrefixIconForShortTitle(
              _dynamicGoals[i]['shortTitle'],
            ),
          ),
        );
      }

      if (i < _dynamicGoals.length - 1) {
        rows.add(SizedBox(height: 12.h));
      }
    }

    return Column(children: rows);
  }

  // 🔥 NEW — Shared decoration helper for multiline TextField
  InputDecoration _reflectionDecoration() {
    return InputDecoration(
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
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: BorderSide(
          color: AppColors.textPrimary.withOpacity(0.05),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: BorderSide(color: AppColors.brand500, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Form(
      key: _formKey,
      child: ListView(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's activity",
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () async {
                  FocusScope.of(context).requestFocus(FocusNode());

                  final todayNormalized = DateTime(
                    DateTime.now().year,
                    DateTime.now().month,
                    DateTime.now().day,
                  );

                  final selected = await showDialog<DateTime>(
                    context: context,
                    builder: (_) => CustomDatePickerDialog(
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: todayNormalized,
                    ),
                  );

                  if (selected != null && selected != _selectedDate) {
                    setState(() {
                      _selectedDate = selected;
                    });
                    _loadData();
                  }
                },
                child: Container(
                  width: 45.w,
                  height: 45.h,
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(100.r),
                  ),
                  padding: EdgeInsets.all(10.w),
                  child: SvgPicture.asset(
                    'assets/icons/svg/calendar.svg',
                    fit: BoxFit.contain,
                    width: 24.w,
                    height: 24.h,
                    colorFilter: ColorFilter.mode(
                      AppColors.textPrimary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          _buildDynamicFields(),
          if (_dynamicGoals.isNotEmpty) SizedBox(height: 12.h),

          // --------------------------------------------------------
          // 🔥 NEW: Extra Static Fields
          // --------------------------------------------------------
          // 1. Attend hair show or class (Dropdown style)
          GestureDetector(
            onTap: _isToday()
                ? () async {
                    final selected = await showModalBottomSheet<int>(
                      context: context,
                      builder: (BuildContext context) {
                        return Container(
                          height: 250.h,
                          child: Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.all(16.w),
                                child: Text(
                                  "Select Count",
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: 11, // 0 to 10
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      title: Center(child: Text('$index')),
                                      onTap: () {
                                        Navigator.pop(context, index);
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );

                    if (selected != null) {
                      setState(() {
                        _attendHairShowController.text = selected.toString();
                      });
                    }
                  }
                : null,
            child: AbsorbPointer(
              child: CustomTextField.TextField(
                controller: _attendHairShowController,
                label: 'Attend hair show or class',
                hint: '0',
                enabled: _isToday(),
                prefixIconSvg: 'assets/icons/svg/pen.svg',
                // Suffix icon as widget for simple IconData
                suffixIcon: Icon(
                  Icons.keyboard_arrow_down,
                  size: 20.r,
                  color: AppColors.textPrimary.withOpacity(0.5),
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h),

          // 2. Location
          CustomTextField.TextField(
            controller: _locationController,
            label: 'Location',
            hint: 'Location here',
            enabled: _isToday(),
            prefixIconSvg: 'assets/icons/svg/pin.svg',
          ),
          SizedBox(height: 12.h),

          // 3. Name of Salon/Spa/Barbershop
          CustomTextField.TextField(
            controller: _salonNameController,
            label: 'Name of Salon/Spa/Barbershop you visited',
            hint: 'Name of Salon/Spa/Barbershop',
            enabled: _isToday(),
            prefixIconSvg: 'assets/icons/svg/comb.svg',
          ),
          SizedBox(height: 20.h),

          // --------------------------------------------------------
          // 🔥 STATIC REFLECTION FIELDS (FULLY UPDATED)
          // --------------------------------------------------------
          for (var entry in reflectionControllers.entries)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reflectionKeys[entry.key] ?? entry.key,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary.withOpacity(0.7),
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 8.h),

                // --------------------------------------
                // 🔥 NEW LOGIC: Today = multiline TextField
                //              Past date = auto-height container
                // --------------------------------------
                _isToday()
                    ? TextField(
                        controller: entry.value,
                        maxLines: 5,
                        minLines: 4,
                        enabled: true,
                        decoration: _reflectionDecoration().copyWith(
                          hintText: reflectionHints[entry.key],
                        ),
                      )
                    : Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: AppColors.lightGrey,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: AppColors.textPrimary.withOpacity(0.05),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          entry.value.text.isEmpty
                              ? "No data"
                              : entry.value.text,
                          style: TextStyle(
                            fontSize: 14.sp,
                            height: 1.4,
                            color: AppColors.textPrimary.withOpacity(0.7),
                          ),
                        ),
                      ),

                SizedBox(height: 16.h),
              ],
            ),
          SizedBox(height: 12.h),

          if (_isToday())
            Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              child: Button(
                onPressed: _isSaving ? null : _saveCheckIn,
                text: 'Save',
                height: 54.h,
                borderRadius: BorderRadius.circular(32.r),
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                textColor: Colors.white,
                backgroundColor: AppColors.brand500,
                isLoading: _isSaving,
              ),
            )
          else
            Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              child: Button(
                onPressed: _isSaving ? null : _saveCheckIn,
                text: 'Save',
                height: 54.h,
                borderRadius: BorderRadius.circular(32.r),
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                textColor: Colors.white,
                backgroundColor: AppColors.brand500.withOpacity(0.1),
                isLoading: _isSaving,
              ),
            ),
        ],
      ),
    );
  }
}
