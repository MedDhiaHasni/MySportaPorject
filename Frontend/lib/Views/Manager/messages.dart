// messages.dart — Views/Manager/messages.dart
// Manager ↔ Players messaging — same structure as player chat_page.dart
// Manager sees conversations with players who booked their courts

import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────
class _Thread {
  final String id, name, initials, preview, time;
  final int unread;
  final Color accentColor;
  final String? courtContext; // e.g. "Court Alpha booking"
  final List<_Msg> messages;
  const _Thread({
    required this.id,
    required this.name,
    required this.initials,
    required this.preview,
    required this.time,
    required this.unread,
    required this.accentColor,
    required this.messages,
    this.courtContext,
  });
}

class _Msg {
  final String text, time;
  final bool isMe;
  const _Msg({required this.text, required this.time, required this.isMe});
}

// ─────────────────────────────────────────────────────────────────────────────
// SAMPLE DATA
// ─────────────────────────────────────────────────────────────────────────────
final _sampleThreads = <_Thread>[
  _Thread(
    id: 't1',
    name: 'Karim Jaziri',
    initials: 'KJ',
    preview: 'Is the football court available tonight at 8pm?',
    time: '18:24',
    unread: 2,
    accentColor: kPrimary,
    courtContext: 'Court Alpha · Football',
    messages: const [
      _Msg(
        text: 'Hello! Is the football court available tonight at 8pm?',
        time: '18:20',
        isMe: false,
      ),
      _Msg(text: 'Hi Karim! Let me check...', time: '18:21', isMe: true),
      _Msg(
        text: 'Yes, Court Alpha is available from 20:00 to 22:00',
        time: '18:22',
        isMe: true,
      ),
      _Msg(
        text: 'Is the football court available tonight at 8pm?',
        time: '18:24',
        isMe: false,
      ),
    ],
  ),
  _Thread(
    id: 't2',
    name: 'Nadia Ben Salah',
    initials: 'NB',
    preview: 'Can we extend our padel booking by 30 minutes?',
    time: '17:10',
    unread: 1,
    accentColor: kPurple,
    courtContext: 'Padel Court A · Padel',
    messages: const [
      _Msg(
        text: 'Hi! We are playing padel now, can we extend by 30 minutes?',
        time: '17:08',
        isMe: false,
      ),
      _Msg(
        text: 'Can we extend our padel booking by 30 minutes?',
        time: '17:10',
        isMe: false,
      ),
    ],
  ),
  _Thread(
    id: 't3',
    name: 'Mehdi Trabelsi',
    initials: 'MT',
    preview: 'Thank you for confirming the reservation.',
    time: '16:45',
    unread: 0,
    accentColor: kGreen,
    courtContext: 'Tennis Court 1 · Tennis',
    messages: const [
      _Msg(
        text: 'Your tennis court booking for tomorrow at 11:00 is confirmed!',
        time: '16:40',
        isMe: true,
      ),
      _Msg(
        text: 'Thank you for confirming the reservation for tomorrow.',
        time: '16:45',
        isMe: false,
      ),
      _Msg(
        text: 'See you tomorrow! The court will be ready.',
        time: '16:46',
        isMe: true,
      ),
    ],
  ),
  _Thread(
    id: 't4',
    name: 'Leila Mallouli',
    initials: 'LM',
    preview: 'I need to reschedule from 14:00 to 16:00',
    time: '15:12',
    unread: 0,
    accentColor: kAmber,
    courtContext: 'Basketball Hall · Basketball',
    messages: const [
      _Msg(
        text:
            'Hello, I need to reschedule my booking from 14:00 to 16:00 if possible.',
        time: '15:10',
        isMe: false,
      ),
      _Msg(
        text: 'I need to reschedule from 14:00 to 16:00',
        time: '15:12',
        isMe: false,
      ),
      _Msg(
        text: 'Hi Leila! 16:00 is available, I\'ll update your booking now.',
        time: '15:15',
        isMe: true,
      ),
      _Msg(
        text: 'Done! Your booking has been moved to 16:00. See you then!',
        time: '15:16',
        isMe: true,
      ),
    ],
  ),
  _Thread(
    id: 't5',
    name: 'Ahmed Ben Ali',
    initials: 'AB',
    preview: 'Great session today! When can I book again?',
    time: '14:30',
    unread: 0,
    accentColor: kBlue,
    courtContext: 'Court Alpha · Football',
    messages: const [
      _Msg(
        text: 'Great session today! When can I book again?',
        time: '14:30',
        isMe: false,
      ),
      _Msg(
        text: 'Glad you enjoyed it! Court Alpha is free Saturday morning.',
        time: '14:35',
        isMe: true,
      ),
      _Msg(
        text: 'Perfect, I\'ll book it now through the app.',
        time: '14:36',
        isMe: false,
      ),
    ],
  ),
  _Thread(
    id: 't6',
    name: 'Sami Khelif',
    initials: 'SK',
    preview: 'Is there parking available near the venue?',
    time: '12:05',
    unread: 0,
    accentColor: kOrange,
    courtContext: 'Padel Court A · Padel',
    messages: const [
      _Msg(
        text: 'Is there parking available near the venue?',
        time: '12:05',
        isMe: false,
      ),
      _Msg(
        text: 'Yes! Free parking is right behind the main entrance.',
        time: '12:08',
        isMe: true,
      ),
      _Msg(text: 'Great, thanks!', time: '12:09', isMe: false),
    ],
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// ROOT WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class Messages extends StatefulWidget {
  const Messages({super.key});
  @override
  State<Messages> createState() => _MessagesState();
}

class _MessagesState extends State<Messages>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  _Thread? _openThread;
  late final List<_Thread> _threads;
  bool _showCompose = false;
  late final AnimationController _composeAnim;
  late final Animation<double> _slideAnim, _fadeAnim;

  @override
  void initState() {
    super.initState();
    _threads = List.from(_sampleThreads);
    _searchCtrl.addListener(() => setState(() {}));
    _composeAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
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

  List<_Thread> get _filtered {
    final q = _searchCtrl.text.toLowerCase();
    if (q.isEmpty) return _threads;
    return _threads
        .where(
          (t) =>
              t.name.toLowerCase().contains(q) ||
              (t.courtContext?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  int get _totalUnread => _threads.fold(0, (s, t) => s + t.unread);

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
          if (_showCompose) ...[
            AnimatedBuilder(
              animation: _fadeAnim,
              builder: (_, __) => GestureDetector(
                onTap: _closeCompose,
                child: Container(
                  color: Colors.black.withOpacity(0.45 * _fadeAnim.value),
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
              child: _ComposeSheet(threads: _threads, onClose: _closeCompose),
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
  final List<_Thread> filtered;
  final TextEditingController searchCtrl;
  final int totalUnread;
  final ValueChanged<_Thread> onOpenThread;
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
        // Header
        Container(
          color: kCard,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
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
                            const SizedBox(height: 2),
                            Text(
                              totalUnread > 0
                                  ? '$totalUnread unread'
                                  : 'All caught up',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: totalUnread > 0 ? kPrimary : kTextMid,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: onOpenCompose,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: kPrimary,
                            borderRadius: BorderRadius.circular(13),
                            boxShadow: [
                              BoxShadow(
                                color: kPrimary.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
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
                const SizedBox(height: 14),
                // Search
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 14),
                        const Icon(
                          Icons.search_rounded,
                          color: kTextLight,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: searchCtrl,
                            style: const TextStyle(
                              fontSize: 14,
                              color: kTextDark,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Search players or courts…',
                              hintStyle: TextStyle(
                                color: kTextLight,
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
                              padding: EdgeInsets.only(right: 12),
                              child: Icon(
                                Icons.close_rounded,
                                size: 15,
                                color: kTextLight,
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

        // Thread list
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
  final _Thread thread;
  final VoidCallback onTap;
  const _ThreadTile({required this.thread, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = thread;
    final hasUnread = t.unread > 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: t.accentColor.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 11, 20, 11),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: t.accentColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: hasUnread
                          ? Border.all(
                              color: t.accentColor.withOpacity(0.4),
                              width: 2,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        t.initials,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: t.accentColor,
                        ),
                      ),
                    ),
                  ),
                  if (hasUnread)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: t.accentColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: kCard, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            '${t.unread}',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
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
                        Text(
                          t.time,
                          style: TextStyle(
                            fontSize: 11,
                            color: hasUnread ? t.accentColor : kTextLight,
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Court context tag
                    if (t.courtContext != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.sports_tennis_rounded,
                            size: 10,
                            color: t.accentColor.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            t.courtContext!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: t.accentColor.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
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
  final _Thread thread;
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
    setState(
      () => _msgs.add(
        _Msg(
          text: text,
          time:
              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
          isMe: true,
        ),
      ),
    );
    _ctrl.clear();
    Future.delayed(const Duration(milliseconds: 80), () {
      if (_scrollCtrl.hasClients)
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.thread;
    final bot = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Column(
        children: [
          // Header
          Container(
            color: kCard,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [t.accentColor, t.accentColor.withOpacity(0.3)],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 10, 16, 14),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: widget.onBack,
                          icon: const Icon(
                            Icons.arrow_back_ios_rounded,
                            size: 18,
                            color: kTextDark,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: t.accentColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: t.accentColor.withOpacity(0.25),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              t.initials,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: t.accentColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: kTextDark,
                                ),
                              ),
                              if (t.courtContext != null)
                                Text(
                                  t.courtContext!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: t.accentColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: kBg,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(
                            Icons.more_vert_rounded,
                            size: 18,
                            color: kTextMid,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: Colors.black.withOpacity(0.06)),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _msgs.length,
              itemBuilder: (_, i) => _Bubble(
                msg: _msgs[i],
                accentColor: t.accentColor,
                initials: t.initials,
              ),
            ),
          ),

          // Input bar
          Container(
            color: kCard,
            padding: EdgeInsets.fromLTRB(14, 10, 14, bot + 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 46),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F8FA),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _isTyping
                            ? t.accentColor.withOpacity(0.4)
                            : Colors.black.withOpacity(0.07),
                      ),
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
                        color: kTextDark,
                        height: 1.4,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Write a message…',
                        hintStyle: TextStyle(color: kTextLight, fontSize: 15),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 9),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _isTyping ? _send : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _isTyping ? t.accentColor : kBg,
                      shape: BoxShape.circle,
                      boxShadow: _isTyping
                          ? [
                              BoxShadow(
                                color: t.accentColor.withOpacity(0.35),
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BUBBLES
// ─────────────────────────────────────────────────────────────────────────────
class _Bubble extends StatelessWidget {
  final _Msg msg;
  final Color accentColor;
  final String initials;
  const _Bubble({
    required this.msg,
    required this.accentColor,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = msg.isMe;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
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
                child: Text(
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? accentColor : kCard,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.text,
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
                        msg.time,
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe
                              ? Colors.white.withOpacity(0.6)
                              : kTextLight,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all_rounded,
                          size: 12,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPOSE SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _ComposeSheet extends StatefulWidget {
  final List<_Thread> threads;
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
  _Thread? _selected;
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

  List<_Thread> get _suggestions {
    if (_selected != null) return [];
    final q = _toCtrl.text.toLowerCase();
    if (q.isEmpty) return widget.threads.take(6).toList();
    return widget.threads
        .where((t) => t.name.toLowerCase().contains(q))
        .take(6)
        .toList();
  }

  bool get _canSend => _selected != null && _msgCtrl.text.trim().isNotEmpty;

  void _pick(_Thread t) {
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
                color: Color(0x28000000),
                blurRadius: 40,
                offset: Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Gradient header
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF003D3E), kPrimary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                                  'Send a message to a player',
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

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _selected != null
                    ? _RecipientChip(
                        thread: _selected!,
                        onClear: _clearRecipient,
                      )
                    : _buildToField(),
              ),

              if (_selected == null) ...[
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _toCtrl.text.isEmpty ? 'Recent' : 'Results',
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
                    height: 88,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) {
                        final t = _suggestions[i];
                        return GestureDetector(
                          onTap: () => _pick(t),
                          child: SizedBox(
                            width: 60,
                            child: Column(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: t.accentColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: t.accentColor.withOpacity(0.25),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
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
                                    fontSize: 10,
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
                          color: kTextLight,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _msgFocused
                                ? Colors.white
                                : const Color(0xFFF7F8FA),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: _msgFocused
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 12,
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
                              color: kTextDark,
                              height: 1.55,
                            ),
                            decoration: InputDecoration(
                              hintText: _selected != null
                                  ? 'Write to ${_selected!.name.split(' ').first}…'
                                  : 'Select a player first…',
                              hintStyle: const TextStyle(
                                color: kTextLight,
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
                    const Spacer(),
                    GestureDetector(
                      onTap: _canSend ? widget.onClose : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        height: 48,
                        width: _canSend ? 120 : 48,
                        decoration: BoxDecoration(
                          gradient: _canSend
                              ? const LinearGradient(
                                  colors: [Color(0xFF003D3E), kPrimary],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: _canSend ? null : kPrimary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: _canSend
                              ? [
                                  BoxShadow(
                                    color: kPrimary.withOpacity(0.3),
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
                              color: _canSend
                                  ? Colors.white
                                  : kPrimary.withOpacity(0.4),
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

  Widget _buildToField() => Container(
    height: 50,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.07),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        const Text(
          'To:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: kTextMid,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _toCtrl,
            focusNode: _toFocus,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: kTextDark,
            ),
            decoration: const InputDecoration(
              hintText: 'Player name…',
              hintStyle: TextStyle(color: kTextLight, fontSize: 14),
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
        if (_toCtrl.text.isNotEmpty)
          GestureDetector(
            onTap: _toCtrl.clear,
            child: const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.close_rounded, size: 16, color: kTextLight),
            ),
          ),
      ],
    ),
  );
}

class _RecipientChip extends StatelessWidget {
  final _Thread thread;
  final VoidCallback onClear;
  const _RecipientChip({required this.thread, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final t = thread;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: t.accentColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.accentColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: t.accentColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: kTextDark,
                  ),
                ),
                if (t.courtContext != null)
                  Text(
                    t.courtContext!,
                    style: TextStyle(
                      fontSize: 11,
                      color: t.accentColor.withOpacity(0.8),
                    ),
                  ),
              ],
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
