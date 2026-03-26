// ai_assistant.dart — Views/Player/ai_assistant.dart
// Light premium design: clean white, teal gradient header, soft bubbles

import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';

class AiAssistant extends StatefulWidget {
  const AiAssistant({super.key});
  @override
  State<AiAssistant> createState() => _AiAssistantState();
}

class _AiAssistantState extends State<AiAssistant>
    with TickerProviderStateMixin {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isTyping = false;
  bool _hasInteracted = false;

  final List<Map<String, dynamic>> _messages = [
    {
      'text':
          'Hi! I\'m Sporta AI 🤖\nHow can I help you today? I can help you find courts, book sessions, or connect you with teammates!',
      'isUser': false,
      'time': '10:00',
    },
  ];

  final List<Map<String, dynamic>> _suggestions = [
    {'icon': '⚽', 'label': 'Find a football court'},
    {'icon': '📅', 'label': 'Book a session'},
    {'icon': '👥', 'label': 'Find teammates'},
    {'icon': '🎾', 'label': 'Padel courts nearby'},
  ];

  late AnimationController _typingCtrl;

  @override
  void initState() {
    super.initState();
    _typingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _typingCtrl.dispose();
    super.dispose();
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add({'text': text.trim(), 'isUser': true, 'time': _now()});
      _isTyping = true;
      _hasInteracted = true;
    });
    _msgCtrl.clear();
    _scrollToBottom();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add({
          'text': _respond(text),
          'isUser': false,
          'time': _now(),
        });
      });
      _scrollToBottom();
    });
  }

  String _respond(String input) {
    final l = input.toLowerCase();
    if (l.contains('football') || l.contains('foot'))
      return '⚽ Found 3 football courts near you:\n\n• Arena Sport Center — 90 DT\n• Green Field Complex — 80 DT\n• City Foot Arena — 85 DT\n\nWant me to book one?';
    if (l.contains('padel'))
      return '🎾 Top padel courts nearby:\n\n• Padel Club Marsa — 120 DT\n• Padel Paradise — 110 DT\n\nBoth have slots available tonight!';
    if (l.contains('book') || l.contains('reserv'))
      return '📅 Sure! Tell me:\n1. Which sport?\n2. Date & time?\n3. Number of players?\n\nAnd I\'ll find the best options for you.';
    if (l.contains('team') || l.contains('teammate') || l.contains('player'))
      return '👥 Looking for teammates?\n\nThere are 8 players near you searching for a match this week. Want me to connect you?';
    if (l.contains('basketball'))
      return '🏀 Basketball courts near you:\n\n• City Basketball Arena — 75 DT\n• Indoor with AC\n\nShall I check availability?';
    if (l.contains('tennis'))
      return '🎾 Tennis courts nearby:\n\n• Tennis Academy Tunis — 105 DT\n• 2 courts available today\n\nWant to book a slot?';
    return '🏆 I can help you with:\n• Finding & booking courts\n• Connecting with players\n• Checking your schedule\n• Tournament info\n\nWhat would you like to do?';
  }

  String _now() {
    final t = TimeOfDay.now();
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bot = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _messages.length) return _buildTypingBubble();
                final m = _messages[i];
                return _buildBubble(
                  text: m['text'],
                  isUser: m['isUser'],
                  time: m['time'],
                );
              },
            ),
          ),

          if (!_hasInteracted) _buildSuggestions(),

          // Input bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 16,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            padding: EdgeInsets.fromLTRB(16, 12, 16, bot + 76),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 50),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 6,
                    ),
                    child: TextField(
                      controller: _msgCtrl,
                      minLines: 1,
                      maxLines: 4,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF0D1117),
                        height: 1.4,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: _send,
                      decoration: const InputDecoration(
                        hintText: 'Ask Sporta AI anything…',
                        hintStyle: TextStyle(
                          color: Color(0xFFB0B7C3),
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _send(_msgCtrl.text),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF003D3E), kPrimary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: kPrimary.withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
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
          ),
        ],
      ),
    );
  }

  // ── Header — teal gradient ─────────────────────────────────────────────────
  Widget _buildHeader() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF002526), Color(0xFF005D5E), Color(0xFF008080)],
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
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
        child: Row(
          children: [
            // AI avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Text('🤖', style: TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sporta AI',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4ADE80),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Online · Always ready',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => setState(() {
                _messages.removeRange(1, _messages.length);
                _hasInteracted = false;
              }),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  // ── Message bubble ─────────────────────────────────────────────────────────
  Widget _buildBubble({
    required String text,
    required bool isUser,
    required String time,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: kPrimary.withOpacity(0.2)),
              ),
              child: const Center(
                child: Text('🤖', style: TextStyle(fontSize: 15)),
              ),
            ),
          ],
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
                    color: isUser ? kPrimary : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isUser ? 0.15 : 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.55,
                      color: isUser ? Colors.white : const Color(0xFF0D0D0D),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: kPrimary.withOpacity(0.2)),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: kPrimary,
                size: 17,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Typing indicator ────────────────────────────────────────────────────────
  Widget _buildTypingBubble() => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: kPrimary.withOpacity(0.2)),
          ),
          child: const Center(
            child: Text('🤖', style: TextStyle(fontSize: 15)),
          ),
        ),
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
            animation: _typingCtrl,
            builder: (_, __) => Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final phase = ((_typingCtrl.value + i * 0.22) % 1.0);
                final opacity = phase > 0.5 ? 1.0 : 0.25;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(0, 93, 94, opacity),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    ),
  );

  // ── Suggestion chips ────────────────────────────────────────────────────────
  Widget _buildSuggestions() => Container(
    height: 52,
    margin: const EdgeInsets.only(bottom: 8),
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _suggestions.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, i) {
        final s = _suggestions[i];
        return GestureDetector(
          onTap: () => _send('${s['icon']} ${s['label']}'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: kPrimary.withOpacity(0.25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s['icon']!, style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 7),
                Text(
                  s['label']!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
