// Views/Manager/messages.dart
// Manager sees two types of conversations:
//   • player ↔ manager  (doc: reservation_{id})     — from players booking courts
//   • worker ↔ manager  (doc: worker_manager_{id})  — permanent team channels
// Uses deterministic UID: "sporta_manager_{strapiUserId}"

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
const _playerColor = kPrimary;
const _workerColor = Color(0xFF7C3AED);

class Messages extends StatefulWidget {
  final String? managerName;
  final String? managerToken;
  const Messages({super.key, this.managerName, this.managerToken});
  @override State<Messages> createState() => _MessagesState();
}

class _MessagesState extends State<Messages> with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  ConversationModel? _openConversation;
  String? _uid;
  bool _loadingUid = true;
  String? _uidError;
  late TabController _tabCtrl;
  
  // Cache for user photos
  final Map<String, String> _userPhotoCache = {};
  // Cache for usernames
  final Map<String, String> _usernameCache = {};

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
      final cached = FirebaseIdentityService.instance.firebaseUid;
      if (cached != null && cached.isNotEmpty) { _setUid(cached); return; }

      final token = await const FlutterSecureStorage().read(key: 'jwt_token');
      if (token != null && token.isNotEmpty) {
        final profile = await PlayerManagerAuthService.getMe(token);
        final user    = profile.containsKey('user') ? profile['user'] as Map<String, dynamic> : profile;
        final id      = user['id']?.toString() ?? '';
        if (id.isNotEmpty) { _setUid('sporta_manager_$id'); return; }
      }
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
  
  Future<String?> _fetchUsername(String userId, String userType) async {
    if (_usernameCache.containsKey(userId)) {
      return _usernameCache[userId];
    }
    
    try {
      final token = widget.managerToken ?? await const FlutterSecureStorage().read(key: 'jwt_token');
      if (token == null) return null;
      
      // Use the new custom endpoint
      final endpoint = '${ApiConstants.baseUrl}/managers/player/$userId/username';
      
      final response = await http.get(
        Uri.parse(endpoint),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      print('🔍 Fetch username response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🔍 User data: $data');
        
        final username = data['username']?.toString() ?? '';
        print('🔍 Found username: "$username"');
        
        if (username.isNotEmpty) {
          _usernameCache[userId] = username;
          return username;
        }
      }
      return null;
    } catch (e) {
      print('Error fetching username: $e');
      return null;
    }
  }
  
  Future<String?> _fetchUserPhoto(String userId, String userType) async {
    if (_userPhotoCache.containsKey(userId)) {
      return _userPhotoCache[userId];
    }
    
    try {
      final token = widget.managerToken ?? await const FlutterSecureStorage().read(key: 'jwt_token');
      if (token == null) return null;
      
      String endpoint;
      if (userType == 'player') {
        endpoint = '${ApiConstants.baseUrl}/players?populate[photo]=*&filters[player][id]=$userId';
      } else {
        endpoint = '${ApiConstants.baseUrl}/workers?populate[photo]=*&filters[worker][id]=$userId';
      }
      
      final response = await http.get(
        Uri.parse(endpoint),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['data'] ?? [];
        if (items.isNotEmpty) {
          final attrs = items[0]['attributes'] ?? items[0];
          String photoUrl = '';
          if (attrs['photo']?['data']?['attributes']?['url'] != null) {
            photoUrl = ApiConstants.getFullImageUrl(attrs['photo']['data']['attributes']['url'].toString());
          } else if (attrs['photo_url'] != null) {
            photoUrl = ApiConstants.getFullImageUrl(attrs['photo_url'].toString());
          }
          if (photoUrl.isNotEmpty) {
            _userPhotoCache[userId] = photoUrl;
            return photoUrl;
          }
        }
      }
      return null;
    } catch (e) {
      print('Error fetching photo for $userId: $e');
      return null;
    }
  }

  @override void dispose() { _tabCtrl.dispose(); _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_loadingUid) return const Scaffold(backgroundColor: kBg, body: Center(child: CircularProgressIndicator(color: kPrimary)));

    if (_uid == null) return _buildUidError();

    if (_openConversation != null) {
      return _ConversationScreen(
        conversation: _openConversation!,
        myUid:        _uid!,
        myName:       widget.managerName ?? 'Manager',
        managerToken: widget.managerToken,
        onBack:       () => setState(() => _openConversation = null),
      );
    }

    return Scaffold(
      backgroundColor: kBg,
      body: Column(children: [
        _buildHeader(),
        Container(
          color: kCard,
          child: TabBar(
            controller: _tabCtrl,
            labelColor:            kPrimary,
            unselectedLabelColor:  kTextMid,
            labelStyle:            const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            indicatorColor:        kPrimary,
            indicatorWeight:       2.5,
            dividerColor:          const Color(0xFFEAECF0),
            tabs: const [
              Tab(icon: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.person_rounded, size: 15), SizedBox(width: 5), Text('Players')])),
              Tab(icon: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.engineering_rounded, size: 15), SizedBox(width: 5), Text('Workers')])),
            ],
          ),
        ),
        Expanded(child: TabBarView(controller: _tabCtrl, children: [
          _buildPlayerList(),
          _buildWorkerList(),
        ])),
      ]),
    );
  }

  Widget _buildHeader() => Container(
    color: kCard,
    child: SafeArea(bottom: false, child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 0), child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Messages', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: kTextDark, letterSpacing: -0.6)),
          const SizedBox(height: 2),
          StreamBuilder<List<ConversationModel>>(
            stream: ChatService.instance.streamConversations(_uid!),
            builder: (_, snap) {
              final c = snap.data?.length ?? 0;
              return Text(c > 0 ? '$c conversation${c == 1 ? '' : 's'}' : 'No conversations yet',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c > 0 ? kPrimary : kTextMid));
            },
          ),
        ])),
        Container(width: 42, height: 42,
          decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(13),
              boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 3))]),
          child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18)),
      ])),
      const SizedBox(height: 14),
      Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 14), child: Container(
        height: 46,
        decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
        child: Row(children: [
          const SizedBox(width: 14),
          const Icon(Icons.search_rounded, color: kTextLight, size: 18),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: _searchCtrl,
            style: const TextStyle(fontSize: 14, color: kTextDark),
            decoration: const InputDecoration(
              hintText: 'Search…', hintStyle: TextStyle(color: kTextLight, fontSize: 14),
              border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 10),
            ))),
          if (_searchCtrl.text.isNotEmpty)
            GestureDetector(onTap: _searchCtrl.clear,
                child: const Padding(padding: EdgeInsets.only(right: 12), child: Icon(Icons.close_rounded, size: 15, color: kTextLight))),
        ]),
      )),
    ])),
  );

  Widget _buildPlayerList() => StreamBuilder<List<ConversationModel>>(
    stream: ChatService.instance.streamPlayerManagerConversations(_uid!),
    builder: (context, snap) {
      if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: kPrimary));
      if (snap.hasError) return _empty(Icons.wifi_off_rounded, 'Could not load', snap.error.toString());

      var convs = snap.data ?? [];
      final q = _searchCtrl.text.toLowerCase();
      if (q.isNotEmpty) {
        convs = convs.where((c) =>
          c.reservationId.contains(q) ||
          (c.lastMessage?.toLowerCase().contains(q) ?? false) ||
          (c.playerName?.toLowerCase().contains(q) ?? false)
        ).toList();
      }
      if (convs.isEmpty) return _empty(Icons.chat_bubble_outline_rounded, 'No player conversations yet', 'Conversations appear when players confirm bookings');

      return _buildList(convs, _playerColor, 'player');
    },
  );

  Widget _buildWorkerList() => StreamBuilder<List<ConversationModel>>(
    stream: ChatService.instance.streamWorkerManagerConversationsForManager(_uid!),
    builder: (context, snap) {
      if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: kPrimary));
      if (snap.hasError) return _empty(Icons.wifi_off_rounded, 'Could not load', snap.error.toString());

      var convs = snap.data ?? [];
      final q = _searchCtrl.text.toLowerCase();
      if (q.isNotEmpty) {
        convs = convs.where((c) =>
          (c.workerName?.toLowerCase().contains(q) ?? false) ||
          (c.lastMessage?.toLowerCase().contains(q) ?? false)
        ).toList();
      }
      if (convs.isEmpty) return _empty(Icons.engineering_rounded, 'No worker channels yet', 'Channels open automatically when you assign a worker to a court');

      return _buildList(convs, _workerColor, 'worker');
    },
  );

  Widget _buildList(List<ConversationModel> convs, Color accent, String userType) {
    final navH = kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(0, 8, 0, navH + 16),
      itemCount: convs.length,
      separatorBuilder: (_, __) => Divider(height: 1, indent: 86, color: Colors.black.withOpacity(0.05)),
      itemBuilder: (_, i) => _ConvTile(
        conv:         convs[i],
        myUid:        _uid!,
        accent:       accent,
        userType:     userType,
        managerToken: widget.managerToken,
        onTap:        () => setState(() => _openConversation = convs[i]),
        onFetchUsername: _fetchUsername,
      ),
    );
  }

  Widget _empty(IconData icon, String title, String sub) => Center(
    child: Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 52, color: kTextLight.withOpacity(0.4)),
      const SizedBox(height: 14),
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kTextDark), textAlign: TextAlign.center),
      if (sub.isNotEmpty) ...[const SizedBox(height: 6), Text(sub, style: const TextStyle(fontSize: 13, color: kTextMid), textAlign: TextAlign.center)],
    ])),
  );

  Widget _buildUidError() => Scaffold(
    backgroundColor: kBg,
    body: Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.wifi_off_rounded, size: 52, color: kTextLight.withOpacity(0.5)),
      const SizedBox(height: 14),
      const Text('Could not connect', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kTextDark)),
      if (_uidError != null) ...[const SizedBox(height: 6), Text(_uidError!, style: const TextStyle(fontSize: 13, color: kTextMid), textAlign: TextAlign.center)],
      const SizedBox(height: 20),
      GestureDetector(onTap: _resolveUid, child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
        decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(14)),
        child: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
      )),
    ]))),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CONVERSATION TILE with Photo and Username
