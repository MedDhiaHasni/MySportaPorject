// lib/views/player/ai_assistant.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sporta/Core/Constants/api_constants.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// ─── Color Palette ────────────────────────────────────────────────────────────
const _c900 = Color(0xFF001A1B);
const _c800 = Color(0xFF002B2C);
const _c600 = Color(0xFF006B6C);
const _c400 = Color(0xFF009999);
const _c200 = Color(0xFF4DD9D9);
const _cAccent = Color(0xFF00F0F0);
const _cSurface = Color(0xFFF0F7F7);
const _cCard = Color(0xFFFFFFFF);

class AiAssistant extends StatefulWidget {
  final String? playerToken;
  const AiAssistant({super.key, this.playerToken});

  @override
  State<AiAssistant> createState() => _AiAssistantState();
}

class _AiAssistantState extends State<AiAssistant>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  // Use FlutterSecureStorage — same store the rest of the app writes to
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isTyping = false;
  String? _sessionId;
  String? _authToken;
  bool _inputFocused = false;

  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _fabController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _fabAnimation;

  final List<SuggestionChip> _suggestions = [
    SuggestionChip(icon: '⚽', label: 'Football courts', query: 'Find football courts near me'),
    SuggestionChip(icon: '🎾', label: 'Padel nearby', query: 'Find padel courts'),
    SuggestionChip(icon: '📅', label: 'Availability', query: 'Check court availability for tomorrow'),
    SuggestionChip(icon: '💰', label: 'Prices', query: 'What are the prices for football courts?'),
    SuggestionChip(icon: '👥', label: 'Find teammates', query: 'I need teammates for a match'),
    SuggestionChip(icon: '🏆', label: 'My bookings', query: 'Show my bookings'),
    SuggestionChip(icon: '📍', label: 'Near me', query: 'Venues near me'),
    SuggestionChip(icon: '⭐', label: 'Best rated', query: 'Recommend the best venues'),
    SuggestionChip(icon: '🎯', label: 'Book a court', query: 'Book a football court for tomorrow at 7 PM'),
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initSession();
    _addWelcomeMessage();
    _focusNode.addListener(() {
      setState(() => _inputFocused = _focusNode.hasFocus);
    });
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _fabAnimation =
        CurvedAnimation(parent: _fabController, curve: Curves.elasticOut);

    _messageController.addListener(() {
      if (_messageController.text.isNotEmpty) {
        _fabController.forward();
      } else {
        _fabController.reverse();
      }
    });
  }

  Future<void> _initSession() async {
    // ── FIX 1: read from FlutterSecureStorage with key 'jwt_token' ──────────
    // The previous code used SharedPreferences + key 'auth_token', which is
    // a different store and a different key from what the rest of the app uses.
    // This caused _authToken to always be null → backend received no userId →
    // every booking attempt returned "auth_required".
    _authToken = widget.playerToken;
    if (_authToken == null || _authToken!.isEmpty) {
      _authToken = await _secureStorage.read(key: 'jwt_token');
    }

    // Session ID can stay in secure storage too for consistency
    _sessionId = await _secureStorage.read(key: 'ai_session_id');
    if (_sessionId == null || _sessionId!.isEmpty) {
      _sessionId = 'sporta_${DateTime.now().millisecondsSinceEpoch}';
      await _secureStorage.write(key: 'ai_session_id', value: _sessionId!);
    }

    debugPrint('[AiAssistant] token=${_authToken != null ? "present" : "null"}, session=$_sessionId');

    if (_authToken != null) await _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (_sessionId == null) return;
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.aiHistory(_sessionId!)),
        headers: {
          'Content-Type': 'application/json',
          if (_authToken != null) 'Authorization': 'Bearer $_authToken',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final List history = data['data'] as List? ?? [];
        if (history.isNotEmpty && mounted) {
          setState(() {
            _messages.clear();
            for (final entry in history) {
              _messages.add(ChatMessage(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                content: entry['question'] as String? ?? '',
                isUser: true,
                timestamp: DateTime.parse(entry['createdAt'] as String),
              ));
              _messages.add(ChatMessage(
                id: '${DateTime.now().millisecondsSinceEpoch}_r',
                content: entry['answer'] as String? ?? '',
                isUser: false,
                timestamp: DateTime.parse(entry['createdAt'] as String),
                contextType: entry['contextType'] as String?,
              ));
            }
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('[AiAssistant] Load history error: $e');
    }
  }

  void _addWelcomeMessage() {
    if (_messages.isEmpty) {
      _messages.add(ChatMessage(
        id: 'welcome',
        content: 'Hey there! 👋 I\'m **SportaAI** — your personal sports assistant.\n\n'
            'I can help you find venues, check availability, compare prices, book courts, and connect with teammates.\n\n'
            'What\'s on your agenda today?',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;
    HapticFeedback.lightImpact();

    // Refresh token just before sending — handles the case where the widget
    // was built before _initSession finished
    if (_authToken == null || _authToken!.isEmpty) {
      _authToken = widget.playerToken ?? await _secureStorage.read(key: 'jwt_token');
      debugPrint('[AiAssistant] token refreshed before send: ${_authToken != null ? "present" : "null"}');
    }

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() => _isTyping = true);

    try {
      final response = await _callAIApi(text);
      if (mounted) {
        setState(() {
          _isTyping = false;
          _isLoading = false;
          _messages.add(ChatMessage(
            id: '${DateTime.now().millisecondsSinceEpoch}_r',
            content: response.reply,
            isUser: false,
            timestamp: DateTime.now(),
            intent: response.intent,
            contextType: response.contextType,
            bookingData: response.bookingData,
          ));
        });
        _scrollToBottom();

        if (response.contextType == 'booking_created' && response.bookingData != null) {
          _showBookingSuccessDialog(response.bookingData!);
        } else if (response.contextType == 'booking_cancelled' && response.bookingData != null) {
          _showBookingCancelledDialog(response.bookingData!);
        } else if (response.contextType == 'auth_required') {
          _showLoginRequiredDialog();
        }
      }
    } catch (e) {
      debugPrint('[AiAssistant] send error: $e');
      if (mounted) {
        setState(() {
          _isTyping = false;
          _isLoading = false;
          _messages.add(ChatMessage(
            id: '${DateTime.now().millisecondsSinceEpoch}_err',
            content: '❌ Connection issue. Please check your network and try again.',
            isUser: false,
            timestamp: DateTime.now(),
            isError: true,
          ));
        });
        _scrollToBottom();
      }
    }
  }

  Future<AIResponse> _callAIApi(String question) async {
    final response = await http.post(
      Uri.parse(ApiConstants.aiChat),
      headers: {
        'Content-Type': 'application/json',
        // ── FIX 2: always attach the token when available ──────────────────
        if (_authToken != null && _authToken!.isNotEmpty)
          'Authorization': 'Bearer $_authToken',
      },
      body: json.encode({
        'question': question,
        'sessionId': _sessionId,
      }),
    );

    debugPrint('[AiAssistant] POST ${ApiConstants.aiChat} → ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;

      // ── FIX 3: booking data lives at data['data'] when the backend returns
      // { reply, intent, contextType, data: { reference, court, … } }
      // But some responses put it one level higher. Handle both.
      Map<String, dynamic>? bookingData;
      if (data['data'] is Map) {
        bookingData = Map<String, dynamic>.from(data['data'] as Map);
      } else if (data['booking'] is Map) {
        bookingData = Map<String, dynamic>.from(data['booking'] as Map);
      }

      final contextType = data['contextType'] as String?;

      // If the backend only set intent but not contextType for bookings, derive it
      final intent = data['intent'] as String? ?? 'general';
      final resolvedContextType = contextType ??
          (intent == 'create_booking' && bookingData != null
              ? 'booking_created'
              : intent == 'cancel_booking' && bookingData != null
                  ? 'booking_cancelled'
                  : null);

      return AIResponse(
        reply: data['reply'] as String? ?? 'Could not generate a response.',
        intent: intent,
        contextType: resolvedContextType,
        usedDatabaseContext: data['usedDatabaseContext'] as bool? ?? false,
        bookingData: bookingData,
      );
    } else if (response.statusCode == 429) {
      return AIResponse(
        reply: '⏳ Service is busy. Please try again shortly.',
        intent: 'error',
        contextType: null,
        usedDatabaseContext: false,
        bookingData: null,
      );
    } else {
      throw Exception('API error ${response.statusCode}: ${response.body}');
    }
  }

  void _showBookingSuccessDialog(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF00C853), Color(0xFF69F0AE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'Booking Created!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _c900),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _BookingDetailRow(label: 'Reference', value: booking['reference']?.toString() ?? 'N/A'),
                    const SizedBox(height: 8),
                    _BookingDetailRow(label: 'Court', value: booking['court']?.toString() ?? 'N/A'),
                    const SizedBox(height: 8),
                    _BookingDetailRow(label: 'Venue', value: booking['venue']?.toString() ?? 'N/A'),
                    const SizedBox(height: 8),
                    _BookingDetailRow(
                      label: 'Date',
                      value: (booking['date']?.toString() ?? 'N/A').split('T')[0],
                    ),
                    const SizedBox(height: 8),
                    _BookingDetailRow(
                      label: 'Time',
                      value: '${booking['startTime'] ?? ''} - ${booking['endTime'] ?? ''}',
                    ),
                    const SizedBox(height: 8),
                    _BookingDetailRow(
                      label: 'Price',
                      value: '${booking['price']} DT',
                      isPrice: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12)),
                      child: const Text('Close'),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _c400,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('View My Bookings',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBookingCancelledDialog(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: Colors.red.shade50),
                child: const Icon(Icons.check_circle_outline_rounded,
                    color: Colors.red, size: 32),
              ),
              const SizedBox(height: 16),
              const Text('Booking Cancelled',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _c900)),
              const SizedBox(height: 8),
              Text(
                'Your booking ${booking['reference'] ?? ''} has been cancelled.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _c400,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('OK',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: Colors.amber.shade50),
                child: const Icon(Icons.lock_outline_rounded,
                    color: Colors.amber, size: 32),
              ),
              const SizedBox(height: 16),
              const Text('Login Required',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _c900)),
              const SizedBox(height: 8),
              const Text(
                'Please log in to make a booking.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _c400,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Login',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _clearChat() async {
    HapticFeedback.mediumImpact();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ClearConfirmSheet(
        onConfirm: () => Navigator.pop(ctx, true),
        onCancel: () => Navigator.pop(ctx, false),
      ),
    );

    if (confirmed == true && _sessionId != null) {
      try {
        await http.delete(
          Uri.parse(ApiConstants.aiClearHistory(_sessionId!)),
          headers: {
            'Content-Type': 'application/json',
            if (_authToken != null) 'Authorization': 'Bearer $_authToken',
          },
        );
      } catch (e) {
        debugPrint('[AiAssistant] Clear history error: $e');
      }
      setState(() {
        _messages.clear();
        _addWelcomeMessage();
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cSurface,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildMessageList()),
          _buildSuggestions(),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_c900, _c800, _c600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (ctx, child) =>
                        Transform.scale(scale: _pulseAnimation.value, child: child),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [_c400, _cAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                              color: _cAccent.withOpacity(0.35),
                              blurRadius: 18,
                              spreadRadius: 2),
                        ],
                      ),
                      child: const Center(
                          child: Text('🤖', style: TextStyle(fontSize: 26))),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Colors.white, _c200],
                          ).createShader(bounds),
                          child: const Text(
                            'Sporta AI',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            _LiveDot(),
                            const SizedBox(width: 6),
                            Text(
                              'Online · Ready to help',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.65),
                                  letterSpacing: 0.2),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _clearChat,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.15)),
                        color: Colors.white.withOpacity(0.07),
                      ),
                      child: const Icon(Icons.autorenew_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            CustomPaint(
              size: Size(MediaQuery.of(context).size.width, 20),
              painter: _WavePainter(color: _cSurface),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i == _messages.length && _isTyping) return _buildTypingIndicator();
        return _MessageBubble(
          message: _messages[i],
          shimmerAnimation: _shimmerAnimation,
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _AIAvatar(size: 32),
          const SizedBox(width: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: _cCard,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                    color: _c800.withOpacity(0.07),
                    blurRadius: 10,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (idx) {
                return AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (_, __) {
                    final phase =
                        (_shimmerController.value + idx * 0.2) % 1.0;
                    final scale = 0.7 + 0.3 * math.sin(phase * math.pi);
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 8 * scale,
                      height: 8 * scale,
                      decoration: BoxDecoration(
                        color: _c400.withOpacity(0.5 + 0.5 * scale),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    final show =
        _messages.isNotEmpty && !_isLoading && !_messages.last.isUser;
    if (!show) return const SizedBox.shrink();

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, idx) {
          final s = _suggestions[idx];
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _sendMessage(s.query);
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _cCard,
                borderRadius: BorderRadius.circular(30),
                border:
                    Border.all(color: _c400.withOpacity(0.3), width: 1),
                boxShadow: [
                  BoxShadow(
                      color: _c800.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s.icon, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(s.label,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _c600)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: _cCard,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: _c800.withOpacity(_inputFocused ? 0.12 : 0.06),
            blurRadius: _inputFocused ? 24 : 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding:
            EdgeInsets.fromLTRB(16, 14, 16, bottomPad + 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _inputFocused
                      ? _c900.withOpacity(0.04)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _inputFocused
                        ? _c400.withOpacity(0.5)
                        : Colors.grey.shade200,
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  minLines: 1,
                  maxLines: 5,
                  style: const TextStyle(
                      fontSize: 15, color: _c900, height: 1.4),
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) =>
                      _sendMessage(_messageController.text),
                  decoration: InputDecoration(
                    hintText: 'Ask Sporta AI anything…',
                    hintStyle: TextStyle(
                        color: Colors.grey.shade400, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.fromLTRB(18, 12, 10, 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _isLoading
                  ? null
                  : () => _sendMessage(_messageController.text),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _isLoading
                      ? const LinearGradient(
                          colors: [Colors.grey, Colors.grey])
                      : const LinearGradient(
                          colors: [_c800, _c400],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  boxShadow: [
                    if (!_isLoading)
                      BoxShadow(
                          color: _c400.withOpacity(0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 4)),
                  ],
                ),
                child: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.arrow_upward_rounded,
                        color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Booking Detail Row ───────────────────────────────────────────────────────
class _BookingDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isPrice;

  const _BookingDetailRow({
    required this.label,
    required this.value,
    this.isPrice = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey)),
        Text(value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isPrice ? _c400 : _c900,
            )),
      ],
    );
  }
}

// ─── Message Bubble ───────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final Animation<double> shimmerAnimation;

  const _MessageBubble(
      {required this.message, required this.shimmerAnimation});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final isError = message.isError == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[_AIAvatar(size: 32), const SizedBox(width: 10)],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (message.contextType != null && !isUser) ...[
                  _ContextTag(type: message.contextType!),
                  const SizedBox(height: 4),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  constraints: BoxConstraints(
                      maxWidth:
                          MediaQuery.of(context).size.width * 0.74),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? const LinearGradient(
                            colors: [_c800, _c400],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isUser
                        ? null
                        : (isError
                            ? const Color(0xFFFFF1F1)
                            : _cCard),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isUser ? _c800 : Colors.black)
                            .withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: isUser
                        ? null
                        : Border.all(
                            color: isError
                                ? Colors.red.withOpacity(0.15)
                                : Colors.grey.shade100,
                            width: 1,
                          ),
                  ),
                  child: SelectableText(
                    message.content,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.55,
                      color: isUser
                          ? Colors.white
                          : (isError
                              ? Colors.red.shade700
                              : const Color(0xFF1A2A2A)),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    _fmtTime(message.timestamp),
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade400,
                        letterSpacing: 0.3),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 10),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [
                  _c400.withOpacity(0.2),
                  _c200.withOpacity(0.3)
                ]),
                border: Border.all(color: _c400.withOpacity(0.3)),
              ),
              child: const Icon(Icons.person_rounded,
                  color: _c600, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  String _fmtTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

// ─── Context Tag ──────────────────────────────────────────────────────────────
class _ContextTag extends StatelessWidget {
  final String type;
  const _ContextTag({required this.type});

  static const _map = {
    'venues_list': ('📋', 'Venues found'),
    'availability': ('📅', 'Availability'),
    'my_bookings': ('📋', 'Your bookings'),
    'price_info': ('💰', 'Pricing'),
    'recommendations': ('⭐', 'Picks for you'),
    'booking_created': ('✅', 'Booking confirmed'),
    'booking_cancelled': ('❌', 'Booking cancelled'),
  };

  @override
  Widget build(BuildContext context) {
    final entry = _map[type] ?? ('ℹ️', 'Info');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          _c400.withOpacity(0.12),
          _c200.withOpacity(0.08)
        ]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _c400.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(entry.$1, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(entry.$2,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _c600)),
        ],
      ),
    );
  }
}

