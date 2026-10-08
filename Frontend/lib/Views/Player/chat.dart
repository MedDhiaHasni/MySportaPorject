// Views/Player/chat.dart
// Shows all conversations the player is part of:
//   • player ↔ manager  (doc: reservation_{id})      — labeled "Manager"
//   • player ↔ worker   (doc: player_worker_{id})    — labeled "Worker"
// Uses deterministic UID: "sporta_player_{strapiId}"

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Services/chat_service.dart';
import 'package:sporta/Services/firebase_identity_service.dart';
import 'package:sporta/Services/player_manager_auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sporta/Core/Constants/api_constants.dart';

// ── Design Tokens ─────────────────────────────────────────────────────────────
const _bg       = Color(0xFFF2F5F9);
const _surface  = Color(0xFFFFFFFF);
const _dark     = Color(0xFF0D1117);
const _mid      = Color(0xFF6B7280);
const _faint    = Color(0xFFB8BDC8);
const _online   = Color(0xFF22C55E);

// Teal brand ramp (matches kPrimary = #009999 area)
const _t900 = Color(0xFF001A1B);
const _t700 = Color(0xFF002B2C);
const _t500 = Color(0xFF006B6C);
const _t400 = Color(0xFF009999);
const _t200 = Color(0xFF4DD9D9);
const _tGlow = Color(0xFF00F0F0);

// Role accent
const _managerGrad = [Color(0xFF002B2C), Color(0xFF009999)];
const _workerGrad  = [Color(0xFF3730A3), Color(0xFF7C3AED)];
const _workerColor = Color(0xFF7C3AED);

class Chat extends StatefulWidget {
  final String? playerName;
  final String? playerToken;
  const Chat({super.key, this.playerName, this.playerToken});
  @override State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  ConversationModel? _openConversation;
  String? _uid;
  bool _loadingUid = true;
  String? _uidError;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  
  // Cache for user photos
  final Map<String, String> _userPhotoCache = {};

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
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
        final user = profile.containsKey('user') ? profile['user'] as Map<String, dynamic> : profile;
        final id = user['id']?.toString() ?? '';
        if (id.isNotEmpty) { _setUid('sporta_player_$id'); return; }
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
    if (mounted) {
      setState(() { _uid = uid; _loadingUid = false; });
      _fadeCtrl.forward();
    }
  }
  
  Future<String?> _fetchUserPhoto(String userId, String userType) async {
    if (_userPhotoCache.containsKey('$userType:$userId')) {
      return _userPhotoCache['$userType:$userId'];
    }
    
    try {
      final token = widget.playerToken ?? await const FlutterSecureStorage().read(key: 'jwt_token');
      if (token == null) return null;
      
      // ✅ Use the player endpoint for fetching manager/worker photos
      final endpoint = '${ApiConstants.playerUserPhoto}/$userType/$userId/photo';
      
      print('Fetching photo from: $endpoint');
      
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
          print('Photo found for $userType $userId: $photoUrl');
          return photoUrl;
        } else {
          print('No photo URL found for $userType $userId');
        }
      } else {
        print('Failed to fetch photo: ${response.statusCode}');
      }
      return null;
    } catch (e) {
      print('Error fetching photo for $userType $userId: $e');
      return null;
    }
  }

  Future<void> _deleteConversation(ConversationModel conv) async {
    final ok = await _confirmSheet(
      icon: Icons.delete_sweep_rounded,
      title: 'Delete conversation?',
      subtitle: 'This will permanently remove all messages.',
      action: 'Delete',
      actionColor: Colors.red,
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
      actionColor: Colors.red,
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
    required Color actionColor,
  }) async {
    return await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConfirmSheet(
        icon: icon, title: title, subtitle: subtitle,
        action: action, actionColor: actionColor,
        onConfirm: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
      ),
    ) ?? false;
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: isError ? Colors.red.shade700 : _t400,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      duration: const Duration(seconds: 2),
    ));
  }

  @override void dispose() { _searchCtrl.dispose(); _fadeCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_loadingUid) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _t400, strokeWidth: 2.5)),
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

  Widget _buildInbox() => Scaffold(
    backgroundColor: _bg,
    body: Column(children: [
      _buildHeader(),
      _buildSearchBar(),
      Expanded(child: FadeTransition(opacity: _fadeAnim, child: _buildList())),
    ]),
  );

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [_t900, _t700, _t500],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 18, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [Colors.white, _t200],
                        ).createShader(b),
                        child: const Text(
                          'Messages',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.9,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      StreamBuilder<List<ConversationModel>>(
                        stream: ChatService.instance.streamConversations(_uid!),
                        builder: (_, snap) {
                          final c = snap.data?.length ?? 0;
                          return Row(
                            children: [
                              Container(
                                width: 7, height: 7,
                                decoration: BoxDecoration(
                                  color: _online,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: _online.withOpacity(0.5), blurRadius: 5)],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                c > 0 ? '$c active conversation${c == 1 ? '' : 's'}' : 'No conversations yet',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.white.withOpacity(0.65),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Clear all button
                GestureDetector(
                  onTap: () { HapticFeedback.mediumImpact(); _clearAll(); },
                  child: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: const Icon(Icons.layers_clear_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Wave
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width, 18),
            painter: _WavePainter(color: _bg),
          ),
        ],
      ),
    ),
  );

  // ── Search Bar ─────────────────────────────────────────────────────────────
  Widget _buildSearchBar() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
    child: Container(
      height: 48,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _searchCtrl.text.isNotEmpty ? _t400.withOpacity(0.4) : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(children: [
        const SizedBox(width: 16),
        Icon(Icons.search_rounded, color: _faint, size: 18),
        const SizedBox(width: 10),
        Expanded(child: TextField(
          controller: _searchCtrl,
          style: const TextStyle(fontSize: 14.5, color: _dark, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: 'Search conversations…',
            hintStyle: TextStyle(color: _faint, fontSize: 14.5),
            border: InputBorder.none,
            isDense: true,
          ),
        )),
        if (_searchCtrl.text.isNotEmpty)
          GestureDetector(
            onTap: () => setState(() => _searchCtrl.clear()),
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Container(
                width: 20, height: 20,
                decoration: BoxDecoration(color: _faint.withOpacity(0.3), shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, size: 13, color: _mid),
              ),
            ),
          ),
      ]),
    ),
  );

  // ── List ───────────────────────────────────────────────────────────────────
  Widget _buildList() => StreamBuilder<List<ConversationModel>>(
    stream: ChatService.instance.streamConversations(_uid!),
    builder: (context, snap) {
      if (snap.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator(color: _t400, strokeWidth: 2));
      }
      if (snap.hasError) return _buildError(message: snap.error.toString());

      var convs = snap.data ?? [];
      final q = _searchCtrl.text.toLowerCase().trim();
      if (q.isNotEmpty) {
        convs = convs.where((c) =>
          c.reservationId.contains(q) ||
          (c.lastMessage?.toLowerCase().contains(q) ?? false) ||
          (c.managerName?.toLowerCase().contains(q) ?? false) ||
          (c.workerName?.toLowerCase().contains(q) ?? false)
        ).toList();
      }
      if (convs.isEmpty) return _buildEmpty(isSearch: q.isNotEmpty);

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        itemCount: convs.length,
        itemBuilder: (_, i) {
          final conv = convs[i];
          return Dismissible(
            key: Key(conv.id),
            direction: DismissDirection.endToStart,
            background: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.red.shade400, Colors.red.shade700]),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 22),
              child: const Icon(Icons.delete_rounded, color: Colors.white, size: 22),
            ),
            confirmDismiss: (_) async { await _deleteConversation(conv); return false; },
            child: _ConvTile(
              conv: conv,
              myUid: _uid!,
              playerToken: widget.playerToken,
              index: i,
              onTap: () { HapticFeedback.selectionClick(); setState(() => _openConversation = conv); },
              onDelete: () => _deleteConversation(conv),
            ),
          );
        },
      );
    },
  );

  Widget _buildEmpty({bool isSearch = false}) => Center(child: Padding(
    padding: const EdgeInsets.all(40),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 88, height: 88,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_t400.withOpacity(0.1), _t200.withOpacity(0.05)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          border: Border.all(color: _t400.withOpacity(0.2)),
        ),
        child: Icon(
          isSearch ? Icons.search_off_rounded : Icons.chat_bubble_outline_rounded,
          size: 36, color: _t400.withOpacity(0.7),
        ),
      ),
      const SizedBox(height: 20),
      Text(
        isSearch ? 'No results found' : 'No conversations yet',
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _dark, letterSpacing: -0.4),
      ),
      const SizedBox(height: 8),
      Text(
        isSearch ? 'Try a different search term' : 'Book a court to start chatting\nwith the venue team.',
        style: TextStyle(fontSize: 13.5, color: _mid, height: 1.6),
        textAlign: TextAlign.center,
      ),
    ]),
  ));

  Widget _buildError({String? message}) => Scaffold(
    backgroundColor: _bg,
    body: Center(child: Padding(
      padding: const EdgeInsets.all(36),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(color: _faint.withOpacity(0.2), shape: BoxShape.circle),
          child: const Icon(Icons.wifi_off_rounded, size: 34, color: _faint),
        ),
        const SizedBox(height: 20),
        const Text('Connection failed', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _dark, letterSpacing: -0.4)),
        const SizedBox(height: 8),
        if ((message ?? _uidError) != null)
          Text(message ?? _uidError!, style: const TextStyle(fontSize: 12.5, color: _mid), textAlign: TextAlign.center, maxLines: 3),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: _resolveUid,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_t700, _t400]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: _t400.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 0.3)),
          ),
        ),
      ]),
    )),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CONVERSATION TILE with Photo
// ─────────────────────────────────────────────────────────────────────────────
class _ConvTile extends StatefulWidget {
  final ConversationModel conv;
  final String myUid;
  final String? playerToken;
  final int index;
  final VoidCallback onTap, onDelete;

  const _ConvTile({
    required this.conv, required this.myUid,
    required this.playerToken,
    required this.index, required this.onTap, required this.onDelete,
  });

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
    bool isWorker = widget.conv.type == ConversationType.playerWorker;
    
    if (isWorker) {
      otherId = widget.conv.participantIds['worker'];
    } else {
      otherId = widget.conv.participantIds['manager'];
    }
    
    print('=== LOAD PHOTO ===');
    print('isWorker: $isWorker');
    print('otherId: $otherId');
    