// ─────────────────────────────────────────────────────────────────────────────
class _ConvTile extends StatefulWidget {
  final ConversationModel conv;
  final String myUid;
  final Color accent;
  final String userType;
  final String? managerToken;
  final VoidCallback onTap;
  final Future<String?> Function(String, String) onFetchUsername;

  const _ConvTile({
    required this.conv,
    required this.myUid,
    required this.accent,
    required this.userType,
    this.managerToken,
    required this.onTap,
    required this.onFetchUsername,
  });

  @override
  State<_ConvTile> createState() => _ConvTileState();
}

class _ConvTileState extends State<_ConvTile> {
  String? _photoUrl;
  bool _loadingPhoto = false;
  String? _displayName;
  bool _loadingName = false;

  @override
  void initState() {
    super.initState();
    _loadPhoto();
    _loadDisplayName();
  }

  Future<void> _loadDisplayName() async {
    if (widget.userType != 'player') {
      setState(() {
        _displayName = widget.conv.workerName ?? 'Worker';
      });
      return;
    }
    
    setState(() => _loadingName = true);
    
    final playerId = widget.conv.participantIds['player'];
    print('🔍 Loading username for player ID: $playerId');
    
    if (playerId != null) {
      final username = await widget.onFetchUsername(playerId, 'player');
      print('🔍 Username fetched: "$username"');
      setState(() {
        _displayName = (username != null && username.isNotEmpty) ? username : 'Player';
        _loadingName = false;
      });
    } else {
      setState(() {
        _displayName = 'Player';
        _loadingName = false;
      });
    }
  }

