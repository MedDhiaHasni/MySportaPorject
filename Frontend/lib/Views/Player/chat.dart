// Views/Player/chat.dart
// Shows all conversations the player is part of:
//   • player ↔ manager  (doc: reservation_{id})      — labeled "Manager"
//   • player ↔ worker   (doc: player_worker_{id})    — labeled "Worker"
// Uses the UID of the authenticated Firebase account.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sporta/Core/Theme/app_tokens.dart';
import 'package:sporta/Services/chat_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sporta/Core/Constants/api_constants.dart';
import 'package:sporta/Core/Utils/app_logger.dart';
import 'package:sporta/Widgets/Buttons/app_buttons.dart';
import 'package:sporta/Widgets/Cards/app_card.dart';
import 'package:sporta/Widgets/Inputs/app_text_field.dart';
import 'package:sporta/Widgets/booking_components.dart';
import 'package:sporta/Widgets/feedback_components.dart';

class Chat extends StatefulWidget {
  final String? playerName;
  final String? playerToken;
  const Chat({super.key, this.playerName, this.playerToken});
  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  ConversationModel? _openConversation;
  String? _uid;
  bool _loadingUid = true;
  String? _uidError;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  final Map<String, String> _userPhotoCache = {};

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _searchCtrl.addListener(() => setState(() {}));
    _resolveUid();
  }

  Future<void> _resolveUid() async {
    setState(() {
      _loadingUid = true;
      _uidError = null;
    });
    try {
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser == null || fbUser.isAnonymous) {
        throw StateError('No authenticated Firebase user is available');
      }
      _setUid(fbUser.uid);
    } catch (e) {
      AppLogger.error('[Chat] secure Firebase identity unavailable: $e');
      if (mounted) {
        setState(() {
          _uidError =
              'Secure chat sign-in failed. Please log out and sign in again. Other app features remain available.';
          _loadingUid = false;
        });
      }
    }
  }

  void _setUid(String uid) {
    if (mounted) {
      setState(() {
        _uid = uid;
        _loadingUid = false;
      });
      _fadeCtrl.forward();
    }
  }

  Future<String?> _fetchUserPhoto(String userId, String userType) async {
    if (_userPhotoCache.containsKey('$userType:$userId')) {
      return _userPhotoCache['$userType:$userId'];
    }

    try {
      final token =
          widget.playerToken ??
          await const FlutterSecureStorage().read(key: 'jwt_token');
      if (token == null) return null;

      final endpoint =
          '${ApiConstants.playerUserPhoto}/$userType/$userId/photo';

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String photoUrl = data['photoUrl'] ?? '';

        if (photoUrl.isNotEmpty) {
          if (!photoUrl.startsWith('http')) {
            photoUrl = '${ApiConstants.mediaBaseUrl}$photoUrl';
          }
          _userPhotoCache['$userType:$userId'] = photoUrl;
          return photoUrl;
        }
      } else {
        AppLogger.error('Failed to fetch photo: ${response.statusCode}');
      }
      return null;
    } catch (e) {
      AppLogger.error('Error fetching photo for $userType $userId: $e');
      return null;
    }
  }

  Future<void> _deleteConversation(ConversationModel conv) async {
    final ok = await _confirmSheet(
      icon: Icons.delete_sweep_rounded,
      title: 'Delete conversation?',
      subtitle: 'This will permanently remove all messages.',
      action: 'Delete',
    );
    if (!ok) return;
    try {
      await ChatService.instance.deleteConversation(conv.id);
      if (mounted) _snack('Conversation deleted');
    } catch (e) {
      if (mounted) _snack('Failed: $e', isError: true);
    }
  }

  Future<void> _clearAll() async {
    final ok = await _confirmSheet(
      icon: Icons.layers_clear_rounded,
      title: 'Clear all chats?',
      subtitle: 'Every conversation will be permanently deleted.',
      action: 'Clear All',
    );
    if (!ok || _uid == null) return;
    try {
      await ChatService.instance.clearAllConversations(_uid!);
      if (mounted) _snack('All conversations cleared');
    } catch (e) {
      if (mounted) _snack('Failed: $e', isError: true);
    }
  }

  Future<bool> _confirmSheet({
    required IconData icon,
    required String title,
    required String subtitle,
    required String action,
  }) async {
    return await showModalBottomSheet<bool>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (ctx) {
            final scheme = Theme.of(ctx).colorScheme;
            return AppBottomSheet(
              title: title,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: scheme.error),
                  const SizedBox(height: AppSpacing.sm),
                  Text(subtitle, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: AppSecondaryButton(
                          label: 'Cancel',
                          onPressed: () => Navigator.pop(ctx, false),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: scheme.error,
                            foregroundColor: scheme.onError,
                            minimumSize: const Size(48, 52),
                          ),
                          child: Text(action),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ) ??
        false;
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? scheme.error : scheme.inverseSurface,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingUid) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Padding(
          padding: EdgeInsetsDirectional.all(AppSpacing.md),
          child: Column(
            children: [
              SizedBox(height: AppSpacing.xxl),
              LoadingSkeleton(height: 72, borderRadius: AppRadius.card),
              SizedBox(height: AppSpacing.md),
              LoadingSkeleton(height: 88, borderRadius: AppRadius.card),
              SizedBox(height: AppSpacing.md),
              LoadingSkeleton(height: 88, borderRadius: AppRadius.card),
            ],
          ),
        ),
      );
    }
    if (_uid == null) return _buildError();
    if (_openConversation != null) {
      return _ConversationScreen(
        conversation: _openConversation!,
        myUid: _uid!,
        myName: widget.playerName ?? 'Player',
        playerToken: widget.playerToken,
        onBack: () => setState(() => _openConversation = null),
        onDelete: () async {
          await _deleteConversation(_openConversation!);
          if (mounted) setState(() => _openConversation = null);
        },
      );
    }
    return _buildInbox();
  }

  Widget _buildInbox() {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          Expanded(
            child: FadeTransition(opacity: _fadeAnim, child: _buildList()),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Messages', style: theme.textTheme.headlineSmall),
                  StreamBuilder<List<ConversationModel>>(
                    stream: ChatService.instance.streamConversations(_uid!),
                    builder: (_, snap) {
                      final c = snap.data?.length ?? 0;
                      return Text(
                        c > 0
                            ? '$c active conversation${c == 1 ? '' : 's'}'
                            : 'No conversations yet',
                        style: theme.textTheme.bodySmall,
                      );
                    },
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Clear all chats',
              onPressed: () {
                HapticFeedback.mediumImpact();
                _clearAll();
              },
              icon: const Icon(Icons.layers_clear_rounded),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(
      AppSpacing.md,
      0,
      AppSpacing.md,
      AppSpacing.sm,
    ),
    child: AppTextField(
      controller: _searchCtrl,
      hint: 'Search conversations…',
      prefixIcon: Icons.search_rounded,
      suffix: _searchCtrl.text.isNotEmpty
          ? IconButton(
              tooltip: 'Clear search',
              onPressed: () => setState(() => _searchCtrl.clear()),
              icon: const Icon(Icons.close_rounded),
            )
          : null,
    ),
  );

  Widget _buildList() {
    final navH =
        AppLayout.bottomNavigationHeight + MediaQuery.of(context).padding.bottom;
    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: StreamBuilder<List<ConversationModel>>(
        stream: ChatService.instance.streamConversations(_uid!),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsetsDirectional.fromSTEB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                navH + AppSpacing.md,
              ),
              children: const [
                LoadingSkeleton(height: 96, borderRadius: AppRadius.card),
                SizedBox(height: AppSpacing.sm),
                LoadingSkeleton(height: 96, borderRadius: AppRadius.card),
                SizedBox(height: AppSpacing.sm),
                LoadingSkeleton(height: 96, borderRadius: AppRadius.card),
              ],
            );
          }
          if (snap.hasError) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                ErrorState(
                  title: 'Could not load chats',
                  message: snap.error.toString(),
                  onRetry: _resolveUid,
                ),
              ],
            );
          }

          var convs = snap.data ?? [];
          final q = _searchCtrl.text.toLowerCase().trim();
          if (q.isNotEmpty) {
            convs = convs
                .where(
                  (c) =>
                      c.reservationId.contains(q) ||
                      (c.lastMessage?.toLowerCase().contains(q) ?? false) ||
                      (c.managerName?.toLowerCase().contains(q) ?? false) ||
                      (c.workerName?.toLowerCase().contains(q) ?? false),
                )
                .toList();
          }
          if (convs.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                EmptyState(
                  icon: q.isNotEmpty
                      ? Icons.search_off_rounded
                      : Icons.chat_bubble_outline_rounded,
                  title: q.isNotEmpty
                      ? 'No results found'
                      : 'No conversations yet',
                  message: q.isNotEmpty
                      ? 'Try a different search term.'
                      : 'Book a court to start chatting with the venue team.',
                ),
              ],
            );
          }

          return ListView.builder(
            padding: EdgeInsetsDirectional.fromSTEB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              navH + AppSpacing.md,
            ),
            itemCount: convs.length,
            itemBuilder: (_, i) {
              final conv = convs[i];
              return Dismissible(
                key: Key(conv.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsetsDirectional.only(
                    bottom: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  alignment: AlignmentDirectional.centerEnd,
                  padding: const EdgeInsetsDirectional.only(end: AppSpacing.md),
                  child: Icon(
                    Icons.delete_rounded,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
                confirmDismiss: (_) async {
                  await _deleteConversation(conv);
                  return false;
                },
                child: _ConvTile(
                  conv: conv,
                  myUid: _uid!,
                  playerToken: widget.playerToken,
                  index: i,
                  fetchPhoto: _fetchUserPhoto,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _openConversation = conv);
                  },
                  onDelete: () => _deleteConversation(conv),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildError({String? message}) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ErrorState(
        title: 'Connection failed',
        message: message ?? _uidError ?? 'Could not open secure chat.',
        onRetry: _resolveUid,
      ),
    );
  }
}

class _ConvTile extends StatefulWidget {
  final ConversationModel conv;
  final String myUid;
  final String? playerToken;
  final int index;
  final VoidCallback onTap, onDelete;
  final Future<String?> Function(String userId, String userType) fetchPhoto;

  const _ConvTile({
    required this.conv,
    required this.myUid,
    required this.playerToken,
    required this.index,
    required this.onTap,
    required this.onDelete,
    required this.fetchPhoto,
  });

  @override
  State<_ConvTile> createState() => _ConvTileState();
}

class _ConvTileState extends State<_ConvTile> {
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  Future<void> _loadPhoto() async {
    String? otherId;
    final isWorker = widget.conv.type == ConversationType.playerWorker;

    if (isWorker) {
      otherId = widget.conv.participantIds['worker'];
    } else {
      otherId = widget.conv.participantIds['manager'];
    }

    if (otherId != null && otherId.isNotEmpty) {
      final photo = await widget.fetchPhoto(
        otherId,
        isWorker ? 'worker' : 'manager',
      );
      if (mounted) setState(() => _photoUrl = photo);
    }
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWorker = widget.conv.type == ConversationType.playerWorker;
    final label = isWorker
        ? (widget.conv.workerName ?? 'Worker')
        : (widget.conv.managerName ?? 'Manager');
    final tag = isWorker ? 'Worker' : 'Manager';
    final initial = isWorker ? 'W' : 'M';
    final hasMsg = widget.conv.lastMessage?.isNotEmpty == true;

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
      child: Semantics(
        button: true,
        label: '$tag conversation with $label',
        child: AppCard(
          onTap: widget.onTap,
          child: Row(
            children: [
              _ChatAvatar(photoUrl: _photoUrl, initial: initial),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SportChip(label: tag),
                        const Spacer(),
                        Text(
                          _fmt(
                            widget.conv.lastMessageAt ?? widget.conv.createdAt,
                          ),
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(label, style: theme.textTheme.titleMedium),
                    Text(
                      'Booking #${widget.conv.reservationId}',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      hasMsg
                          ? widget.conv.lastMessage!
                          : 'Tap to start chatting',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: hasMsg ? FontStyle.normal : FontStyle.italic,
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

class _ConversationScreen extends StatefulWidget {
  final ConversationModel conversation;
  final String myUid, myName;
  final String? playerToken;
  final VoidCallback onBack, onDelete;
  const _ConversationScreen({
    required this.conversation,
    required this.myUid,
    required this.myName,
    required this.playerToken,
    required this.onBack,
    required this.onDelete,
  });
  @override
  State<_ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<_ConversationScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _typing = false, _sending = false, _inputFocused = false;
  final _focusNode = FocusNode();
  String? _otherPhotoUrl;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(
      () => setState(() => _typing = _ctrl.text.trim().isNotEmpty),
    );
    _focusNode.addListener(
      () => setState(() => _inputFocused = _focusNode.hasFocus),
    );
    _loadOtherPhoto();
  }

  Future<void> _loadOtherPhoto() async {
    String? otherId;
    final isWorker = widget.conversation.type == ConversationType.playerWorker;

    if (isWorker) {
      otherId = widget.conversation.participantIds['worker'];
    } else {
      otherId = widget.conversation.participantIds['manager'];
    }

    if (otherId != null && otherId.isNotEmpty && widget.playerToken != null) {
      try {
        final userType = isWorker ? 'worker' : 'manager';
        final endpoint =
            '${ApiConstants.playerUserPhoto}/$userType/$otherId/photo';

        final response = await http.get(
          Uri.parse(endpoint),
          headers: {'Authorization': 'Bearer ${widget.playerToken}'},
        );

        if (response.statusCode == 200 && mounted) {
          final data = json.decode(response.body);
          String photoUrl = data['photoUrl'] ?? '';
          if (photoUrl.isNotEmpty) {
            if (!photoUrl.startsWith('http')) {
              photoUrl = '${ApiConstants.mediaBaseUrl}$photoUrl';
            }
            setState(() => _otherPhotoUrl = photoUrl);
          }
        } else {
          AppLogger.error('Failed with status: ${response.statusCode}');
        }
      } catch (e) {
        AppLogger.error('Error loading other photo: $e');
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    HapticFeedback.lightImpact();
    _ctrl.clear();
    setState(() {
      _typing = false;
      _sending = true;
    });
    try {
      await ChatService.instance.sendMessage(
        conversationId: widget.conversation.id,
        senderId: widget.myUid,
        text: text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool get _isWorker =>
      widget.conversation.type == ConversationType.playerWorker;

  String get _headerTitle {
    final c = widget.conversation;
    return _isWorker
        ? (c.workerName ?? 'Worker')
        : (c.managerName ?? 'Manager');
  }

  String get _headerSub =>
      '${_isWorker ? "Court Worker" : "Venue Manager"} · #${widget.conversation.reservationId}';

  String get _headerInitial => _isWorker ? 'W' : 'M';

  @override
  Widget build(BuildContext context) {
    final bot = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(child: _buildMessages()),
          _buildInputBar(bot),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.xxs,
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Back to inbox',
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              _ChatAvatar(
                photoUrl: _otherPhotoUrl,
                initial: _headerInitial,
                size: 48,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_headerTitle, style: theme.textTheme.titleMedium),
                    Text(
                      _headerSub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Delete conversation',
                onPressed: widget.onDelete,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: scheme.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessages() => StreamBuilder<List<MessageModel>>(
    stream: ChatService.instance.streamMessages(widget.conversation.id),
    builder: (_, snap) {
      if (snap.connectionState == ConnectionState.waiting) {
        return const Padding(
          padding: EdgeInsetsDirectional.all(AppSpacing.md),
          child: Column(
            children: [
              LoadingSkeleton(height: 48, borderRadius: AppRadius.input),
              SizedBox(height: AppSpacing.sm),
              LoadingSkeleton(height: 48, borderRadius: AppRadius.input),
            ],
          ),
        );
      }
      if (snap.hasError) {
        return ErrorState(
          title: 'Could not load messages',
          message: snap.error.toString(),
          onRetry: () => setState(() {}),
        );
      }
      final msgs = snap.data ?? [];
      if (msgs.isEmpty) {
        return EmptyState(
          icon: Icons.chat_bubble_outline_rounded,
          title: 'No messages yet',
          message: 'Say hi to your ${_isWorker ? "worker" : "manager"}!',
        );
      }
      _scrollToBottom();
      return ListView.builder(
        controller: _scroll,
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        itemCount: msgs.length,
        itemBuilder: (_, i) {
          final msg = msgs[i];
          final isMe = msg.senderId == widget.myUid;
          final showAvatar =
              !isMe &&
              (i == msgs.length - 1 || msgs[i + 1].senderId != msg.senderId);
          return _Bubble(
            msg: msg,
            isMe: isMe,
            theirInitial: _headerInitial,
            theirPhotoUrl: _otherPhotoUrl,
            showAvatar: showAvatar,
          );
        },
      );
    },
  );

  Widget _buildInputBar(double bot) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surface,
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          bot + AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                focusNode: _focusNode,
                minLines: 1,
                maxLines: 5,
                style: theme.textTheme.bodyLarge,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type a message…',
                  filled: true,
                  fillColor: _inputFocused
                      ? scheme.surfaceContainerHighest
                      : scheme.surface,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Semantics(
              button: true,
              label: 'Send message',
              child: FilledButton(
                onPressed: (_typing && !_sending) ? _send : null,
                style: FilledButton.styleFrom(
                  backgroundColor: NightMatchColors.actionLime,
                  foregroundColor: NightMatchColors.onAction,
                  minimumSize: const Size(48, 48),
                  shape: const CircleBorder(),
                  padding: EdgeInsets.zero,
                ),
                child: _sending
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: NightMatchColors.onAction,
                        ),
                      )
                    : Icon(
                        _typing
                            ? Icons.arrow_upward_rounded
                            : Icons.mic_rounded,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final MessageModel msg;
  final bool isMe, showAvatar;
  final String theirInitial;
  final String? theirPhotoUrl;

  const _Bubble({
    required this.msg,
    required this.isMe,
    required this.showAvatar,
    required this.theirInitial,
    this.theirPhotoUrl,
  });

  String _fmt(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            showAvatar
                ? Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: AppSpacing.xs,
                    ),
                    child: _ChatAvatar(
                      photoUrl: theirPhotoUrl,
                      initial: theirInitial,
                      size: 32,
                    ),
                  )
                : const SizedBox(width: 40),
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? NightMatchColors.actionLime
                        : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadiusDirectional.only(
                      topStart: const Radius.circular(AppRadius.input),
                      topEnd: const Radius.circular(AppRadius.input),
                      bottomStart: Radius.circular(
                        isMe ? AppRadius.input : AppRadius.xs,
                      ),
                      bottomEnd: Radius.circular(
                        isMe ? AppRadius.xs : AppRadius.input,
                      ),
                    ),
                  ),
                  child: Text(
                    msg.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isMe
                          ? NightMatchColors.onAction
                          : scheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(_fmt(msg.createdAt), style: theme.textTheme.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({
    required this.initial,
    this.photoUrl,
    this.size = 56,
  });

  final String initial;
  final String? photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.secondaryContainer,
        border: Border.all(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: photoUrl != null && photoUrl!.isNotEmpty
          ? Image.network(
              photoUrl!,
              fit: BoxFit.cover,
              width: size,
              height: size,
              errorBuilder: (_, _, _) => Text(
                initial,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: scheme.onSecondaryContainer,
                ),
              ),
            )
          : Text(
              initial,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: scheme.onSecondaryContainer,
              ),
            ),
    );
  }
}
