// Views/Worker/worker_chat_page.dart
// Worker sees two types of conversations:
//   • player ↔ worker   (doc: player_worker_{reservationId}) — per booking
//   • worker ↔ manager  (doc: worker_manager_{workerId})     — permanent team channel
// Uses deterministic UID: "sporta_worker_{strapiId}"

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Services/chat_service.dart';
import 'package:sporta/Services/firebase_identity_service.dart';
import 'package:sporta/Services/player_manager_auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sporta/Core/Constants/api_constants.dart';

// ── Local palette ─────────────────────────────────────────────────────────────
const _bg          = Color(0xFFF5F6FA);
const _white       = Colors.white;
const _dark        = Color(0xFF0D1117);
const _mid         = Color(0xFF6B7280);
const _light       = Color(0xFFB0B7C3);
const _playerColor = Color(0xFF0EA5E9);   // sky blue — player conversations
const _managerColor = kPrimary;           // teal    — manager channel

class WorkerChatPage extends StatefulWidget {
  final String? workerName;
  final String? workerToken;
  const WorkerChatPage({super.key, this.workerName, this.workerToken});
  @override State<WorkerChatPage> createState() => _WorkerChatPageState();
}

class _WorkerChatPageState extends State<WorkerChatPage> with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  ConversationModel? _openConversation;
  String? _uid;
  bool _loadingUid = true;
  String? _uidError;
  late TabController _tabCtrl;
  
  // Cache for user photos
  final Map<String, String> _userPhotoCache = {};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _searchCtrl.addListener(() => setState(() {}));
    _resolveUid();
  }

  Future<void> _resolveUid() async {
    setState(() { _loadingUid = true; _uidError = null; });
    try {
      // 1. Try FirebaseIdentityService cache
      final cached = FirebaseIdentityService.instance.firebaseUid;
      if (cached != null && cached.isNotEmpty) { _setUid(cached); return; }

      // 2. Build from JWT (worker token or stored token)
      final token = widget.workerToken
          ?? await const FlutterSecureStorage().read(key: 'jwt_token');
      if (token != null && token.isNotEmpty) {
        final profile = await PlayerManagerAuthService.getMe(token);
        final user    = profile.containsKey('user') ? profile['user'] as Map<String, dynamic> : profile;
        final id      = user['id']?.toString() ?? '';
        if (id.isNotEmpty) { _setUid('sporta_worker_$id'); return; }
      }

      // 3. Firebase anonymous fallback
      var fbUser = FirebaseAuth.instance.currentUser;
      fbUser ??= (await FirebaseAuth.instance.signInAnonymously()).user;
      if (fbUser != null) { _setUid(fbUser.uid); return; }
      throw Exception('Could not resolve UID');
    } catch (e) {
      if (mounted) setState(() { _uidError = e.toString(); _loadingUid = false; });
    }
  }

  void _setUid(String uid) {
    if (mounted) setState(() { _uid = uid; _loadingUid = false; });
  }
  
  Future<String?> _fetchUserPhoto(String userId, String userType) async {
    if (_userPhotoCache.containsKey('$userType:$userId')) {
      return _userPhotoCache['$userType:$userId'];
    }
    
    try {
      final token = widget.workerToken ?? await const FlutterSecureStorage().read(key: 'jwt_token');
      if (token == null) return null;
      
      final endpoint = '${ApiConstants.workerUserPhoto}/$userType/$userId/photo';
      
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
      }
      return null;
    } catch (e) {
      print('Error fetching photo for $userType $userId: $e');
      return null;
    }
  }

  @override void dispose() { _tabCtrl.dispose(); _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_loadingUid) {
      return const Scaffold(backgroundColor: _bg, body: Center(child: CircularProgressIndicator(color: kPrimary)));
    }
    if (_uid == null) return _buildUidError();

    if (_openConversation != null) {
      return _ConversationScreen(
        conversation: _openConversation!,
        myUid:        _uid!,
        myName:       widget.workerName ?? 'Worker',
        workerToken:  widget.workerToken,
        onBack:       () => setState(() => _openConversation = null),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      body: Column(children: [
        _buildHeader(),
        // Tabs: Players / My Manager
        Container(
          color: _white,
          child: TabBar(
            controller:          _tabCtrl,
            labelColor:          kPrimary,
            unselectedLabelColor: _mid,
            labelStyle:          const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            indicatorColor:      kPrimary,
            indicatorWeight:     2.5,
            dividerColor:        const Color(0xFFEAECF0),
            tabs: const [
              Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.person_rounded, size: 15),
                SizedBox(width: 6),
                Text('Players'),
              ])),
              Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.business_center_rounded, size: 15),
                SizedBox(width: 6),
                Text('My Manager'),
              ])),
            ],
          ),
        ),
        Expanded(child: TabBarView(controller: _tabCtrl, children: [
          _buildPlayerList(),
          _buildManagerChannel(),
        ])),
      ]),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() => Container(
    color: _white,
    child: SafeArea(bottom: false, child: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Messages', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _dark, letterSpacing: -0.6)),
            const SizedBox(height: 2),
            StreamBuilder<List<ConversationModel>>(
              stream: ChatService.instance.streamConversations(_uid!),
              builder: (_, snap) {
                final c = snap.data?.length ?? 0;
                return Text(
                  c > 0 ? '$c conversation${c == 1 ? '' : 's'}' : 'No conversations yet',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: c > 0 ? kPrimary : _mid),
                );
              },
            ),
          ])),
          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kPrimary.withOpacity(0.2)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)),
              const SizedBox(width: 7),
              const Text('Worker', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kPrimary)),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 14),
      // Search bar
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F2F8),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            const SizedBox(width: 14),
            Icon(Icons.search_rounded, color: Colors.grey[400], size: 18),
            const SizedBox(width: 10),
            Expanded(child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(fontSize: 14, color: _dark),
              decoration: InputDecoration(
                hintText: 'Search conversations…',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                border: InputBorder.none, isDense: true,
              ),
            )),
            if (_searchCtrl.text.isNotEmpty)
              GestureDetector(
                onTap: () => setState(() => _searchCtrl.clear()),
                child: Padding(padding: const EdgeInsets.only(right: 10), child: Icon(Icons.close_rounded, size: 18, color: Colors.grey[400])),
              ),
          ]),
        ),
      ),
    ])),
  );

  // ── Player conversations (player_worker_*) ──────────────────────────────────
  Widget _buildPlayerList() {
    return StreamBuilder<List<ConversationModel>>(
      stream: ChatService.instance.streamPlayerWorkerConversations(_uid!),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kPrimary));
        }
        if (snap.hasError) {
          return _emptyState(Icons.wifi_off_rounded, 'Could not load', snap.error.toString());
        }

        var convs = snap.data ?? [];
        final q = _searchCtrl.text.toLowerCase().trim();
        if (q.isNotEmpty) {
          convs = convs.where((c) =>
            c.reservationId.contains(q) ||
            (c.lastMessage?.toLowerCase().contains(q) ?? false) ||
            (c.playerName?.toLowerCase().contains(q) ?? false)
          ).toList();
        }

        if (convs.isEmpty) {
          return _emptyState(
            Icons.person_off_rounded,
            'No player chats yet',
            'Conversations appear when players book courts you manage.',
          );
        }

        return _buildConvList(convs, _playerColor, 'player');
      },
    );
  }

  // ── Manager channel (worker_manager_*) ─────────────────────────────────────
  Widget _buildManagerChannel() {
    return StreamBuilder<List<ConversationModel>>(
      stream: ChatService.instance.streamWorkerManagerConversationsForManager(_uid!),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kPrimary));
        }
        if (snap.hasError) {
          return _emptyState(Icons.wifi_off_rounded, 'Could not load', snap.error.toString());
        }

        final convs = snap.data ?? [];

        if (convs.isEmpty) {
          return _emptyState(
            Icons.business_center_rounded,
            'No manager channel yet',
            'This channel opens automatically when your manager assigns you to a court.',
          );
        }

        // Show the permanent worker↔manager channel(s)
        return _buildConvList(convs, _managerColor, 'manager');
      },
    );
  }

  Widget _buildConvList(List<ConversationModel> convs, Color accent, String userType) {
    final navH = kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(0, 8, 0, navH + 16),
      itemCount: convs.length,
      separatorBuilder: (_, __) => Divider(height: 1, indent: 82, color: Colors.black.withOpacity(0.05)),
      itemBuilder: (_, i) => _ConvTile(
        conv:       convs[i],
        myUid:      _uid!,
        accent:     accent,
        userType:   userType,
        workerToken: widget.workerToken,
        onTap:      () => setState(() => _openConversation = convs[i]),
      ),
    );
  }

  Widget _emptyState(IconData icon, String title, String sub) => Center(
    child: Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(color: kPrimary.withOpacity(0.07), shape: BoxShape.circle),
        child: Icon(icon, size: 32, color: kPrimary.withOpacity(0.5)),
      ),
      const SizedBox(height: 18),
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _dark), textAlign: TextAlign.center),
      const SizedBox(height: 6),
      Text(sub, style: const TextStyle(fontSize: 13, color: _mid, height: 1.5), textAlign: TextAlign.center),
    ])),
  );

  Widget _buildUidError() => Scaffold(
    backgroundColor: _bg,
    body: Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.lock_outline_rounded, size: 52, color: _light),
      const SizedBox(height: 14),
      const Text('Could not connect', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _dark)),
      if (_uidError != null) ...[
        const SizedBox(height: 6),
        Text(_uidError!, style: const TextStyle(fontSize: 12, color: _mid), textAlign: TextAlign.center, maxLines: 3),
      ],
      const SizedBox(height: 20),
      GestureDetector(
        onTap: _resolveUid,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
          decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(14)),
          child: const Text('Retry', style: TextStyle(color: _white, fontWeight: FontWeight.w700, fontSize: 14)),
        ),
      ),
    ]))),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CONVERSATION TILE with Photo
