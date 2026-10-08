// lib/services/ai_chat_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sporta/Core/Constants/api_constants.dart';
import 'package:flutter/foundation.dart';

class AIChatService {
  final String? authToken;
  
  AIChatService({this.authToken});
  
  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    if (authToken != null && authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  /// Send a message to the AI assistant
  Future<AIChatResponse> sendMessage({
    required String message,
    String? sessionId,
    List<Map<String, String>>? conversationHistory,
  }) async {
    try {
      final body = {
        'question': message,
        if (sessionId != null) 'sessionId': sessionId,
        if (conversationHistory != null) 'conversationHistory': conversationHistory,
      };

      debugPrint('[AIChat] Sending message: $message');
      debugPrint('[AIChat] Session ID: $sessionId');

      final response = await http.post(
        Uri.parse(ApiConstants.aiChat),
        headers: _headers,
        body: json.encode(body),
      );

      debugPrint('[AIChat] Response status: ${response.statusCode}');
      debugPrint('[AIChat] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AIChatResponse.fromJson(data);
      } else if (response.statusCode == 429) {
        throw Exception('AI service is busy. Please try again in a moment.');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? 'Failed to get AI response');
      }
    } catch (e) {
      debugPrint('[AIChat] Error: $e');
      throw Exception('Failed to communicate with AI assistant: $e');
    }
  }

  /// Get conversation history
  Future<List<AIConversationEntry>> getHistory(String sessionId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.aiHistory(sessionId)),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List entries = data['data'] ?? [];
        return entries.map((e) => AIConversationEntry.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[AIChat] Get history error: $e');
      return [];
    }
  }

  /// Clear conversation history
  Future<void> clearHistory(String sessionId) async {
    try {
      await http.delete(
        Uri.parse(ApiConstants.aiClearHistory(sessionId)),
        headers: _headers,
      );
    } catch (e) {
      debugPrint('[AIChat] Clear history error: $e');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────

class AIChatResponse {
  final String reply;
  final String intent;
  final bool usedDatabaseContext;
  final String? contextType;
  final String model;
  final int tokensUsed;
  final String sessionId;

  AIChatResponse({
    required this.reply,
    required this.intent,
    required this.usedDatabaseContext,
    this.contextType,
    required this.model,
    required this.tokensUsed,
    required this.sessionId,
  });

  factory AIChatResponse.fromJson(Map<String, dynamic> json) {
    return AIChatResponse(
      reply: json['reply'] ?? '',
      intent: json['intent'] ?? 'general',
      usedDatabaseContext: json['usedDatabaseContext'] ?? false,
      contextType: json['contextType'],
      model: json['model'] ?? '',
      tokensUsed: json['tokensUsed'] ?? 0,
      sessionId: json['sessionId'] ?? '',
    );
  }
}

class AIConversationEntry {
  final String question;
  final String answer;
  final String? contextType;
  final DateTime createdAt;

  AIConversationEntry({
    required this.question,
    required this.answer,
    this.contextType,
    required this.createdAt,
  });

  factory AIConversationEntry.fromJson(Map<String, dynamic> json) {
    return AIConversationEntry(
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
      contextType: json['contextType'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHAT MESSAGE MODEL FOR UI
// ─────────────────────────────────────────────────────────────────────────────

enum ChatMessageType { user, assistant, loading, error }

class ChatMessage {
  final String id;
  final String content;
  final ChatMessageType type;
  final DateTime timestamp;
  final String? intent;
  final bool isLoading;
  final bool isError;

  ChatMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.timestamp,
    this.intent,
    this.isLoading = false,
    this.isError = false,
  });

  factory ChatMessage.user(String content) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: ChatMessageType.user,
      timestamp: DateTime.now(),
    );
  }

  factory ChatMessage.assistant(String content, {String? intent}) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: ChatMessageType.assistant,
      timestamp: DateTime.now(),
      intent: intent,
    );
  }

  factory ChatMessage.loading() {
    return ChatMessage(
      id: 'loading_${DateTime.now().millisecondsSinceEpoch}',
      content: '',
      type: ChatMessageType.loading,
      timestamp: DateTime.now(),
      isLoading: true,
    );
  }

  factory ChatMessage.error(String content) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: ChatMessageType.error,
      timestamp: DateTime.now(),
      isError: true,
    );
  }
}