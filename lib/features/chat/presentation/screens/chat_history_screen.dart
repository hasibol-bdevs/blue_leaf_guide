import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../main.dart';
import '../../../../shared/widgets/custom_appbar.dart';
import '../../../../shared/widgets/custom_dialog.dart';
import '../../../../shared/widgets/custom_popup_menu.dart';
import '../../data/chat_api_service.dart';
import '../../data/chat_firestore_service.dart';

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  final ChatFirestoreService _firestoreService = ChatFirestoreService();

  Map<String, List<ChatSessionModel>> _groupChatHistoryByDate(
    List<ChatSessionModel> items,
  ) {
    final now = DateTime.now();
    final currentYear = now.year;
    final lastYear = currentYear - 1;

    final Map<String, List<ChatSessionModel>> groups = {};

    for (final item in items) {
      final year = item.lastMessageTime.year;
      String label;

      if (year == currentYear) {
        label = 'Recent History';
      } else if (year == lastYear) {
        label = 'Last Year';
      } else {
        label = '$year';
      }

      groups.putIfAbsent(label, () => []).add(item);
    }

    final sortedKeys = <String>[];
    if (groups.containsKey('Recent History')) sortedKeys.add('Recent History');
    if (groups.containsKey('Last Year')) sortedKeys.add('Last Year');

    final olderYears =
        groups.keys
            .where((k) => k != 'Recent History' && k != 'Last Year')
            .map((k) => int.tryParse(k) ?? 0)
            .where((y) => y > 0)
            .toList()
          ..sort((a, b) => b.compareTo(a));

    sortedKeys.addAll(olderYears.map((y) => '$y'));

    return {for (final key in sortedKeys) key: groups[key]!};
  }

  String _formatSubtitle(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = difference.inDays ~/ 7;
      return '$weeks ${weeks == 1 ? "week" : "weeks"} ago';
    } else if (difference.inDays < 365) {
      final months = difference.inDays ~/ 30;
      return '$months ${months == 1 ? "month" : "months"} ago';
    } else {
      return DateFormat('MMMM yyyy').format(time);
    }
  }

  Future<void> _deleteChat(int chatId) async {
    await showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: 'Delete Chat',
        subtitle: 'Are you sure you want to delete this chat?',
        primaryButtonText: 'Delete',
        secondaryButtonText: 'Cancel',
        primaryButtonOnPressed: () async {
          Navigator.of(context).pop(); // Close the dialog first

          // Create a flag to track success
          // ignore: unused_local_variable
          bool apiSuccess = false;

          // Delete from API first (source of truth for existence)
          try {
            final userId = FirebaseAuth.instance.currentUser?.uid;
            if (userId != null) {
              await ChatApiService.deleteChat(userId: userId, chatId: chatId);
              apiSuccess = true;
            }
          } catch (e) {
            debugPrint("Error deleting chat from API: $e");
            // If API delete fails, we might still want to delete locally or warn user?
            // For now, proceed to delete local data so it's consistent at least locally
          }

          // Delete from Firestore (local customizations)
          await _firestoreService.deleteChatSession(chatId);

          if (mounted) {
            setState(() {}); // Refresh the list

            scaffoldMessengerKey.currentState?.showSnackBar(
              const SnackBar(
                content: Text(
                  'Chat deleted successfully',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: AppColors.errorRed,
              ),
            );
          }
        },
        secondaryButtonOnPressed: () {
          Navigator.of(context).pop(); // Just close the dialog
        },
      ),
    );
  }

  // ✅ NEW: Sync API chats to Firestore
  Future<void> _syncChatsToFirestore(List<dynamic> rawApiChats) async {
    for (var rawChat in rawApiChats) {
      if (rawChat is! Map) continue;

      final int? chatId = int.tryParse(rawChat['chatId'].toString());
      if (chatId == null || chatId == 0) continue;

      final title = rawChat['title'] as String? ?? 'Chat $chatId';
      final timeStr =
          rawChat['lastMessageAt'] ??
          rawChat['createdAt'] ??
          rawChat['updatedAt'];
      final time = DateTime.tryParse(timeStr ?? '') ?? DateTime.now();

      // Save to Firestore (will create if doesn't exist)
      await _firestoreService.saveChatSession(
        chatId: chatId,
        title: title,
        lastMessageTime: time,
      );
    }
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    ChatSessionModel item,
  ) async {
    final controller = TextEditingController(text: item.title);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Rename Chat',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              style: TextStyle(fontSize: 14.sp, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Enter new chat name',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: AppColors.textPrimary.withOpacity(0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: AppColors.brand500),
                ),
              ),
            ),
          ],
        ),
        actionsPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brand500,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            ),
            child: Text(
              'Rename',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final newTitle = controller.text.trim();
      if (newTitle.isNotEmpty && newTitle != item.title) {
        bool apiSuccess = false;

        // Call API first
        try {
          final userId = FirebaseAuth.instance.currentUser?.uid;
          if (userId != null) {
            final response = await ChatApiService.renameChat(
              userId: userId,
              chatId: item.chatId,
              title: newTitle,
            );

            if (response['error'] != true) {
              apiSuccess = true;
            } else {
              debugPrint("API rename failed: ${response['message']}");
            }
          }
        } catch (e) {
          debugPrint("Error renaming chat via API: $e");
        }

        // Update Firestore (using upsert now, so it won't fail if doesn't exist)
        try {
          await _firestoreService.updateChatTitle(item.chatId, newTitle);
        } catch (e) {
          debugPrint("Error updating Firestore: $e");
        }

        if (mounted) {
          setState(() {});

          scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text(
                apiSuccess
                    ? 'Chat renamed successfully'
                    : 'Chat renamed locally (server error)',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: apiSuccess
                  ? AppColors.timelinePrimary
                  : AppColors.errorRed,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: 'Chat History'),
      body: FutureBuilder<Map<String, dynamic>>(
        future: ChatApiService.listChats(
          userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        ),
        builder: (context, apiSnapshot) {
          if (apiSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (apiSnapshot.hasError) {
            debugPrint("Error loading chats API: ${apiSnapshot.error}");
          }

          final apiData = apiSnapshot.data;
          final List<dynamic> rawApiChats =
              (apiData != null && apiData['chats'] is List)
              ? apiData['chats']
              : [];

          // ✅ NEW: Sync API chats to Firestore when loaded
          _syncChatsToFirestore(rawApiChats);

          return StreamBuilder<List<ChatSessionModel>>(
            stream: _firestoreService.getChatSessions(),
            builder: (context, streamSnapshot) {
              final firestoreChats = streamSnapshot.data ?? [];

              final Map<int, ChatSessionModel> firestoreMap = {
                for (var item in firestoreChats) item.chatId: item,
              };

              final List<ChatSessionModel> mergedChats = [];

              for (var rawChat in rawApiChats) {
                if (rawChat is! Map) continue;

                final int? chatId =
                    int.tryParse(rawChat['chatId'].toString()) ??
                    ChatApiService.extractChatId({
                      'messages': [rawChat],
                    }) ??
                    int.tryParse(rawChat['id'].toString());

                if (chatId == null || chatId == 0) continue;

                final apiTitle = rawChat['title'] as String?;
                final apiTimeStr =
                    rawChat['lastMessageAt'] ??
                    rawChat['createdAt'] ??
                    rawChat['updatedAt'];
                final apiTime =
                    DateTime.tryParse(apiTimeStr ?? '') ?? DateTime.now();

                final localData = firestoreMap[chatId];

                mergedChats.add(
                  ChatSessionModel(
                    chatId: chatId,
                    title: localData?.title ?? apiTitle ?? 'Chat $chatId',
                    lastMessageTime: apiTime,
                  ),
                );
              }

              mergedChats.sort(
                (a, b) => b.lastMessageTime.compareTo(a.lastMessageTime),
              );

              if (mergedChats.isEmpty) {
                return _buildEmptyState();
              }

              final grouped = _groupChatHistoryByDate(mergedChats);

              return ListView.builder(
                padding: EdgeInsets.only(
                  top: 20.0.h,
                  bottom: MediaQuery.of(context).padding.bottom + 80.h,
                ),
                itemCount: grouped.length,
                itemBuilder: (context, groupIndex) {
                  final label = grouped.keys.elementAt(groupIndex);
                  final items = grouped[label]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary.withOpacity(0.7),
                          ),
                        ),
                      ),
                      ...List.generate(items.length, (index) {
                        final isLast = index == items.length - 1;
                        return _buildHistoryCard(
                          items[index],
                          showBorder: !isLast,
                        );
                      }),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: EdgeInsets.symmetric(horizontal: 36.w),
        child: SizedBox(
          width: double.infinity,
          height: 50.h,
          child: ElevatedButton(
            onPressed: () {
              context.push('/chat').then((_) {
                if (mounted) setState(() {});
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brand500,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32.r),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 24.r, color: Colors.white),
                SizedBox(width: 8.w),
                Text(
                  'New Chat',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(ChatSessionModel item, {required bool showBorder}) {
    return GestureDetector(
      onTap: () {
        // Use push instead of pushReplacement to keep history in stack
        // and refresh when returning
        context.push('/chat', extra: item.chatId).then((_) {
          if (mounted) setState(() {});
        });
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 0.w),
        decoration: BoxDecoration(
          border: showBorder
              ? Border(
                  bottom: BorderSide(
                    color: AppColors.textSecondary.withOpacity(0.05),
                    width: 1.w,
                  ),
                )
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/gemini-chat.png',
              width: 35.w,
              height: 35.w,
              fit: BoxFit.contain,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _formatSubtitle(item.lastMessageTime),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textPrimary.withOpacity(0.5),
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Align(
              alignment: Alignment.topRight,
              child: CustomPopupMenu(
                iconPath: 'assets/icons/svg/more.svg',
                offset: Offset(-100, 8), // adjust if needed
                menuWidth: 140.w,
                items: [
                  PopupMenuItemData(
                    text: 'Rename',
                    textColor: AppColors.textPrimary.withOpacity(0.8),
                    onPressed: () {
                      _showRenameDialog(context, item);
                    },
                  ),
                  PopupMenuItemData(
                    text: 'Delete',
                    textColor: AppColors.errorRed,
                    onPressed: () {
                      _deleteChat(item.chatId);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/icons/svg/empty.svg',
              width: 80.w,
              height: 80.w,
            ),
            SizedBox(height: 24.h),
            Text(
              'No chat history yet',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                'Your conversations will appear here once you start chatting with your AI Tutor.',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