    if (otherId != null && otherId.isNotEmpty) {
      try {
        final token = widget.playerToken ?? await const FlutterSecureStorage().read(key: 'jwt_token');
        if (token != null) {
          final userType = isWorker ? 'worker' : 'manager';
          // ✅ Use the player endpoint
          final endpoint = '${ApiConstants.playerUserPhoto}/$userType/$otherId/photo';
          
          print('Endpoint: $endpoint');
          
          final response = await http.get(
            Uri.parse(endpoint),
            headers: {'Authorization': 'Bearer $token'},
          );
          
          print('Response status: ${response.statusCode}');
          
          if (response.statusCode == 200 && mounted) {
            final data = json.decode(response.body);
            print('Response data: $data');
            
            String photoUrl = data['photoUrl'] ?? '';
            
            if (photoUrl.isNotEmpty) {
              if (!photoUrl.startsWith('http')) {
                photoUrl = '${ApiConstants.mediaBaseUrl}$photoUrl';
              }
              print('Photo URL found: $photoUrl');
              setState(() => _photoUrl = photoUrl);
            } else {
              print('No photo URL found for $userType $otherId');
            }
          } else {
            print('Failed with status: ${response.statusCode}');
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

  _TypeMeta _meta() {
    switch (widget.conv.type) {
      case ConversationType.playerManager:
        return _TypeMeta(label: widget.conv.managerName ?? 'Manager', tag: 'Manager',
          icon: Icons.storefront_rounded, gradient: _managerGrad, initial: 'M');
      case ConversationType.playerWorker:
        return _TypeMeta(label: widget.conv.workerName ?? 'Worker', tag: 'Worker',
          icon: Icons.engineering_rounded, gradient: _workerGrad, initial: 'W');
      default:
        return _TypeMeta(label: 'Chat', tag: '', icon: Icons.chat_rounded,
          gradient: [_mid, _mid], initial: '?');
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = _meta();
    final isWorker = widget.conv.type == ConversationType.playerWorker;
    final accentColor = isWorker ? _workerColor : _t400;
    final hasMsg = widget.conv.lastMessage?.isNotEmpty == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 3)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: accentColor.withOpacity(0.06),
          highlightColor: accentColor.withOpacity(0.03),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              // Avatar with photo or gradient fallback
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: m.gradient.last.withOpacity(0.28), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: ClipOval(
                  child: _photoUrl != null && _photoUrl!.isNotEmpty
                      ? Image.network(
                          _photoUrl!,
                          fit: BoxFit.cover,
                          width: 56,
                          height: 56,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: m.gradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(child: Text(m.initial, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white))),
                          ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: m.gradient,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: m.gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(child: Text(m.initial, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white))),
                        ),
                ),
              ),
              const SizedBox(width: 14),

              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(children: [
                    // Role pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(m.icon, size: 10, color: accentColor),
                        const SizedBox(width: 4),
                        Text(m.tag, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: accentColor, letterSpacing: 0.2)),
                      ]),
                    ),
                    const Spacer(),
                    Text(
                      _fmt(widget.conv.lastMessageAt ?? widget.conv.createdAt),
                      style: const TextStyle(fontSize: 11.5, color: _faint, fontWeight: FontWeight.w500),
                    ),
                  ]),
                  const SizedBox(height: 5),
                  Text(
                    m.label,
                    style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: _dark, letterSpacing: -0.3),
                  ),
                  const SizedBox(height: 3),
                  Row(children: [
                    Icon(Icons.confirmation_number_outlined, size: 11, color: _faint),
                    const SizedBox(width: 4),
                    Text(
                      'Booking #${widget.conv.reservationId}',
                      style: const TextStyle(fontSize: 11, color: _faint, fontWeight: FontWeight.w500),
                    ),
                  ]),
                  const SizedBox(height: 5),
                  Text(
                    hasMsg ? widget.conv.lastMessage! : 'Tap to start chatting',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: hasMsg ? _mid : _faint,
                      fontStyle: hasMsg ? FontStyle.normal : FontStyle.italic,
                      fontWeight: hasMsg ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ],
              )),

              // Chevron
              const SizedBox(width: 8),
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.arrow_forward_ios_rounded, size: 13, color: accentColor.withOpacity(0.7)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _TypeMeta {
  final String label, tag, initial;
  final IconData icon;
  final List<Color> gradient;
  const _TypeMeta({required this.label, required this.tag, required this.icon, required this.gradient, required this.initial});
}

// ─────────────────────────────────────────────────────────────────────────────
// CONFIRM SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _ConfirmSheet extends StatelessWidget {
  final IconData icon;
  final String title, subtitle, action;
  final Color actionColor;
  final VoidCallback onConfirm, onCancel;

  const _ConfirmSheet({
    required this.icon, required this.title, required this.subtitle,
    required this.action, required this.actionColor,
    required this.onConfirm, required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 28),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, -4))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 40, height: 4,
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
        ),
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(color: actionColor.withOpacity(0.08), shape: BoxShape.circle),
          child: Icon(icon, color: actionColor, size: 28),
        ),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _dark, letterSpacing: -0.5)),
        const SizedBox(height: 8),
        Text(subtitle, style: TextStyle(fontSize: 13.5, color: _mid, height: 1.5), textAlign: TextAlign.center),
        const SizedBox(height: 26),
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: onCancel,
            child: Container(
              height: 50,
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
              child: const Center(child: Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700, color: _mid))),
            ),
          )),
          const SizedBox(width: 12),
          Expanded(child: GestureDetector(
            onTap: onConfirm,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: actionColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: actionColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Center(child: Text(action, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14))),
            ),
          )),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONVERSATION SCREEN with Photo
// ─────────────────────────────────────────────────────────────────────────────
class _ConversationScreen extends StatefulWidget {
  final ConversationModel conversation;
  final String myUid, myName;
  final String? playerToken;
  final VoidCallback onBack, onDelete;
  const _ConversationScreen({
    required this.conversation, required this.myUid, required this.myName,
    required this.playerToken,
    required this.onBack, required this.onDelete,
  });
  @override State<_ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<_ConversationScreen> {
  final _ctrl   = TextEditingController();
  final _scroll = ScrollController();
  bool _typing = false, _sending = false, _inputFocused = false;
  final _focusNode = FocusNode();
  String? _otherPhotoUrl;
  bool _loadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() => _typing = _ctrl.text.trim().isNotEmpty));
    _focusNode.addListener(() => setState(() => _inputFocused = _focusNode.hasFocus));
    _loadOtherPhoto();
  }
  
  Future<void> _loadOtherPhoto() async {
    setState(() => _loadingPhoto = true);
    
    String? otherId;
    bool isWorker = widget.conversation.type == ConversationType.playerWorker;
    
    if (isWorker) {
      otherId = widget.conversation.participantIds['worker'];
    } else {
      otherId = widget.conversation.participantIds['manager'];
    }
    
    print('=== LOAD OTHER PHOTO ===');
    print('isWorker: $isWorker');
    print('otherId: $otherId');
    
    if (otherId != null && otherId.isNotEmpty && widget.playerToken != null) {
      try {
        final userType = isWorker ? 'worker' : 'manager';
        // ✅ Use the player endpoint
        final endpoint = '${ApiConstants.playerUserPhoto}/$userType/$otherId/photo';
        
        print('Endpoint: $endpoint');
        
        final response = await http.get(
          Uri.parse(endpoint),
          headers: {'Authorization': 'Bearer ${widget.playerToken}'},
        );
        
        print('Response status: ${response.statusCode}');
        
        if (response.statusCode == 200 && mounted) {
          final data = json.decode(response.body);
          print('Response data: $data');
          
          String photoUrl = data['photoUrl'] ?? '';
          
          if (photoUrl.isNotEmpty) {
            if (!photoUrl.startsWith('http')) {
              photoUrl = '${ApiConstants.mediaBaseUrl}$photoUrl';
            }
            print('Photo URL found: $photoUrl');
            setState(() => _otherPhotoUrl = photoUrl);
          } else {
            print('No photo URL found for $userType $otherId');
          }
        } else {
          print('Failed with status: ${response.statusCode}');
        }
      } catch (e) {
        print('Error loading other photo: $e');
      }
    }
    
    if (mounted) setState(() => _loadingPhoto = false);
  }

  @override void dispose() { _ctrl.dispose(); _scroll.dispose(); _focusNode.dispose(); super.dispose(); }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    HapticFeedback.lightImpact();
    _ctrl.clear(); setState(() { _typing = false; _sending = true; });
    try {
      await ChatService.instance.sendMessage(
        conversationId: widget.conversation.id, senderId: widget.myUid, text: text,
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed: $e'),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scroll.hasClients) _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic,
      );
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200), curve: Curves.easeOut,
      );
    });
  }

  bool get _isWorker => widget.conversation.type == ConversationType.playerWorker;
  List<Color> get _grad => _isWorker ? _workerGrad : _managerGrad;
  Color get _accent => _isWorker ? _workerColor : _t400;

  String get _headerTitle {
    final c = widget.conversation;
    return _isWorker ? (c.workerName ?? 'Worker') : (c.managerName ?? 'Manager');
  }

  String get _headerSub =>
    '${_isWorker ? "Court Worker" : "Venue Manager"} · #${widget.conversation.reservationId}';

  String get _headerInitial => _isWorker ? 'W' : 'M';

  @override
  Widget build(BuildContext context) {
    final bot = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFEEF1F7),
      body: Column(children: [
        _buildAppBar(),
        Expanded(child: _buildMessages()),
        _buildInputBar(bot),
      ]),
    );
  }

  Widget _buildAppBar() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [_grad.first, _grad.last], begin: Alignment.topLeft, end: Alignment.bottomRight),
    ),
    child: SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 10, 16, 0),
            child: Row(children: [
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 6),
              // Avatar with photo or fallback
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.35), width: 2),
                ),
                child: ClipOval(
                  child: _otherPhotoUrl != null && _otherPhotoUrl!.isNotEmpty
                      ? Image.network(
                          _otherPhotoUrl!,
                          fit: BoxFit.cover,
                          width: 44,
                          height: 44,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: _grad, begin: Alignment.topLeft, end: Alignment.bottomRight),
                            ),
                            child: Center(child: Text(_headerInitial, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white))),
                          ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: _grad, begin: Alignment.topLeft, end: Alignment.bottomRight),
                              ),
                              child: Center(child: Text(_headerInitial, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white))),
                            );
                          },
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: _grad, begin: Alignment.topLeft, end: Alignment.bottomRight),
                          ),
                          child: Center(child: Text(_headerInitial, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white))),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_headerTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3)),
                  const SizedBox(height: 2),
                  Text(_headerSub, style: TextStyle(fontSize: 11.5, color: Colors.white.withOpacity(0.65)), overflow: TextOverflow.ellipsis),
                ],
              )),
              // Delete
              GestureDetector(
                onTap: widget.onDelete,
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.white),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width, 16),
            painter: _WavePainter(color: const Color(0xFFEEF1F7)),
          ),
        ],
      ),
    ),
  );

  Widget _buildMessages() => StreamBuilder<List<MessageModel>>(
    stream: ChatService.instance.streamMessages(widget.conversation.id),
    builder: (_, snap) {
      if (snap.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator(color: _t400, strokeWidth: 2));
      }
      final msgs = snap.data ?? [];
      if (msgs.isEmpty) return _emptyMessages();
      _scrollToBottom();
      return ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        itemCount: msgs.length,
        itemBuilder: (_, i) {
          final msg = msgs[i];
          final isMe = msg.senderId == widget.myUid;
          final showAvatar = !isMe && (i == msgs.length - 1 || msgs[i + 1].senderId != msg.senderId);
          return _Bubble(
            msg: msg, isMe: isMe,
            theirGrad: _grad,
            theirAccent: _accent,
            theirInitial: _headerInitial,
            theirPhotoUrl: _otherPhotoUrl,
            showAvatar: showAvatar,
          );
        },
      );
    },
  );

  Widget _buildInputBar(double bot) => AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: const BorderRadius.only(topLeft: Radius.circular(26), topRight: Radius.circular(26)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(_inputFocused ? 0.1 : 0.05),
          blurRadius: _inputFocused ? 22 : 12,
          offset: const Offset(0, -3),
        ),
      ],
    ),
    padding: EdgeInsets.fromLTRB(14, 12, 14, bot + 12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Expanded(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minHeight: 46),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F5F9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _inputFocused ? _accent.withOpacity(0.45) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: _ctrl,
            focusNode: _focusNode,
            minLines: 1, maxLines: 5,
            style: const TextStyle(fontSize: 15, color: _dark, height: 1.4),
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Type a message…',
              hintStyle: TextStyle(color: _faint, fontSize: 15),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              isDense: true,
            ),
          ),
        ),
      ),
      const SizedBox(width: 10),
      GestureDetector(
        onTap: (_typing && !_sending) ? _send : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 46, height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: (_typing && !_sending)
                ? LinearGradient(colors: _grad, begin: Alignment.topLeft, end: Alignment.bottomRight)
                : null,
            color: (_typing && !_sending) ? null : _accent.withOpacity(0.1),
            boxShadow: (_typing && !_sending)
                ? [BoxShadow(color: _accent.withOpacity(0.38), blurRadius: 14, offset: const Offset(0, 4))]
                : [],
          ),
          child: _sending
              ? Padding(
                  padding: const EdgeInsets.all(13),
                  child: CircularProgressIndicator(strokeWidth: 2, color: _typing ? Colors.white : _accent),
                )
              : Icon(
                  _typing ? Icons.arrow_upward_rounded : Icons.mic_rounded,
                  size: 20,
                  color: _typing ? Colors.white : _accent,
                ),
        ),
      ),
    ]),
  );

  Widget _emptyMessages() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(
      width: 70, height: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_accent.withOpacity(0.1), _accent.withOpacity(0.05)]),
        shape: BoxShape.circle,
        border: Border.all(color: _accent.withOpacity(0.2)),
      ),
      child: Icon(Icons.chat_bubble_outline_rounded, size: 30, color: _accent.withOpacity(0.6)),
    ),
    const SizedBox(height: 16),
    const Text('No messages yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _dark, letterSpacing: -0.3)),
    const SizedBox(height: 6),
    Text('Say hi to your ${_isWorker ? "worker" : "manager"}!',
        style: const TextStyle(fontSize: 13, color: _mid)),
  ]));
}