  Future<void> _loadPhoto() async {
    setState(() => _loadingPhoto = true);
    
    String? userId;
    if (widget.userType == 'player') {
      userId = widget.conv.participantIds['player'];
    } else {
      userId = widget.conv.participantIds['worker'];
    }
    
    if (userId != null && userId.isNotEmpty) {
      try {
        final token = widget.managerToken ?? await const FlutterSecureStorage().read(key: 'jwt_token');
        
        if (token != null) {
          final endpoint = '${ApiConstants.baseUrl}/managers/user/${widget.userType}/$userId/photo';
          
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
    return '${diff.inDays}d';
  }

  String get _title {
    if (_displayName != null && _displayName!.isNotEmpty) return _displayName!;
    return 'Player';
  }

  String get _subtitle {
    if (widget.conv.type == ConversationType.workerManager) return 'Team Channel';
    return 'Booking #${widget.conv.reservationId}';
  }

  String get _initial {
    if (_displayName != null && _displayName!.isNotEmpty) {
      return _displayName![0].toUpperCase();
    }
    if (widget.conv.type == ConversationType.workerManager) return 'W';
    return 'P';
  }

  @override
  Widget build(BuildContext context) {
    final hasMsg = widget.conv.lastMessage?.isNotEmpty == true;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        splashColor: widget.accent.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 11, 20, 11),
          child: Row(children: [
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
                          child: Center(child: Text(_initial, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: widget.accent))),
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
                        child: Center(child: Text(_initial, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: widget.accent))),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(
                    _loadingName ? 'Loading...' : _title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kTextDark),
                  ),
                ),
                Text(_fmt(widget.conv.lastMessageAt ?? widget.conv.createdAt), style: const TextStyle(fontSize: 11, color: kTextLight)),
              ]),
              const SizedBox(height: 2),
              Row(children: [
                Icon(widget.conv.type == ConversationType.workerManager ? Icons.engineering_rounded : Icons.confirmation_number_rounded, size: 10, color: widget.accent),
                const SizedBox(width: 4),
                Text(_subtitle, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: widget.accent)),
              ]),
              const SizedBox(height: 3),
              Text(
                hasMsg ? widget.conv.lastMessage! : 'No messages yet — say hello!',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: hasMsg ? kTextMid : kTextLight),
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
  final String? managerToken;
  final VoidCallback onBack;
  const _ConversationScreen({required this.conversation, required this.myUid, required this.myName, required this.managerToken, required this.onBack});
  @override State<_ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<_ConversationScreen> {
  final _ctrl   = TextEditingController();
  final _scroll = ScrollController();
  bool _typing = false, _sending = false;
  String? _otherPhotoUrl;
  bool _loadingPhoto = false;
  String? _otherDisplayName;
  bool _loadingName = false;

  @override void initState() { 
    super.initState(); 
    _ctrl.addListener(() => setState(() => _typing = _ctrl.text.trim().isNotEmpty)); 
    _loadOtherPhoto();
    _loadOtherName();
  }
  
  Future<void> _loadOtherName() async {
    setState(() => _loadingName = true);
    
    bool isWorker = widget.conversation.type == ConversationType.workerManager;
    
    if (isWorker) {
      setState(() {
        _otherDisplayName = widget.conversation.workerName ?? 'Worker';
        _loadingName = false;
      });
    } else {
      setState(() {
        _otherDisplayName = widget.conversation.playerName ?? 'Player';
        _loadingName = false;
      });
    }
  }
  
  Future<void> _loadOtherPhoto() async {
    setState(() => _loadingPhoto = true);
    
    String? otherId;
    bool isWorker = widget.conversation.type == ConversationType.workerManager;
    
    if (isWorker) {
      otherId = widget.conversation.participantIds['worker'];
    } else {
      otherId = widget.conversation.participantIds['player'];
    }
    
    if (otherId != null && otherId.isNotEmpty && widget.managerToken != null) {
      try {
        final userType = isWorker ? 'worker' : 'player';
        final endpoint = '${ApiConstants.baseUrl}/managers/user/$userType/$otherId/photo';
        
        final response = await http.get(
          Uri.parse(endpoint),
          headers: {'Authorization': 'Bearer ${widget.managerToken}'},
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
    _ctrl.clear(); setState(() { _typing = false; _sending = true; });
    try {
      await ChatService.instance.sendMessage(conversationId: widget.conversation.id, senderId: widget.myUid, text: text);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    });
  }

  Color get _accent => widget.conversation.type == ConversationType.workerManager ? const Color(0xFF7C3AED) : kPrimary;
  String get _title  => _otherDisplayName ?? (widget.conversation.type == ConversationType.workerManager ? (widget.conversation.workerName ?? 'Worker') : (widget.conversation.playerName ?? 'Player'));
  String get _sub    => widget.conversation.type == ConversationType.workerManager ? 'Team Channel' : 'Booking #${widget.conversation.reservationId}';
  String get _initial => _otherDisplayName != null && _otherDisplayName!.isNotEmpty ? _otherDisplayName![0].toUpperCase() : (widget.conversation.type == ConversationType.workerManager ? 'W' : 'P');

  @override
  Widget build(BuildContext context) {
    final bot = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Column(children: [
        Container(color: kCard, child: SafeArea(bottom: false, child: Column(children: [
          Container(height: 3, decoration: BoxDecoration(gradient: LinearGradient(colors: [_accent, _accent.withOpacity(0.6)]))),
          Padding(padding: const EdgeInsets.fromLTRB(4, 10, 16, 14), child: Row(children: [
            IconButton(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back_ios_rounded, size: 18, color: kTextDark), padding: EdgeInsets.zero),
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _accent.withOpacity(0.25), width: 1.5),
              ),
              child: ClipOval(
                child: _otherPhotoUrl != null && _otherPhotoUrl!.isNotEmpty
                    ? Image.network(
                        _otherPhotoUrl!,
                        fit: BoxFit.cover,
                        width: 42,
                        height: 42,
                        errorBuilder: (_, __, ___) => Container(
                          color: _accent.withOpacity(0.1),
                          child: Center(child: Text(_initial, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _accent))),
                        ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: _accent.withOpacity(0.1),
                            child: Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: _accent),
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: _accent.withOpacity(0.1),
                        child: Center(child: Text(_initial, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _accent))),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_loadingName ? 'Loading...' : _title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kTextDark), overflow: TextOverflow.ellipsis),
              Text(_sub, style: TextStyle(fontSize: 11, color: _accent, fontWeight: FontWeight.w600)),
            ])),
            Container(width: 36, height: 36, decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(11)),
                child: const Icon(Icons.more_vert_rounded, size: 18, color: kTextMid)),
          ])),
        ]))),
        Divider(height: 1, color: Colors.black.withOpacity(0.06)),
        Expanded(child: StreamBuilder<List<MessageModel>>(
          stream: ChatService.instance.streamMessages(widget.conversation.id),
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: kPrimary));
            final msgs = snap.data ?? [];
            if (msgs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.chat_bubble_outline_rounded, size: 44, color: kTextLight.withOpacity(0.4)),
              const SizedBox(height: 12),
              const Text('No messages yet', style: TextStyle(fontSize: 14, color: kTextMid)),
              const SizedBox(height: 4),
              const Text('Start the conversation!', style: TextStyle(fontSize: 12, color: kTextLight)),
            ]));
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
            });
            return ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: msgs.length,
              itemBuilder: (_, i) => _Bubble(
                msg: msgs[i], 
                isMe: msgs[i].senderId == widget.myUid, 
                theirInitial: _initial, 
                theirColor: _accent,
                theirPhotoUrl: !(msgs[i].senderId == widget.myUid) ? _otherPhotoUrl : null,
              ),
            );
          },
        )),
        Container(color: kCard, padding: EdgeInsets.fromLTRB(14, 10, 14, bot + 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(child: Container(
              constraints: const BoxConstraints(minHeight: 46),
              decoration: BoxDecoration(color: const Color(0xFFF7F8FA), borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _typing ? kPrimary.withOpacity(0.4) : Colors.black.withOpacity(0.07))),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: TextField(controller: _ctrl, minLines: 1, maxLines: 5,
                style: const TextStyle(fontSize: 15, color: kTextDark, height: 1.4),
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: 'Write a message…', hintStyle: TextStyle(color: kTextLight, fontSize: 15), border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 9))),
            )),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: (_typing && !_sending) ? _send : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200), width: 46, height: 46,
                decoration: BoxDecoration(color: (_typing && !_sending) ? kPrimary : kBg, shape: BoxShape.circle,
                    boxShadow: (_typing && !_sending) ? [BoxShadow(color: kPrimary.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 3))] : []),
                child: _sending
                    ? const Padding(padding: EdgeInsets.all(13), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(Icons.send_rounded, size: 19, color: _typing ? Colors.white : kTextLight),
              ),
            ),
          ])),
      ]),
    );
  }
}