// ─────────────────────────────────────────────────────────────────────────────
class _ConvTile extends StatefulWidget {
  final ConversationModel conv;
  final String myUid;
  final Color accent;
  final String userType;
  final String? workerToken;
  final VoidCallback onTap;
  const _ConvTile({required this.conv, required this.myUid, required this.accent, required this.userType, this.workerToken, required this.onTap});

  @override
  State<_ConvTile> createState() => _ConvTileState();
}

class _ConvTileState extends State<_ConvTile> {
  String? _photoUrl;
  bool _loadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  Future<void> _loadPhoto() async {
    setState(() => _loadingPhoto = true);
    
    String? otherId;
    if (widget.userType == 'player') {
      otherId = widget.conv.participantIds['player'];
    } else {
      otherId = widget.conv.participantIds['manager'];
    }
    
    if (otherId != null && otherId.isNotEmpty) {
      try {
        final token = widget.workerToken ?? await const FlutterSecureStorage().read(key: 'jwt_token');
        if (token != null) {
          final endpoint = '${ApiConstants.workerUserPhoto}/${widget.userType}/$otherId/photo';
          
          final response = await http.get(
            Uri.parse(endpoint),
            headers: {'Authorization': 'Bearer $token'},
          );
          
          if (response.statusCode == 200 && mounted) {
            final data = json.decode(response.body);
            String photoUrl = data['photoUrl'] ?? '';
            
            if (photoUrl.isNotEmpty) {
              if (!photoUrl.startsWith('http')) {
                photoUrl = '${ApiConstants.mediaBaseUrl}$photoUrl';
              }
              setState(() => _photoUrl = photoUrl);
            }
          }
        }
      } catch (e) {
        print('Error loading photo: $e');
      }
    }
    
    if (mounted) setState(() => _loadingPhoto = false);
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24)   return '${diff.inHours}h';
    if (diff.inDays < 7)     return '${diff.inDays}d';
    return '${dt.day}/${dt.month}';
  }

  String get _title {
    if (widget.conv.type == ConversationType.workerManager) {
      return widget.conv.managerName ?? 'My Manager';
    }
    return widget.conv.playerName ?? 'Player #${widget.conv.participantIds['player'] ?? '?'}';
  }

  String get _subtitle {
    if (widget.conv.type == ConversationType.workerManager) return 'Team Channel · Always open';
    return 'Booking #${widget.conv.reservationId}';
  }

  String get _initial {
    if (widget.conv.type == ConversationType.workerManager) return 'M';
    return 'P';
  }

  IconData get _icon {
    if (widget.conv.type == ConversationType.workerManager) return Icons.business_center_rounded;
    return Icons.person_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final hasMsg = widget.conv.lastMessage?.isNotEmpty == true;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        splashColor: widget.accent.withOpacity(0.06),
        highlightColor: widget.accent.withOpacity(0.03),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Avatar with photo or fallback
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: widget.accent.withOpacity(0.3), width: 1.5),
              ),
              child: ClipOval(
                child: _photoUrl != null && _photoUrl!.isNotEmpty
                    ? Image.network(
                        _photoUrl!,
                        fit: BoxFit.cover,
                        width: 52,
                        height: 52,
                        errorBuilder: (_, __, ___) => Container(
                          color: widget.accent.withOpacity(0.12),
                          child: Center(child: Text(_initial, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: widget.accent))),
                        ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: widget.accent.withOpacity(0.12),
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: widget.accent),
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: widget.accent.withOpacity(0.12),
                        child: Center(child: Text(_initial, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: widget.accent))),
                      ),
              ),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(_title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _dark),
                    overflow: TextOverflow.ellipsis)),
                Text(_fmt(widget.conv.lastMessageAt ?? widget.conv.createdAt),
                    style: const TextStyle(fontSize: 11, color: _mid)),
              ]),
              const SizedBox(height: 3),
              Row(children: [
                Icon(_icon, size: 10, color: widget.accent),
                const SizedBox(width: 4),
                Text(_subtitle, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: widget.accent)),
              ]),
              const SizedBox(height: 4),
              Text(
                hasMsg ? widget.conv.lastMessage! : 'Tap to open conversation',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: hasMsg ? _mid : _light,
                    fontStyle: hasMsg ? FontStyle.normal : FontStyle.italic),
              ),
            ])),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONVERSATION SCREEN with Photo
