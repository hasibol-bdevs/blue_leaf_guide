// lib/features/clients/screens/total_clients_screen.dart
import 'dart:convert';

import 'package:blue_leaf_guide/shared/widgets/custom_appbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/button.dart';
import '../../../../shared/widgets/custom_popup_menu.dart';
import '../../data/client_service.dart';

class TotalClientsScreen extends StatelessWidget {
  const TotalClientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final router = GoRouter.of(context);
        if (router.canPop()) {
          router.pop(); // safe pop
        } else {
          router.go('/home'); // fallback
        }
        return false; // prevent default pop
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(
          title: 'Clients',
          onBack: () {
            // Use GoRouter to safely navigate back
            if (GoRouter.of(context).canPop()) {
              GoRouter.of(context).pop();
            } else {
              GoRouter.of(context).go('/home'); // safe fallback
            }
          },
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: ClientService().getClientsStream(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading clients',
                  style: TextStyle(color: AppColors.danger, fontSize: 16.sp),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            final clients = snapshot.data?.docs ?? [];
            final totalClients = clients.length;

            if (clients.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/svg/hand.svg',
                      height: 80.r,
                      width: 80.r,
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      'No clients yet',
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 260.w, // <-- your desired max width
                      ),
                      child: Text(
                        'You haven’t added any clients. Start by adding a new client.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary.withOpacity(0.7),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    SizedBox(
                      width: 180.w,
                      height: 50.h,
                      child: ElevatedButton(
                        onPressed: () => context.push('/add-client'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brand500,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32.r),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Add Client',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Icon(Icons.add, size: 20.r, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                /// TOP BAR SHOWING COUNT
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'All Clients',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary.withOpacity(0.9),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            '(${clients.length})',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),

                      /// Add Client Button
                      GestureDetector(
                        onTap: () => context.push('/add-client'),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 10.h,
                            horizontal: 16.w,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brand500,
                            borderRadius: BorderRadius.circular(32.r),
                          ),
                          child: Row(
                            children: [
                              Text(
                                "Add Client",
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Icon(Icons.add, size: 18.r, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 10.h),

                Expanded(
                  child: clients.isEmpty
                      ? Center(child: Text("No clients added yet"))
                      : Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: ListView.builder(
                            itemCount: totalClients,
                            itemBuilder: (context, index) {
                              final doc = clients[index];
                              final client = doc.data() as Map<String, dynamic>;
                              final clientId = doc.id;
                              return _buildClientCard(
                                context,
                                client,
                                clientId,
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildClientCard(
    BuildContext context,
    Map<String, dynamic> client,
    String clientId,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      padding: EdgeInsets.symmetric(vertical: 16.h),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Color(0xFFF6F3F6), // 2px border color
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile image with popup button overlaid
          Stack(
            alignment: Alignment.center,
            children: [
              _buildProfileImage(client['profileImage']),

              // Align(
              //   alignment: Alignment.topRight,
              //   child: Padding(
              //     padding: EdgeInsets.only(right: 8.w),
              //     child: Transform.translate(
              //       offset: Offset(-5.w, -10.h),
              //       child: // In _buildClientCard method, replace the PopupMenuButton with:
              //       CustomPopupMenu(
              //         iconPath:
              //             'assets/icons/svg/more.svg', // Replace with your actual path
              //         items: [
              //           PopupMenuItemData(
              //             text: 'Edit',
              //             textColor: AppColors.textPrimary.withOpacity(0.8),
              //             onPressed: () {
              //               context.push(
              //                 '/add-client',
              //                 extra: {
              //                   'clientId': clientId,
              //                   'clientData': client,
              //                 },
              //               );
              //             },
              //           ),
              //           PopupMenuItemData(
              //             text: 'Delete',
              //             textColor: AppColors.errorRed,
              //             onPressed: () {
              //               _showDeleteDialog(context, clientId);
              //             },
              //           ),
              //         ],
              //       ),
              //     ),
              //   ),
              // ),
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: Transform.translate(
                    offset: Offset(-5.w, -10.h),
                    child: // In _buildClientCard method, replace the PopupMenuButton with:
                    CustomPopupMenu(
                      iconPath: 'assets/icons/svg/more.svg',
                      offset: Offset(-100, 8), // Adjust position
                      menuWidth: 140.w, // Custom width
                      items: [
                        PopupMenuItemData(
                          text: 'Edit',
                          textColor: AppColors.textPrimary.withOpacity(0.8),

                          onPressed: () {
                            context.push(
                              '/add-client',
                              extra: {
                                'clientId': clientId,
                                'clientData': client,
                              },
                            );
                          },
                        ),
                        PopupMenuItemData(
                          text: 'Delete',
                          textColor: AppColors.errorRed,
                          onPressed: () {
                            _showDeleteDialog(context, clientId);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // NAME centered
          Text(
            '${client['firstName']} ${client['lastName']}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary.withOpacity(0.8),
            ),
          ),

          SizedBox(height: 4.h),

          SizedBox(height: 4.h),

          // SOCIAL ICONS Centered
          _buildSocialIcons(client, context),

          SizedBox(height: 12.h),

          // INFO ROWS CENTERED
          _buildCenteredInfoRow(Icons.email, client['email'] ?? 'N/A'),
          SizedBox(height: 8.h),
          _buildCenteredInfoRow(Icons.phone, client['phone'] ?? 'N/A'),
          SizedBox(height: 12.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Client Type Badge
              Container(
                padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 8.w),
                decoration: BoxDecoration(
                  color: Color(0xFFEBEDE5), // #EBEDE5
                  borderRadius: BorderRadius.circular(100.r),
                ),
                child: Text(
                  client['clientType'] ?? 'Regular',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              SizedBox(width: 8.w),

              // Join Date Badge
              Container(
                padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 8.w),
                decoration: BoxDecoration(
                  color: Color(0xFFEFE5FA), // #EFE5FA
                  borderRadius: BorderRadius.circular(100.r),
                ),
                child: Text(
                  // Format date as 'Since Nov 21, 2025'
                  'Since ${DateFormat('MMM d, yyyy').format(DateTime.tryParse(client['joinDate'] ?? '') ?? DateTime.now())}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCenteredInfoRow(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 14.sp,
            color: AppColors.textPrimary.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileImage(String? base64Image) {
    return Container(
      width: 48.w,
      height: 48.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.neutral10.withOpacity(0.1),
      ),
      child: base64Image != null && base64Image.isNotEmpty
          ? ClipOval(
              child: Image.memory(
                const Base64Decoder().convert(base64Image),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.person,
                    size: 30.r,
                    color: AppColors.textSecondary,
                  );
                },
              ),
            )
          : Icon(Icons.person, size: 30.r, color: AppColors.textSecondary),
    );
  }

  Widget _buildSocialIcons(Map<String, dynamic> client, context) {
    final socials = <String, String>{};

    if (client['instagram']?.isNotEmpty ?? false) {
      socials['https://instagram.com/${client['instagram']}'] =
          'assets/icons/svg/insta.svg';
    }
    if (client['tiktok']?.isNotEmpty ?? false) {
      socials['https://www.tiktok.com/@${client['tiktok']}'] =
          'assets/icons/svg/tik.svg';
    }
    if (client['linkedin']?.isNotEmpty ?? false) {
      socials['https://www.linkedin.com/in/${client['linkedin']}'] =
          'assets/icons/svg/link.svg';
    }
    if (client['twitter']?.isNotEmpty ?? false) {
      socials['https://twitter.com/${client['twitter']}'] =
          'assets/icons/svg/twitter.svg';
    }

    if (socials.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: socials.entries.map((entry) {
        final url = entry.key;
        final path = entry.value;

        return Padding(
          padding: EdgeInsets.only(right: 12.w),
          child: GestureDetector(
            onTap: () async {
              final uri = Uri.parse(url);

              try {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'CThe link seems incorrect. Please check and try again.',
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
            },
            child: Container(
              width: 35.w,
              height: 35.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(100.r),
              ),
              child: Center(
                child: SvgPicture.asset(path, width: 20.w, height: 20.h),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showDeleteDialog(BuildContext context, String clientId) {
    showDialog(
      context: context,
      builder: (ctx) => DeleteClientDialog(clientId: clientId),
    );
  }
}

class DeleteClientDialog extends StatefulWidget {
  final String clientId;

  const DeleteClientDialog({super.key, required this.clientId});

  @override
  State<DeleteClientDialog> createState() => _DeleteClientDialogState();
}

class _DeleteClientDialogState extends State<DeleteClientDialog> {
  bool _isDeleting = false;

  Future<void> _deleteClient() async {
    setState(() => _isDeleting = true);

    final result = await ClientService().deleteClient(widget.clientId);

    if (!mounted) return;

    if (result['success']) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'],
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.timelinePrimary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36.r)),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Delete Client',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 12.h),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 280.w),
              child: Text(
                'Deleting this client will remove the client and all related data.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary.withOpacity(0.7),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Button(
              onPressed: _isDeleting ? null : _deleteClient,
              text: 'Yes, Delete',
              height: 54.h,
              borderRadius: BorderRadius.circular(32.r),
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              textColor: Colors.white,
              backgroundColor: AppColors.danger,
              isLoading: _isDeleting,
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _isDeleting
                    ? null
                    : () => Navigator.of(context).pop(),
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