class _Bubble extends StatelessWidget {
  final MessageModel msg;
  final bool isMe;
  final String theirInitial;
  final Color theirColor;
  final String? theirPhotoUrl;
  const _Bubble({required this.msg, required this.isMe, required this.theirInitial, required this.theirColor, this.theirPhotoUrl});

  String _fmt(DateTime? dt) => dt == null ? '' : '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.end, children: [
      if (!isMe) ...[
        Container(
          width: 28, height: 28,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: theirColor.withOpacity(0.3), width: 1),
          ),
          child: ClipOval(
            child: theirPhotoUrl != null && theirPhotoUrl!.isNotEmpty
                ? Image.network(
                    theirPhotoUrl!,
                    fit: BoxFit.cover,
                    width: 28,
                    height: 28,
                    errorBuilder: (_, __, ___) => Container(
                      color: theirColor.withOpacity(0.1),
                      child: Center(child: Text(theirInitial, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: theirColor))),
                    ),
                  )
                : Container(
                    color: theirColor.withOpacity(0.1),
                    child: Center(child: Text(theirInitial, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: theirColor))),
                  ),
          ),
        ),
      ],
      Flexible(child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? kPrimary : kCard,
          borderRadius: BorderRadius.only(topLeft: const Radius.circular(18), topRight: const Radius.circular(18), bottomLeft: Radius.circular(isMe ? 18 : 4), bottomRight: Radius.circular(isMe ? 4 : 18)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(msg.text, style: TextStyle(fontSize: 14, height: 1.4, color: isMe ? Colors.white : kTextDark)),
          const SizedBox(height: 4),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text(_fmt(msg.createdAt), style: TextStyle(fontSize: 10, color: isMe ? Colors.white.withOpacity(0.6) : kTextLight)),
            if (isMe) ...[const SizedBox(width: 4), Icon(Icons.done_all_rounded, size: 12, color: Colors.white.withOpacity(0.6))],
          ]),
        ]),
      )),
      if (isMe) const SizedBox(width: 4),
    ]),
  );
}