// ─────────────────────────────────────────────────────────────────────────────
// BUBBLE with Photo
// ─────────────────────────────────────────────────────────────────────────────
class _Bubble extends StatelessWidget {
  final MessageModel msg;
  final bool isMe, showAvatar;
  final List<Color> theirGrad;
  final Color theirAccent;
  final String theirInitial;
  final String? theirPhotoUrl;

  const _Bubble({
    required this.msg, required this.isMe, required this.showAvatar,
    required this.theirGrad, required this.theirAccent, required this.theirInitial,
    this.theirPhotoUrl,
  });

  String _fmt(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 6,
        left: isMe ? 56 : 0,
        right: isMe ? 0 : 56,
      ),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            showAvatar
                ? Container(
                    width: 32, height: 32,
                    margin: const EdgeInsets.only(right: 8, bottom: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: theirAccent.withOpacity(0.3), width: 1),
                    ),
                    child: ClipOval(
                      child: theirPhotoUrl != null && theirPhotoUrl!.isNotEmpty
                          ? Image.network(
                              theirPhotoUrl!,
                              fit: BoxFit.cover,
                              width: 32,
                              height: 32,
                              errorBuilder: (_, __, ___) => Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: theirGrad, begin: Alignment.topLeft, end: Alignment.bottomRight),
                                ),
                                child: Center(child: Text(theirInitial, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white))),
                              ),
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: theirGrad, begin: Alignment.topLeft, end: Alignment.bottomRight),
                                  ),
                                  child: Center(
                                    child: SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: theirGrad, begin: Alignment.topLeft, end: Alignment.bottomRight),
                              ),
                              child: Center(child: Text(theirInitial, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white))),
                            ),
                    ),
                  )
                : const SizedBox(width: 40),
          ],
          Flexible(child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isMe
                      ? const LinearGradient(colors: [_t700, _t400], begin: Alignment.topLeft, end: Alignment.bottomRight)
                      : null,
                  color: isMe ? null : _surface,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isMe ? _t400.withOpacity(0.22) : Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: isMe ? null : Border.all(color: Colors.grey.shade100),
                ),
                child: Text(
                  msg.text,
                  style: TextStyle(
                    fontSize: 14.5, height: 1.45,
                    color: isMe ? Colors.white : _dark,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_fmt(msg.createdAt), style: const TextStyle(fontSize: 10.5, color: _faint)),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.done_all_rounded, size: 14, color: _t400),
                  ],
                ],
              ),
            ],
          )),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WAVE PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _WavePainter extends CustomPainter {
  final Color color;
  _WavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(size.width * 0.25, 0, size.width * 0.5, size.height * 0.55)
      ..quadraticBezierTo(size.width * 0.75, size.height, size.width, size.height * 0.3)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.color != color;
}