// ─────────────────────────────────────────────────────────────────────────────
class _ConversationScreen extends StatefulWidget {
  final ConversationModel conversation;
  final String myUid, myName;
  final String? workerToken;
  final VoidCallback onBack;
  const _ConversationScreen({required this.conversation, required this.myUid, required this.myName, required this.workerToken, required this.onBack});
  @override State<_ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<_ConversationScreen> {
  final _ctrl   = TextEditingController();
  final _scroll = ScrollController();
  bool _typing = false, _sending = false;
  String? _otherPhotoUrl;
  bool _loadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() => _typing = _ctrl.text.trim().isNotEmpty));
    _loadOtherPhoto();
  }
  
  Future<void> _loadOtherPhoto() async {
    setState(() => _loadingPhoto = true);
    
    String? otherId;
    String otherType;
    bool isManager = widget.conversation.type == ConversationType.workerManager;
    
    if (isManager) {
      otherId = widget.conversation.participantIds['manager'];
      otherType = 'manager';
    } else {
      otherId = widget.conversation.participantIds['player'];
      otherType = 'player';
    }
    
    if (otherId != null && otherId.isNotEmpty && widget.workerToken != null) {
      try {
        final endpoint = '${ApiConstants.workerUserPhoto}/$otherType/$otherId/photo';
        
        final response = await http.get(
          Uri.parse(endpoint),
          headers: {'Authorization': 'Bearer ${widget.workerToken}'},
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
        }
      } catch (e) {
        print('Error loading other photo: $e');
      }
    }
    
    if (mounted) setState(() => _loadingPhoto = false);
  }

  @override void dispose() { _ctrl.dispose(); _scroll.dispose(); super.dispose(); }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    _ctrl.clear();
    setState(() { _typing = false; _sending = true; });
    try {
      await ChatService.instance.sendMessage(
        conversationId: widget.conversation.id,
        senderId:       widget.myUid,
        text:           text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  // Header meta per type
  Color get _accentColor {
    return widget.conversation.type == ConversationType.workerManager ? _managerColor : _playerColor;
  }

  String get _headerTitle {
    final conv = widget.conversation;
    if (conv.type == ConversationType.workerManager) return conv.managerName ?? 'My Manager';
    return conv.playerName ?? 'Player #${conv.participantIds['player'] ?? '?'}';
  }

  String get _headerSub {
    final conv = widget.conversation;
    if (conv.type == ConversationType.workerManager) return 'Team Channel · Manager';
    return 'Player · Booking #${conv.reservationId}';
  }

  String get _headerInitial {
    return widget.conversation.type == ConversationType.workerManager ? 'M' : 'P';
  }

  String get _emptyHint {
    return widget.conversation.type == ConversationType.workerManager
        ? 'Start coordinating with your manager!'
        : 'Say hello to the player!';
  }

  @override
  Widget build(BuildContext context) {
    final bot = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      body: Column(children: [

        // ── App bar ────────────────────────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(color: _white,
              boxShadow: [BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 2))]),
          child: SafeArea(bottom: false, child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
            child: Row(children: [
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded, size: 22, color: _dark),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 6),
              // Avatar with photo or fallback
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _accentColor.withOpacity(0.3), width: 1.5),
                ),
                child: ClipOval(
                  child: _otherPhotoUrl != null && _otherPhotoUrl!.isNotEmpty
                      ? Image.network(
                          _otherPhotoUrl!,
                          fit: BoxFit.cover,
                          width: 44,
                          height: 44,
                          errorBuilder: (_, __, ___) => Container(
                            color: _accentColor.withOpacity(0.12),
                            child: Center(child: Text(_headerInitial, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _accentColor))),
                          ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: _accentColor.withOpacity(0.12),
                              child: Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: _accentColor),
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: _accentColor.withOpacity(0.12),
                          child: Center(child: Text(_headerInitial, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _accentColor))),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_headerTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _dark), overflow: TextOverflow.ellipsis),
                Text(_headerSub, style: TextStyle(fontSize: 11, color: _accentColor, fontWeight: FontWeight.w600)),
              ])),
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: kPrimary.withOpacity(0.07), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.more_vert_rounded, size: 17, color: kPrimary),
              ),
            ]),
          )),
        ),

        // ── Messages ───────────────────────────────────────────────────────────
        Expanded(child: StreamBuilder<List<MessageModel>>(
          stream: ChatService.instance.streamMessages(widget.conversation.id),
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: kPrimary));
            }
            final msgs = snap.data ?? [];
            if (msgs.isEmpty) {
              return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(width: 64, height: 64,
                    decoration: BoxDecoration(color: _accentColor.withOpacity(0.08), shape: BoxShape.circle),
                    child: Icon(Icons.chat_bubble_outline_rounded, size: 28, color: _accentColor.withOpacity(0.5))),
                const SizedBox(height: 14),
                const Text('No messages yet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _mid)),
                const SizedBox(height: 4),
                Text(_emptyHint, style: const TextStyle(fontSize: 12, color: _light)),
              ]));
            }
            _scrollToBottom();
            return ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: msgs.length,
              itemBuilder: (_, i) {
                final msg        = msgs[i];
                final isMe       = msg.senderId == widget.myUid;
                final showAvatar = !isMe && (i == msgs.length - 1 || msgs[i + 1].senderId != msg.senderId);
                return _Bubble(
                  msg:          msg,
                  isMe:         isMe,
                  showAvatar:   showAvatar,
                  theirColor:   _accentColor,
                  theirInitial: _headerInitial,
                  theirPhotoUrl: !isMe ? _otherPhotoUrl : null,
                );
              },
            );
          },
        )),

        // ── Input bar ──────────────────────────────────────────────────────────
        Container(
          color: _white,
          padding: EdgeInsets.fromLTRB(12, 10, 12, bot + 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F8),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: _typing ? kPrimary.withOpacity(0.4) : Colors.transparent,
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: TextField(
                controller: _ctrl, minLines: 1, maxLines: 5,
                style: const TextStyle(fontSize: 15, color: _dark, height: 1.4),
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Type a message…',
                  hintStyle: TextStyle(color: _light, fontSize: 15),
                  border: InputBorder.none, isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            )),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: (_typing && !_sending) ? _send : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: (_typing && !_sending) ? kPrimary : kPrimary.withOpacity(0.12),
                  shape: BoxShape.circle,
                  boxShadow: (_typing && !_sending)
                      ? [BoxShadow(color: kPrimary.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]
                      : [],
                ),
                child: _sending
                    ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: _white))
                    : Icon(_typing ? Icons.send_rounded : Icons.mic_rounded, size: 20,
                        color: _typing ? _white : kPrimary),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BUBBLE with Photo
