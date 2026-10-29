/*// lib/Core/Services/worker_chat_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sporta/Core/Constants/api_constants.dart';
import 'package:sporta/Core/Utils/app_logger.dart';

class WorkerChatService {
  // ─────────────────────────────────────────────────────────────────────────
  // GET ALL CONVERSATIONS - Get all conversations for the authenticated worker
  // ─────────────────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getConversations(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.workerConversations),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );


      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['conversations'] ?? [];
      } else {
        final Map<String, dynamic> error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to get conversations');
      }
    } catch (e) {
      AppLogger.error('Error in getConversations: $e');
      throw Exception(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GET MANAGER CONVERSATION - Get or create permanent conversation with manager
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getManagerConversation(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.workerManagerConversation),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );


      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['conversation'] ?? {};
      } else {
        final Map<String, dynamic> error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to get manager conversation');
      }
    } catch (e) {
      AppLogger.error('Error in getManagerConversation: $e');
      throw Exception(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GET MESSAGES - Get messages for a specific conversation
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getMessages({
    required String token,
    required String conversationId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.workerConversationMessages(conversationId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );


      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'messages': data['messages'] ?? [],
          'conversation': data['conversation'] ?? {},
        };
      } else {
        final Map<String, dynamic> error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to get messages');
      }
    } catch (e) {
      AppLogger.error('Error in getMessages: $e');
      throw Exception(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SEND MESSAGE - Send a message in a conversation
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> sendMessage({
    required String token,
    required String conversationId,
    required String text,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.workerSendMessage(conversationId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'text': text,
        }),
      );


      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['message'] ?? {};
      } else {
        final Map<String, dynamic> error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to send message');
      }
    } catch (e) {
      AppLogger.error('Error in sendMessage: $e');
      throw Exception(e.toString());
    }
  }
}*/

/*// lib/Core/Services/worker_chat_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sporta/Core/Constants/api_constants.dart';

class WorkerChatService {
  // ─────────────────────────────────────────────────────────────────────────
  // GET ALL CONVERSATIONS - Get all conversations for the authenticated worker
  // ─────────────────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getConversations(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.workerConversations),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );


      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['conversations'] ?? [];
      } else {
        final Map<String, dynamic> error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to get conversations');
      }
    } catch (e) {
      AppLogger.error('Error in getConversations: $e');
      throw Exception(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GET MESSAGES - Get messages for a specific conversation
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getMessages({
    required String token,
    required String conversationId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.workerConversationMessages(conversationId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );


      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'messages': data['messages'] ?? [],
          'conversation': data['conversation'] ?? {},
        };
      } else {
        final Map<String, dynamic> error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to get messages');
      }
    } catch (e) {
      AppLogger.error('Error in getMessages: $e');
      throw Exception(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SEND MESSAGE - Send a message in a conversation
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> sendMessage({
    required String token,
    required String conversationId,
    required String text,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.workerSendMessage(conversationId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'text': text,
        }),
      );


      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['message'] ?? {};
      } else {
        final Map<String, dynamic> error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to send message');
      }
    } catch (e) {
      AppLogger.error('Error in sendMessage: $e');
      throw Exception(e.toString());
    }
  }
}*/