// ─── AI Avatar ────────────────────────────────────────────────────────────────
class _AIAvatar extends StatelessWidget {
  final double size;
  const _AIAvatar({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [_c800, _c400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
          child: Text('🤖',
              style: TextStyle(fontSize: size * 0.5))),
    );
  }
}

// ─── Live Dot ─────────────────────────────────────────────────────────────────
class _LiveDot extends StatefulWidget {
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _a = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (_, __) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.greenAccent.shade400.withOpacity(_a.value),
          boxShadow: [
            BoxShadow(
                color: Colors.greenAccent.withOpacity(0.4 * _a.value),
                blurRadius: 5)
          ],
        ),
      ),
    );
  }
}

// ─── Wave Painter ─────────────────────────────────────────────────────────────
class _WavePainter extends CustomPainter {
  final Color color;
  _WavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(
          size.width * 0.25, 0, size.width * 0.5, size.height * 0.5)
      ..quadraticBezierTo(
          size.width * 0.75, size.height, size.width, size.height * 0.3)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.color != color;
}

// ─── Clear Confirm Sheet ──────────────────────────────────────────────────────
class _ClearConfirmSheet extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  const _ClearConfirmSheet(
      {required this.onConfirm, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: _c800.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, -4))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 5,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10)),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: Colors.red.shade50),
            child: const Icon(Icons.delete_sweep_rounded,
                color: Colors.red, size: 32),
          ),
          const SizedBox(height: 16),
          const Text(
            'Clear conversation?',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _c900,
                letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'All messages will be permanently deleted.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13.5, color: Colors.grey.shade500, height: 1.5),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onCancel,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.grey.shade100),
                    child: const Center(
                        child: Text('Cancel',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.black87))),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: onConfirm,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Colors.red, Color(0xFFFF6B6B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: const Center(
                        child: Text('Clear',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.white))),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Models ───────────────────────────────────────────────────────────────────
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? contextType;
  final String? intent;
  final bool? isError;
  final Map<String, dynamic>? bookingData;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.contextType,
    this.intent,
    this.isError,
    this.bookingData,
  });
}