/*// Views/Player/chat.dart
// Shows all conversations the player is part of:
//   • player ↔ manager  (doc: reservation_{id})      — labeled "Manager"
//   • player ↔ worker   (doc: player_worker_{id})    — labeled "Worker"
// Uses deterministic UID: "sporta_player_{strapiId}"

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Services/chat_service.dart';
import 'package:sporta/Services/firebase_identity_service.dart';
import 'package:sporta/Services/player_manager_auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ── Design Tokens ─────────────────────────────────────────────────────────────
const _bg       = Color(0xFFF2F5F9);
const _surface  = Color(0xFFFFFFFF);
const _dark     = Color(0xFF0D1117);
const _mid      = Color(0xFF6B7280);
const _faint    = Color(0xFFB8BDC8);
const _online   = Color(0xFF22C55E);

// Teal brand ramp (matches kPrimary = #009999 area)
const _t900 = Color(0xFF001A1B);
const _t700 = Color(0xFF002B2C);
const _t500 = Color(0xFF006B6C);
const _t400 = Color(0xFF009999);
const _t200 = Color(0xFF4DD9D9);
const _tGlow = Color(0xFF00F0F0);

// Role accent
const _managerGrad = [Color(0xFF002B2C), Color(0xFF009999)];
const _workerGrad  = [Color(0xFF3730A3), Color(0xFF7C3AED)];
const _workerColor = Color(0xFF7C3AED);

class Chat extends StatefulWidget {
  final String? playerName;
  const Chat({super.key, this.playerName});
  @override State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  ConversationModel? _openConversation;
  String? _uid;
  bool _loadingUid = true;
  String? _uidError;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
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
        final user = profile.containsKey('user') ? profile['user'] as Map<String, dynamic> : profile;
        final id = user['id']?.toString() ?? '';
        if (id.isNotEmpty) { _setUid('sporta_player_$id'); return; }
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
    if (mounted) {
      setState(() { _uid = uid; _loadingUid = false; });
      _fadeCtrl.forward();
    }
  }

  Future<void> _deleteConversation(ConversationModel conv) async {
    final ok = await _confirmSheet(
      icon: Icons.delete_sweep_rounded,
      title: 'Delete conversation?',
      subtitle: 'This will permanently remove all messages.',
      action: 'Delete',
      actionColor: Colors.red,
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
      actionColor: Colors.red,
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
    required Color actionColor,
  }) async {
    return await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConfirmSheet(
        icon: icon, title: title, subtitle: subtitle,
        action: action, actionColor: actionColor,
        onConfirm: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
      ),
    ) ?? false;
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: isError ? Colors.red.shade700 : _t400,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      duration: const Duration(seconds: 2),
    ));
  }

  @override void dispose() { _searchCtrl.dispose(); _fadeCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_loadingUid) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _t400, strokeWidth: 2.5)),
      );
    }
    if (_uid == null) return _buildError();
    if (_openConversation != null) {
      return _ConversationScreen(
        conversation: _openConversation!,
        myUid: _uid!,
        myName: widget.playerName ?? 'Player',
        onBack: () => setState(() => _openConversation = null),
        onDelete: () async {
          await _deleteConversation(_openConversation!);
          if (mounted) setState(() => _openConversation = null);
        },
      );
    }
    return _buildInbox();
  }

  Widget _buildInbox() => Scaffold(
    backgroundColor: _bg,
    body: Column(children: [
      _buildHeader(),
      _buildSearchBar(),
      Expanded(child: FadeTransition(opacity: _fadeAnim, child: _buildList())),
    ]),
  );

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [_t900, _t700, _t500],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 18, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [Colors.white, _t200],
                        ).createShader(b),
                        child: const Text(
                          'Messages',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.9,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      StreamBuilder<List<ConversationModel>>(
                        stream: ChatService.instance.streamConversations(_uid!),
                        builder: (_, snap) {
                          final c = snap.data?.length ?? 0;
                          return Row(
                            children: [
                              Container(
                                width: 7, height: 7,
                                decoration: BoxDecoration(
                                  color: _online,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: _online.withOpacity(0.5), blurRadius: 5)],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                c > 0 ? '$c active conversation${c == 1 ? '' : 's'}' : 'No conversations yet',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.white.withOpacity(0.65),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Clear all button
                GestureDetector(
                  onTap: () { HapticFeedback.mediumImpact(); _clearAll(); },
                  child: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: const Icon(Icons.layers_clear_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Wave
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width, 18),
            painter: _WavePainter(color: _bg),
          ),
        ],
      ),
    ),
  );

  // ── Search Bar ─────────────────────────────────────────────────────────────
  Widget _buildSearchBar() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
    child: Container(
      height: 48,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _searchCtrl.text.isNotEmpty ? _t400.withOpacity(0.4) : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(children: [
        const SizedBox(width: 16),
        Icon(Icons.search_rounded, color: _faint, size: 18),
        const SizedBox(width: 10),
        Expanded(child: TextField(
          controller: _searchCtrl,
          style: const TextStyle(fontSize: 14.5, color: _dark, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: 'Search conversations…',
            hintStyle: TextStyle(color: _faint, fontSize: 14.5),
            border: InputBorder.none,
            isDense: true,
          ),
        )),
        if (_searchCtrl.text.isNotEmpty)
          GestureDetector(
            onTap: () => setState(() => _searchCtrl.clear()),
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Container(
                width: 20, height: 20,
                decoration: BoxDecoration(color: _faint.withOpacity(0.3), shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, size: 13, color: _mid),
              ),
            ),
          ),
      ]),
    ),
  );

  // ── List ───────────────────────────────────────────────────────────────────
  Widget _buildList() => StreamBuilder<List<ConversationModel>>(
    stream: ChatService.instance.streamConversations(_uid!),
    builder: (context, snap) {
      if (snap.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator(color: _t400, strokeWidth: 2));
      }
      if (snap.hasError) return _buildError(message: snap.error.toString());

      var convs = snap.data ?? [];
      final q = _searchCtrl.text.toLowerCase().trim();
      if (q.isNotEmpty) {
        convs = convs.where((c) =>
          c.reservationId.contains(q) ||
          (c.lastMessage?.toLowerCase().contains(q) ?? false) ||
          (c.managerName?.toLowerCase().contains(q) ?? false) ||
          (c.workerName?.toLowerCase().contains(q) ?? false)
        ).toList();
      }
      if (convs.isEmpty) return _buildEmpty(isSearch: q.isNotEmpty);

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        itemCount: convs.length,
        itemBuilder: (_, i) {
          final conv = convs[i];
          return Dismissible(
            key: Key(conv.id),
            direction: DismissDirection.endToStart,
            background: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.red.shade400, Colors.red.shade700]),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 22),
              child: const Icon(Icons.delete_rounded, color: Colors.white, size: 22),
            ),
            confirmDismiss: (_) async { await _deleteConversation(conv); return false; },
            child: _ConvTile(
              conv: conv,
              myUid: _uid!,
              index: i,
              onTap: () { HapticFeedback.selectionClick(); setState(() => _openConversation = conv); },
              onDelete: () => _deleteConversation(conv),
            ),
          );
        },
      );
    },
  );

  Widget _buildEmpty({bool isSearch = false}) => Center(child: Padding(
    padding: const EdgeInsets.all(40),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 88, height: 88,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_t400.withOpacity(0.1), _t200.withOpacity(0.05)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          border: Border.all(color: _t400.withOpacity(0.2)),
        ),
        child: Icon(
          isSearch ? Icons.search_off_rounded : Icons.chat_bubble_outline_rounded,
          size: 36, color: _t400.withOpacity(0.7),
        ),
      ),
      const SizedBox(height: 20),
      Text(
        isSearch ? 'No results found' : 'No conversations yet',
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _dark, letterSpacing: -0.4),
      ),
      const SizedBox(height: 8),
      Text(
        isSearch ? 'Try a different search term' : 'Book a court to start chatting\nwith the venue team.',
        style: TextStyle(fontSize: 13.5, color: _mid, height: 1.6),
        textAlign: TextAlign.center,
      ),
    ]),
  ));

  Widget _buildError({String? message}) => Scaffold(
    backgroundColor: _bg,
    body: Center(child: Padding(
      padding: const EdgeInsets.all(36),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(color: _faint.withOpacity(0.2), shape: BoxShape.circle),
          child: const Icon(Icons.wifi_off_rounded, size: 34, color: _faint),
        ),
        const SizedBox(height: 20),
        const Text('Connection failed', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _dark, letterSpacing: -0.4)),
        const SizedBox(height: 8),
        if ((message ?? _uidError) != null)
          Text(message ?? _uidError!, style: const TextStyle(fontSize: 12.5, color: _mid), textAlign: TextAlign.center, maxLines: 3),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: _resolveUid,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_t700, _t400]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: _t400.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 0.3)),
          ),
        ),
      ]),
    )),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CONVERSATION TILE
// ─────────────────────────────────────────────────────────────────────────────
class _ConvTile extends StatelessWidget {
  final ConversationModel conv;
  final String myUid;
  final int index;
  final VoidCallback onTap, onDelete;

  const _ConvTile({
    required this.conv, required this.myUid,
    required this.index, required this.onTap, required this.onDelete,
  });

  String _fmt(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24)   return '${diff.inHours}h';
    if (diff.inDays < 7)     return '${diff.inDays}d';
    return '${dt.day}/${dt.month}';
  }

  _TypeMeta _meta() {
    switch (conv.type) {
      case ConversationType.playerManager:
        return _TypeMeta(label: conv.managerName ?? 'Manager', tag: 'Manager',
          icon: Icons.storefront_rounded, gradient: _managerGrad, initial: 'M');
      case ConversationType.playerWorker:
        return _TypeMeta(label: conv.workerName ?? 'Worker', tag: 'Worker',
          icon: Icons.engineering_rounded, gradient: _workerGrad, initial: 'W');
      default:
        return _TypeMeta(label: 'Chat', tag: '', icon: Icons.chat_rounded,
          gradient: [_mid, _mid], initial: '?');
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = _meta();
    final isWorker = conv.type == ConversationType.playerWorker;
    final accentColor = isWorker ? _workerColor : _t400;
    final hasMsg = conv.lastMessage?.isNotEmpty == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 3)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: accentColor.withOpacity(0.06),
          highlightColor: accentColor.withOpacity(0.03),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              // Gradient avatar
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: m.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: m.gradient.last.withOpacity(0.28), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Center(
                  child: Text(m.initial, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 14),

              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(children: [
                    // Role pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(m.icon, size: 10, color: accentColor),
                        const SizedBox(width: 4),
                        Text(m.tag, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: accentColor, letterSpacing: 0.2)),
                      ]),
                    ),
                    const Spacer(),
                    Text(
                      _fmt(conv.lastMessageAt ?? conv.createdAt),
                      style: const TextStyle(fontSize: 11.5, color: _faint, fontWeight: FontWeight.w500),
                    ),
                  ]),
                  const SizedBox(height: 5),
                  Text(
                    m.label,
                    style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: _dark, letterSpacing: -0.3),
                  ),
                  const SizedBox(height: 3),
                  Row(children: [
                    Icon(Icons.confirmation_number_outlined, size: 11, color: _faint),
                    const SizedBox(width: 4),
                    Text(
                      'Booking #${conv.reservationId}',
                      style: const TextStyle(fontSize: 11, color: _faint, fontWeight: FontWeight.w500),
                    ),
                  ]),
                  const SizedBox(height: 5),
                  Text(
                    hasMsg ? conv.lastMessage! : 'Tap to start chatting',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: hasMsg ? _mid : _faint,
                      fontStyle: hasMsg ? FontStyle.normal : FontStyle.italic,
                      fontWeight: hasMsg ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ],
              )),

              // Chevron
              const SizedBox(width: 8),
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.arrow_forward_ios_rounded, size: 13, color: accentColor.withOpacity(0.7)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _TypeMeta {
  final String label, tag, initial;
  final IconData icon;
  final List<Color> gradient;
  const _TypeMeta({required this.label, required this.tag, required this.icon, required this.gradient, required this.initial});
}

// ─────────────────────────────────────────────────────────────────────────────
// CONFIRM SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _ConfirmSheet extends StatelessWidget {
  final IconData icon;
  final String title, subtitle, action;
  final Color actionColor;
  final VoidCallback onConfirm, onCancel;

  const _ConfirmSheet({
    required this.icon, required this.title, required this.subtitle,
    required this.action, required this.actionColor,
    required this.onConfirm, required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 28),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, -4))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 40, height: 4,
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
        ),
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(color: actionColor.withOpacity(0.08), shape: BoxShape.circle),
          child: Icon(icon, color: actionColor, size: 28),
        ),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _dark, letterSpacing: -0.5)),
        const SizedBox(height: 8),
        Text(subtitle, style: TextStyle(fontSize: 13.5, color: _mid, height: 1.5), textAlign: TextAlign.center),
        const SizedBox(height: 26),
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: onCancel,
            child: Container(
              height: 50,
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
              child: const Center(child: Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700, color: _mid))),
            ),
          )),
          const SizedBox(width: 12),
          Expanded(child: GestureDetector(
            onTap: onConfirm,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: actionColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: actionColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Center(child: Text(action, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14))),
            ),
          )),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONVERSATION SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class _ConversationScreen extends StatefulWidget {
  final ConversationModel conversation;
  final String myUid, myName;
  final VoidCallback onBack, onDelete;
  const _ConversationScreen({
    required this.conversation, required this.myUid, required this.myName,
    required this.onBack, required this.onDelete,
  });
  @override State<_ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<_ConversationScreen> {
  final _ctrl   = TextEditingController();
  final _scroll = ScrollController();
  bool _typing = false, _sending = false, _inputFocused = false;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() => _typing = _ctrl.text.trim().isNotEmpty));
    _focusNode.addListener(() => setState(() => _inputFocused = _focusNode.hasFocus));
  }

  @override void dispose() { _ctrl.dispose(); _scroll.dispose(); _focusNode.dispose(); super.dispose(); }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    HapticFeedback.lightImpact();
    _ctrl.clear(); setState(() { _typing = false; _sending = true; });
    try {
      await ChatService.instance.sendMessage(
        conversationId: widget.conversation.id, senderId: widget.myUid, text: text,
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed: $e'),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scroll.hasClients) _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic,
      );
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200), curve: Curves.easeOut,
      );
    });
  }

  bool get _isWorker => widget.conversation.type == ConversationType.playerWorker;
  List<Color> get _grad => _isWorker ? _workerGrad : _managerGrad;
  Color get _accent => _isWorker ? _workerColor : _t400;

  String get _headerTitle {
    final c = widget.conversation;
    return _isWorker ? (c.workerName ?? 'Worker') : (c.managerName ?? 'Manager');
  }

  String get _headerSub =>
    '${_isWorker ? "Court Worker" : "Venue Manager"} · #${widget.conversation.reservationId}';

  String get _headerInitial => _isWorker ? 'W' : 'M';

  @override
  Widget build(BuildContext context) {
    final bot = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFEEF1F7),
      body: Column(children: [
        _buildAppBar(),
        Expanded(child: _buildMessages()),
        _buildInputBar(bot),
      ]),
    );
  }

  Widget _buildAppBar() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [_grad.first, _grad.last], begin: Alignment.topLeft, end: Alignment.bottomRight),
    ),
    child: SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 10, 16, 0),
            child: Row(children: [
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 6),
              // Avatar
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(color: Colors.white.withOpacity(0.35), width: 2),
                ),
                child: Center(child: Text(_headerInitial,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_headerTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3)),
                  const SizedBox(height: 2),
                  Text(_headerSub, style: TextStyle(fontSize: 11.5, color: Colors.white.withOpacity(0.65)), overflow: TextOverflow.ellipsis),
                ],
              )),
              // Delete
              GestureDetector(
                onTap: widget.onDelete,
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.white),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width, 16),
            painter: _WavePainter(color: const Color(0xFFEEF1F7)),
          ),
        ],
      ),
    ),
  );

  Widget _buildMessages() => StreamBuilder<List<MessageModel>>(
    stream: ChatService.instance.streamMessages(widget.conversation.id),
    builder: (_, snap) {
      if (snap.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator(color: _t400, strokeWidth: 2));
      }
      final msgs = snap.data ?? [];
      if (msgs.isEmpty) return _emptyMessages();
      _scrollToBottom();
      return ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        itemCount: msgs.length,
        itemBuilder: (_, i) {
          final msg = msgs[i];
          final isMe = msg.senderId == widget.myUid;
          final showAvatar = !isMe && (i == msgs.length - 1 || msgs[i + 1].senderId != msg.senderId);
          return _Bubble(
            msg: msg, isMe: isMe,
            theirGrad: _grad,
            theirAccent: _accent,
            theirInitial: _headerInitial,
            showAvatar: showAvatar,
          );
        },
      );
    },
  );

  Widget _buildInputBar(double bot) => AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: const BorderRadius.only(topLeft: Radius.circular(26), topRight: Radius.circular(26)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(_inputFocused ? 0.1 : 0.05),
          blurRadius: _inputFocused ? 22 : 12,
          offset: const Offset(0, -3),
        ),
      ],
    ),
    padding: EdgeInsets.fromLTRB(14, 12, 14, bot + 12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Expanded(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minHeight: 46),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F5F9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _inputFocused ? _accent.withOpacity(0.45) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: _ctrl,
            focusNode: _focusNode,
            minLines: 1, maxLines: 5,
            style: const TextStyle(fontSize: 15, color: _dark, height: 1.4),
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Type a message…',
              hintStyle: TextStyle(color: _faint, fontSize: 15),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              isDense: true,
            ),
          ),
        ),
      ),
      const SizedBox(width: 10),
      GestureDetector(
        onTap: (_typing && !_sending) ? _send : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 46, height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: (_typing && !_sending)
                ? LinearGradient(colors: _grad, begin: Alignment.topLeft, end: Alignment.bottomRight)
                : null,
            color: (_typing && !_sending) ? null : _accent.withOpacity(0.1),
            boxShadow: (_typing && !_sending)
                ? [BoxShadow(color: _accent.withOpacity(0.38), blurRadius: 14, offset: const Offset(0, 4))]
                : [],
          ),
          child: _sending
              ? Padding(
                  padding: const EdgeInsets.all(13),
                  child: CircularProgressIndicator(strokeWidth: 2, color: _typing ? Colors.white : _accent),
                )
              : Icon(
                  _typing ? Icons.arrow_upward_rounded : Icons.mic_rounded,
                  size: 20,
                  color: _typing ? Colors.white : _accent,
                ),
        ),
      ),
    ]),
  );

  Widget _emptyMessages() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(
      width: 70, height: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_accent.withOpacity(0.1), _accent.withOpacity(0.05)]),
        shape: BoxShape.circle,
        border: Border.all(color: _accent.withOpacity(0.2)),
      ),
      child: Icon(Icons.chat_bubble_outline_rounded, size: 30, color: _accent.withOpacity(0.6)),
    ),
    const SizedBox(height: 16),
    const Text('No messages yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _dark, letterSpacing: -0.3)),
    const SizedBox(height: 6),
    Text('Say hi to your ${_isWorker ? "worker" : "manager"}!',
        style: const TextStyle(fontSize: 13, color: _mid)),
  ]));
}

// ─────────────────────────────────────────────────────────────────────────────
// BUBBLE
// ─────────────────────────────────────────────────────────────────────────────
class _Bubble extends StatelessWidget {
  final MessageModel msg;
  final bool isMe, showAvatar;
  final List<Color> theirGrad;
  final Color theirAccent;
  final String theirInitial;

  const _Bubble({
    required this.msg, required this.isMe, required this.showAvatar,
    required this.theirGrad, required this.theirAccent, required this.theirInitial,
  });

  String _fmt(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 6,
        left: isMe ? 56 : 0,
        right: isMe ? 0 : 56,
      ),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            showAvatar
                ? Container(
                    width: 32, height: 32,
                    margin: const EdgeInsets.only(right: 8, bottom: 2),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: theirGrad, begin: Alignment.topLeft, end: Alignment.bottomRight),
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: Text(theirInitial, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white))),
                  )
                : const SizedBox(width: 40),
          ],
          Flexible(child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isMe
                      ? const LinearGradient(colors: [_t700, _t400], begin: Alignment.topLeft, end: Alignment.bottomRight)
                      : null,
                  color: isMe ? null : _surface,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isMe ? _t400.withOpacity(0.22) : Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: isMe ? null : Border.all(color: Colors.grey.shade100),
                ),
                child: Text(
                  msg.text,
                  style: TextStyle(
                    fontSize: 14.5, height: 1.45,
                    color: isMe ? Colors.white : _dark,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_fmt(msg.createdAt), style: const TextStyle(fontSize: 10.5, color: _faint)),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.done_all_rounded, size: 14, color: _t400),
                  ],
                ],
              ),
            ],
          )),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WAVE PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _WavePainter extends CustomPainter {
  final Color color;
  _WavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(size.width * 0.25, 0, size.width * 0.5, size.height * 0.55)
      ..quadraticBezierTo(size.width * 0.75, size.height, size.width, size.height * 0.3)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.color != color;
}










******************************************************







// Views/Player/chat.dart
// Shows all conversations the player is part of:
//   • player ↔ manager  (doc: reservation_{id})      — labeled "Manager"
//   • player ↔ worker   (doc: player_worker_{id})    — labeled "Worker"
// Uses deterministic UID: "sporta_player_{strapiId}"

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Services/chat_service.dart';
import 'package:sporta/Services/firebase_identity_service.dart';
import 'package:sporta/Services/player_manager_auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _bg     = Color(0xFFF5F6FA);
const _white  = Colors.white;
const _dark   = Color(0xFF0D1117);
const _mid    = Color(0xFF6B7280);
const _light  = Color(0xFFB0B7C3);
const _online = Color(0xFF22C55E);

// Type badge colors
const _managerColor = kPrimary;
const _workerColor  = Color(0xFF7C3AED);

class Chat extends StatefulWidget {
  final String? playerName;
  const Chat({super.key, this.playerName});
  @override State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  ConversationModel? _openConversation;
  String? _uid;
  bool _loadingUid = true;
  String? _uidError;
  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _searchCtrl.addListener(() => setState(() {}));
    _resolveUid();
  }

  Future<void> _resolveUid() async {
    setState(() { _loadingUid = true; _uidError = null; });
    try {
      // 1. Try FirebaseIdentityService cache
      final cached = FirebaseIdentityService.instance.firebaseUid;
      if (cached != null && cached.isNotEmpty) {
        _setUid(cached); return;
      }
      // 2. Build from Strapi JWT
      final token = await const FlutterSecureStorage().read(key: 'jwt_token');
      if (token != null && token.isNotEmpty) {
        final profile = await PlayerManagerAuthService.getMe(token);
        final user    = profile.containsKey('user') ? profile['user'] as Map<String, dynamic> : profile;
        final id      = user['id']?.toString() ?? '';
        if (id.isNotEmpty) { _setUid('sporta_player_$id'); return; }
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
    if (mounted) {
      setState(() { _uid = uid; _loadingUid = false; });
      _fadeCtrl.forward();
    }
  }

  // ── Delete helpers ────────────────────────────────────────────────────────
  Future<void> _deleteConversation(ConversationModel conv) async {
    final ok = await _confirmDialog(
      title:   'Delete Conversation',
      message: 'This conversation will be deleted permanently.',
      action:  'Delete',
    );
    if (!ok) return;
    try {
      await ChatService.instance.deleteConversation(conv.id);
      if (mounted) _snack('Conversation deleted', isError: false);
    } catch (e) {
      if (mounted) _snack('Failed: $e', isError: true);
    }
  }

  Future<void> _clearAll() async {
    final ok = await _confirmDialog(
      title:   'Clear All Conversations',
      message: 'All your conversations will be deleted permanently.',
      action:  'Clear All',
    );
    if (!ok || _uid == null) return;
    try {
      await ChatService.instance.clearAllConversations(_uid!);
      if (mounted) _snack('All conversations cleared', isError: false);
    } catch (e) {
      if (mounted) _snack('Failed: $e', isError: true);
    }
  }

  Future<bool> _confirmDialog({required String title, required String message, required String action}) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        content: Text(message, style: const TextStyle(fontSize: 14, color: _mid)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: _mid))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: _white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(action),
          ),
        ],
      ),
    ) ?? false;
  }

  void _snack(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  @override void dispose() { _searchCtrl.dispose(); _fadeCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_loadingUid) return const Scaffold(backgroundColor: _bg, body: Center(child: CircularProgressIndicator(color: kPrimary)));
    if (_uid == null)           return _buildError();
    if (_openConversation != null) {
      return _ConversationScreen(
        conversation:  _openConversation!,
        myUid:         _uid!,
        myName:        widget.playerName ?? 'Player',
        onBack:        () => setState(() => _openConversation = null),
        onDelete:      () async { await _deleteConversation(_openConversation!); if (mounted) setState(() => _openConversation = null); },
      );
    }
    return _buildInbox();
  }

  Widget _buildInbox() => Scaffold(
    backgroundColor: _bg,
    body: Column(children: [
      _buildHeader(),
      _buildSearchBar(),
      Expanded(child: FadeTransition(opacity: _fadeAnim, child: _buildList())),
    ]),
  );

  Widget _buildHeader() => Container(
    color: _white,
    child: SafeArea(bottom: false, child: Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Messages', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _dark, letterSpacing: -0.6)),
          const SizedBox(height: 2),
          StreamBuilder<List<ConversationModel>>(
            stream: ChatService.instance.streamConversations(_uid!),
            builder: (_, snap) {
              final c = snap.data?.length ?? 0;
              return Text(c > 0 ? '$c conversation${c == 1 ? '' : 's'}' : 'No conversations yet',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: c > 0 ? kPrimary : _mid));
            },
          ),
        ]),
        const Spacer(),
        GestureDetector(
          onTap: _clearAll,
          child: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.red.withOpacity(0.2))),
            child: const Icon(Icons.delete_sweep_rounded, color: Colors.red, size: 20),
          ),
        ),
      ]),
    )),
  );

  Widget _buildSearchBar() => Container(
    color: _white,
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
    child: Container(
      height: 46,
      decoration: BoxDecoration(color: const Color(0xFFF0F2F8), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        const SizedBox(width: 14),
        Icon(Icons.search_rounded, color: Colors.grey[400], size: 18),
        const SizedBox(width: 10),
        Expanded(child: TextField(
          controller: _searchCtrl,
          style: const TextStyle(fontSize: 14, color: _dark),
          decoration: InputDecoration(hintText: 'Search conversations…', hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14), border: InputBorder.none, isDense: true),
        )),
        if (_searchCtrl.text.isNotEmpty)
          GestureDetector(onTap: () => setState(() => _searchCtrl.clear()),
            child: Padding(padding: const EdgeInsets.only(right: 10), child: Icon(Icons.close_rounded, size: 18, color: Colors.grey[400]))),
      ]),
    ),
  );

  Widget _buildList() => StreamBuilder<List<ConversationModel>>(
    stream: ChatService.instance.streamConversations(_uid!),
    builder: (context, snap) {
      if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: kPrimary));
      if (snap.hasError) return _buildError(message: snap.error.toString());

      var convs = snap.data ?? [];
      final q = _searchCtrl.text.toLowerCase().trim();
      if (q.isNotEmpty) {
        convs = convs.where((c) =>
          c.reservationId.contains(q) ||
          (c.lastMessage?.toLowerCase().contains(q) ?? false) ||
          (c.managerName?.toLowerCase().contains(q) ?? false) ||
          (c.workerName?.toLowerCase().contains(q) ?? false)
        ).toList();
      }
      if (convs.isEmpty) return _buildEmpty(isSearch: q.isNotEmpty);

      return ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        itemCount: convs.length,
        itemBuilder: (_, i) {
          final conv = convs[i];
          return Dismissible(
            key: Key(conv.id),
            direction: DismissDirection.endToStart,
            background: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete_rounded, color: _white, size: 24),
            ),
            confirmDismiss: (_) async {
              await _deleteConversation(conv);
              return false; // let the stream update the list
            },
            child: _ConvTile(
              conv:   conv,
              myUid:  _uid!,
              onTap:  () => setState(() => _openConversation = conv),
              onDelete: () => _deleteConversation(conv),
            ),
          );
        },
      );
    },
  );

  Widget _buildEmpty({bool isSearch = false}) => Center(child: Padding(
    padding: const EdgeInsets.all(40),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 80, height: 80, decoration: BoxDecoration(color: kPrimary.withOpacity(0.07), shape: BoxShape.circle),
        child: Icon(isSearch ? Icons.search_off_rounded : Icons.chat_bubble_outline_rounded, size: 36, color: kPrimary.withOpacity(0.6))),
      const SizedBox(height: 18),
      Text(isSearch ? 'No conversations found' : 'No conversations yet',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _dark)),
      const SizedBox(height: 6),
      Text(isSearch ? 'Try a different search term' : 'Book a court to start chatting\nwith the venue team.',
          style: const TextStyle(fontSize: 13, color: _mid, height: 1.5), textAlign: TextAlign.center),
    ]),
  ));

  Widget _buildError({String? message}) => Scaffold(
    backgroundColor: _bg,
    body: Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.lock_outline_rounded, size: 52, color: _light),
        const SizedBox(height: 14),
        const Text('Could not connect', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _dark)),
        if ((message ?? _uidError) != null) ...[
          const SizedBox(height: 6),
          Text(message ?? _uidError!, style: const TextStyle(fontSize: 12, color: _mid), textAlign: TextAlign.center, maxLines: 3),
        ],
        const SizedBox(height: 20),
        GestureDetector(onTap: _resolveUid, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
          decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(14)),
          child: const Text('Retry', style: TextStyle(color: _white, fontWeight: FontWeight.w700, fontSize: 14)),
        )),
      ]),
    )),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CONVERSATION TILE
// ─────────────────────────────────────────────────────────────────────────────
class _ConvTile extends StatelessWidget {
  final ConversationModel conv;
  final String myUid;
  final VoidCallback onTap, onDelete;
  const _ConvTile({required this.conv, required this.myUid, required this.onTap, required this.onDelete});

  String _fmt(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24)   return '${diff.inHours}h';
    if (diff.inDays < 7)     return '${diff.inDays}d';
    return '${dt.day}/${dt.month}';
  }

  // Returns label, icon, color per conversation type
  _TypeMeta _meta() {
    switch (conv.type) {
      case ConversationType.playerManager:
        return _TypeMeta(
          label:   conv.managerName ?? 'Manager',
          tag:     'Manager',
          icon:    Icons.storefront_rounded,
          color:   _managerColor,
          initial: 'M',
        );
      case ConversationType.playerWorker:
        return _TypeMeta(
          label:   conv.workerName ?? 'Worker',
          tag:     'Worker',
          icon:    Icons.engineering_rounded,
          color:   _workerColor,
          initial: 'W',
        );
      default:
        return _TypeMeta(label: 'Chat', tag: '', icon: Icons.chat_rounded, color: _mid, initial: '?');
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasMsg = conv.lastMessage?.isNotEmpty == true;
    final m      = _meta();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        highlightColor: m.color.withOpacity(0.04),
        splashColor:    m.color.withOpacity(0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Avatar
            Container(
              width: 54, height: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: conv.type == ConversationType.playerWorker
                      ? [_workerColor, const Color(0xFF5B21B6)]
                      : [kPrimary, const Color(0xFF004D4F)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: m.color.withOpacity(0.22), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: Center(child: Text(m.initial,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _white))),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                // Type badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: m.color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(m.icon, size: 10, color: m.color),
                    const SizedBox(width: 4),
                    Text(m.tag, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: m.color)),
                  ]),
                ),
                const Spacer(),
                Text(_fmt(conv.lastMessageAt ?? conv.createdAt),
                    style: const TextStyle(fontSize: 11, color: _mid)),
              ]),
              const SizedBox(height: 4),
              Text(m.label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _dark)),
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.confirmation_number_rounded, size: 10, color: _light),
                const SizedBox(width: 3),
                Text('Booking #${conv.reservationId}', style: const TextStyle(fontSize: 11, color: _light, fontWeight: FontWeight.w500)),
              ]),
              const SizedBox(height: 4),
              Text(
                hasMsg ? conv.lastMessage! : 'Tap to start chatting',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: hasMsg ? _mid : _light, fontStyle: hasMsg ? FontStyle.normal : FontStyle.italic),
              ),
            ])),
          ]),
        ),
      ),
    );
  }
}

class _TypeMeta {
  final String label, tag, initial;
  final IconData icon;
  final Color color;
  const _TypeMeta({required this.label, required this.tag, required this.icon, required this.color, required this.initial});
}

// ─────────────────────────────────────────────────────────────────────────────
// CONVERSATION SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class _ConversationScreen extends StatefulWidget {
  final ConversationModel conversation;
  final String myUid, myName;
  final VoidCallback onBack, onDelete;
  const _ConversationScreen({required this.conversation, required this.myUid, required this.myName, required this.onBack, required this.onDelete});
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
    _ctrl.clear(); setState(() { _typing = false; _sending = true; });
    try {
      await ChatService.instance.sendMessage(
          conversationId: widget.conversation.id, senderId: widget.myUid, text: text);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    });
  }

  String get _headerTitle {
    final conv = widget.conversation;
    switch (conv.type) {
      case ConversationType.playerManager: return conv.managerName ?? 'Manager';
      case ConversationType.playerWorker:  return conv.workerName  ?? 'Worker';
      default: return 'Chat';
    }
  }

  Color get _headerColor {
    return widget.conversation.type == ConversationType.playerWorker ? _workerColor : _managerColor;
  }

  String get _headerInitial {
    return widget.conversation.type == ConversationType.playerWorker ? 'W' : 'M';
  }

  String get _headerSub {
    switch (widget.conversation.type) {
      case ConversationType.playerManager: return 'Venue Manager · Booking #${widget.conversation.reservationId}';
      case ConversationType.playerWorker:  return 'Court Worker · Booking #${widget.conversation.reservationId}';
      default: return 'Booking #${widget.conversation.reservationId}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bot = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      body: Column(children: [

        // ── App bar ──────────────────────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(color: _white,
              boxShadow: [BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 2))]),
          child: SafeArea(bottom: false, child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
            child: Row(children: [
              IconButton(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back_rounded, size: 22, color: _dark), padding: EdgeInsets.zero),
              const SizedBox(width: 6),
              // Avatar
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _headerColor == _workerColor
                        ? [_workerColor, const Color(0xFF5B21B6)]
                        : [kPrimary, const Color(0xFF004D4F)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text(_headerInitial,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _white))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_headerTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _dark)),
                Text(_headerSub, style: TextStyle(fontSize: 11, color: _headerColor, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
              ])),
              // Delete
              GestureDetector(
                onTap: widget.onDelete,
                child: Container(width: 36, height: 36,
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.withOpacity(0.2))),
                    child: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red)),
              ),
              const SizedBox(width: 8),
              Container(width: 36, height: 36, decoration: BoxDecoration(color: kPrimary.withOpacity(0.07), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.more_vert_rounded, size: 17, color: kPrimary)),
            ]),
          )),
        ),

        // ── Messages ─────────────────────────────────────────────────────────
        Expanded(child: StreamBuilder<List<MessageModel>>(
          stream: ChatService.instance.streamMessages(widget.conversation.id),
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: kPrimary));
            final msgs = snap.data ?? [];
            if (msgs.isEmpty) return _emptyMessages();
            _scrollToBottom();
            return ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: msgs.length,
              itemBuilder: (_, i) => _Bubble(
                msg:         msgs[i],
                isMe:        msgs[i].senderId == widget.myUid,
                theirColor:  _headerColor,
                theirInitial: _headerInitial,
                showAvatar:  !msgs[i].senderId.startsWith(widget.myUid) &&
                    (i == msgs.length - 1 || msgs[i + 1].senderId != msgs[i].senderId),
              ),
            );
          },
        )),

        // ── Input bar ────────────────────────────────────────────────────────
        Container(
          color: _white,
          padding: EdgeInsets.fromLTRB(12, 10, 12, bot + 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F8), borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _typing ? kPrimary.withOpacity(0.4) : Colors.transparent, width: 1.5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: TextField(
                controller: _ctrl, minLines: 1, maxLines: 5,
                style: const TextStyle(fontSize: 15, color: _dark, height: 1.4),
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Type a message…', hintStyle: TextStyle(color: _light, fontSize: 15),
                  border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8),
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
                  boxShadow: (_typing && !_sending) ? [BoxShadow(color: kPrimary.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))] : [],
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

  Widget _emptyMessages() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(width: 64, height: 64, decoration: BoxDecoration(color: _headerColor.withOpacity(0.08), shape: BoxShape.circle),
        child: Icon(Icons.chat_bubble_outline_rounded, size: 28, color: _headerColor.withOpacity(0.5))),
    const SizedBox(height: 14),
    const Text('No messages yet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _mid)),
    const SizedBox(height: 4),
    Text('Say hello to your ${widget.conversation.type == ConversationType.playerWorker ? "worker" : "manager"}!',
        style: const TextStyle(fontSize: 12, color: _light)),
  ]));
}

// ─────────────────────────────────────────────────────────────────────────────
// BUBBLE
// ─────────────────────────────────────────────────────────────────────────────
class _Bubble extends StatelessWidget {
  final MessageModel msg;
  final bool isMe, showAvatar;
  final Color theirColor;
  final String theirInitial;
  const _Bubble({required this.msg, required this.isMe, required this.showAvatar, required this.theirColor, required this.theirInitial});

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
              ? Container(width: 30, height: 30, margin: const EdgeInsets.only(right: 8, bottom: 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: theirColor == _workerColor
                        ? [_workerColor, const Color(0xFF5B21B6)]
                        : [kPrimary, const Color(0xFF004D4F)]),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: Text(theirInitial, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _white))))
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
                  topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4), bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: [BoxShadow(color: isMe ? kPrimary.withOpacity(0.22) : Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Text(msg.text, style: TextStyle(fontSize: 14, height: 1.4, color: isMe ? _white : _dark)),
            ),
            const SizedBox(height: 3),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text(_fmt(msg.createdAt), style: const TextStyle(fontSize: 10, color: _light)),
              if (isMe) ...[const SizedBox(width: 4), const Icon(Icons.done_all_rounded, size: 13, color: kPrimary)],
            ]),
          ],
        )),
        if (isMe) const SizedBox(width: 4),
      ],
    ),
  );
}















**********************************************************







// Views/Player/chat.dart
// Enhanced UI — inspired by Messengerish design:
// - Avatar with online indicator
// - Unread message badges
// - Clean conversation list with last message preview
// - Beautiful chat screen with delivery ticks
// - Added delete conversation functionality (swipe & modal)
// - Improved search bar matching home/explore page style
// - Redesigned delete buttons with better styling
// Uses deterministic UIDs from FirebaseIdentityService

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Services/chat_service.dart';
import 'package:sporta/Services/firebase_identity_service.dart';
import 'package:sporta/Services/player_manager_auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _bg     = Color(0xFFF5F6FA);
const _white  = Colors.white;
const _dark   = Color(0xFF0D1117);
const _mid    = Color(0xFF6B7280);
const _light  = Color(0xFFB0B7C3);
const _online = Color(0xFF22C55E);
const _unread = Color(0xFF006D6F);

class Chat extends StatefulWidget {
  final String? playerName;
  const Chat({super.key, this.playerName});
  @override State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> with SingleTickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  ConversationModel? _openConversation;
  String? _uid;
  bool _loadingUid = true;
  String? _uidError;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _searchCtrl.addListener(() => setState(() {}));
    _resolveUid();
  }

  Future<void> _resolveUid() async {
    setState(() { _loadingUid = true; _uidError = null; });
    try {
      String? deterministicUid = FirebaseIdentityService.instance.firebaseUid;
      
      if (deterministicUid != null && deterministicUid.isNotEmpty) {
        debugPrint('[Chat] Using deterministic UID: $deterministicUid');
        if (mounted) {
          setState(() { _uid = deterministicUid; _loadingUid = false; });
          _fadeCtrl.forward();
        }
        return;
      }
      
      final storage = FlutterSecureStorage();
      final token = await storage.read(key: 'jwt_token');
      
      if (token != null && token.isNotEmpty) {
        final profile = await PlayerManagerAuthService.getMe(token);
        final user = profile.containsKey('user') ? profile['user'] as Map<String, dynamic> : profile;
        final userId = user['id']?.toString() ?? '';
        
        if (userId.isNotEmpty) {
          deterministicUid = 'sporta_player_$userId';
          debugPrint('[Chat] Built deterministic UID from Strapi: $deterministicUid');
          if (mounted) {
            setState(() { _uid = deterministicUid; _loadingUid = false; });
            _fadeCtrl.forward();
          }
          return;
        }
      }
      
      final auth = FirebaseAuth.instance;
      User? firebaseUser = auth.currentUser;
      if (firebaseUser == null) {
        final cred = await auth.signInAnonymously();
        firebaseUser = cred.user;
      }
      if (firebaseUser != null) {
        debugPrint('[Chat] WARNING: Using anonymous UID (may not match backend): ${firebaseUser.uid}');
        if (mounted) {
          setState(() { _uid = firebaseUser!.uid; _loadingUid = false; });
          _fadeCtrl.forward();
        }
      } else {
        throw Exception('Could not get any UID');
      }
    } catch (e) {
      debugPrint('[Chat] uid error: $e');
      if (mounted) setState(() { _uidError = e.toString(); _loadingUid = false; });
    }
  }

  Future<void> _deleteConversation(String conversationId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Conversation', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        content: const Text('Are you sure you want to delete this conversation? This action cannot be undone.', style: TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: _mid)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        await ChatService.instance.deleteConversation(conversationId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Conversation deleted'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _clearAllConversations() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Clear All Conversations', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        content: const Text('Are you sure you want to delete ALL conversations? This action cannot be undone.', style: TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: _mid)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        await ChatService.instance.clearAllConversations(_uid!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All conversations cleared'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to clear: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() { _searchCtrl.dispose(); _fadeCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_loadingUid) return const Scaffold(backgroundColor: _bg, body: Center(child: CircularProgressIndicator(color: kPrimary)));
    if (_uid == null) return _buildError();
    if (_openConversation != null) {
      return _ConversationScreen(
        conversation: _openConversation!, myUid: _uid!,
        myName: widget.playerName ?? 'Player',
        onBack: () => setState(() => _openConversation = null),
      );
    }
    return _buildInbox();
  }

  Widget _buildInbox() => Scaffold(
    backgroundColor: _bg,
    body: Column(children: [
      _buildHeader(),
      _buildSearchBar(),
      Expanded(child: FadeTransition(opacity: _fadeAnim, child: _buildList())),
    ]),
  );

  Widget _buildHeader() => Container(
    color: _white,
    child: SafeArea(bottom: false, child: Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Messages', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _dark, letterSpacing: -0.6)),
          const SizedBox(height: 2),
          StreamBuilder<List<ConversationModel>>(
            stream: ChatService.instance.streamConversations(_uid!),
            builder: (_, snap) {
              final c = snap.data?.length ?? 0;
              return Text(c > 0 ? '$c conversation${c == 1 ? '' : 's'}' : 'No conversations yet',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: c > 0 ? kPrimary : _mid));
            },
          ),
        ]),
        const Spacer(),
        // Clear All button
        if (_searchCtrl.text.isEmpty)
          GestureDetector(
            onTap: _clearAllConversations,
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: const Icon(Icons.delete_sweep_rounded, color: Colors.red, size: 20),
            ),
          ),
        const SizedBox(width: 8),
        // New chat button
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: kPrimary,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: const Icon(Icons.edit_rounded, color: _white, size: 18),
        ),
      ]),
    )),
  );

  Widget _buildSearchBar() => Container(
    color: _white,
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
    child: Container(
      height: 48,
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(Icons.search_rounded, color: Colors.grey[400], size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 14, color: _dark),
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (_searchCtrl.text.isNotEmpty)
            GestureDetector(
              onTap: () => setState(() { _searchCtrl.clear(); }),
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Icon(Icons.close_rounded, size: 18, color: Colors.grey[400]),
              ),
            )
          else
            const SizedBox(width: 14),
        ],
      ),
    ),
  );

  Widget _buildList() => StreamBuilder<List<ConversationModel>>(
    stream: ChatService.instance.streamConversations(_uid!),
    builder: (context, snap) {
      if (snap.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator(color: kPrimary));
      }
      if (snap.hasError) return _buildStreamError(snap.error.toString());

      var convs = snap.data ?? [];
      final q = _searchCtrl.text.toLowerCase().trim();
      if (q.isNotEmpty) {
        convs = convs.where((c) => 
          c.reservationId.toString().contains(q) || 
          (c.lastMessage?.toLowerCase().contains(q) ?? false)
        ).toList();
      }
      if (convs.isEmpty) return _buildEmptyState(q.isNotEmpty);

      return ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        itemCount: convs.length,
        itemBuilder: (_, i) => Dismissible(
          key: Key(convs[i].id),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete_rounded, color: _white, size: 24),
          ),
          onDismissed: (_) => _deleteConversation(convs[i].id),
          child: _ConvTile(
            conv: convs[i], myUid: _uid!,
            onTap: () => setState(() => _openConversation = convs[i]),
            onDelete: () => _deleteConversation(convs[i].id),
          ),
        ),
      );
    },
  );

  Widget _buildEmptyState(bool isSearch) => Center(child: Padding(
    padding: const EdgeInsets.all(40),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 80, height: 80, decoration: BoxDecoration(color: kPrimary.withOpacity(0.07), shape: BoxShape.circle),
        child: Icon(isSearch ? Icons.search_off_rounded : Icons.chat_bubble_outline_rounded, size: 36, color: kPrimary.withOpacity(0.6))),
      const SizedBox(height: 18),
      Text(isSearch ? 'No conversations found' : 'No conversations yet', 
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _dark)),
      const SizedBox(height: 6),
      Text(isSearch 
          ? 'Try a different search term' 
          : 'Book a court to start chatting\nwith the venue manager',
          style: const TextStyle(fontSize: 13, color: _mid, height: 1.5), textAlign: TextAlign.center),
    ]),
  ));

  Widget _buildStreamError(String err) => Center(child: Padding(
    padding: const EdgeInsets.all(40),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.wifi_off_rounded, size: 48, color: _light),
      const SizedBox(height: 14),
      const Text('Could not load chats', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _dark)),
      const SizedBox(height: 6),
      Text(err, style: const TextStyle(fontSize: 12, color: _mid), textAlign: TextAlign.center, maxLines: 2),
      const SizedBox(height: 18),
      GestureDetector(onTap: _resolveUid, child: Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11), decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(12)), child: const Text('Retry', style: TextStyle(color: _white, fontWeight: FontWeight.w700)))),
    ]),
  ));

  Widget _buildError() => Scaffold(backgroundColor: _bg, body: Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.lock_outline_rounded, size: 52, color: _light),
      const SizedBox(height: 14),
      const Text('Could not connect', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _dark)),
      if (_uidError != null) ...[const SizedBox(height: 6), Text(_uidError!, style: const TextStyle(fontSize: 12, color: _mid), textAlign: TextAlign.center)],
      const SizedBox(height: 20),
      GestureDetector(onTap: _resolveUid, child: Container(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13), decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(14)), child: const Text('Retry', style: TextStyle(color: _white, fontWeight: FontWeight.w700, fontSize: 14)))),
    ]),
  )));
}

// ── CONVERSATION TILE ─────────────────────────────────────────────────────────
class _ConvTile extends StatelessWidget {
  final ConversationModel conv;
  final String myUid;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _ConvTile({required this.conv, required this.myUid, required this.onTap, required this.onDelete});

  String _fmt(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    final hasMsg = conv.lastMessage?.isNotEmpty == true;
    final initials = 'VM';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        highlightColor: kPrimary.withOpacity(0.04),
        splashColor: kPrimary.withOpacity(0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            Stack(children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kPrimary, const Color(0xFF004D4F)]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: Center(child: Text(initials, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _white, letterSpacing: -0.5))),
              ),
              Positioned(bottom: 2, right: 2, child: Container(
                width: 13, height: 13,
                decoration: BoxDecoration(color: _online, shape: BoxShape.circle, border: Border.all(color: _white, width: 2)),
              )),
            ]),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text('Booking #${conv.reservationId}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _dark))),
                Text(_fmt(conv.lastMessageAt ?? conv.createdAt),
                    style: const TextStyle(fontSize: 11, color: _mid)),
              ]),
              const SizedBox(height: 3),
              Row(children: [
                const Icon(Icons.storefront_rounded, size: 11, color: kPrimary),
                const SizedBox(width: 4),
                const Text('Venue Manager', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kPrimary)),
              ]),
              const SizedBox(height: 3),
              Row(children: [
                Expanded(child: Text(
                    hasMsg ? conv.lastMessage! : 'Tap to start chatting',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: hasMsg ? _mid : _light, fontStyle: hasMsg ? FontStyle.normal : FontStyle.italic))),
              ]),
            ])),
          ]),
        ),
      ),
    );
  }
}

// ── CONVERSATION SCREEN ───────────────────────────────────────────────────────
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
      await ChatService.instance.sendMessage(conversationId: widget.conversation.id, senderId: widget.myUid, text: text);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  Future<void> _deleteThisConversation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Conversation', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        content: const Text('Are you sure you want to delete this conversation?', style: TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: _mid)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        await ChatService.instance.deleteConversation(widget.conversation.id);
        if (mounted) {
          widget.onBack();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Conversation deleted'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bot  = MediaQuery.of(context).padding.bottom;
    final conv = widget.conversation;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      body: Column(children: [
        Container(
          decoration: BoxDecoration(
            color: _white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
          ),
          child: SafeArea(bottom: false, child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
            child: Row(children: [
              IconButton(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back_rounded, size: 22, color: _dark), padding: EdgeInsets.zero),
              const SizedBox(width: 6),
              Stack(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kPrimary, const Color(0xFF004D4F)]),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(child: Text('VM', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _white))),
                ),
                Positioned(bottom: 1, right: 1, child: Container(width: 11, height: 11, decoration: BoxDecoration(color: _online, shape: BoxShape.circle, border: Border.all(color: _white, width: 2)))),
              ]),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Booking #${conv.reservationId}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _dark)),
                const Text('Online', style: TextStyle(fontSize: 11, color: _online, fontWeight: FontWeight.w600)),
              ])),
              // Delete button in conversation header - redesigned
              GestureDetector(
                onTap: _deleteThisConversation,
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                ),
              ),
              const SizedBox(width: 8),
              Container(width: 36, height: 36, decoration: BoxDecoration(color: kPrimary.withOpacity(0.07), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.call_outlined, size: 17, color: kPrimary)),
              const SizedBox(width: 8),
              Container(width: 36, height: 36, decoration: BoxDecoration(color: kPrimary.withOpacity(0.07), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.more_vert_rounded, size: 17, color: kPrimary)),
            ]),
          )),
        ),

        Expanded(child: StreamBuilder<List<MessageModel>>(
          stream: ChatService.instance.streamMessages(conv.id),
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: kPrimary));
            final msgs = snap.data ?? [];

            if (msgs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 64, height: 64, decoration: BoxDecoration(color: kPrimary.withOpacity(0.08), shape: BoxShape.circle), child: Icon(Icons.chat_bubble_outline_rounded, size: 28, color: kPrimary.withOpacity(0.5))),
              const SizedBox(height: 14),
              const Text('No messages yet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _mid)),
              const SizedBox(height: 4),
              const Text('Say hello to your manager!', style: TextStyle(fontSize: 12, color: _light)),
            ]));

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
            });

            return ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: msgs.length,
              itemBuilder: (_, i) {
                final msg    = msgs[i];
                final isMe   = msg.senderId == widget.myUid;
                return _Bubble(msg: msg, isMe: isMe, showAvatar: !isMe && (i == msgs.length - 1 || msgs[i + 1].senderId != msg.senderId));
              },
            );
          },
        )),

        Container(
          color: _white,
          padding: EdgeInsets.fromLTRB(12, 10, 12, bot + 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.attach_file_rounded, size: 18, color: _mid)),
            const SizedBox(width: 8),
            Expanded(child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              decoration: BoxDecoration(
                color: _bg, borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _typing ? kPrimary.withOpacity(0.4) : Colors.transparent, width: 1.5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: TextField(
                controller: _ctrl, minLines: 1, maxLines: 5,
                style: const TextStyle(fontSize: 15, color: _dark, height: 1.4),
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Type Something...', hintStyle: TextStyle(color: _light, fontSize: 15),
                  border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                  isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            )),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: (_typing && !_sending) ? _send : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: (_typing && !_sending) ? kPrimary : kPrimary.withOpacity(0.12),
                  shape: BoxShape.circle,
                  boxShadow: (_typing && !_sending) ? [BoxShadow(color: kPrimary.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))] : [],
                ),
                child: _sending
                    ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: _white))
                    : Icon(_typing ? Icons.send_rounded : Icons.mic_rounded, size: 20, color: _typing ? _white : kPrimary),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── BUBBLE ────────────────────────────────────────────────────────────────────
class _Bubble extends StatelessWidget {
  final MessageModel msg;
  final bool isMe, showAvatar;
  const _Bubble({required this.msg, required this.isMe, required this.showAvatar});

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
              ? Container(width: 30, height: 30, margin: const EdgeInsets.only(right: 8, bottom: 2),
                  decoration: BoxDecoration(gradient: LinearGradient(colors: [kPrimary, const Color(0xFF004D4F)]), shape: BoxShape.circle),
                  child: const Center(child: Text('V', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _white))))
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
                  topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4), bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: [BoxShadow(color: isMe ? kPrimary.withOpacity(0.25) : Colors.black.withOpacity(0.06), blurRadius: isMe ? 8 : 6, offset: const Offset(0, 2))],
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










****************************










// Views/Player/chat.dart
// Enhanced UI — inspired by Messengerish design:
// - Avatar with online indicator
// - Unread message badges
// - Clean conversation list with last message preview
// - Beautiful chat screen with delivery ticks
// Uses deterministic UIDs from FirebaseIdentityService

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Services/chat_service.dart';
import 'package:sporta/Services/firebase_identity_service.dart';
import 'package:sporta/Services/player_manager_auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _bg     = Color(0xFFF5F6FA);
const _white  = Colors.white;
const _dark   = Color(0xFF0D1117);
const _mid    = Color(0xFF6B7280);
const _light  = Color(0xFFB0B7C3);
const _online = Color(0xFF22C55E);
const _unread = Color(0xFF006D6F);

class Chat extends StatefulWidget {
  final String? playerName;
  const Chat({super.key, this.playerName});
  @override State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  ConversationModel? _openConversation;
  String? _uid;
  bool _loadingUid = true;
  String? _uidError;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _searchCtrl.addListener(() => setState(() {}));
    _resolveUid();
  }

  Future<void> _resolveUid() async {
    setState(() { _loadingUid = true; _uidError = null; });
    try {
      // First, try to get deterministic UID from FirebaseIdentityService
      String? deterministicUid = FirebaseIdentityService.instance.firebaseUid;
      
      if (deterministicUid != null && deterministicUid.isNotEmpty) {
        debugPrint('[Chat] Using deterministic UID: $deterministicUid');
        if (mounted) {
          setState(() { _uid = deterministicUid; _loadingUid = false; });
          _fadeCtrl.forward();
        }
        return;
      }
      
      // If not set, try to get it from Strapi user ID
      final storage = FlutterSecureStorage();
      final token = await storage.read(key: 'jwt_token');
      
      if (token != null && token.isNotEmpty) {
        final profile = await PlayerManagerAuthService.getMe(token);
        final user = profile.containsKey('user') ? profile['user'] as Map<String, dynamic> : profile;
        final userId = user['id']?.toString() ?? '';
        
        if (userId.isNotEmpty) {
          deterministicUid = 'sporta_player_$userId';
          debugPrint('[Chat] Built deterministic UID from Strapi: $deterministicUid');
          if (mounted) {
            setState(() { _uid = deterministicUid; _loadingUid = false; });
            _fadeCtrl.forward();
          }
          return;
        }
      }
      
      // Last resort: use anonymous auth (won't match backend but prevents crash)
      final auth = FirebaseAuth.instance;
      User? firebaseUser = auth.currentUser;
      if (firebaseUser == null) {
        final cred = await auth.signInAnonymously();
        firebaseUser = cred.user;
      }
      if (firebaseUser != null) {
        debugPrint('[Chat] WARNING: Using anonymous UID (may not match backend): ${firebaseUser.uid}');
        if (mounted) {
          setState(() { _uid = firebaseUser!.uid; _loadingUid = false; });
          _fadeCtrl.forward();
        }
      } else {
        throw Exception('Could not get any UID');
      }
    } catch (e) {
      debugPrint('[Chat] uid error: $e');
      if (mounted) setState(() { _uidError = e.toString(); _loadingUid = false; });
    }
  }

  @override
  void dispose() { _searchCtrl.dispose(); _fadeCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_loadingUid) return const Scaffold(backgroundColor: _bg, body: Center(child: CircularProgressIndicator(color: kPrimary)));
    if (_uid == null) return _buildError();
    if (_openConversation != null) {
      return _ConversationScreen(
        conversation: _openConversation!, myUid: _uid!,
        myName: widget.playerName ?? 'Player',
        onBack: () => setState(() => _openConversation = null),
      );
    }
    return _buildInbox();
  }

  Widget _buildInbox() => Scaffold(
    backgroundColor: _bg,
    body: Column(children: [
      _buildHeader(),
      _buildSearchBar(),
      Expanded(child: FadeTransition(opacity: _fadeAnim, child: _buildList())),
    ]),
  );

  Widget _buildHeader() => Container(
    color: _white,
    child: SafeArea(bottom: false, child: Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Messages', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _dark, letterSpacing: -0.6)),
          const SizedBox(height: 2),
          StreamBuilder<List<ConversationModel>>(
            stream: ChatService.instance.streamConversations(_uid!),
            builder: (_, snap) {
              final c = snap.data?.length ?? 0;
              return Text(c > 0 ? '$c conversation${c == 1 ? '' : 's'}' : 'No conversations yet',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: c > 0 ? kPrimary : _mid));
            },
          ),
        ]),
        const Spacer(),
        // New chat button
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))]),
          child: const Icon(Icons.edit_rounded, color: _white, size: 18),
        ),
      ]),
    )),
  );

  Widget _buildSearchBar() => Container(
    color: _white,
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
    child: Container(
      height: 44,
      decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        const SizedBox(width: 12),
        const Icon(Icons.search_rounded, color: _light, size: 18),
        const SizedBox(width: 8),
        Expanded(child: TextField(
          controller: _searchCtrl,
          style: const TextStyle(fontSize: 14, color: _dark),
          decoration: const InputDecoration(hintText: 'Search conversations...', hintStyle: TextStyle(color: _light, fontSize: 14), border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 10)),
        )),
        if (_searchCtrl.text.isNotEmpty)
          GestureDetector(onTap: () { _searchCtrl.clear(); setState(() {}); },
            child: const Padding(padding: EdgeInsets.only(right: 10), child: Icon(Icons.close_rounded, size: 15, color: _light))),
      ]),
    ),
  );

  Widget _buildList() => StreamBuilder<List<ConversationModel>>(
    stream: ChatService.instance.streamConversations(_uid!),
    builder: (context, snap) {
      if (snap.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator(color: kPrimary));
      }
      if (snap.hasError) return _buildStreamError(snap.error.toString());

      var convs = snap.data ?? [];
      final q = _searchCtrl.text.toLowerCase();
      if (q.isNotEmpty) {
        convs = convs.where((c) => c.reservationId.contains(q) || (c.lastMessage?.toLowerCase().contains(q) ?? false)).toList();
      }
      if (convs.isEmpty) return _buildEmptyState();

      return ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        itemCount: convs.length,
        itemBuilder: (_, i) => _ConvTile(
          conv: convs[i], myUid: _uid!,
          onTap: () => setState(() => _openConversation = convs[i]),
        ),
      );
    },
  );

  Widget _buildEmptyState() => Center(child: Padding(
    padding: const EdgeInsets.all(40),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 80, height: 80, decoration: BoxDecoration(color: kPrimary.withOpacity(0.07), shape: BoxShape.circle),
        child: Icon(Icons.chat_bubble_outline_rounded, size: 36, color: kPrimary.withOpacity(0.6))),
      const SizedBox(height: 18),
      const Text('No conversations yet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _dark)),
      const SizedBox(height: 6),
      const Text('Book a court to start chatting\nwith the venue manager', style: TextStyle(fontSize: 13, color: _mid, height: 1.5), textAlign: TextAlign.center),
    ]),
  ));

  Widget _buildStreamError(String err) => Center(child: Padding(
    padding: const EdgeInsets.all(40),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.wifi_off_rounded, size: 48, color: _light),
      const SizedBox(height: 14),
      const Text('Could not load chats', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _dark)),
      const SizedBox(height: 6),
      Text(err, style: const TextStyle(fontSize: 12, color: _mid), textAlign: TextAlign.center, maxLines: 2),
      const SizedBox(height: 18),
      GestureDetector(onTap: _resolveUid, child: Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11), decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(12)), child: const Text('Retry', style: TextStyle(color: _white, fontWeight: FontWeight.w700)))),
    ]),
  ));

  Widget _buildError() => Scaffold(backgroundColor: _bg, body: Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.lock_outline_rounded, size: 52, color: _light),
      const SizedBox(height: 14),
      const Text('Could not connect', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _dark)),
      if (_uidError != null) ...[const SizedBox(height: 6), Text(_uidError!, style: const TextStyle(fontSize: 12, color: _mid), textAlign: TextAlign.center)],
      const SizedBox(height: 20),
      GestureDetector(onTap: _resolveUid, child: Container(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13), decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(14)), child: const Text('Retry', style: TextStyle(color: _white, fontWeight: FontWeight.w700, fontSize: 14)))),
    ]),
  )));
}

// ── CONVERSATION TILE ─────────────────────────────────────────────────────────
class _ConvTile extends StatelessWidget {
  final ConversationModel conv;
  final String myUid;
  final VoidCallback onTap;
  const _ConvTile({required this.conv, required this.myUid, required this.onTap});

  String _fmt(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    final hasMsg = conv.lastMessage?.isNotEmpty == true;
    final initials = 'VM'; // Venue Manager

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        highlightColor: kPrimary.withOpacity(0.04),
        splashColor: kPrimary.withOpacity(0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            // Avatar with online indicator
            Stack(children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kPrimary, const Color(0xFF004D4F)]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: Center(child: Text(initials, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _white, letterSpacing: -0.5))),
              ),
              // Online dot
              Positioned(bottom: 2, right: 2, child: Container(
                width: 13, height: 13,
                decoration: BoxDecoration(color: _online, shape: BoxShape.circle, border: Border.all(color: _white, width: 2)),
              )),
            ]),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text('Booking #${conv.reservationId}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _dark))),
                Text(_fmt(conv.lastMessageAt ?? conv.createdAt),
                    style: const TextStyle(fontSize: 11, color: _mid)),
              ]),
              const SizedBox(height: 3),
              Row(children: [
                const Icon(Icons.storefront_rounded, size: 11, color: kPrimary),
                const SizedBox(width: 4),
                const Text('Venue Manager', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kPrimary)),
              ]),
              const SizedBox(height: 3),
              Row(children: [
                Expanded(child: Text(
                    hasMsg ? conv.lastMessage! : 'Tap to start chatting',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: hasMsg ? _mid : _light, fontStyle: hasMsg ? FontStyle.normal : FontStyle.italic))),
              ]),
            ])),
          ]),
        ),
      ),
    );
  }
}

// ── CONVERSATION SCREEN ───────────────────────────────────────────────────────
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
      await ChatService.instance.sendMessage(conversationId: widget.conversation.id, senderId: widget.myUid, text: text);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bot  = MediaQuery.of(context).padding.bottom;
    final conv = widget.conversation;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      body: Column(children: [
        // ── Header ─────────────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: _white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
          ),
          child: SafeArea(bottom: false, child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
            child: Row(children: [
              IconButton(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back_rounded, size: 22, color: _dark), padding: EdgeInsets.zero),
              const SizedBox(width: 6),
              // Avatar
              Stack(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kPrimary, const Color(0xFF004D4F)]),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(child: Text('VM', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _white))),
                ),
                Positioned(bottom: 1, right: 1, child: Container(width: 11, height: 11, decoration: BoxDecoration(color: _online, shape: BoxShape.circle, border: Border.all(color: _white, width: 2)))),
              ]),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Booking #${conv.reservationId}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _dark)),
                const Text('Online', style: TextStyle(fontSize: 11, color: _online, fontWeight: FontWeight.w600)),
              ])),
              // Actions
              Container(width: 36, height: 36, decoration: BoxDecoration(color: kPrimary.withOpacity(0.07), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.call_outlined, size: 17, color: kPrimary)),
              const SizedBox(width: 8),
              Container(width: 36, height: 36, decoration: BoxDecoration(color: kPrimary.withOpacity(0.07), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.more_vert_rounded, size: 17, color: kPrimary)),
            ]),
          )),
        ),

        // ── Messages ───────────────────────────────────────────────────────
        Expanded(child: StreamBuilder<List<MessageModel>>(
          stream: ChatService.instance.streamMessages(conv.id),
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: kPrimary));
            final msgs = snap.data ?? [];

            if (msgs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 64, height: 64, decoration: BoxDecoration(color: kPrimary.withOpacity(0.08), shape: BoxShape.circle), child: Icon(Icons.chat_bubble_outline_rounded, size: 28, color: kPrimary.withOpacity(0.5))),
              const SizedBox(height: 14),
              const Text('No messages yet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _mid)),
              const SizedBox(height: 4),
              const Text('Say hello to your manager!', style: TextStyle(fontSize: 12, color: _light)),
            ]));

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
            });

            return ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: msgs.length,
              itemBuilder: (_, i) {
                final msg    = msgs[i];
                final isMe   = msg.senderId == widget.myUid;
                // Group by sender
                final prevMe = i > 0 && msgs[i - 1].senderId == widget.myUid;
                final nextMe = i < msgs.length - 1 && msgs[i + 1].senderId == widget.myUid;
                final isFirst = !prevMe || msgs[i-1 < 0 ? 0 : i-1].senderId != msg.senderId;
                return _Bubble(msg: msg, isMe: isMe, showAvatar: !isMe && (i == msgs.length - 1 || msgs[i + 1].senderId != msg.senderId));
              },
            );
          },
        )),

        // ── Input ──────────────────────────────────────────────────────────
        Container(
          color: _white,
          padding: EdgeInsets.fromLTRB(12, 10, 12, bot + 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            // Attach
            Container(width: 40, height: 40, decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.attach_file_rounded, size: 18, color: _mid)),
            const SizedBox(width: 8),
            // Text field
            Expanded(child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              decoration: BoxDecoration(
                color: _bg, borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _typing ? kPrimary.withOpacity(0.4) : Colors.transparent, width: 1.5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: TextField(
                controller: _ctrl, minLines: 1, maxLines: 5,
                style: const TextStyle(fontSize: 15, color: _dark, height: 1.4),
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Type Something...', hintStyle: TextStyle(color: _light, fontSize: 15),
                  border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                  isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            )),
            const SizedBox(width: 8),
            // Send / Voice
            GestureDetector(
              onTap: (_typing && !_sending) ? _send : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: (_typing && !_sending) ? kPrimary : kPrimary.withOpacity(0.12),
                  shape: BoxShape.circle,
                  boxShadow: (_typing && !_sending) ? [BoxShadow(color: kPrimary.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))] : [],
                ),
                child: _sending
                    ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: _white))
                    : Icon(_typing ? Icons.send_rounded : Icons.mic_rounded, size: 20, color: _typing ? _white : kPrimary),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── BUBBLE ────────────────────────────────────────────────────────────────────
class _Bubble extends StatelessWidget {
  final MessageModel msg;
  final bool isMe, showAvatar;
  const _Bubble({required this.msg, required this.isMe, required this.showAvatar});

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
        // Their avatar
        if (!isMe) ...[
          showAvatar
              ? Container(width: 30, height: 30, margin: const EdgeInsets.only(right: 8, bottom: 2),
                  decoration: BoxDecoration(gradient: LinearGradient(colors: [kPrimary, const Color(0xFF004D4F)]), shape: BoxShape.circle),
                  child: const Center(child: Text('V', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _white))))
              : const SizedBox(width: 38),
        ],
        // Bubble
        Flexible(child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? kPrimary : _white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4), bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: [BoxShadow(color: isMe ? kPrimary.withOpacity(0.25) : Colors.black.withOpacity(0.06), blurRadius: isMe ? 8 : 6, offset: const Offset(0, 2))],
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