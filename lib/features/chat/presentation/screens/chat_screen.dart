import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/custom_appbar.dart';
import '../../data/chat_api_service.dart';
import '../../data/chat_firestore_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();
}

class ChatScreen extends StatefulWidget {
  final int? chatId;

  const ChatScreen({super.key, this.chatId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatFirestoreService _firestoreService = ChatFirestoreService();

  List<ChatMessage> _messages = [];
  int? _currentChatId;
  bool _isLoading = false;
  bool _isSending = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    _userId = FirebaseAuth.instance.currentUser?.uid;
    if (_userId == null) {
      _showError('Please log in to use chat');
      return;
    }

    if (widget.chatId != null) {
      await _loadChatHistory(widget.chatId!);
    }
  }

  Future<void> _loadChatHistory(int chatId) async {
    setState(() => _isLoading = true);

    try {
      final response = await ChatApiService.loadHistory(
        userId: _userId!,
        chatId: chatId,
      );

      if (response['error'] == true) {
        _showError('Failed to load chat history');
        setState(() => _isLoading = false);
        return;
      }

      final messages = ChatApiService.extractMessages(response);
      setState(() {
        _currentChatId = chatId;
        _messages = _mapMessages(messages);
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      _showError('Error loading chat: $e');
      setState(() => _isLoading = false);
    }
  }

  List<ChatMessage> _mapMessages(List<Map<String, dynamic>> messages) {
    return messages.map((m) {
      return ChatMessage(
        text: m['content'] ?? m['message'] ?? m['text'] ?? m['response'] ?? '',
        isUser: m['role'] == 'user',
        timestamp: DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
      );
    }).toList();
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    if (_userId == null) return;

    final messageText = _controller.text.trim();
    _controller.clear();

    // If no chat exists, create one with the user's actual message
    if (_currentChatId == null) {
      // Add user message to UI immediately
      setState(() {
        _messages.add(ChatMessage(text: messageText, isUser: true));
        _isSending = true;
      });

      _scrollToBottom();

      try {
        // Create new chat with the actual user message
        final newChatResponse = await ChatApiService.newChat(
          userId: _userId!,
          message: messageText,
        );

        if (newChatResponse['error'] == true) {
          _showError('Failed to create chat');
          setState(() {
            _messages.removeLast(); // Remove the optimistic message
            _isSending = false;
          });
          return;
        }

        final chatId = ChatApiService.extractChatId(newChatResponse);
        if (chatId == null) {
          _showError('Invalid chat ID received');
          setState(() {
            _messages.removeLast();
            _isSending = false;
          });
          return;
        }

        _currentChatId = chatId;

        // Fetch the full history (including the AI response) immediately
        // because newChat response might not contain the message content
        final historyResponse = await ChatApiService.loadHistory(
          userId: _userId!,
          chatId: chatId,
        );

        if (historyResponse['error'] == true) {
          // Fallback: use what we have (likely just the user message without AI reply yet)
          // But actually we should try to show what we can or wait.
          final partialMessages = ChatApiService.extractMessages(
            newChatResponse,
          );
          _messages = _mapMessages(partialMessages);
        } else {
          final historyMessages = ChatApiService.extractMessages(
            historyResponse,
          );
          _messages = _mapMessages(historyMessages);
        }

        setState(() {
          _isSending = false;
        });

        _scrollToBottom();

        // Save to Firestore (Title generation is fine)
        await _firestoreService.saveChatSession(
          chatId: _currentChatId!,
          title: _firestoreService.generateChatTitle(messageText),
          lastMessageTime: DateTime.now(),
        );
      } catch (e) {
        _showError('Error sending message: $e');
        setState(() {
          if (_messages.isNotEmpty && _messages.last.isUser) {
            _messages.removeLast();
          }
          _isSending = false;
        });
      }
      return;
    }

    // Existing chat - normal flow
    setState(() {
      _messages.add(ChatMessage(text: messageText, isUser: true));
      _isSending = true;
    });

    _scrollToBottom();

    try {
      final response = await ChatApiService.sendMessage(
        userId: _userId!,
        chatId: _currentChatId!,
        message: messageText,
      );

      if (response['error'] == true) {
        _showError('Failed to send message');
        setState(() {
          _messages.removeLast();
          _isSending = false;
        });
        return;
      }

      final messages = ChatApiService.extractMessages(response);

      setState(() {
        _messages = _mapMessages(messages);
        _isSending = false;
      });

      _scrollToBottom();

      // Update last message time
      final session = await _firestoreService.getChatSession(_currentChatId!);
      if (session != null) {
        await _firestoreService.saveChatSession(
          chatId: _currentChatId!,
          title: session.title,
          lastMessageTime: DateTime.now(),
        );
      }
    } catch (e) {
      _showError('Error sending message: $e');
      setState(() {
        if (_messages.isNotEmpty && _messages.last.isUser) {
          _messages.removeLast();
        }
        _isSending = false;
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _onFeatureBoxTap(String text) {
    _controller.text = text;
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        hideRightIcon: false,
        title: "AI Tutor",
        rightIconPath: "assets/icons/svg/history.svg",
        onRightTap: () => context.push('/chat-history'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _messages.isEmpty
                      ? _buildWelcomeScreen()
                      : _buildMessagesList(),
                ),
                if (_messages.isEmpty) _buildFeatureBoxes(),
                SizedBox(height: _messages.isEmpty ? 12.h : 8.h),
                _buildInputBar(),
              ],
            ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/images/gemini-chat.png",
              width: 72.w,
              height: 72.w,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 24.h),
            Text(
              "Welcome to Your AI Tutor",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
            SizedBox(height: 8.h),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 300.w),
              child: Text(
                "Ask me anything about cosmetology, career advice, or building your brand",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary.withOpacity(0.7),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      itemCount: _messages.length + (_isSending ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          return _buildAILoadingMessage();
        }
        final message = _messages[index];
        return message.isUser
            ? _buildUserMessage(message.text)
            : _buildAIMessage(message.text);
      },
    );
  }

  Widget _buildUserMessage(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
              decoration: BoxDecoration(
                color: const Color(0x0D090F05),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary.withOpacity(0.8),
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildAIMessage(String text) {
  //   return Padding(
  //     padding: EdgeInsets.only(bottom: 16.h),
  //     child: Row(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Image.asset(
  //           "assets/images/gemini-chat.png",
  //           width: 35.w,
  //           height: 35.w,
  //           fit: BoxFit.contain,
  //         ),
  //         SizedBox(width: 12.w),
  //         Flexible(
  //           child: Padding(
  //             padding: EdgeInsets.only(top: 0.h),
  //             child: Text(
  //               text,
  //               style: TextStyle(
  //                 fontSize: 12.sp,
  //                 fontWeight: FontWeight.w500,
  //                 color: AppColors.textPrimary.withOpacity(0.8),
  //                 height: 1.4,
  //               ),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildAIMessage(String text) {
    // Text style to measure
    final textStyle = TextStyle(
      fontSize: 12.sp,
      fontWeight: FontWeight.w500,
      height: 1.4,
    );

    // Measure the text width
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 250.w); // Set max width of the message bubble

    final isSingleLine = textPainter.didExceedMaxLines == false;

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        crossAxisAlignment: isSingleLine
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Image.asset(
            "assets/images/gemini-chat.png",
            width: 35.w,
            height: 35.w,
            fit: BoxFit.contain,
          ),
          SizedBox(width: 12.w),
          Flexible(
            child: Padding(
              padding: EdgeInsets.only(top: 0.h),
              child: Text(
                text,
                style: textStyle.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAILoadingMessage() {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
            decoration: BoxDecoration(
              color: const Color(0x090F050D),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const _TypingIndicator(),

                SizedBox(width: 8.w),

                Text(
                  'Generating',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textPrimary.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBoxes() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildFeatureBox("How do I build my client base?"),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildFeatureBox("Tips for my first salon interview?"),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: _buildFeatureBox("How to improve my cutting technique?"),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildFeatureBox(
                  "Social media tips for cosmetologists?",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBox(String title) {
    return GestureDetector(
      onTap: () => _onFeatureBoxTap(title),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color: AppColors.textPrimary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary.withOpacity(0.8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20.w,
          4.h,
          16.w,
          MediaQuery.of(context).padding.bottom + 16.h,
        ),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100.r),
            border: Border.all(
              width: 1.5,
              color: AppColors.textPrimary.withOpacity(0.05),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  enabled: !_isSending,
                  decoration: InputDecoration(
                    fillColor: Colors.white,
                    border: InputBorder.none,
                    hintText: "Ask tutor anything...",
                    hintStyle: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
              Container(
                width: 40.w,
                height: 40.w,
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  "assets/icons/svg/file.svg",
                  width: 20.w,
                  height: 20.w,
                ),
              ),
              SizedBox(width: 10.w),
              GestureDetector(
                onTap: _isSending ? null : _sendMessage,
                child: Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: _isSending
                        ? AppColors.brand500.withOpacity(0.5)
                        : AppColors.brand500,
                    borderRadius: BorderRadius.circular(100.r),
                  ),
                  child: Center(
                    child: _isSending
                        ? SizedBox(
                            width: 16.w,
                            height: 16.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : SvgPicture.asset(
                            "assets/icons/svg/send.svg",
                            width: 20.w,
                            height: 20.w,
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

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator({super.key});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
} // ✅ MISSING BRACE FIXED

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  final List<double> _sizes = [3, 4, 5];
  final List<Color> _colors = [
    Color(0xFF6292FD),
    Color(0xFF447DFD),
    Color(0xFF155DFC),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final value = (_controller.value - delay) % 1.0;

            final opacity = value < 0.5
                ? Curves.easeIn.transform(value * 2)
                : Curves.easeOut.transform((1 - value) * 2);

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 3.w),
              child: Opacity(
                opacity: 0.3 + (opacity * 0.7),
                child: Container(
                  width: _sizes[index].w,
                  height: _sizes[index].w,
                  decoration: BoxDecoration(
                    color: _colors[index],
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