/*// Views/Manager/messages.dart
// Manager sees two types of conversations:
//   • player ↔ manager  (doc: reservation_{id})     — from players booking courts
//   • worker ↔ manager  (doc: worker_manager_{id})  — permanent team channels
// Uses deterministic UID: "sporta_manager_{strapiUserId}"

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Services/chat_service.dart';
import 'package:sporta/Services/firebase_identity_service.dart';
import 'package:sporta/Services/player_manager_auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ── Local palette ─────────────────────────────────────────────────────────────
const _playerColor = kPrimary;
const _workerColor = Color(0xFF7C3AED);

class Messages extends StatefulWidget {
  final String? managerName;
  const Messages({super.key, this.managerName});
  @override State<Messages> createState() => _MessagesState();
}

class _MessagesState extends State<Messages> with SingleTickerProviderStateMixin {
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
      final cached = FirebaseIdentityService.instance.firebaseUid;
      if (cached != null && cached.isNotEmpty) { _setUid(cached); return; }

      final token = await const FlutterSecureStorage().read(key: 'jwt_token');
      if (token != null && token.isNotEmpty) {
        final profile = await PlayerManagerAuthService.getMe(token);
        final user    = profile.containsKey('user') ? profile['user'] as Map<String, dynamic> : profile;
        final id      = user['id']?.toString() ?? '';
        if (id.isNotEmpty) { _setUid('sporta_manager_$id'); return; }
      }
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
    if (_loadingUid) return const Scaffold(backgroundColor: kBg, body: Center(child: CircularProgressIndicator(color: kPrimary)));

    if (_uid == null) return _buildUidError();

    if (_openConversation != null) {
      return _ConversationScreen(
        conversation: _openConversation!,
        myUid:        _uid!,
        myName:       widget.managerName ?? 'Manager',
        onBack:       () => setState(() => _openConversation = null),
      );
    }

    return Scaffold(
      backgroundColor: kBg,
      body: Column(children: [
        _buildHeader(),
        // Tabs: Players / Workers
        Container(
          color: kCard,
          child: TabBar(
            controller: _tabCtrl,
            labelColor:            kPrimary,
            unselectedLabelColor:  kTextMid,
            labelStyle:            const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            indicatorColor:        kPrimary,
            indicatorWeight:       2.5,
            dividerColor:          const Color(0xFFEAECF0),
            tabs: const [
              Tab(icon: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.person_rounded, size: 15), SizedBox(width: 5), Text('Players')])),
              Tab(icon: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.engineering_rounded, size: 15), SizedBox(width: 5), Text('Workers')])),
            ],
          ),
        ),
        Expanded(child: TabBarView(controller: _tabCtrl, children: [
          _buildPlayerList(),
          _buildWorkerList(),
        ])),
      ]),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() => Container(
    color: kCard,
    child: SafeArea(bottom: false, child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 0), child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Messages', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: kTextDark, letterSpacing: -0.6)),
          const SizedBox(height: 2),
          StreamBuilder<List<ConversationModel>>(
            stream: ChatService.instance.streamConversations(_uid!),
            builder: (_, snap) {
              final c = snap.data?.length ?? 0;
              return Text(c > 0 ? '$c conversation${c == 1 ? '' : 's'}' : 'No conversations yet',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c > 0 ? kPrimary : kTextMid));
            },
          ),
        ])),
        Container(width: 42, height: 42,
          decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(13),
              boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 3))]),
          child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18)),
      ])),
      const SizedBox(height: 14),
      Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 14), child: Container(
        height: 46,
        decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
        child: Row(children: [
          const SizedBox(width: 14),
          const Icon(Icons.search_rounded, color: kTextLight, size: 18),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: _searchCtrl,
            style: const TextStyle(fontSize: 14, color: kTextDark),
            decoration: const InputDecoration(
              hintText: 'Search…', hintStyle: TextStyle(color: kTextLight, fontSize: 14),
              border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 10),
            ))),
          if (_searchCtrl.text.isNotEmpty)
            GestureDetector(onTap: _searchCtrl.clear,
                child: const Padding(padding: EdgeInsets.only(right: 12), child: Icon(Icons.close_rounded, size: 15, color: kTextLight))),
        ]),
      )),
    ])),
  );

  // ── Player conversations tab ────────────────────────────────────────────────
  Widget _buildPlayerList() => StreamBuilder<List<ConversationModel>>(
    stream: ChatService.instance.streamPlayerManagerConversations(_uid!),
    builder: (context, snap) {
      if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: kPrimary));
      if (snap.hasError) return _empty(Icons.wifi_off_rounded, 'Could not load', snap.error.toString());

      var convs = snap.data ?? [];
      final q = _searchCtrl.text.toLowerCase();
      if (q.isNotEmpty) {
        convs = convs.where((c) =>
          c.reservationId.contains(q) ||
          (c.lastMessage?.toLowerCase().contains(q) ?? false) ||
          (c.playerName?.toLowerCase().contains(q) ?? false)
        ).toList();
      }
      if (convs.isEmpty) return _empty(Icons.chat_bubble_outline_rounded, 'No player conversations yet', 'Conversations appear when players confirm bookings');

      return _buildList(convs, _playerColor);
    },
  );

  // ── Worker conversations tab ────────────────────────────────────────────────
  Widget _buildWorkerList() => StreamBuilder<List<ConversationModel>>(
    stream: ChatService.instance.streamWorkerManagerConversationsForManager(_uid!),
    builder: (context, snap) {
      if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: kPrimary));
      if (snap.hasError) return _empty(Icons.wifi_off_rounded, 'Could not load', snap.error.toString());

      var convs = snap.data ?? [];
      final q = _searchCtrl.text.toLowerCase();
      if (q.isNotEmpty) {
        convs = convs.where((c) =>
          (c.workerName?.toLowerCase().contains(q) ?? false) ||
          (c.lastMessage?.toLowerCase().contains(q) ?? false)
        ).toList();
      }
      if (convs.isEmpty) return _empty(Icons.engineering_rounded, 'No worker channels yet', 'Channels open automatically when you assign a worker to a court');

      return _buildList(convs, _workerColor);
    },
  );

  Widget _buildList(List<ConversationModel> convs, Color accent) {
    final navH = kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(0, 8, 0, navH + 16),
      itemCount: convs.length,
      separatorBuilder: (_, __) => Divider(height: 1, indent: 86, color: Colors.black.withOpacity(0.05)),
      itemBuilder: (_, i) => _ConvTile(
        conv:   convs[i],
        myUid:  _uid!,
        accent: accent,
        onTap:  () => setState(() => _openConversation = convs[i]),
      ),
    );
  }

  Widget _empty(IconData icon, String title, String sub) => Center(
    child: Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 52, color: kTextLight.withOpacity(0.4)),
      const SizedBox(height: 14),
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kTextDark), textAlign: TextAlign.center),
      if (sub.isNotEmpty) ...[const SizedBox(height: 6), Text(sub, style: const TextStyle(fontSize: 13, color: kTextMid), textAlign: TextAlign.center)],
    ])),
  );

  Widget _buildUidError() => Scaffold(
    backgroundColor: kBg,
    body: Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.wifi_off_rounded, size: 52, color: kTextLight.withOpacity(0.5)),
      const SizedBox(height: 14),
      const Text('Could not connect', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kTextDark)),
      if (_uidError != null) ...[const SizedBox(height: 6), Text(_uidError!, style: const TextStyle(fontSize: 13, color: kTextMid), textAlign: TextAlign.center)],
      const SizedBox(height: 20),
      GestureDetector(onTap: _resolveUid, child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
        decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(14)),
        child: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
      )),
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
    return '${diff.inDays}d';
  }

  String get _title {
    if (conv.type == ConversationType.workerManager) return conv.workerName ?? 'Worker';
    return conv.playerName ?? 'Player #${conv.participantIds['player'] ?? '?'}';
  }

  String get _subtitle {
    if (conv.type == ConversationType.workerManager) return 'Team Channel';
    return 'Booking #${conv.reservationId}';
  }

  String get _initial {
    if (conv.type == ConversationType.workerManager) return 'W';
    return 'P';
  }

  @override
  Widget build(BuildContext context) {
    final hasMsg = conv.lastMessage?.isNotEmpty == true;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: accent.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 11, 20, 11),
          child: Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12), shape: BoxShape.circle,
                border: Border.all(color: accent.withOpacity(0.3), width: 1.5),
              ),
              child: Center(child: Text(_initial, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: accent))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(_title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kTextDark))),
                Text(_fmt(conv.lastMessageAt ?? conv.createdAt), style: const TextStyle(fontSize: 11, color: kTextLight)),
              ]),
              const SizedBox(height: 2),
              Row(children: [
                Icon(conv.type == ConversationType.workerManager ? Icons.engineering_rounded : Icons.confirmation_number_rounded, size: 10, color: accent),
                const SizedBox(width: 4),
                Text(_subtitle, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: accent)),
              ]),
              const SizedBox(height: 3),
              Text(
                hasMsg ? conv.lastMessage! : 'No messages yet — say hello!',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: hasMsg ? kTextMid : kTextLight),
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

  @override void initState() { super.initState(); _ctrl.addListener(() => setState(() => _typing = _ctrl.text.trim().isNotEmpty)); }
  @override void dispose() { _ctrl.dispose(); _scroll.dispose(); super.dispose(); }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    _ctrl.clear(); setState(() { _typing = false; _sending = true; });
    try {
      await ChatService.instance.sendMessage(conversationId: widget.conversation.id, senderId: widget.myUid, text: text);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    });
  }

  Color get _accent => widget.conversation.type == ConversationType.workerManager ? const Color(0xFF7C3AED) : kPrimary;
  String get _title  => widget.conversation.type == ConversationType.workerManager ? (widget.conversation.workerName ?? 'Worker') : (widget.conversation.playerName ?? 'Player');
  String get _sub    => widget.conversation.type == ConversationType.workerManager ? 'Team Channel' : 'Booking #${widget.conversation.reservationId}';
  String get _initial => widget.conversation.type == ConversationType.workerManager ? 'W' : 'P';

  @override
  Widget build(BuildContext context) {
    final bot = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Column(children: [
        Container(color: kCard, child: SafeArea(bottom: false, child: Column(children: [
          Container(height: 3, decoration: BoxDecoration(gradient: LinearGradient(colors: [_accent, _accent.withOpacity(0.6)]))),
          Padding(padding: const EdgeInsets.fromLTRB(4, 10, 16, 14), child: Row(children: [
            IconButton(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back_ios_rounded, size: 18, color: kTextDark), padding: EdgeInsets.zero),
            Container(width: 42, height: 42,
                decoration: BoxDecoration(color: _accent.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: _accent.withOpacity(0.25), width: 1.5)),
                child: Center(child: Text(_initial, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _accent)))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kTextDark)),
              Text(_sub, style: TextStyle(fontSize: 11, color: _accent, fontWeight: FontWeight.w600)),
            ])),
            Container(width: 36, height: 36, decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(11)),
                child: const Icon(Icons.more_vert_rounded, size: 18, color: kTextMid)),
          ])),
        ]))),
        Divider(height: 1, color: Colors.black.withOpacity(0.06)),
        Expanded(child: StreamBuilder<List<MessageModel>>(
          stream: ChatService.instance.streamMessages(widget.conversation.id),
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: kPrimary));
            final msgs = snap.data ?? [];
            if (msgs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.chat_bubble_outline_rounded, size: 44, color: kTextLight.withOpacity(0.4)),
              const SizedBox(height: 12),
              const Text('No messages yet', style: TextStyle(fontSize: 14, color: kTextMid)),
              const SizedBox(height: 4),
              const Text('Start the conversation!', style: TextStyle(fontSize: 12, color: kTextLight)),
            ]));
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
            });
            return ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: msgs.length,
              itemBuilder: (_, i) => _Bubble(msg: msgs[i], isMe: msgs[i].senderId == widget.myUid, theirInitial: _initial, theirColor: _accent),
            );
          },
        )),
        Container(color: kCard, padding: EdgeInsets.fromLTRB(14, 10, 14, bot + 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(child: Container(
              constraints: const BoxConstraints(minHeight: 46),
              decoration: BoxDecoration(color: const Color(0xFFF7F8FA), borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _typing ? kPrimary.withOpacity(0.4) : Colors.black.withOpacity(0.07))),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: TextField(controller: _ctrl, minLines: 1, maxLines: 5,
                style: const TextStyle(fontSize: 15, color: kTextDark, height: 1.4),
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: 'Write a message…', hintStyle: TextStyle(color: kTextLight, fontSize: 15), border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 9))),
            )),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: (_typing && !_sending) ? _send : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200), width: 46, height: 46,
                decoration: BoxDecoration(color: (_typing && !_sending) ? kPrimary : kBg, shape: BoxShape.circle,
                    boxShadow: (_typing && !_sending) ? [BoxShadow(color: kPrimary.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 3))] : []),
                child: _sending
                    ? const Padding(padding: EdgeInsets.all(13), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(Icons.send_rounded, size: 19, color: _typing ? Colors.white : kTextLight),
              ),
            ),
          ])),
      ]),
    );
  }
}

class _Bubble extends StatelessWidget {
  final MessageModel msg;
  final bool isMe;
  final String theirInitial;
  final Color theirColor;
  const _Bubble({required this.msg, required this.isMe, required this.theirInitial, required this.theirColor});

  String _fmt(DateTime? dt) => dt == null ? '' : '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.end, children: [
      if (!isMe) ...[
        Container(width: 28, height: 28, margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(color: theirColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Center(child: Text(theirInitial, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: theirColor)))),
      ],
      Flexible(child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? kPrimary : kCard,
          borderRadius: BorderRadius.only(topLeft: const Radius.circular(18), topRight: const Radius.circular(18), bottomLeft: Radius.circular(isMe ? 18 : 4), bottomRight: Radius.circular(isMe ? 4 : 18)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(msg.text, style: TextStyle(fontSize: 14, height: 1.4, color: isMe ? Colors.white : kTextDark)),
          const SizedBox(height: 4),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text(_fmt(msg.createdAt), style: TextStyle(fontSize: 10, color: isMe ? Colors.white.withOpacity(0.6) : kTextLight)),
            if (isMe) ...[const SizedBox(width: 4), Icon(Icons.done_all_rounded, size: 12, color: Colors.white.withOpacity(0.6))],
          ]),
        ]),
      )),
      if (isMe) const SizedBox(width: 4),
    ]),
  );
}
















// Views/Manager/messages.dart
// Uses deterministic UID: "sporta_manager_{strapiUserId}"

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Services/chat_service.dart';
import 'package:sporta/Services/firebase_identity_service.dart';
import 'package:sporta/Services/player_manager_auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Messages extends StatefulWidget {
  final String? managerName;
  const Messages({super.key, this.managerName});

  @override
  State<Messages> createState() => _MessagesState();
}

class _MessagesState extends State<Messages> {
  final _searchCtrl = TextEditingController();
  ConversationModel? _openConversation;

  String? _uid;
  bool _loadingUid = true;
  String? _uidError;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    _resolveUid();
  }

  Future<void> _resolveUid() async {
    setState(() { _loadingUid = true; _uidError = null; });
    try {
      // First, ensure FirebaseIdentityService has the deterministic UID
      final firebaseUid = FirebaseIdentityService.instance.firebaseUid;
      
      if (firebaseUid != null && firebaseUid.isNotEmpty) {
        debugPrint('[Messages] Using deterministic UID: $firebaseUid');
        if (mounted) setState(() { _uid = firebaseUid; _loadingUid = false; });
        return;
      }
      
      // If not set, try to get it from Strapi
      final storage = FlutterSecureStorage();
      final token = await storage.read(key: 'jwt_token');
      
      if (token != null) {
        final profile = await PlayerManagerAuthService.getMe(token);
        final user = profile.containsKey('user') ? profile['user'] as Map<String, dynamic> : profile;
        final userId = user['id']?.toString() ?? '';
        
        if (userId.isNotEmpty) {
          // Build deterministic UID for manager (same as backend)
          final deterministicUid = 'sporta_manager_$userId';
          debugPrint('[Messages] Built deterministic UID: $deterministicUid');
          if (mounted) setState(() { _uid = deterministicUid; _loadingUid = false; });
          return;
        }
      }
      
      // Last resort: try to get from Firebase Auth
      final auth = FirebaseAuth.instance;
      User? firebaseUser = auth.currentUser;
      if (firebaseUser == null) {
        final cred = await auth.signInAnonymously();
        firebaseUser = cred.user;
      }
      if (firebaseUser != null) {
        debugPrint('[Messages] WARNING: Using anonymous UID: ${firebaseUser.uid}');
        if (mounted) setState(() { _uid = firebaseUser!.uid; _loadingUid = false; });
      } else {
        throw Exception('Could not get any UID');
      }
      
    } catch (e) {
      debugPrint('[Messages] uid error: $e');
      if (mounted) setState(() { _uidError = e.toString(); _loadingUid = false; });
    }
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_loadingUid) {
      return const Scaffold(
        backgroundColor: kBg,
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircularProgressIndicator(color: kPrimary),
          SizedBox(height: 16),
          Text('Loading messages…', style: TextStyle(fontSize: 14, color: kTextMid)),
        ])),
      );
    }

    if (_uid == null || _uid!.isEmpty) {
      return Scaffold(
        backgroundColor: kBg,
        body: Center(child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.wifi_off_rounded, size: 52, color: kTextLight.withOpacity(0.5)),
            const SizedBox(height: 14),
            const Text('Could not connect', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kTextDark)),
            const SizedBox(height: 6),
            Text(_uidError ?? 'Please check your connection', style: const TextStyle(fontSize: 13, color: kTextMid), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _resolveUid,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(14)),
                child: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
          ]),
        )),
      );
    }

    return Scaffold(
      backgroundColor: kBg,
      body: _openConversation != null
          ? _ConversationScreen(
              conversation: _openConversation!,
              myUid: _uid!,
              myName: widget.managerName ?? 'Manager',
              onBack: () => setState(() => _openConversation = null),
            )
          : _ListScreen(
              myUid: _uid!,
              searchCtrl: _searchCtrl,
              onOpen: (conv) => setState(() => _openConversation = conv),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LIST SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class _ListScreen extends StatelessWidget {
  final String myUid;
  final TextEditingController searchCtrl;
  final ValueChanged<ConversationModel> onOpen;
  const _ListScreen({required this.myUid, required this.searchCtrl, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final navH = kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    return Column(children: [
      _buildHeader(),
      Divider(height: 1, color: Colors.black.withOpacity(0.06)),
      Expanded(child: _buildList(navH)),
    ]);
  }

  Widget _buildHeader() => Container(
    color: kCard,
    child: SafeArea(bottom: false, child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 0), child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Messages', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: kTextDark, letterSpacing: -0.6)),
          const SizedBox(height: 2),
          StreamBuilder<List<ConversationModel>>(
            stream: ChatService.instance.streamConversations(myUid),
            builder: (_, snap) {
              final c = snap.data?.length ?? 0;
              return Text(c > 0 ? '$c conversation${c == 1 ? '' : 's'}' : 'No conversations yet',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c > 0 ? kPrimary : kTextMid));
            },
          ),
        ])),
        Container(width: 42, height: 42,
            decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(13),
                boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 3))]),
            child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18)),
      ])),
      const SizedBox(height: 14),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Container(
        height: 48,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, 2))]),
        child: Row(children: [
          const SizedBox(width: 14),
          const Icon(Icons.search_rounded, color: kTextLight, size: 18),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: searchCtrl,
            style: const TextStyle(fontSize: 14, color: kTextDark),
            decoration: const InputDecoration(
              hintText: 'Search players or bookings…', hintStyle: TextStyle(color: kTextLight, fontSize: 14),
              border: InputBorder.none, enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 10),
            ))),
          if (searchCtrl.text.isNotEmpty)
            GestureDetector(onTap: searchCtrl.clear,
                child: const Padding(padding: EdgeInsets.only(right: 12),
                    child: Icon(Icons.close_rounded, size: 15, color: kTextLight))),
        ]),
      )),
      const SizedBox(height: 16),
    ])),
  );

  Widget _buildList(double navH) => StreamBuilder<List<ConversationModel>>(
    stream: ChatService.instance.streamConversations(myUid),
    builder: (context, snap) {
      if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: kPrimary));
      if (snap.hasError) return _empty(Icons.wifi_off_rounded, 'Could not load chats', snap.error.toString());

      var convs = snap.data ?? [];
      final q = searchCtrl.text.toLowerCase();
      if (q.isNotEmpty) {
        convs = convs.where((c) => c.reservationId.contains(q) || (c.lastMessage?.toLowerCase().contains(q) ?? false)).toList();
      }
      if (convs.isEmpty) return _empty(Icons.chat_bubble_outline_rounded, 'No conversations yet', 'Conversations appear when players confirm bookings');

      return ListView.separated(
        padding: EdgeInsets.fromLTRB(0, 8, 0, navH + 16),
        itemCount: convs.length,
        separatorBuilder: (_, __) => Divider(height: 1, indent: 86, color: Colors.black.withOpacity(0.05)),
        itemBuilder: (_, i) => _ConvTile(conv: convs[i], myUid: myUid, onTap: () => onOpen(convs[i])),
      );
    },
  );

  Widget _empty(IconData icon, String title, String sub) => Center(
    child: Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 52, color: kTextLight.withOpacity(0.5)),
      const SizedBox(height: 14),
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kTextDark), textAlign: TextAlign.center),
      if (sub.isNotEmpty) ...[const SizedBox(height: 6), Text(sub, style: const TextStyle(fontSize: 13, color: kTextMid), textAlign: TextAlign.center)],
    ])),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CONVERSATION TILE
// ─────────────────────────────────────────────────────────────────────────────
class _ConvTile extends StatelessWidget {
  final ConversationModel conv;
  final String myUid;
  final VoidCallback onTap;
  const _ConvTile({required this.conv, required this.myUid, required this.onTap});

  String _fmt(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final hasMsg = conv.lastMessage?.isNotEmpty == true;
    final playerLabel = 'Player #${conv.participantIds['player'] ?? '?'}';
    final initial = conv.participantIds['player']?.isNotEmpty == true
        ? 'P${conv.participantIds['player']}'
        : 'P?';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: kPrimary.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 11, 20, 11),
          child: Row(children: [
            Container(width: 52, height: 52,
                decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), shape: BoxShape.circle,
                    border: Border.all(color: kPrimary.withOpacity(0.25), width: 1.5)),
                child: Center(child: Text(
                    initial.length >= 2 ? initial.substring(0, 2).toUpperCase() : 'P',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kPrimary)))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(playerLabel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kTextDark))),
                Text(_fmt(conv.lastMessageAt ?? conv.createdAt), style: const TextStyle(fontSize: 11, color: kTextLight)),
              ]),
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.confirmation_number_rounded, size: 10, color: kPrimary),
                const SizedBox(width: 4),
                Text('Booking #${conv.reservationId}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kPrimary)),
              ]),
              const SizedBox(height: 3),
              Text(hasMsg ? conv.lastMessage! : 'No messages yet — say hello!',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: hasMsg ? kTextMid : kTextLight)),
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

  @override
  void dispose() { _ctrl.dispose(); _scroll.dispose(); super.dispose(); }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    _ctrl.clear();
    setState(() { _typing = false; _sending = true; });
    try {
      await ChatService.instance.sendMessage(
          conversationId: widget.conversation.id, senderId: widget.myUid, text: text);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bot  = MediaQuery.of(context).padding.bottom;
    final conv = widget.conversation;
    final playerLabel = 'Player #${conv.participantIds['player'] ?? '?'}';
    final initial = conv.participantIds['player']?.isNotEmpty == true
        ? 'P${conv.participantIds['player']}'
        : 'P?';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Column(children: [
        Container(color: kCard, child: SafeArea(bottom: false, child: Column(children: [
          Container(height: 3, decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [kPrimary, Color(0xFF007B7D)]))),
          Padding(padding: const EdgeInsets.fromLTRB(4, 10, 16, 14), child: Row(children: [
            IconButton(onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_ios_rounded, size: 18, color: kTextDark), padding: EdgeInsets.zero),
            Container(width: 42, height: 42,
                decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), shape: BoxShape.circle,
                    border: Border.all(color: kPrimary.withOpacity(0.25), width: 1.5)),
                child: Center(child: Text(
                    initial.length >= 2 ? initial.substring(0, 2).toUpperCase() : 'P',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kPrimary)))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(playerLabel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kTextDark)),
              Text('Booking #${conv.reservationId}', style: const TextStyle(fontSize: 11, color: kPrimary, fontWeight: FontWeight.w600)),
            ])),
            Container(width: 36, height: 36, decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(11)),
                child: const Icon(Icons.more_vert_rounded, size: 18, color: kTextMid)),
          ])),
        ]))),
        Divider(height: 1, color: Colors.black.withOpacity(0.06)),
        Expanded(child: StreamBuilder<List<MessageModel>>(
          stream: ChatService.instance.streamMessages(conv.id),
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: kPrimary));
            final msgs = snap.data ?? [];
            if (msgs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.chat_bubble_outline_rounded, size: 44, color: kTextLight.withOpacity(0.4)),
              const SizedBox(height: 12),
              const Text('No messages yet', style: TextStyle(fontSize: 14, color: kTextMid)),
              const SizedBox(height: 4),
              const Text('Start the conversation!', style: TextStyle(fontSize: 12, color: kTextLight)),
            ]));
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
            });
            return ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: msgs.length,
              itemBuilder: (_, i) => _Bubble(msg: msgs[i], isMe: msgs[i].senderId == widget.myUid,
                  theirInitial: initial.isNotEmpty ? initial[0] : 'P'),
            );
          },
        )),
        Container(color: kCard, padding: EdgeInsets.fromLTRB(14, 10, 14, bot + 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(child: Container(
              constraints: const BoxConstraints(minHeight: 46),
              decoration: BoxDecoration(color: const Color(0xFFF7F8FA), borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _typing ? kPrimary.withOpacity(0.4) : Colors.black.withOpacity(0.07))),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: TextField(controller: _ctrl, minLines: 1, maxLines: 5,
                style: const TextStyle(fontSize: 15, color: kTextDark, height: 1.4),
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Write a message…', hintStyle: TextStyle(color: kTextLight, fontSize: 15),
                  border: InputBorder.none, enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 9),
                )),
            )),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: (_typing && !_sending) ? _send : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200), width: 46, height: 46,
                decoration: BoxDecoration(
                    color: (_typing && !_sending) ? kPrimary : kBg, shape: BoxShape.circle,
                    boxShadow: (_typing && !_sending)
                        ? [BoxShadow(color: kPrimary.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 3))]
                        : []),
                child: _sending
                    ? const Padding(padding: EdgeInsets.all(13), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(Icons.send_rounded, size: 19, color: _typing ? Colors.white : kTextLight),
              ),
            ),
          ])),
      ]),
    );
  }
}

class _Bubble extends StatelessWidget {
  final MessageModel msg;
  final bool isMe;
  final String theirInitial;
  const _Bubble({required this.msg, required this.isMe, required this.theirInitial});

  String _fmt(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isMe) ...[
          Container(width: 28, height: 28, margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), shape: BoxShape.circle),
              child: Center(child: Text(theirInitial,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: kPrimary)))),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? kPrimary : kCard,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4), bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(msg.text, style: TextStyle(fontSize: 14, height: 1.4, color: isMe ? Colors.white : kTextDark)),
              const SizedBox(height: 4),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text(_fmt(msg.createdAt), style: TextStyle(fontSize: 10, color: isMe ? Colors.white.withOpacity(0.6) : kTextLight)),
                if (isMe) ...[const SizedBox(width: 4), Icon(Icons.done_all_rounded, size: 12, color: Colors.white.withOpacity(0.6))],
              ]),
            ]),
          ),
        ),
        if (isMe) const SizedBox(width: 4),
      ],
    ),
  );
}*/