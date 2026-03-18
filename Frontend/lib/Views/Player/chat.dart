// chat_page.dart — Views/Player/chat_page.dart
// Completely rebuilt: no contacts tab, premium sporty messaging UI

import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Models/app_enums.dart';
import 'package:sporta/Models/app_models.dart';
import 'package:sporta/Models/sample_data.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA
// ─────────────────────────────────────────────────────────────────────────────
class _ChatThread {
  final String id;
  final String name;
  final String initials;
  final bool isCourt; // venue vs player
  final bool online;
  final String preview;
  final String time;
  final int unread;
  final Color accentColor;
  final List<_Msg> messages;

  const _ChatThread({
    required this.id,
    required this.name,
    required this.initials,
    required this.isCourt,
    required this.online,
    required this.preview,
    required this.time,
    required this.unread,
    required this.accentColor,
    required this.messages,
  });
}

class _Msg {
  final String text;
  final String time;
  final bool isMe;
  final bool isLocation;
  const _Msg({
    required this.text,
    required this.time,
    required this.isMe,
    this.isLocation = false,
  });
}

final _threads = <_ChatThread>[
  _ChatThread(
    id: 't1',
    name: 'Arena Sport Center',
    initials: '🏟',
    isCourt: true,
    online: true,
    preview: 'Your booking for tomorrow is confirmed!',
    time: '5m',
    unread: 2,
    accentColor: kPrimary,
    messages: const [
      _Msg(
        text: 'Hello! Your booking for tomorrow at 20:00 is confirmed.',
        time: '14:32',
        isMe: false,
      ),
      _Msg(
        text: 'Great, thank you! Is there parking available?',
        time: '14:33',
        isMe: true,
      ),
      _Msg(
        text: 'Yes, free parking is available at the back.',
        time: '14:33',
        isMe: false,
      ),
      _Msg(
        text: 'Arena Sport Center, Lac 2, Tunis',
        time: '14:34',
        isMe: false,
        isLocation: true,
      ),
      _Msg(text: 'Perfect! See you tomorrow 👋', time: '14:35', isMe: true),
    ],
  ),
  _ChatThread(
    id: 't2',
    name: 'Ahmed Ben Ali',
    initials: 'AB',
    isCourt: false,
    online: false,
    preview: 'See you at the game tonight!',
    time: '1h',
    unread: 0,
    accentColor: kBlue,
    messages: const [
      _Msg(
        text: 'Hey! Are you coming to the game tonight?',
        time: '12:10',
        isMe: false,
      ),
      _Msg(text: 'Yes! What time does it start?', time: '12:11', isMe: true),
      _Msg(text: '20:00 sharp. Don\'t be late 😄', time: '12:12', isMe: false),
      _Msg(text: 'See you at the game tonight!', time: '12:13', isMe: false),
    ],
  ),
  _ChatThread(
    id: 't3',
    name: 'Padel Club Marsa',
    initials: '🎾',
    isCourt: true,
    online: true,
    preview: 'Your court has been rescheduled to 19:00',
    time: '3h',
    unread: 1,
    accentColor: kPurple,
    messages: const [
      _Msg(
        text: 'Good news! We were able to fit you in earlier.',
        time: '10:00',
        isMe: false,
      ),
      _Msg(
        text: 'Your court has been rescheduled to 19:00',
        time: '10:01',
        isMe: false,
      ),
      _Msg(text: 'That works great, thanks!', time: '10:05', isMe: true),
    ],
  ),
  _ChatThread(
    id: 't4',
    name: 'Sarra Mahjoubi',
    initials: 'SM',
    isCourt: false,
    online: true,
    preview: 'Thanks for organizing the match!',
    time: '1d',
    unread: 0,
    accentColor: kOrange,
    messages: const [
      _Msg(
        text: 'That was such a great game yesterday!',
        time: '09:20',
        isMe: false,
      ),
      _Msg(
        text: 'Thanks for organizing the match!',
        time: '09:21',
        isMe: false,
      ),
      _Msg(
        text: 'Glad you enjoyed it! Same time next week?',
        time: '09:30',
        isMe: true,
      ),
    ],
  ),
  _ChatThread(
    id: 't5',
    name: 'City Basketball Arena',
    initials: '🏀',
    isCourt: true,
    online: false,
    preview: 'Reminder: Your game starts in 2 hours',
    time: '2d',
    unread: 0,
    accentColor: kAmber,
    messages: const [
      _Msg(
        text: 'Reminder: Your game starts in 2 hours.',
        time: '16:00',
        isMe: false,
      ),
      _Msg(
        text: 'Please arrive 15 minutes early to warm up.',
        time: '16:00',
        isMe: false,
      ),
      _Msg(text: 'Got it, thanks for the reminder!', time: '16:10', isMe: true),
    ],
  ),
  _ChatThread(
    id: 't6',
    name: 'Nadia Ben Salah',
    initials: 'NB',
    isCourt: false,
    online: false,
    preview: 'Are you joining the padel tournament?',
    time: '2d',
    unread: 0,
    accentColor: kGreen,
    messages: const [
      _Msg(
        text: 'Hey! Are you joining the padel tournament next week?',
        time: '11:30',
        isMe: false,
      ),
      _Msg(
        text: 'I\'m thinking about it, depends on my schedule.',
        time: '11:45',
        isMe: true,
      ),
      _Msg(
        text: 'Are you joining the padel tournament?',
        time: '11:46',
        isMe: false,
      ),
    ],
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// MAIN CHAT PAGE
// ─────────────────────────────────────────────────────────────────────────────
class Chat extends StatefulWidget {
  const Chat({super.key});
  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  _ChatThread? _openThread;
  late final List<_ChatThread> _data;

  // compose sheet
  bool _showCompose = false;
  late final AnimationController _composeAnim;
  late final Animation<double> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _data = List.from(_threads);
    _searchCtrl.addListener(() => setState(() {}));
    _composeAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _slideAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _composeAnim, curve: Curves.easeOutCubic),
    );
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _composeAnim, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _composeAnim.dispose();
    super.dispose();
  }

  List<_ChatThread> get _filtered {
    final q = _searchCtrl.text.toLowerCase();
    if (q.isEmpty) return _data;
    return _data.where((t) => t.name.toLowerCase().contains(q)).toList();
  }

  int get _totalUnread => _data.fold(0, (s, t) => s + t.unread);

  void _openCompose() {
    setState(() => _showCompose = true);
    _composeAnim.forward(from: 0);
  }

  void _closeCompose() {
    _composeAnim.reverse().then((_) {
      if (mounted) setState(() => _showCompose = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          // ── Main content ────────────────────────────────────────────────
          _openThread != null
              ? _ConversationScreen(
                  thread: _openThread!,
                  onBack: () => setState(() => _openThread = null),
                )
              : _ListScreen(
                  filtered: _filtered,
                  searchCtrl: _searchCtrl,
                  totalUnread: _totalUnread,
                  onOpenThread: (t) => setState(() => _openThread = t),
                  onOpenCompose: _openCompose,
                ),

          // ── Compose overlay ─────────────────────────────────────────────
          if (_showCompose) ...[
            AnimatedBuilder(
              animation: _fadeAnim,
              builder: (_, __) => GestureDetector(
                onTap: _closeCompose,
                child: Container(
                  color: Colors.black.withOpacity(0.5 * _fadeAnim.value),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _slideAnim,
              builder: (_, child) => Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Transform.translate(
                  offset: Offset(
                    0,
                    _slideAnim.value * MediaQuery.of(context).size.height,
                  ),
                  child: child,
                ),
              ),
              child: _ComposeSheet(threads: _data, onClose: _closeCompose),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LIST SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class _ListScreen extends StatelessWidget {
  final List<_ChatThread> filtered;
  final TextEditingController searchCtrl;
  final int totalUnread;
  final ValueChanged<_ChatThread> onOpenThread;
  final VoidCallback onOpenCompose;

  const _ListScreen({
    required this.filtered,
    required this.searchCtrl,
    required this.totalUnread,
    required this.onOpenThread,
    required this.onOpenCompose,
  });

  @override
  Widget build(BuildContext context) {
    final navH =
        kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    return Column(
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Container(
          color: kCard,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Messages',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: kTextDark,
                              letterSpacing: -0.6,
                            ),
                          ),
                          if (totalUnread > 0)
                            Text(
                              '$totalUnread unread',
                              style: const TextStyle(
                                fontSize: 12,
                                color: kPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          else
                            const Text(
                              'All caught up',
                              style: TextStyle(fontSize: 12, color: kTextMid),
                            ),
                        ],
                      ),
                      const Spacer(),
                      // Compose button — styled differently
                      GestureDetector(
                        onTap: onOpenCompose,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: kPrimary,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Search bar ─────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F8FA),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.search_rounded,
                          color: Color(0xFFB0B7C3),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: searchCtrl,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF0D1117),
                            ),
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              hintText: 'Search conversations…',
                              hintStyle: TextStyle(
                                color: Color(0xFFB0B7C3),
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                        if (searchCtrl.text.isNotEmpty)
                          GestureDetector(
                            onTap: searchCtrl.clear,
                            child: const Padding(
                              padding: EdgeInsets.only(right: 14),
                              child: Icon(
                                Icons.close_rounded,
                                size: 15,
                                color: Color(0xFFB0B7C3),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        Divider(height: 1, color: Colors.black.withOpacity(0.06)),

        // ── Thread list ──────────────────────────────────────────────────────
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: kTextLight.withOpacity(0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No results for "${searchCtrl.text}"',
                        style: const TextStyle(fontSize: 14, color: kTextMid),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(0, 8, 0, navH + 16),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _ThreadTile(
                    thread: filtered[i],
                    onTap: () => onOpenThread(filtered[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// THREAD TILE
// ─────────────────────────────────────────────────────────────────────────────
class _ThreadTile extends StatelessWidget {
  final _ChatThread thread;
  final VoidCallback onTap;
  const _ThreadTile({required this.thread, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = thread;
    final hasUnread = t.unread > 0;
    final isEmoji = t.initials.runes.any((r) => r > 127);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: kPrimary.withOpacity(0.04),
        highlightColor: kPrimary.withOpacity(0.02),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: t.accentColor.withOpacity(0.10),
                  shape: BoxShape.circle,
                  border: hasUnread
                      ? Border.all(
                          color: t.accentColor.withOpacity(0.35),
                          width: 1.5,
                        )
                      : null,
                ),
                child: Center(
                  child: isEmoji
                      ? Text(t.initials, style: const TextStyle(fontSize: 22))
                      : Text(
                          t.initials,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: t.accentColor,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            t.name,
                            style: TextStyle(
                              fontSize: 15,
                              color: kTextDark,
                              fontWeight: hasUnread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          t.time,
                          style: TextStyle(
                            fontSize: 11,
                            color: hasUnread ? t.accentColor : kTextLight,
                            fontWeight: hasUnread
                                ? FontWeight.w700
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            t.preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: hasUnread ? kTextDark : kTextMid,
                              fontWeight: hasUnread
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (hasUnread)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: t.accentColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${t.unread}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONVERSATION SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class _ConversationScreen extends StatefulWidget {
  final _ChatThread thread;
  final VoidCallback onBack;
  const _ConversationScreen({required this.thread, required this.onBack});
  @override
  State<_ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<_ConversationScreen> {
  late final List<_Msg> _msgs;
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _msgs = List.from(widget.thread.messages);
    _ctrl.addListener(
      () => setState(() => _isTyping = _ctrl.text.trim().isNotEmpty),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final now = DateTime.now();
    setState(() {
      _msgs.add(
        _Msg(
          text: text,
          time:
              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
          isMe: true,
        ),
      );
    });
    _ctrl.clear();
    Future.delayed(const Duration(milliseconds: 80), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.thread;
    final isEmoji = t.initials.runes.any((r) => r > 127);
    final bot = MediaQuery.of(context).padding.bottom;

    return Column(
      children: [
        // ── Conversation header ─────────────────────────────────────────────
        Container(
          color: kCard,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 10, 16, 12),
                  child: Row(
                    children: [
                      // Back
                      IconButton(
                        onPressed: widget.onBack,
                        icon: const Icon(
                          Icons.arrow_back_ios_rounded,
                          size: 18,
                          color: kTextDark,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      // Avatar — no online dot
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: t.accentColor.withOpacity(0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isEmoji
                              ? Text(
                                  t.initials,
                                  style: const TextStyle(fontSize: 20),
                                )
                              : Text(
                                  t.initials,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: t.accentColor,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          t.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: kTextDark,
                          ),
                        ),
                      ),
                      // Only info/more button
                      _HeaderBtn(icon: Icons.more_vert_rounded, onTap: () {}),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Divider(height: 1, color: Colors.black.withOpacity(0.06)),

        // ── Messages ────────────────────────────────────────────────────────
        Expanded(
          child: Container(
            color: kBg,
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _msgs.length,
              itemBuilder: (_, i) {
                // show date divider at start
                final msg = _msgs[i];
                return _BubbleWidget(
                  msg: msg,
                  accentColor: t.accentColor,
                  initials: t.initials,
                );
              },
            ),
          ),
        ),

        // ── Input bar ───────────────────────────────────────────────────────
        Container(
          color: kCard,
          padding: EdgeInsets.fromLTRB(12, 10, 12, bot + 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // text field
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 46),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 6,
                  ),
                  child: TextField(
                    controller: _ctrl,
                    minLines: 1,
                    maxLines: 5,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF0D1117),
                      height: 1.4,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Write a message…',
                      hintStyle: TextStyle(
                        color: Color(0xFFB0B7C3),
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // send button — always visible, activates when typing
              GestureDetector(
                onTap: _isTyping ? _send : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _isTyping ? kPrimary : kBg,
                    shape: BoxShape.circle,
                    border: _isTyping
                        ? null
                        : Border.all(color: Colors.black.withOpacity(0.08)),
                    boxShadow: _isTyping
                        ? [
                            BoxShadow(
                              color: kPrimary.withOpacity(0.32),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    size: 19,
                    color: _isTyping ? Colors.white : kTextLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MESSAGE BUBBLE
// ─────────────────────────────────────────────────────────────────────────────
class _BubbleWidget extends StatelessWidget {
  final _Msg msg;
  final Color accentColor;
  final String initials;
  const _BubbleWidget({
    required this.msg,
    required this.accentColor,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = msg.isMe;
    final isEmoji = initials.runes.any((r) => r > 127);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar for received
          if (!isMe) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isEmoji
                    ? Text(initials, style: const TextStyle(fontSize: 13))
                    : Text(
                        initials.substring(0, 1),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                        ),
                      ),
              ),
            ),
          ],

          Flexible(
            child: msg.isLocation
                ? _LocationBubble(text: msg.text, time: msg.time)
                : _TextBubble(
                    text: msg.text,
                    time: msg.time,
                    isMe: isMe,
                    accentColor: accentColor,
                  ),
          ),

          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _TextBubble extends StatelessWidget {
  final String text, time;
  final bool isMe;
  final Color accentColor;
  const _TextBubble({
    required this.text,
    required this.time,
    required this.isMe,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: isMe ? accentColor : kCard,
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(18),
        topRight: const Radius.circular(18),
        bottomLeft: Radius.circular(isMe ? 18 : 4),
        bottomRight: Radius.circular(isMe ? 4 : 18),
      ),
      boxShadow: kElevation,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: isMe ? Colors.white : kTextDark,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              time,
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white.withOpacity(0.55) : kTextLight,
              ),
            ),
            if (isMe) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.done_all_rounded,
                size: 12,
                color: Colors.white.withOpacity(0.55),
              ),
            ],
          ],
        ),
      ],
    ),
  );
}

class _LocationBubble extends StatelessWidget {
  final String text, time;
  const _LocationBubble({required this.text, required this.time});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: kCard,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kPrimary.withOpacity(0.15)),
      boxShadow: kElevation,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.location_on_rounded,
            size: 18,
            color: kPrimary,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Location',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: kTextDark,
                ),
              ),
              Text(text, style: const TextStyle(fontSize: 11, color: kTextMid)),
              const SizedBox(height: 2),
              Text(
                time,
                style: const TextStyle(fontSize: 10, color: kTextLight),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPOSE SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _ComposeSheet extends StatefulWidget {
  final List<_ChatThread> threads;
  final VoidCallback onClose;
  const _ComposeSheet({required this.threads, required this.onClose});
  @override
  State<_ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends State<_ComposeSheet> {
  final _toCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  final _toFocus = FocusNode();
  final _msgFocus = FocusNode();
  _ChatThread? _selected;
  bool _msgFocused = false;

  @override
  void initState() {
    super.initState();
    _toCtrl.addListener(() => setState(() {}));
    _msgCtrl.addListener(() => setState(() {}));
    _msgFocus.addListener(
      () => setState(() => _msgFocused = _msgFocus.hasFocus),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _toFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _toCtrl.dispose();
    _msgCtrl.dispose();
    _toFocus.dispose();
    _msgFocus.dispose();
    super.dispose();
  }

  List<_ChatThread> get _suggestions {
    if (_selected != null) return [];
    final q = _toCtrl.text.toLowerCase();
    if (q.isEmpty) return widget.threads.take(6).toList();
    return widget.threads
        .where((t) => t.name.toLowerCase().contains(q))
        .take(6)
        .toList();
  }

  bool get _canSend => _selected != null && _msgCtrl.text.trim().isNotEmpty;

  void _pick(_ChatThread t) {
    setState(() => _selected = t);
    _toCtrl.text = t.name;
    _toFocus.unfocus();
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _msgFocus.requestFocus();
    });
  }

  void _clearRecipient() {
    setState(() => _selected = null);
    _toCtrl.clear();
    Future.delayed(const Duration(milliseconds: 60), () {
      if (mounted) _toFocus.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bot = MediaQuery.of(context).padding.bottom;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.88,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: const BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Color(0x30000000),
                blurRadius: 40,
                offset: Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF003D3E), kPrimary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 16, 20),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'New Message',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Text(
                                  'Start a conversation',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white60,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.onClose,
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 17,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── To field ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _selected != null
                    ? _RecipientChip(
                        thread: _selected!,
                        onClear: _clearRecipient,
                      )
                    : _ToField(ctrl: _toCtrl, focus: _toFocus),
              ),

              // ── Suggestions ───────────────────────────────────────────────
              if (_selected == null) ...[
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _toCtrl.text.isEmpty ? 'Suggested' : 'Results',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: kTextLight,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (_suggestions.isEmpty && _toCtrl.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: Text(
                        'No results for "${_toCtrl.text}"',
                        style: const TextStyle(fontSize: 13, color: kTextLight),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (_, i) {
                        final t = _suggestions[i];
                        final isEmoji = t.initials.runes.any((r) => r > 127);
                        return GestureDetector(
                          onTap: () => _pick(t),
                          child: SizedBox(
                            width: 62,
                            child: Column(
                              children: [
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: t.accentColor.withOpacity(0.10),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: t.accentColor.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: isEmoji
                                        ? Text(
                                            t.initials,
                                            style: const TextStyle(
                                              fontSize: 22,
                                            ),
                                          )
                                        : Text(
                                            t.initials,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: t.accentColor,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  t.name.split(' ').first,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: kTextDark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Divider(
                  height: 1,
                  color: Colors.black.withOpacity(0.05),
                ),
              ),

              // ── Message field ─────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Message',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB0B7C3),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _msgFocused
                                ? Colors.white
                                : const Color(0xFFF7F8FA),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: _msgFocused
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.07),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: TextField(
                            controller: _msgCtrl,
                            focusNode: _msgFocus,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF0D1117),
                              height: 1.55,
                            ),
                            decoration: InputDecoration(
                              hintText: _selected != null
                                  ? 'Write to ${_selected!.name.split(' ').first}…'
                                  : 'Select a recipient first…',
                              hintStyle: const TextStyle(
                                color: Color(0xFFB0B7C3),
                                fontSize: 15,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Bottom bar ────────────────────────────────────────────────
              Container(
                padding: EdgeInsets.fromLTRB(16, 12, 16, bot + 16),
                decoration: BoxDecoration(
                  color: kCard,
                  border: Border(
                    top: BorderSide(color: Colors.black.withOpacity(0.05)),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: kBg,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.sentiment_satisfied_alt_rounded,
                        color: kTextLight,
                        size: 22,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _canSend ? widget.onClose : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        height: 48,
                        width: _canSend ? 110 : 48,
                        decoration: BoxDecoration(
                          gradient: _canSend
                              ? const LinearGradient(
                                  colors: [Color(0xFF003D3E), kPrimary],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: _canSend ? null : kBg,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: _canSend
                              ? [
                                  BoxShadow(
                                    color: kPrimary.withOpacity(0.28),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.send_rounded,
                              size: 18,
                              color: _canSend ? Colors.white : kTextLight,
                            ),
                            if (_canSend) ...[
                              const SizedBox(width: 6),
                              const Text(
                                'Send',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPOSE SUB-WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _ToField extends StatelessWidget {
  final TextEditingController ctrl;
  final FocusNode focus;
  const _ToField({required this.ctrl, required this.focus});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: focus,
    builder: (_, __) {
      final isFocused = focus.hasFocus;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 50,
        decoration: BoxDecoration(
          color: isFocused ? Colors.white : const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(26),
          boxShadow: isFocused
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: [
            Text(
              'To:',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: ctrl,
                focusNode: focus,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0D1117),
                ),
                decoration: const InputDecoration(
                  hintText: 'Name or venue…',
                  hintStyle: TextStyle(color: Color(0xFFB0B7C3), fontSize: 14),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (ctrl.text.isNotEmpty)
              GestureDetector(
                onTap: ctrl.clear,
                child: const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Color(0xFFB0B7C3),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}

class _RecipientChip extends StatelessWidget {
  final _ChatThread thread;
  final VoidCallback onClear;
  const _RecipientChip({required this.thread, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final t = thread;
    final isEmoji = t.initials.runes.any((r) => r > 127);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: t.accentColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.accentColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: t.accentColor.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isEmoji
                  ? Text(t.initials, style: const TextStyle(fontSize: 17))
                  : Text(
                      t.initials,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: t.accentColor,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              t.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: kTextDark,
              ),
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: kBg, shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded, size: 14, color: kTextMid),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SMALL SHARED
// ─────────────────────────────────────────────────────────────────────────────
class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, size: 18, color: kPrimary),
    ),
  );
}
