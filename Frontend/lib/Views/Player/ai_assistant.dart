import 'package:flutter/material.dart';

class AiAssistant extends StatefulWidget {
  const AiAssistant({super.key});

  @override
  State<AiAssistant> createState() => _AiAssistantState();
}

class _AiAssistantState extends State<AiAssistant>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Chat messages list: {text, isUser, time}
  final List<Map<String, dynamic>> _messages = [
    {
      'text':
          "Hi! I'm Sporta AI 🤖\nHow can I help you today? I can help you find courts, book matches, or answer any sports questions!",
      'isUser': false,
      'time': '10:00',
    },
  ];

  bool _isTyping = false;

  // Quick suggestion chips
  final List<String> _suggestions = [
    '⚽  Find a football court',
    '📅  Book a match',
    '👥  Find teammates',
    '🎾  Padel courts near me',
  ];

  late AnimationController _typingController;

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'text': text.trim(),
        'isUser': true,
        'time': _currentTime(),
      });
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Simulate AI response after delay
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add({
          'text': _getAiResponse(text),
          'isUser': false,
          'time': _currentTime(),
        });
      });
      _scrollToBottom();
    });
  }

  // Simple mock AI responses — nhar e5er nwaslouha bel backend
  String _getAiResponse(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('football') || lower.contains('foot')) {
      return "Great choice! ⚽ I found 3 football courts available near you:\n\n• Arena Sport Center — 20 DT/hr\n• Green Field Complex — 15 DT/hr\n• City Foot Arena — 18 DT/hr\n\nWant me to book one?";
    } else if (lower.contains('padel')) {
      return "🎾 Here are the best padel courts near you:\n\n• Padel Club Marsa — 25 DT/hr\n• Padel Paradise — 22 DT/hr\n\nAll courts are available this evening!";
    } else if (lower.contains('book') || lower.contains('reserve')) {
      return "Sure! 📅 Tell me:\n1. Which sport?\n2. What date & time?\n3. How many players?\n\nAnd I'll find the best available courts for you!";
    } else if (lower.contains('team') || lower.contains('teammate')) {
      return "👥 Looking for teammates? I can help!\n\nThere are 12 players in your area looking for a match this week. Want me to connect you with them?";
    } else {
      return "I'm here to help! 🏆 You can ask me to:\n• Find & book courts\n• Connect with players\n• Check your upcoming matches\n• Get sports tips\n\nWhat would you like to do?";
    }
  }

  String _currentTime() {
    final now = TimeOfDay.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    return '$h:$m';
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: Column(
        children: [
          //  Header
          _buildHeader(),

          //  Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                // Typing indicator bubble
                if (index == _messages.length) {
                  return _buildTypingIndicator();
                }
                final msg = _messages[index];
                return _buildMessageBubble(
                  text: msg['text'],
                  isUser: msg['isUser'],
                  time: msg['time'],
                );
              },
            ),
          ),

          //  Suggestion chips (only when no messages sent yet) ───
          if (_messages.length == 1) _buildSuggestions(),

          //  Input bar
          _buildInputBar(),
        ],
      ),
    );
  }

  //  Header
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF003D3E), Color(0xFF005D5E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Row(
            children: [
              // AI Avatar
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white38, width: 1.5),
                ),
                child: const Center(
                  child: Text('🤖', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),

              // Name + status
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sporta AI',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 4,
                          backgroundColor: Color(0xFF4ADE80),
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Online • Always here to help',
                          style: TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Clear chat button
              IconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Colors.white70,
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    _messages.removeRange(1, _messages.length);
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  //  Message bubble
  Widget _buildMessageBubble({
    required String text,
    required bool isUser,
    required String time,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // AI avatar
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF005D5E).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🤖', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Bubble
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFF005D5E) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isUser ? Colors.white : const Color(0xFF0D0D0D),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),

          // User avatar
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF005D5E).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Color(0xFF005D5E),
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  //  Typing indicator
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF005D5E).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🤖', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _typingController,
              builder: (_, __) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final delay = i * 0.2;
                    final opacity =
                        (((_typingController.value + delay) % 1.0) > 0.5)
                        ? 1.0
                        : 0.3;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(0, 93, 94, opacity),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  //  Suggestion chips
  Widget _buildSuggestions() {
    return Container(
      height: 46,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          return GestureDetector(
            onTap: () => _sendMessage(_suggestions[i]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF005D5E).withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                _suggestions[i],
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF005D5E),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  //  Input bar
  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.of(context).padding.bottom + 76,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Text input
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 46),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(26),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                minLines: 1,
                style: const TextStyle(fontSize: 14, color: Color(0xFF0D1117)),
                decoration: const InputDecoration(
                  hintText: 'Ask Sporta AI anything...',
                  hintStyle: TextStyle(color: Color(0xFFB0B7C3), fontSize: 14),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                onSubmitted: _sendMessage,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Send button
          GestureDetector(
            onTap: () => _sendMessage(_messageController.text),
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF003D3E), Color(0xFF005D5E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