// ─────────────────────────────────────────────────────────────────────────────
class _Bubble extends StatelessWidget {
  final MessageModel msg;
  final bool isMe, showAvatar;
  final Color theirColor;
  final String theirInitial;
  final String? theirPhotoUrl;
  const _Bubble({
    required this.msg,
    required this.isMe,
    required this.showAvatar,
    required this.theirColor,
    required this.theirInitial,
    this.theirPhotoUrl,
  });

  String _fmt(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: 4, left: isMe ? 60 : 0, right: isMe ? 0 : 60),
    child: Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isMe) ...[
          showAvatar
              ? Container(
                  width: 30, height: 30,
                  margin: const EdgeInsets.only(right: 8, bottom: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: theirColor.withOpacity(0.3), width: 1),
                  ),
                  child: ClipOval(
                    child: theirPhotoUrl != null && theirPhotoUrl!.isNotEmpty
                        ? Image.network(
                            theirPhotoUrl!,
                            fit: BoxFit.cover,
                            width: 30,
                            height: 30,
                            errorBuilder: (_, __, ___) => Container(
                              color: theirColor.withOpacity(0.15),
                              child: Center(child: Text(theirInitial, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: theirColor))),
                            ),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: theirColor.withOpacity(0.15),
                                child: Center(
                                  child: SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: theirColor),
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: theirColor.withOpacity(0.15),
                            child: Center(child: Text(theirInitial, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: theirColor))),
                          ),
                  ),
                )
              : const SizedBox(width: 38),
        ],
        Flexible(child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? kPrimary : _white,
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(18),
                  topRight:    const Radius.circular(18),
                  bottomLeft:  Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: [BoxShadow(
                  color:  isMe ? kPrimary.withOpacity(0.22) : Colors.black.withOpacity(0.06),
                  blurRadius: 6, offset: const Offset(0, 2),
                )],
              ),
              child: Text(msg.text, style: TextStyle(fontSize: 14, height: 1.4, color: isMe ? _white : _dark)),
            ),
            const SizedBox(height: 3),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text(_fmt(msg.createdAt), style: const TextStyle(fontSize: 10, color: _light)),
              if (isMe) ...[
                const SizedBox(width: 4),
                const Icon(Icons.done_all_rounded, size: 13, color: kPrimary),
              ],
            ]),
          ],
        )),
        if (isMe) const SizedBox(width: 4),
      ],
    ),
  );
}
















