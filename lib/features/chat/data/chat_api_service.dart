import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class ChatApiService {
  static final Dio _dio =
      Dio(
          BaseOptions(
            baseUrl: "http://54.144.185.224:5678",
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 60),
            headers: {
              "Content-Type": "application/json",
              "X-API-Key": "e\$G@AhcsQRW\$w!iHI\$\$\$)Asv",
            },
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              debugPrint("🟦 REQUEST");
              debugPrint("➡️ ${options.method} ${options.uri}");
              debugPrint("Headers: ${options.headers}");
              debugPrint("Body: ${options.data}");
              handler.next(options);
            },
            onResponse: (response, handler) {
              debugPrint("🟩 RESPONSE");
              debugPrint("Status: ${response.statusCode}");
              debugPrint("Data: ${response.data}");
              handler.next(response);
            },
            onError: (DioException e, handler) {
              debugPrint("🟥 DIO ERROR");
              debugPrint("Type: ${e.type}");
              debugPrint("Message: ${e.message}");

              if (e.response != null) {
                debugPrint("Status: ${e.response?.statusCode}");
                debugPrint("Headers: ${e.response?.headers}");
                debugPrint("Data: ${e.response?.data}");
              } else {
                debugPrint("No server response (network / timeout)");
              }

              handler.next(e);
            },
          ),
        );

  static Future<Map<String, dynamic>> _post(
    Map<String, dynamic> payload,
  ) async {
    try {
      final res = await _dio.post("/webhook/blg-chabot", data: payload);

      if (res.data is Map) {
        return Map<String, dynamic>.from(res.data);
      }

      return {"error": true, "message": "Invalid response format"};
    } on DioException catch (e, stack) {
      debugPrint("🔥 CAUGHT DIO EXCEPTION");
      debugPrint(stack.toString());

      return {
        "error": true,
        "status": e.response?.statusCode,
        "data": e.response?.data,
        "message": e.message,
      };
    } catch (e, stack) {
      debugPrint("💥 UNKNOWN ERROR");
      debugPrint(e.toString());
      debugPrint(stack.toString());

      return {"error": true, "message": e.toString()};
    }
  }

  /// NEW CHAT
  static Future<Map<String, dynamic>> newChat({
    required String userId,
    String message = "Hello!",
  }) {
    return _post({"userId": userId, "message": message, "action": "newChat"});
  }

  /// CONTINUE CHAT
  static Future<Map<String, dynamic>> sendMessage({
    required String userId,
    required int chatId,
    required String message,
  }) {
    return _post({
      "userId": userId,
      "chatId": chatId.toString(),
      "message": message,
      "action": "chat",
    });
  }

  /// LOAD HISTORY
  static Future<Map<String, dynamic>> loadHistory({
    required String userId,
    required int chatId,
  }) {
    return _post({
      "userId": userId,
      "chatId": chatId.toString(),
      "action": "history",
    });
  }

  /// LIST CHATS
  static Future<Map<String, dynamic>> listChats({required String userId}) {
    return _post({"userId": userId, "action": "listChats"});
  }

  /// Helper to extract chatId from response
  static int? extractChatId(Map<String, dynamic> res) {
    // Case 1: backend sends chatId directly
    if (res["chatId"] != null) {
      return _parseInt(res["chatId"]);
    }

    // Case 2: backend sends messages array
    final messages = res["messages"];
    if (messages is List && messages.isNotEmpty) {
      return _parseInt(messages.first["id"]);
    }

    return null;
  }

  /// Helper to parse messages from response
  static List<Map<String, dynamic>> extractMessages(Map<String, dynamic> res) {
    final messages = res["messages"];
    if (messages is List) {
      return messages.map((m) => Map<String, dynamic>.from(m)).toList();
    }
    return [];
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// DELETE CHAT - Send chatId as integer, not string
  static Future<Map<String, dynamic>> deleteChat({
    required String userId,
    required int chatId,
  }) {
    return _post({
      "userId": userId,
      "chatId": chatId.toString(), // ← Changed from chatId.toString() to chatId
      "action": "deleteChat",
    });
  }

  /// RENAME CHAT - Already correct, but ensure consistency
  static Future<Map<String, dynamic>> renameChat({
    required String userId,
    required int chatId,
    required String title,
  }) {
    return _post({
      "userId": userId,
      "chatId": chatId, // ← Keep as integer
      "title": title,
      "action": "RenameChat",
    });
  }
}