class AIResponse {
  final String reply;
  final String intent;
  final String? contextType;
  final bool usedDatabaseContext;
  final Map<String, dynamic>? bookingData;

  AIResponse({
    required this.reply,
    required this.intent,
    this.contextType,
    required this.usedDatabaseContext,
    this.bookingData,
  });
}

class SuggestionChip {
  final String icon;
  final String label;
  final String query;
  SuggestionChip(
      {required this.icon, required this.label, required this.query});
}

















/*// lib/views/player/ai_assistant.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sporta/Core/Constants/api_constants.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// ─── Color Palette ────────────────────────────────────────────────────────────
const _c900 = Color(0xFF001A1B);
const _c800 = Color(0xFF002B2C);
const _c600 = Color(0xFF006B6C);
const _c400 = Color(0xFF009999);
const _c200 = Color(0xFF4DD9D9);
const _cAccent = Color(0xFF00F0F0);
const _cSurface = Color(0xFFF0F7F7);
const _cCard = Color(0xFFFFFFFF);

class AiAssistant extends StatefulWidget {
  const AiAssistant({super.key});

  @override
  State<AiAssistant> createState() => _AiAssistantState();
}

class _AiAssistantState extends State<AiAssistant> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isTyping = false;
  String? _sessionId;
  String? _authToken;
  bool _inputFocused = false;

  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _fabController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _fabAnimation;

  final List<SuggestionChip> _suggestions = [
    SuggestionChip(icon: '⚽', label: 'Football courts', query: 'Find football courts near me'),
    SuggestionChip(icon: '🎾', label: 'Padel nearby', query: 'Find padel courts'),
    SuggestionChip(icon: '📅', label: 'Availability', query: 'Check court availability for tomorrow'),
    SuggestionChip(icon: '💰', label: 'Prices', query: 'What are the prices for football courts?'),
    SuggestionChip(icon: '👥', label: 'Find teammates', query: 'I need teammates for a match'),
    SuggestionChip(icon: '🏆', label: 'My bookings', query: 'Show my bookings'),
    SuggestionChip(icon: '📍', label: 'Near me', query: 'Venues near me'),
    SuggestionChip(icon: '⭐', label: 'Best rated', query: 'Recommend the best venues'),
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initSession();
    _addWelcomeMessage();

    _focusNode.addListener(() {
      setState(() => _inputFocused = _focusNode.hasFocus);
    });
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _fabAnimation = CurvedAnimation(parent: _fabController, curve: Curves.elasticOut);

    _messageController.addListener(() {
      if (_messageController.text.isNotEmpty) {
        _fabController.forward();
      } else {
        _fabController.reverse();
      }
    });
  }

  Future<void> _initSession() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    _sessionId = prefs.getString('ai_session_id');
    if (_sessionId == null) {
      _sessionId = 'sporta_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString('ai_session_id', _sessionId!);
    }
    if (_authToken != null) await _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (_sessionId == null) return;
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.aiHistory(_sessionId!)),
        headers: {
          'Content-Type': 'application/json',
          if (_authToken != null) 'Authorization': 'Bearer $_authToken',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List history = data['data'] ?? [];
        if (history.isNotEmpty && mounted) {
          setState(() {
            _messages.clear();
            for (var entry in history) {
              _messages.add(ChatMessage(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                content: entry['question'],
                isUser: true,
                timestamp: DateTime.parse(entry['createdAt']),
              ));
              _messages.add(ChatMessage(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                content: entry['answer'],
                isUser: false,
                timestamp: DateTime.parse(entry['createdAt']),
                contextType: entry['contextType'],
              ));
            }
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('Load history error: $e');
    }
  }

  void _addWelcomeMessage() {
    if (_messages.isEmpty) {
      _messages.add(ChatMessage(
        id: 'welcome',
        content:
            'Hey there! 👋 I\'m **SportaAI** — your personal sports assistant.\n\n'
            'I can help you find venues, check availability, compare prices, book courts, and connect with teammates.\n\n'
            'What\'s on your agenda today?',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;
    HapticFeedback.lightImpact();

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() => _isTyping = true);

    try {
      final response = await _callAIApi(text);
      if (mounted) {
        setState(() {
          _isTyping = false;
          _isLoading = false;
          _messages.add(ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: response.reply,
            isUser: false,
            timestamp: DateTime.now(),
            intent: response.intent,
            contextType: response.contextType,
          ));
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _isLoading = false;
          _messages.add(ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: '❌ Connection issue. Please check your network and try again.',
            isUser: false,
            timestamp: DateTime.now(),
            isError: true,
          ));
        });
        _scrollToBottom();
      }
    }
  }

  Future<AIResponse> _callAIApi(String question) async {
    final response = await http.post(
      Uri.parse(ApiConstants.aiChat),
      headers: {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      },
      body: json.encode({'question': question, 'sessionId': _sessionId}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return AIResponse(
        reply: data['reply'] ?? 'Could not generate a response.',
        intent: data['intent'] ?? 'general',
        contextType: data['contextType'],
        usedDatabaseContext: data['usedDatabaseContext'] ?? false,
      );
    } else if (response.statusCode == 429) {
      return AIResponse(
        reply: '⏳ Service is busy. Please try again shortly.',
        intent: 'error',
        contextType: null,
        usedDatabaseContext: false,
      );
    } else {
      throw Exception('API error ${response.statusCode}');
    }
  }

  Future<void> _clearChat() async {
    HapticFeedback.mediumImpact();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ClearConfirmSheet(onConfirm: () => Navigator.pop(ctx, true), onCancel: () => Navigator.pop(ctx, false)),
    );

    if (confirmed == true && _sessionId != null) {
      try {
        await http.delete(
          Uri.parse(ApiConstants.aiClearHistory(_sessionId!)),
          headers: {
            'Content-Type': 'application/json',
            if (_authToken != null) 'Authorization': 'Bearer $_authToken',
          },
        );
      } catch (e) {
        debugPrint('Clear history error: $e');
      }
      setState(() {
        _messages.clear();
        _addWelcomeMessage();
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cSurface,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildMessageList()),
          _buildSuggestions(),
          _buildInputBar(),
        ],
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_c900, _c800, _c600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  // AI Avatar with pulse
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (ctx, child) => Transform.scale(
                      scale: _pulseAnimation.value,
                      child: child,
                    ),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [_c400, _cAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(color: _cAccent.withOpacity(0.35), blurRadius: 18, spreadRadius: 2),
                        ],
                      ),
                      child: const Center(child: Text('🤖', style: TextStyle(fontSize: 26))),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Colors.white, _c200],
                          ).createShader(bounds),
                          child: const Text(
                            'Sporta AI',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            _LiveDot(),
                            const SizedBox(width: 6),
                            Text(
                              'Online · Ready to help',
                              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.65), letterSpacing: 0.2),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Clear button — minimal icon
                  GestureDetector(
                    onTap: _clearChat,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.15)),
                        color: Colors.white.withOpacity(0.07),
                      ),
                      child: const Icon(Icons.autorenew_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Divider wave
            CustomPaint(
              size: Size(MediaQuery.of(context).size.width, 20),
              painter: _WavePainter(color: _cSurface),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Message List ──────────────────────────────────────────────────────────
  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i == _messages.length && _isTyping) return _buildTypingIndicator();
        return _MessageBubble(
          message: _messages[i],
          shimmerAnimation: _shimmerAnimation,
        );
      },
    );
  }

  // ─── Typing indicator ──────────────────────────────────────────────────────
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _AIAvatar(size: 32),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: _cCard,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(color: _c800.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (idx) {
                return AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (_, __) {
                    final phase = (_shimmerController.value + idx * 0.2) % 1.0;
                    final scale = 0.7 + 0.3 * math.sin(phase * math.pi);
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 8 * scale,
                      height: 8 * scale,
                      decoration: BoxDecoration(
                        color: _c400.withOpacity(0.5 + 0.5 * scale),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Suggestions ──────────────────────────────────────────────────────────
  Widget _buildSuggestions() {
    final show = _messages.isNotEmpty && !_isLoading && !_messages.last.isUser;
    if (!show) return const SizedBox.shrink();

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, idx) {
          final s = _suggestions[idx];
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _sendMessage(s.query);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _cCard,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: _c400.withOpacity(0.3), width: 1),
                boxShadow: [
                  BoxShadow(color: _c800.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s.icon, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(
                    s.label,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _c600),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Input Bar ─────────────────────────────────────────────────────────────
  Widget _buildInputBar() {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: _cCard,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: _c800.withOpacity(_inputFocused ? 0.12 : 0.06),
            blurRadius: _inputFocused ? 24 : 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 14, 16, bottomPad + 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _inputFocused ? _c900.withOpacity(0.04) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _inputFocused ? _c400.withOpacity(0.5) : Colors.grey.shade200,
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  minLines: 1,
                  maxLines: 5,
                  style: const TextStyle(fontSize: 15, color: _c900, height: 1.4),
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(_messageController.text),
                  decoration: InputDecoration(
                    hintText: 'Ask Sporta AI anything…',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.fromLTRB(18, 12, 10, 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Send button
            GestureDetector(
              onTap: _isLoading ? null : () => _sendMessage(_messageController.text),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _isLoading
                      ? const LinearGradient(colors: [Colors.grey, Colors.grey])
                      : const LinearGradient(
                          colors: [_c800, _c400],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  boxShadow: [
                    if (!_isLoading)
                      BoxShadow(color: _c400.withOpacity(0.4), blurRadius: 14, offset: const Offset(0, 4)),
                  ],
                ),
                child: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

// ─── Message Bubble Widget ────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final Animation<double> shimmerAnimation;

  const _MessageBubble({required this.message, required this.shimmerAnimation});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final isError = message.isError == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _AIAvatar(size: 32),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Context tag
                if (message.contextType != null && !isUser) ...[
                  _ContextTag(type: message.contextType!),
                  const SizedBox(height: 4),
                ],
                // Bubble
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? const LinearGradient(
                            colors: [_c800, _c400],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isUser
                        ? null
                        : (isError ? const Color(0xFFFFF1F1) : _cCard),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isUser ? _c800 : Colors.black).withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: isUser
                        ? null
                        : Border.all(
                            color: isError ? Colors.red.withOpacity(0.15) : Colors.grey.shade100,
                            width: 1,
                          ),
                  ),
                  child: SelectableText(
                    message.content,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.55,
                      color: isUser
                          ? Colors.white
                          : (isError ? Colors.red.shade700 : const Color(0xFF1A2A2A)),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    _fmtTime(message.timestamp),
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade400, letterSpacing: 0.3),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 10),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [_c400.withOpacity(0.2), _c200.withOpacity(0.3)],
                ),
                border: Border.all(color: _c400.withOpacity(0.3)),
              ),
              child: const Icon(Icons.person_rounded, color: _c600, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  String _fmtTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

// ─── Context Tag ──────────────────────────────────────────────────────────────
class _ContextTag extends StatelessWidget {
  final String type;
  const _ContextTag({required this.type});

  static const _map = {
    'venues_list': ('📋', 'Venues found'),
    'availability_found': ('📅', 'Availability'),
    'my_bookings': ('📋', 'Your bookings'),
    'price_info': ('💰', 'Pricing'),
    'recommendations': ('⭐', 'Picks for you'),
    'booking_created': ('✅', 'Booking confirmed'),
    'booking_cancelled': ('❌', 'Booking cancelled'),
  };

  @override
  Widget build(BuildContext context) {
    final entry = _map[type] ?? ('ℹ️', 'Info');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_c400.withOpacity(0.12), _c200.withOpacity(0.08)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _c400.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(entry.$1, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(entry.$2, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _c600)),
        ],
      ),
    );
  }
}

// ─── AI Avatar ────────────────────────────────────────────────────────────────
class _AIAvatar extends StatelessWidget {
  final double size;
  const _AIAvatar({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [_c800, _c400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(child: Text('🤖', style: TextStyle(fontSize: size * 0.5))),
    );
  }
}

// ─── Live Dot ─────────────────────────────────────────────────────────────────
class _LiveDot extends StatefulWidget {
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _a = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (_, __) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.greenAccent.shade400.withOpacity(_a.value),
          boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.4 * _a.value), blurRadius: 5)],
        ),
      ),
    );
  }
}

// ─── Wave Painter ─────────────────────────────────────────────────────────────
class _WavePainter extends CustomPainter {
  final Color color;
  _WavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(size.width * 0.25, 0, size.width * 0.5, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.75, size.height, size.width, size.height * 0.3)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.color != color;
}

// ─── Clear Confirm Bottom Sheet ───────────────────────────────────────────────
class _ClearConfirmSheet extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _ClearConfirmSheet({required this.onConfirm, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: _c800.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 5,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.shade50,
            ),
            child: const Icon(Icons.delete_sweep_rounded, color: Colors.red, size: 32),
          ),
          const SizedBox(height: 16),
          const Text(
            'Clear conversation?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _c900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'All messages will be permanently deleted.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: Colors.grey.shade500, height: 1.5),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onCancel,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.grey.shade100,
                    ),
                    child: const Center(
                      child: Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: onConfirm,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Colors.red, Color(0xFFFF6B6B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: const Center(
                      child: Text('Clear', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Models ───────────────────────────────────────────────────────────────────
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? contextType;
  final String? intent;
  final bool? isError;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.contextType,
    this.intent,
    this.isError,
  });
}

class AIResponse {
  final String reply;
  final String intent;
  final String? contextType;
  final bool usedDatabaseContext;

  AIResponse({
    required this.reply,
    required this.intent,
    this.contextType,
    required this.usedDatabaseContext,
  });
}

class SuggestionChip {
  final String icon;
  final String label;
  final String query;

  SuggestionChip({required this.icon, required this.label, required this.query});
}*/