/*// Views/Worker/worker_chat_page.dart
// Worker sees two types of conversations:
//   • player ↔ worker   (doc: player_worker_{reservationId}) — per booking
//   • worker ↔ manager  (doc: worker_manager_{workerId})     — permanent team channel
// Uses deterministic UID: "sporta_worker_{strapiId}"

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Services/chat_service.dart';
import 'package:sporta/Services/firebase_identity_service.dart';
import 'package:sporta/Services/player_manager_auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ── Local palette ─────────────────────────────────────────────────────────────
const _bg          = Color(0xFFF5F6FA);
const _white       = Colors.white;
const _dark        = Color(0xFF0D1117);
const _mid         = Color(0xFF6B7280);
const _light       = Color(0xFFB0B7C3);
const _playerColor = Color(0xFF0EA5E9);   // sky blue — player conversations
const _managerColor = kPrimary;           // teal    — manager channel

class WorkerChatPage extends StatefulWidget {
  final String? workerName;
  final String? workerToken;
  const WorkerChatPage({super.key, this.workerName, this.workerToken});
  @override State<WorkerChatPage> createState() => _WorkerChatPageState();
}

class _WorkerChatPageState extends State<WorkerChatPage> with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  ConversationModel? _openConversation;
  String? _uid;
  bool _loadingUid = true;
  String? _uidError;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _searchCtrl.addListener(() => setState(() {}));
    _resolveUid();
  }

  Future<void> _resolveUid() async {
    setState(() { _loadingUid = true; _uidError = null; });
    try {
      // 1. Try FirebaseIdentityService cache
      final cached = FirebaseIdentityService.instance.firebaseUid;
      if (cached != null && cached.isNotEmpty) { _setUid(cached); return; }

      // 2. Build from JWT (worker token or stored token)
      final token = widget.workerToken
          ?? await const FlutterSecureStorage().read(key: 'jwt_token');
      if (token != null && token.isNotEmpty) {
        final profile = await PlayerManagerAuthService.getMe(token);
        final user    = profile.containsKey('user') ? profile['user'] as Map<String, dynamic> : profile;
        final id      = user['id']?.toString() ?? '';
        if (id.isNotEmpty) { _setUid('sporta_worker_$id'); return; }
      }

      // 3. Firebase anonymous fallback
      var fbUser = FirebaseAuth.instance.currentUser;
      fbUser ??= (await FirebaseAuth.instance.signInAnonymously()).user;
      if (fbUser != null) { _setUid(fbUser.uid); return; }
      throw Exception('Could not resolve UID');
    } catch (e) {
      if (mounted) setState(() { _uidError = e.toString(); _loadingUid = false; });
    }
  }

  void _setUid(String uid) {
    if (mounted) setState(() { _uid = uid; _loadingUid = false; });
  }

  @override void dispose() { _tabCtrl.dispose(); _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_loadingUid) {
      return const Scaffold(backgroundColor: _bg, body: Center(child: CircularProgressIndicator(color: kPrimary)));
    }
    if (_uid == null) return _buildUidError();

    if (_openConversation != null) {
      return _ConversationScreen(
        conversation: _openConversation!,
        myUid:        _uid!,
        myName:       widget.workerName ?? 'Worker',
        onBack:       () => setState(() => _openConversation = null),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      body: Column(children: [
        _buildHeader(),
        // Tabs: Players / My Manager
        Container(
          color: _white,
          child: TabBar(
            controller:          _tabCtrl,
            labelColor:          kPrimary,
            unselectedLabelColor: _mid,
            labelStyle:          const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            indicatorColor:      kPrimary,
            indicatorWeight:     2.5,
            dividerColor:        const Color(0xFFEAECF0),
            tabs: const [
              Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.person_rounded, size: 15),
                SizedBox(width: 6),
                Text('Players'),
              ])),
              Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.business_center_rounded, size: 15),
                SizedBox(width: 6),
                Text('My Manager'),
              ])),
            ],
          ),
        ),
        Expanded(child: TabBarView(controller: _tabCtrl, children: [
          _buildPlayerList(),
          _buildManagerChannel(),
        ])),
      ]),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() => Container(
    color: _white,
    child: SafeArea(bottom: false, child: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Messages', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _dark, letterSpacing: -0.6)),
            const SizedBox(height: 2),
            StreamBuilder<List<ConversationModel>>(
              stream: ChatService.instance.streamConversations(_uid!),
              builder: (_, snap) {
                final c = snap.data?.length ?? 0;
                return Text(
                  c > 0 ? '$c conversation${c == 1 ? '' : 's'}' : 'No conversations yet',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: c > 0 ? kPrimary : _mid),
                );
              },
            ),
          ])),
          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kPrimary.withOpacity(0.2)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)),
              const SizedBox(width: 7),
              const Text('Worker', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kPrimary)),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 14),
      // Search bar
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F2F8),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            const SizedBox(width: 14),
            Icon(Icons.search_rounded, color: Colors.grey[400], size: 18),
            const SizedBox(width: 10),
            Expanded(child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(fontSize: 14, color: _dark),
              decoration: InputDecoration(
                hintText: 'Search conversations…',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                border: InputBorder.none, isDense: true,
              ),
            )),
            if (_searchCtrl.text.isNotEmpty)
              GestureDetector(
                onTap: () => setState(() => _searchCtrl.clear()),
                child: Padding(padding: const EdgeInsets.only(right: 10), child: Icon(Icons.close_rounded, size: 18, color: Colors.grey[400])),
              ),
          ]),
        ),
      ),
    ])),
  );

  // ── Player conversations (player_worker_*) ──────────────────────────────────
  Widget _buildPlayerList() {
    return StreamBuilder<List<ConversationModel>>(
      stream: ChatService.instance.streamPlayerWorkerConversations(_uid!),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kPrimary));
        }
        if (snap.hasError) {
          return _emptyState(Icons.wifi_off_rounded, 'Could not load', snap.error.toString());
        }

        var convs = snap.data ?? [];
        final q = _searchCtrl.text.toLowerCase().trim();
        if (q.isNotEmpty) {
          convs = convs.where((c) =>
            c.reservationId.contains(q) ||
            (c.lastMessage?.toLowerCase().contains(q) ?? false) ||
            (c.playerName?.toLowerCase().contains(q) ?? false)
          ).toList();
        }

        if (convs.isEmpty) {
          return _emptyState(
            Icons.person_off_rounded,
            'No player chats yet',
            'Conversations appear when players book courts you manage.',
          );
        }

        return _buildConvList(convs, _playerColor);
      },
    );
  }

  // ── Manager channel (worker_manager_*) ─────────────────────────────────────
  Widget _buildManagerChannel() {
    return StreamBuilder<List<ConversationModel>>(
      stream: ChatService.instance.streamWorkerManagerConversationsForManager(_uid!),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kPrimary));
        }
        if (snap.hasError) {
          return _emptyState(Icons.wifi_off_rounded, 'Could not load', snap.error.toString());
        }

        final convs = snap.data ?? [];

        if (convs.isEmpty) {
          return _emptyState(
            Icons.business_center_rounded,
            'No manager channel yet',
            'This channel opens automatically when your manager assigns you to a court.',
          );
        }

        // Show the permanent worker↔manager channel(s)
        return _buildConvList(convs, _managerColor);
      },
    );
  }

  Widget _buildConvList(List<ConversationModel> convs, Color accent) {
    final navH = kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(0, 8, 0, navH + 16),
      itemCount: convs.length,
      separatorBuilder: (_, __) => Divider(height: 1, indent: 82, color: Colors.black.withOpacity(0.05)),
      itemBuilder: (_, i) => _ConvTile(
        conv:  convs[i],
        myUid: _uid!,
        accent: accent,
        onTap: () => setState(() => _openConversation = convs[i]),
      ),
    );
  }

  Widget _emptyState(IconData icon, String title, String sub) => Center(
    child: Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(color: kPrimary.withOpacity(0.07), shape: BoxShape.circle),
        child: Icon(icon, size: 32, color: kPrimary.withOpacity(0.5)),
      ),
      const SizedBox(height: 18),
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _dark), textAlign: TextAlign.center),
      const SizedBox(height: 6),
      Text(sub, style: const TextStyle(fontSize: 13, color: _mid, height: 1.5), textAlign: TextAlign.center),
    ])),
  );

  Widget _buildUidError() => Scaffold(
    backgroundColor: _bg,
    body: Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.lock_outline_rounded, size: 52, color: _light),
      const SizedBox(height: 14),
      const Text('Could not connect', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _dark)),
      if (_uidError != null) ...[
        const SizedBox(height: 6),
        Text(_uidError!, style: const TextStyle(fontSize: 12, color: _mid), textAlign: TextAlign.center, maxLines: 3),
      ],
      const SizedBox(height: 20),
      GestureDetector(
        onTap: _resolveUid,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
          decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(14)),
          child: const Text('Retry', style: TextStyle(color: _white, fontWeight: FontWeight.w700, fontSize: 14)),
        ),
      ),
    ]))),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CONVERSATION TILE
// ─────────────────────────────────────────────────────────────────────────────
class _ConvTile extends StatelessWidget {
  final ConversationModel conv;
  final String myUid;
  final Color accent;
  final VoidCallback onTap;
  const _ConvTile({required this.conv, required this.myUid, required this.accent, required this.onTap});

  String _fmt(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24)   return '${diff.inHours}h';
    if (diff.inDays < 7)     return '${diff.inDays}d';
    return '${dt.day}/${dt.month}';
  }

  String get _title {
    if (conv.type == ConversationType.workerManager) {
      return conv.managerName ?? 'My Manager';
    }
    return conv.playerName ?? 'Player #${conv.participantIds['player'] ?? '?'}';
  }

  String get _subtitle {
    if (conv.type == ConversationType.workerManager) return 'Team Channel · Always open';
    return 'Booking #${conv.reservationId}';
  }

  String get _initial {
    if (conv.type == ConversationType.workerManager) return 'M';
    return 'P';
  }

  IconData get _icon {
    if (conv.type == ConversationType.workerManager) return Icons.business_center_rounded;
    return Icons.person_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final hasMsg = conv.lastMessage?.isNotEmpty == true;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: accent.withOpacity(0.06),
        highlightColor: accent.withOpacity(0.03),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Avatar
            Stack(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: accent.withOpacity(0.3), width: 1.5),
                ),
                child: Center(child: Text(_initial,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: accent))),
              ),
              // Permanent badge for manager channel
              if (conv.type == ConversationType.workerManager)
                Positioned(bottom: 0, right: 0, child: Container(
                  width: 16, height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E), shape: BoxShape.circle,
                    border: Border.all(color: _white, width: 2),
                  ),
                )),
            ]),
            const SizedBox(width: 14),

            // Content
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(_title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _dark),
                    overflow: TextOverflow.ellipsis)),
                Text(_fmt(conv.lastMessageAt ?? conv.createdAt),
                    style: const TextStyle(fontSize: 11, color: _mid)),
              ]),
              const SizedBox(height: 3),
              Row(children: [
                Icon(_icon, size: 10, color: accent),
                const SizedBox(width: 4),
                Text(_subtitle, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accent)),
              ]),
              const SizedBox(height: 4),
              Text(
                hasMsg ? conv.lastMessage! : 'Tap to open conversation',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: hasMsg ? _mid : _light,
                    fontStyle: hasMsg ? FontStyle.normal : FontStyle.italic),
              ),
            ])),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONVERSATION SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class _ConversationScreen extends StatefulWidget {
  final ConversationModel conversation;
  final String myUid, myName;
  final VoidCallback onBack;
  const _ConversationScreen({required this.conversation, required this.myUid, required this.myName, required this.onBack});
  @override State<_ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<_ConversationScreen> {
  final _ctrl   = TextEditingController();
  final _scroll = ScrollController();
  bool _typing = false, _sending = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() => _typing = _ctrl.text.trim().isNotEmpty));
  }

  @override void dispose() { _ctrl.dispose(); _scroll.dispose(); super.dispose(); }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    _ctrl.clear();
    setState(() { _typing = false; _sending = true; });
    try {
      await ChatService.instance.sendMessage(
        conversationId: widget.conversation.id,
        senderId:       widget.myUid,
        text:           text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  // Header meta per type
  Color get _accentColor {
    return widget.conversation.type == ConversationType.workerManager ? _managerColor : _playerColor;
  }

  String get _headerTitle {
    final conv = widget.conversation;
    if (conv.type == ConversationType.workerManager) return conv.managerName ?? 'My Manager';
    return conv.playerName ?? 'Player #${conv.participantIds['player'] ?? '?'}';
  }

  String get _headerSub {
    final conv = widget.conversation;
    if (conv.type == ConversationType.workerManager) return 'Team Channel · Manager';
    return 'Player · Booking #${conv.reservationId}';
  }

  String get _headerInitial {
    return widget.conversation.type == ConversationType.workerManager ? 'M' : 'P';
  }

  String get _emptyHint {
    return widget.conversation.type == ConversationType.workerManager
        ? 'Start coordinating with your manager!'
        : 'Say hello to the player!';
  }

  @override
  Widget build(BuildContext context) {
    final bot = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      body: Column(children: [

        // ── App bar ────────────────────────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(color: _white,
              boxShadow: [BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 2))]),
          child: SafeArea(bottom: false, child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
            child: Row(children: [
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded, size: 22, color: _dark),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 6),
              // Avatar
              Stack(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: _accentColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: _accentColor.withOpacity(0.3), width: 1.5),
                  ),
                  child: Center(child: Text(_headerInitial,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _accentColor))),
                ),
                if (widget.conversation.type == ConversationType.workerManager)
                  Positioned(bottom: 0, right: 0, child: Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(color: const Color(0xFF22C55E), shape: BoxShape.circle, border: Border.all(color: _white, width: 2)),
                  )),
              ]),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_headerTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _dark), overflow: TextOverflow.ellipsis),
                Text(_headerSub, style: TextStyle(fontSize: 11, color: _accentColor, fontWeight: FontWeight.w600)),
              ])),
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: kPrimary.withOpacity(0.07), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.more_vert_rounded, size: 17, color: kPrimary),
              ),
            ]),
          )),
        ),

        // ── Messages ───────────────────────────────────────────────────────────
        Expanded(child: StreamBuilder<List<MessageModel>>(
          stream: ChatService.instance.streamMessages(widget.conversation.id),
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: kPrimary));
            }
            final msgs = snap.data ?? [];
            if (msgs.isEmpty) {
              return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(width: 64, height: 64,
                    decoration: BoxDecoration(color: _accentColor.withOpacity(0.08), shape: BoxShape.circle),
                    child: Icon(Icons.chat_bubble_outline_rounded, size: 28, color: _accentColor.withOpacity(0.5))),
                const SizedBox(height: 14),
                const Text('No messages yet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _mid)),
                const SizedBox(height: 4),
                Text(_emptyHint, style: const TextStyle(fontSize: 12, color: _light)),
              ]));
            }
            _scrollToBottom();
            return ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: msgs.length,
              itemBuilder: (_, i) {
                final msg        = msgs[i];
                final isMe       = msg.senderId == widget.myUid;
                final showAvatar = !isMe && (i == msgs.length - 1 || msgs[i + 1].senderId != msg.senderId);
                return _Bubble(
                  msg:          msg,
                  isMe:         isMe,
                  showAvatar:   showAvatar,
                  theirColor:   _accentColor,
                  theirInitial: _headerInitial,
                );
              },
            );
          },
        )),

        // ── Input bar ──────────────────────────────────────────────────────────
        Container(
          color: _white,
          padding: EdgeInsets.fromLTRB(12, 10, 12, bot + 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F8),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: _typing ? kPrimary.withOpacity(0.4) : Colors.transparent,
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: TextField(
                controller: _ctrl, minLines: 1, maxLines: 5,
                style: const TextStyle(fontSize: 15, color: _dark, height: 1.4),
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Type a message…',
                  hintStyle: TextStyle(color: _light, fontSize: 15),
                  border: InputBorder.none, isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            )),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: (_typing && !_sending) ? _send : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: (_typing && !_sending) ? kPrimary : kPrimary.withOpacity(0.12),
                  shape: BoxShape.circle,
                  boxShadow: (_typing && !_sending)
                      ? [BoxShadow(color: kPrimary.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]
                      : [],
                ),
                child: _sending
                    ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: _white))
                    : Icon(_typing ? Icons.send_rounded : Icons.mic_rounded, size: 20,
                        color: _typing ? _white : kPrimary),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BUBBLE
// ─────────────────────────────────────────────────────────────────────────────
class _Bubble extends StatelessWidget {
  final MessageModel msg;
  final bool isMe, showAvatar;
  final Color theirColor;
  final String theirInitial;
  const _Bubble({
    required this.msg,
    required this.isMe,
    required this.showAvatar,
    required this.theirColor,
    required this.theirInitial,
  });

  String _fmt(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: 4, left: isMe ? 60 : 0, right: isMe ? 0 : 60),
    child: Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isMe) ...[
          showAvatar
              ? Container(
                  width: 30, height: 30,
                  margin: const EdgeInsets.only(right: 8, bottom: 2),
                  decoration: BoxDecoration(color: theirColor.withOpacity(0.15), shape: BoxShape.circle),
                  child: Center(child: Text(theirInitial,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: theirColor))))
              : const SizedBox(width: 38),
        ],
        Flexible(child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? kPrimary : _white,
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(18),
                  topRight:    const Radius.circular(18),
                  bottomLeft:  Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: [BoxShadow(
                  color:  isMe ? kPrimary.withOpacity(0.22) : Colors.black.withOpacity(0.06),
                  blurRadius: 6, offset: const Offset(0, 2),
                )],
              ),
              child: Text(msg.text, style: TextStyle(fontSize: 14, height: 1.4, color: isMe ? _white : _dark)),
            ),
            const SizedBox(height: 3),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text(_fmt(msg.createdAt), style: const TextStyle(fontSize: 10, color: _light)),
              if (isMe) ...[
                const SizedBox(width: 4),
                const Icon(Icons.done_all_rounded, size: 13, color: kPrimary),
              ],
            ]),
          ],
        )),
        if (isMe) const SizedBox(width: 4),
      ],
    ),
  );
}*/