//*************************************** */












/*// lib/views/player/ai_assistant.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sporta/Core/Constants/api_constants.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AiAssistant extends StatefulWidget {
  const AiAssistant({super.key});

  @override
  State<AiAssistant> createState() => _AiAssistantState();
}

class _AiAssistantState extends State<AiAssistant> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isTyping = false;
  String? _sessionId;
  String? _authToken;
  
  late AnimationController _typingAnimationController;
  late Animation<double> _fadeAnimation;

  final List<SuggestionChip> _suggestions = [
    SuggestionChip(icon: '⚽', label: 'Find football courts', query: 'Find football courts near me'),
    SuggestionChip(icon: '🎾', label: 'Padel courts nearby', query: 'Find padel courts'),
    SuggestionChip(icon: '📅', label: 'Check availability', query: 'Check court availability for tomorrow'),
    SuggestionChip(icon: '💰', label: 'Price comparison', query: 'What are the prices for football courts?'),
    SuggestionChip(icon: '👥', label: 'Find teammates', query: 'I need teammates for a match'),
    SuggestionChip(icon: '🏆', label: 'My bookings', query: 'Show my bookings'),
    SuggestionChip(icon: '📍', label: 'Near me', query: 'Venues near me'),
    SuggestionChip(icon: '⭐', label: 'Best rated', query: 'Recommend the best venues'),
  ];

  @override
  void initState() {
    super.initState();
    _initSession();
    _initAnimations();
    _addWelcomeMessage();
  }

  void _initAnimations() {
    _typingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    
    _fadeAnimation = CurvedAnimation(
      parent: _typingAnimationController,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _initSession() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    
    // Load or create session ID
    _sessionId = prefs.getString('ai_session_id');
    if (_sessionId == null) {
      _sessionId = 'sporta_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
      await prefs.setString('ai_session_id', _sessionId!);
    }
    
    // Load history if authenticated
    if (_authToken != null) {
      await _loadHistory();
    }
  }

  Future<void> _loadHistory() async {
    if (_sessionId == null) return;
    
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.aiHistory(_sessionId!)),
        headers: {
          'Content-Type': 'application/json',
          if (_authToken != null) 'Authorization': 'Bearer $_authToken',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List history = data['data'] ?? [];
        
        if (history.isNotEmpty && mounted) {
          setState(() {
            _messages.clear();
            for (var entry in history) {
              _messages.add(ChatMessage(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                content: entry['question'],
                isUser: true,
                timestamp: DateTime.parse(entry['createdAt']),
              ));
              _messages.add(ChatMessage(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                content: entry['answer'],
                isUser: false,
                timestamp: DateTime.parse(entry['createdAt']),
                contextType: entry['contextType'],
              ));
            }
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('Load history error: $e');
    }
  }

  void _addWelcomeMessage() {
    if (_messages.isEmpty) {
      _messages.add(ChatMessage(
        id: 'welcome',
        content: '👋 **Hello! I\'m SportaAI** — your personal sports assistant.\n\n'
            'I can help you with:\n\n'
            '⚽ **Find venues** — Search for football, padel, tennis, or basketball courts\n'
            '📅 **Check availability** — See open time slots\n'
            '💰 **Compare prices** — Find the best deals\n'
            '🎯 **Book courts** — Make reservations instantly\n'
            '👥 **Find teammates** — Connect with other players\n'
            '📋 **View bookings** — Check your upcoming matches\n\n'
            '**How can I help you today?**',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;
    
    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });
    
    _messageController.clear();
    _scrollToBottom();
    
    // Show typing indicator
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() {
        _isTyping = true;
      });
    }
    
    try {
      // Call the REAL AI API that queries your database
      final response = await _callAIApi(text);
      
      if (mounted) {
        setState(() {
          _isTyping = false;
          _isLoading = false;
          _messages.add(ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: response.reply,
            isUser: false,
            timestamp: DateTime.now(),
            intent: response.intent,
            contextType: response.contextType,
          ));
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('AI API error: $e');
      if (mounted) {
        setState(() {
          _isTyping = false;
          _isLoading = false;
          _messages.add(ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: '❌ Sorry, I\'m having trouble connecting to the AI service. Please check your connection and try again.',
            isUser: false,
            timestamp: DateTime.now(),
            isError: true,
          ));
        });
        _scrollToBottom();
      }
    }
  }

  Future<AIResponse> _callAIApi(String question) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.aiChat),
        headers: {
          'Content-Type': 'application/json',
          if (_authToken != null) 'Authorization': 'Bearer $_authToken',
        },
        body: json.encode({
          'question': question,
          'sessionId': _sessionId,
        }),
      );
      
      debugPrint('AI API Response Status: ${response.statusCode}');
      debugPrint('AI API Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AIResponse(
          reply: data['reply'] ?? 'I received your message but couldn\'t generate a proper response.',
          intent: data['intent'] ?? 'general',
          contextType: data['contextType'],
          usedDatabaseContext: data['usedDatabaseContext'] ?? false,
        );
      } else if (response.statusCode == 429) {
        return AIResponse(
          reply: '⏳ The AI service is busy right now. Please try again in a moment.',
          intent: 'error',
          contextType: null,
          usedDatabaseContext: false,
        );
      } else {
        final errorData = json.decode(response.body);
        return AIResponse(
          reply: '❌ Error: ${errorData['error']?['message'] ?? 'Failed to get AI response'}',
          intent: 'error',
          contextType: null,
          usedDatabaseContext: false,
        );
      }
    } catch (e) {
      debugPrint('AI API exception: $e');
      rethrow;
    }
  }

  Future<void> _clearChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to clear all conversation history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed == true && _sessionId != null) {
      try {
        await http.delete(
          Uri.parse(ApiConstants.aiClearHistory(_sessionId!)),
          headers: {
            'Content-Type': 'application/json',
            if (_authToken != null) 'Authorization': 'Bearer $_authToken',
          },
        );
      } catch (e) {
        debugPrint('Clear history error: $e');
      }
      
      setState(() {
        _messages.clear();
        _addWelcomeMessage();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chat history cleared'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _messages.isEmpty && !_isLoading
                ? _buildEmptyState()
                : _buildMessageList(),
          ),
          _buildSuggestions(),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF002B2C), Color(0xFF006B6C), Color(0xFF009999)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.white, Color(0xFFE0F7FA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🤖', style: TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sporta AI Assistant',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        AnimatedBuilder(
                          animation: _fadeAnimation,
                          builder: (context, child) {
                            return Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.green.shade300,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.shade300.withOpacity(0.5),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Online · Powered by AI',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                  onPressed: _clearChat,
                  tooltip: 'Clear chat',
                  iconSize: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🏃', style: TextStyle(fontSize: 64)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome to Sporta AI!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your personal sports assistant\nAsk me anything about sports venues!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isTyping) {
          return _buildTypingIndicator();
        }
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    final isError = message.isError == true;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF002B2C), Color(0xFF009999)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🤖', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (message.contextType != null && !isUser)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: kPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _formatContextType(message.contextType!),
                        style: TextStyle(
                          fontSize: 10,
                          color: kPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? kPrimary
                        : (isError ? Colors.red.shade50 : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SelectableText(
                    message.content,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: isUser ? Colors.white : (isError ? Colors.red.shade700 : Colors.grey.shade900),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 10),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_rounded,
                color: kPrimary,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatContextType(String type) {
    switch (type) {
      case 'venues_list':
        return '📋 Venues found';
      case 'availability_found':
        return '📅 Availability check';
      case 'my_bookings':
        return '📋 Your bookings';
      case 'price_info':
        return '💰 Price information';
      case 'recommendations':
        return '⭐ Recommendations';
      case 'booking_created':
        return '✅ Booking confirmed';
      case 'booking_cancelled':
        return '❌ Booking cancelled';
      default:
        return 'ℹ️ Information';
    }
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF002B2C), Color(0xFF009999)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🤖', style: TextStyle(fontSize: 18)),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _typingAnimationController,
                  builder: (context, child) {
                    final value = (_typingAnimationController.value + index * 0.2) % 1.0;
                    final opacity = value > 0.5 ? 1.0 : 0.3;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: kPrimary.withOpacity(opacity),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    if (_messages.isNotEmpty && !_isLoading && !_messages.last.isUser) {
      return Container(
        height: 50,
        margin: const EdgeInsets.only(bottom: 8),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _suggestions.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, index) {
            final suggestion = _suggestions[index];
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.grey.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: kPrimary.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _sendMessage(suggestion.query),
                  borderRadius: BorderRadius.circular(30),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Text(suggestion.icon, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          suggestion.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: kPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildInputBar() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding + 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _messageController,
                    focusNode: _focusNode,
                    minLines: 1,
                    maxLines: 5,
                    style: const TextStyle(fontSize: 15),
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(_messageController.text),
                    decoration: InputDecoration(
                      hintText: 'Ask Sporta AI anything...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading ? null : () => _sendMessage(_messageController.text),
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: _isLoading
                            ? const LinearGradient(colors: [Colors.grey, Colors.grey])
                            : const LinearGradient(
                                colors: [Color(0xFF002B2C), Color(0xFF009999)],
                              ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          if (!_isLoading)
                            BoxShadow(
                              color: kPrimary.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
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

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

// Models
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? contextType;
  final String? intent;
  final bool? isError;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.contextType,
    this.intent,
    this.isError,
  });
}

class AIResponse {
  final String reply;
  final String intent;
  final String? contextType;
  final bool usedDatabaseContext;

  AIResponse({
    required this.reply,
    required this.intent,
    this.contextType,
    required this.usedDatabaseContext,
  });
}

class SuggestionChip {
  final String icon;
  final String label;
  final String query;

  SuggestionChip({
    required this.icon,
    required this.label,
    required this.query,
  });
}*/