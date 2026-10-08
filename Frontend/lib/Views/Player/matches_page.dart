// lib/Views/Player/matches_page.dart

// e5er 7ajet zedthom :
// Premium redesign:
//   - Sport filter chips + tab-style switching (Community / My Matches)
//   - Hero image cards with gradient overlay + sport badge
//   - Join request shows player phone to host
//   - Host phone visible in detail sheet after acceptance
//   - Pull-to-refresh, animated join state
//   - Notification bell: pending requests + my responses (with phone)
//   - Accepted players list with call button on My Matches tab

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Models/app_enums.dart';
import 'package:sporta/Models/app_models.dart';
import 'package:sporta/Services/announcement_service.dart';
import 'package:sporta/Services/booking_store.dart';
import 'package:sporta/Services/player_manager_auth_service.dart';
import 'package:sporta/Widgets/Buttons/primary_button.dart';
import 'package:sporta/Widgets/Lists/avatar_widget.dart';

// 
// HELPERS
//

SportType _parseSport(String sport) {
  switch (sport.toLowerCase()) {
    case 'football':   return SportType.football;
    case 'tennis':     return SportType.tennis;
    case 'padel':      return SportType.padel;
    case 'basketball': return SportType.basketball;
    default:           return SportType.football;
  }
}

AnnouncementModel _toModel(AnnouncementData d) {
  final reservation = CourtReservation(
    id:            d.reservationId,
    courtId:       '',
    courtName:     d.courtName,
    hostId:        d.hostPlayerId,
    sport:         _parseSport(d.sport),
    date:          DateTime.tryParse(d.date) ?? DateTime.now(),
    startTime:     d.startTime,
    endTime:       d.endTime,
    durationHours: 1,
    totalPrice:    0,
    paymentOption: PaymentOption.payAtVenue,
    courtImageUrl: d.courtImageUrl.isNotEmpty ? d.courtImageUrl : null,
  );
  final requests = d.joinRequests.map((jr) => JoinRequest(
    id:      jr.id,
    player:  AppPlayer(
      id:             jr.playerId,
      name:           jr.playerName,
      avatarInitials: jr.playerInitials,
      phone:          jr.playerPhone,
    ),
    message: jr.message,
    status:  _parseStatus(jr.status),
  )).toList();
  final model = AnnouncementModel(
    id:            d.id,
    reservation:   reservation,
    host: AppPlayer(
      id:             d.hostPlayerId,
      name:           d.hostName,
      avatarInitials: d.hostInitials,
      phone:          d.hostPhone,
    ),
    playersNeeded: d.playersNeeded,
    description:   d.description,
    createdAt:     DateTime.now(),
    requests:      requests,
  );
  // Store status from AnnouncementData so we can read it on the model
  _announcementStatusMap[d.id] = d.status;
  _announcementVenueMap[d.id]  = d.venueName;
  return model;
}

// Global status/venue cache — avoids adding fields to AnnouncementModel
final Map<String, String> _announcementStatusMap = {};
final Map<String, String> _announcementVenueMap  = {};

JoinRequestStatus _parseStatus(String s) {
  switch (s.toLowerCase()) {
    case 'accepted': return JoinRequestStatus.accepted;
    case 'declined': return JoinRequestStatus.declined;
    default:         return JoinRequestStatus.pending;
  }
}

String _fixImageUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  if (url.contains('localhost')) return url.replaceAll('localhost', '10.0.2.2');
  return url;
}

Future<void> _callPhone(String phone) async {
  if (phone.isEmpty) return;
  try {
    final encoded = Uri.encodeComponent(phone);
    if (Platform.isAndroid) {
      await Process.run('am', ['start', '-a', 'android.intent.action.DIAL', '-d', 'tel:$encoded']);
    } else if (Platform.isIOS) {
      await Process.run('open', ['tel://$encoded']);
    }
  } catch (_) {
    // Silently fail — phone calling is best-effort
  }
}

// 
// CONSTANTS
// 
const _kBg     = Color(0xFFF2F4F7);
const _kCard   = Colors.white;
const _kInk    = Color(0xFF0A0E1A);
const _kMid    = Color(0xFF64748B);
const _kLight  = Color(0xFFB0B7C3);
const _kBorder = Color(0xFFE8EDF3);

// 
// PAGE
// 

class Matches extends StatefulWidget {
  final String? playerToken;
  const Matches({super.key, this.playerToken});
  @override State<Matches> createState() => _MatchesState();
}

class _MatchesState extends State<Matches>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {

  // Tabs: 0 = Community, 1 = My Matches
  // 0 - 1 y3awnou akther
  late final TabController _tab;

  SportType? _sportFilter;

  List<AnnouncementModel> _community   = [];
  List<AnnouncementModel> _mine        = [];
  List<JoinRequestData>   _myResponses = [];

  bool   _loading     = true;
  bool   _initialized = false;
  AnnouncementService? _svc;
  String? _currentUsername;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    BookingStore.instance.addListener(_onStoreChanged);
    _init();
  }

  @override
  void dispose() {
    _tab.dispose();
    WidgetsBinding.instance.removeObserver(this);
    BookingStore.instance.removeListener(_onStoreChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshAll();
  }

  //  Init 

  Future<void> _init() async {
    if (_initialized) return;
    String? token = widget.playerToken;
    if (token == null || token.isEmpty) {
      token = await const FlutterSecureStorage().read(key: 'jwt_token');
    }
    if (token == null || token.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    await BookingStore.instance.initialize(token);
    _svc = AnnouncementService(token: token);
    try {
      final me = await PlayerManagerAuthService.getMe(token);
      _currentUsername = me['user']?['username']?.toString() ?? me['username']?.toString();
    } catch (_) {}
    _initialized = true;
    await _loadAll();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _refreshAll() async {
    String? token = widget.playerToken;
    if (token == null || token.isEmpty) {
      token = await const FlutterSecureStorage().read(key: 'jwt_token');
    }
    if (token == null) return;
    if (!_initialized) {
      await BookingStore.instance.initialize(token);
      _svc = AnnouncementService(token: token);
      _initialized = true;
    }
    await BookingStore.instance.refresh();
    await _loadAll();
  }

  void _onStoreChanged() => _loadAll();

  Future<void> _loadAll() async {
    await Future.wait([_loadCommunity(), _loadMine(), _loadMyResponses()]);
    if (mounted) setState(() {});
  }

  Future<void> _loadCommunity() async {
    if (_svc == null) return;
    try { _community = (await _svc!.fetchFeed()).map(_toModel).toList(); }
    catch (e) { debugPrint('_loadCommunity: $e'); }
  }

  Future<void> _loadMine() async {
    if (_svc == null) return;
    try { _mine = (await _svc!.fetchMine()).map(_toModel).toList(); }
    catch (e) { debugPrint('_loadMine: $e'); }
  }

  Future<void> _loadMyResponses() async {
    if (_svc == null) return;
    try { _myResponses = (await _svc!.fetchMyRequests()).where((r) => r.status != 'pending').toList(); }
    catch (e) { debugPrint('_loadMyResponses: $e'); }
  }

  

  bool _isMine(AnnouncementModel a) => 
      _currentUsername != null && a.host.name == _currentUsername;

  bool _hasRequested(AnnouncementModel a) =>  
      _currentUsername != null &&
      a.requests.any((r) => r.player.name == _currentUsername);

  bool _isAccepted(AnnouncementModel a) =>
      _currentUsername != null &&
      a.requests.any((r) => r.player.name == _currentUsername && r.status == JoinRequestStatus.accepted);

  bool _isPending(AnnouncementModel a) =>
      _currentUsername != null &&
      a.requests.any((r) => r.player.name == _currentUsername && r.status == JoinRequestStatus.pending);

  List<AnnouncementModel> get _filteredCommunity => _community.where((a) { 
    if (_sportFilter != null && a.reservation.sport != _sportFilter) return false;
    return true;
  }).toList();

  List<AnnouncementModel> get _filteredMine => _mine.where((a) {
    if (_sportFilter != null && a.reservation.sport != _sportFilter) return false;
    return true;
  }).toList();

  int get _pendingCount  => _mine.fold(0, (s, a) => s + a.pendingCount);
  int get _totalBell     => _pendingCount + _myResponses.length;

  //  Actions 

  void _openBell() => showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (_) => _NotificationSheet(
      myAnnouncements: _mine,
      myResponses:     _myResponses,
      svc:             _svc,
      onUpdate:        _loadAll,
    ),
  );

  void _openDetail(AnnouncementModel ann) => showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (_) => _DetailSheet(
      ann:          ann,
      isMine:       _isMine(ann),
      hasRequested: _hasRequested(ann),
      isAccepted:   _isAccepted(ann),
      isPending:    _isPending(ann),
      onRequest:    () => _requestJoin(ann),
    ),
  );

  void _requestJoin(AnnouncementModel ann) => showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (_) => _JoinSheet(
      ann:    ann,
      onSend: (msg) async {
        Navigator.pop(context);
        if (_svc == null) return;
        try {
          final jr = await _svc!.requestJoin(ann.id, message: msg);
          setState(() {
            ann.requests.add(JoinRequest(
              id:      jr.id,
              player:  AppPlayer(
                id:             _currentUsername ?? '',
                name:           _currentUsername ?? 'You',
                avatarInitials: _currentUsername?.isNotEmpty == true ? _currentUsername![0].toUpperCase() : 'Y',
                phone:          '',
              ),
              message: jr.message,
              status:  JoinRequestStatus.pending,
            ));
          });
          _snack('Request sent! Waiting for approval.', kGreen);
        } catch (e) {
          _snack('Failed: ${e.toString().replaceAll('Exception:', '')}', kRed);
        }
      },
    ),
  );

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:  Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape:    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin:   const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  // Build 

  @override
  Widget build(BuildContext context) {
    final navH = kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(children: [
        // Header 
        _buildHeader(),

        // Tab bar
        Container(
          color: _kCard,
          child: TabBar(
            controller: _tab,
            labelColor: kPrimary,
            unselectedLabelColor: _kMid,
            indicatorColor: kPrimary,
            indicatorWeight: 2.5,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            tabs: [
              Tab(text: 'Community  ${_filteredCommunity.isEmpty ? '' : '(${_filteredCommunity.length})'}'),
              Tab(text: 'My Matches  ${_filteredMine.isEmpty ? '' : '(${_filteredMine.length})'}'),
            ],
          ),
        ),

        // Content 
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: kPrimary))
            : TabBarView(controller: _tab, children: [
                _CommunityTab(
                  announcements: _filteredCommunity,
                  isMine:        _isMine,
                  hasRequested:  _hasRequested,
                  isAccepted:    _isAccepted,
                  isPending:     _isPending,
                  onTap:         _openDetail,
                  onRequest:     _requestJoin,
                  onRefresh:     _refreshAll,
                  navH:          navH,
                ),
                _MyMatchesTab(
                  announcements: _filteredMine,
                  onTap:         _openDetail,
                  onRefresh:     _refreshAll,
                  myResponses:   _myResponses,
                  navH:          navH,
                ),
              ])),
      ]),
    );
  }

  Widget _buildHeader() => Container(
    color: _kCard,
    child: SafeArea(bottom: false, child: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Community', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _kInk, letterSpacing: -0.6)),
            Text(_loading ? 'Loading…' : '${_filteredCommunity.length} open near you',
                style: const TextStyle(fontSize: 12, color: _kMid)),
          ])),
          // Refresh
          GestureDetector(onTap: _refreshAll,
            child: Container(width: 36, height: 36,
              decoration: BoxDecoration(color: kPrimary.withOpacity(0.08), shape: BoxShape.circle),
              child: const Icon(Icons.refresh_rounded, size: 18, color: kPrimary))),
          const SizedBox(width: 8),
          // Notification bell
          GestureDetector(onTap: _openBell,
            child: Stack(clipBehavior: Clip.none, children: [
              Container(width: 42, height: 42,
                decoration: BoxDecoration(
                  color: _totalBell > 0 ? kPrimary.withOpacity(0.08) : _kBg,
                  shape: BoxShape.circle),
                child: Icon(
                  _totalBell > 0 ? Icons.notifications_rounded : Icons.notifications_outlined,
                  color: _totalBell > 0 ? kPrimary : _kMid, size: 22)),
              if (_totalBell > 0)
                Positioned(right: 8, top: 8,
                  child: Container(width: 9, height: 9,
                    decoration: BoxDecoration(color: kGreen, shape: BoxShape.circle,
                        border: Border.all(color: _kCard, width: 1.5)))),
            ])),
        ]),
      ),
      const SizedBox(height: 12),
      // Sport filter
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: _SportFilter(selected: _sportFilter, onSelect: (s) => setState(() => _sportFilter = s)),
      ),
      const SizedBox(height: 12),
    ])),
  );
}

// 
// COMMUNITY TAB
// 

class _CommunityTab extends StatelessWidget {
  final List<AnnouncementModel> announcements;
  final bool Function(AnnouncementModel) isMine, hasRequested, isAccepted, isPending;
  final void Function(AnnouncementModel) onTap, onRequest;
  final Future<void> Function() onRefresh;
  final double navH;

  const _CommunityTab({
    required this.announcements, required this.isMine, required this.hasRequested,
    required this.isAccepted, required this.isPending, required this.onTap,
    required this.onRequest, required this.onRefresh, required this.navH,
  });

  @override
  Widget build(BuildContext context) {
    if (announcements.isEmpty) {
      return RefreshIndicator(onRefresh: onRefresh, color: kPrimary,
        child: ListView(padding: EdgeInsets.fromLTRB(16, 16, 16, navH + 16), children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          const _EmptyState(
            icon: Icons.campaign_outlined,
            title: 'No matches nearby',
            subtitle: 'Book a court and post an announcement\nto find players for your session',
          ),
        ]));
    }

    return RefreshIndicator(
      onRefresh: onRefresh, color: kPrimary,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(16, 16, 16, navH + 16),
        itemCount: announcements.length,
        itemBuilder: (_, i) => _AnnouncementCard(
          ann:          announcements[i],
          isMine:       isMine(announcements[i]),
          hasRequested: hasRequested(announcements[i]),
          isAccepted:   isAccepted(announcements[i]),
          isPending:    isPending(announcements[i]),
          onTap:        () => onTap(announcements[i]),
          onRequest:    () => onRequest(announcements[i]),
        ),
      ),
    );
  }
}

// 
// MY MATCHES TAB
// 

class _MyMatchesTab extends StatelessWidget {
  final List<AnnouncementModel>  announcements;
  final List<JoinRequestData>    myResponses;
  final void Function(AnnouncementModel) onTap;
  final Future<void> Function() onRefresh;
  final double navH;

  const _MyMatchesTab({
    required this.announcements, required this.myResponses,
    required this.onTap, required this.onRefresh, required this.navH,
  });

  @override
  Widget build(BuildContext context) {
    if (announcements.isEmpty && myResponses.isEmpty) {
      return RefreshIndicator(onRefresh: onRefresh, color: kPrimary,
        child: ListView(padding: EdgeInsets.fromLTRB(16, 16, 16, navH + 16), children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          const _EmptyState(
            icon: Icons.sports_rounded,
            title: 'No matches yet',
            subtitle: 'Book a court and post an announcement\nor join one from the Community tab',
          ),
        ]));
    }

    return RefreshIndicator(
      onRefresh: onRefresh, color: kPrimary,
      child: ListView(padding: EdgeInsets.fromLTRB(16, 16, 16, navH + 16), children: [
        // My announcements
        if (announcements.isNotEmpty) ...[
          _SectionLabel('My Announcements', Icons.campaign_rounded, kPrimary),
          const SizedBox(height: 10),
          ...announcements.map((a) => _MyAnnouncementCard(ann: a, onTap: () => onTap(a))),
          const SizedBox(height: 20),
        ],

        // Accepted responses — joined matches
        if (myResponses.isNotEmpty) ...[
          _SectionLabel('Matches I\'ve Joined', Icons.check_circle_rounded, kGreen),
          const SizedBox(height: 10),
          ...myResponses.map((r) => _ResponseCard(response: r)),
        ],
      ]),
    );
  }
}

// 
// ANNOUNCEMENT CARD (Community)
// 

class _AnnouncementCard extends StatelessWidget {
  final AnnouncementModel ann;
  final bool isMine, hasRequested, isAccepted, isPending;
  final VoidCallback onTap, onRequest;

  const _AnnouncementCard({
    required this.ann, required this.isMine, required this.hasRequested,
    required this.isAccepted, required this.isPending,
    required this.onTap, required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    final sc      = ann.reservation.sport.color;
    final imgUrl  = _fixImageUrl(ann.reservation.courtImageUrl);
    final dateStr = _formatDate(ann.reservation.date);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 14, offset: const Offset(0, 4))],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(children: [
          // Hero image 
          SizedBox(height: 160, width: double.infinity,
            child: Stack(fit: StackFit.expand, children: [
              imgUrl.isNotEmpty
                  ? Image.network(imgUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _gradBg(sc),
                      loadingBuilder: (_, child, p) => p == null ? child : _gradBg(sc))
                  : _gradBg(sc),

              // Gradient overlay
              Container(decoration: BoxDecoration(gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.7)]))),

              // Sport badge top-left
              Positioned(top: 12, left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: sc.withOpacity(0.92), borderRadius: BorderRadius.circular(14)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(ann.reservation.sport.icon, size: 12, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(ann.reservation.sport.label,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                  ]))),

              // Spots badge top-right
              Positioned(top: 12, right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: ann.isFull ? kRed.withOpacity(0.9) : kGreen.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(14)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(ann.isFull ? Icons.lock_rounded : Icons.people_rounded, size: 11, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(ann.isFull ? 'Full' : '${ann.spotsLeft} left',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                  ]))),

              // Court name + date bottom
              Positioned(bottom: 12, left: 14, right: 14, child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(ann.reservation.courtName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.4),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.calendar_today_rounded, size: 11, color: Colors.white.withOpacity(0.8)),
                  const SizedBox(width: 4),
                  Text(dateStr, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8))),
                  const SizedBox(width: 12),
                  Icon(Icons.access_time_rounded, size: 11, color: Colors.white.withOpacity(0.8)),
                  const SizedBox(width: 4),
                  Text('${ann.reservation.startTime} – ${ann.reservation.endTime}',
                      style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8))),
                ]),
              ])),
            ])),

          // Body ─────────────────────────────────────────────────────────
          Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 16), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Host row
            Row(children: [
              AvatarWidget(initials: ann.host.avatarInitials, size: 36, bg: sc),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                RichText(text: TextSpan(style: const TextStyle(fontSize: 13, color: _kInk), children: [
                  TextSpan(text: ann.host.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const TextSpan(text: ' is looking for players', style: TextStyle(color: _kMid, fontSize: 12)),
                ])),
                const SizedBox(height: 2),
                Text(_announcementVenueMap[ann.id] ?? '',
                    style: const TextStyle(fontSize: 11, color: _kLight)),
              ])),
              // Players needed chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: sc.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.group_rounded, size: 13, color: sc),
                  const SizedBox(width: 4),
                  Text('${ann.playersNeeded} needed', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: sc)),
                ])),
            ]),
            const SizedBox(height: 10),

            // Description
            Text(ann.description,
                style: const TextStyle(fontSize: 13, color: _kMid, height: 1.5),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 14),

            // CTA
            _buildCta(sc),
          ])),
        ]),
      ),
    );
  }

  Widget _buildCta(Color sc) {
    if (ann.isFull && !hasRequested) {
      return _flatBanner(const Color(0xFFF2F4F7), null, Icons.lock_rounded, 'This match is full', _kMid);
    }
    if (isMine) {
      return _flatBanner(sc.withOpacity(0.06), sc.withOpacity(0.2), Icons.edit_note_rounded,
          '${ann.spotsLeft} spot${ann.spotsLeft == 1 ? '' : 's'} left — tap to manage', sc);
    }
    if (isAccepted) {
      return _flatBanner(kGreen.withOpacity(0.07), kGreen.withOpacity(0.2), Icons.check_circle_rounded,
          'You\'re in! 🎉', kGreen);
    }
    if (isPending) {
      return _flatBanner(kPrimary.withOpacity(0.06), kPrimary.withOpacity(0.2), Icons.hourglass_top_rounded,
          'Request sent — awaiting approval', kPrimary);
    }
    return GestureDetector(
      onTap: onRequest,
      child: Container(
        height: 46, width: double.infinity,
        decoration: BoxDecoration(
          color: sc,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: sc.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]),
        child: const Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.send_rounded, color: Colors.white, size: 15),
          SizedBox(width: 8),
          Text('Request to Join', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
        ]))));
  }

  Widget _flatBanner(Color bg, Color? border, IconData icon, String text, Color tc) => Container(
    height: 46, width: double.infinity,
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14),
        border: border != null ? Border.all(color: border) : null),
    child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: tc), const SizedBox(width: 7),
      Text(text, style: TextStyle(fontSize: 12, color: tc, fontWeight: FontWeight.w600)),
    ])));

  Widget _gradBg(Color c) => Container(decoration: BoxDecoration(gradient: LinearGradient(
      colors: [Color.lerp(c, Colors.black, 0.4)!, c], begin: Alignment.topLeft, end: Alignment.bottomRight)));

  String _formatDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const days   = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
  }
}

// 
// MY ANNOUNCEMENT CARD (My Matches tab) — shows pending count + accepted list
// 

class _MyAnnouncementCard extends StatelessWidget {
  final AnnouncementModel ann;
  final VoidCallback onTap;
  const _MyAnnouncementCard({required this.ann, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sc       = ann.reservation.sport.color;
    final accepted = ann.requests.where((r) => r.status == JoinRequestStatus.accepted).toList();
    final pending  = ann.requests.where((r) => r.status == JoinRequestStatus.pending).toList();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 3))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 42, height: 42,
              decoration: BoxDecoration(color: sc.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(ann.reservation.sport.icon, color: sc, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ann.reservation.courtName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kInk), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('${ann.reservation.startTime} – ${ann.reservation.endTime}',
                  style: const TextStyle(fontSize: 11, color: _kMid)),
            ])),
            // Status badge
            Builder(builder: (ctx) {
              final s = _announcementStatusMap[ann.id] ?? 'open';
              final isOpen = !ann.isFull && s == 'open';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: ann.isFull ? kRed.withOpacity(0.1) : isOpen ? kGreen.withOpacity(0.1) : _kBorder,
                  borderRadius: BorderRadius.circular(12)),
                child: Text(
                  ann.isFull ? 'Full' : isOpen ? '${ann.spotsLeft} left' : 'Closed',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      color: ann.isFull ? kRed : isOpen ? kGreen : _kMid)));
            }),
          ]),

          if (pending.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: kPrimary.withOpacity(0.05), borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kPrimary.withOpacity(0.15))),
              child: Row(children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text('${pending.length} pending request${pending.length == 1 ? '' : 's'} — tap to review',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kPrimary)),
              ])),
          ],

          // Accepted players
          if (accepted.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Accepted Players', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kMid)),
            const SizedBox(height: 8),
            ...accepted.map((r) => _PlayerRow(
              name:  r.player.name,
              phone: r.player.phone,
              color: sc)),
          ],
        ]),
      ),
    );
  }
}

// 
// RESPONSE CARD (My Matches tab — matches I joined)
// 

class _ResponseCard extends StatelessWidget {
  final JoinRequestData response;
  const _ResponseCard({required this.response});

  @override
  Widget build(BuildContext context) {
    final isAccepted = response.status == 'accepted';
    final color      = isAccepted ? kGreen : kRed;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2))),
      child: Row(children: [
        Container(width: 44, height: 44,
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(isAccepted ? Icons.check_circle_rounded : Icons.cancel_rounded, color: color, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isAccepted ? 'Request Accepted! 🎉' : 'Request Declined',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kInk)),
          const SizedBox(height: 3),
          Text(
            response.courtName?.isNotEmpty == true
                ? '${response.courtName}'
                : isAccepted ? 'You\'re in!' : 'Better luck next time',
            style: const TextStyle(fontSize: 12, color: _kMid)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Text(isAccepted ? 'Accepted' : 'Declined',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color))),
      ]),
    );
  }
}

// 
// DETAIL SHEET
// 

class _DetailSheet extends StatelessWidget {
  final AnnouncementModel ann;
  final bool isMine, hasRequested, isAccepted, isPending;
  final VoidCallback onRequest;

  const _DetailSheet({
    required this.ann, required this.isMine, required this.hasRequested,
    required this.isAccepted, required this.isPending, required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    final sc     = ann.reservation.sport.color;
    final bot    = MediaQuery.of(context).padding.bottom;
    final imgUrl = _fixImageUrl(ann.reservation.courtImageUrl);

    return DraggableScrollableSheet(
      initialChildSize: 0.9, minChildSize: 0.5, maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: _kCard, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(children: [
          // Hero
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: Stack(children: [
              SizedBox(height: 240, width: double.infinity,
                child: imgUrl.isNotEmpty
                    ? Image.network(imgUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _heroBg(sc),
                        loadingBuilder: (_, child, p) => p == null ? child : _heroBg(sc))
                    : _heroBg(sc)),
              // Gradient
              Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.75)])))),
              // Handle
              Positioned(top: 12, left: 0, right: 0,
                child: Center(child: Container(width: 38, height: 4,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.4), borderRadius: BorderRadius.circular(2))))),
              // Sport badge
              Positioned(top: 28, right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: sc.withOpacity(0.9), borderRadius: BorderRadius.circular(14)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(ann.reservation.sport.icon, size: 12, color: Colors.white), const SizedBox(width: 5),
                    Text(ann.reservation.sport.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                  ]))),
              // Spots
              Positioned(top: 28, left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: ann.isFull ? kRed.withOpacity(0.9) : kGreen.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(14)),
                  child: Text(ann.isFull ? 'Full' : '${ann.spotsLeft} spots left',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)))),
              // Court info
              Positioned(bottom: 14, left: 16, right: 16, child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(ann.reservation.courtName,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                const SizedBox(height: 5),
                Row(children: [
                  Icon(Icons.calendar_today_rounded, size: 12, color: Colors.white70), const SizedBox(width: 4),
                  Text(_fmtDate(ann.reservation.date), style: const TextStyle(fontSize: 12, color: Colors.white70)),
                  const SizedBox(width: 12),
                  Icon(Icons.access_time_rounded, size: 12, color: Colors.white70), const SizedBox(width: 4),
                  Text('${ann.reservation.startTime} – ${ann.reservation.endTime}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ]),
              ])),
            ])),

          // Body
          Expanded(child: ListView(controller: ctrl,
              padding: EdgeInsets.fromLTRB(20, 20, 20, bot + 20), children: [

            // Host row
            Row(children: [
              AvatarWidget(initials: ann.host.avatarInitials, size: 48, bg: sc),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(ann.host.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _kInk)),
                const SizedBox(height: 2),
                const Text('Match host', style: TextStyle(fontSize: 12, color: _kMid)),
              ])),
              // If accepted, show host phone
              if (isAccepted && ann.host.phone.isNotEmpty)
                GestureDetector(onTap: () => _callPhone(ann.host.phone),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(color: kGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kGreen.withOpacity(0.3))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.call_rounded, size: 14, color: kGreen),
                      const SizedBox(width: 5),
                      Text(ann.host.phone, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kGreen)),
                    ]))),
            ]),
            const SizedBox(height: 18),

            // Stats row
            Row(children: [
              Expanded(child: _StatTile(Icons.people_rounded, '${ann.playersNeeded}', 'Needed', sc)),
              const SizedBox(width: 10),
              Expanded(child: _StatTile(Icons.check_circle_rounded, '${ann.acceptedCount}', 'Joined', kGreen)),
              const SizedBox(width: 10),
              Expanded(child: _StatTile(Icons.hourglass_top_rounded, '${ann.spotsLeft}', 'Left', ann.isFull ? kRed : kPrimary)),
            ]),
            const SizedBox(height: 18),

            // Description
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(14)),
              child: Text(ann.description, style: const TextStyle(fontSize: 13, color: _kMid, height: 1.55))),
            const SizedBox(height: 18),

            // Details card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: sc.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: sc.withOpacity(0.15))),
              child: Column(children: [
                _DetailRow(Icons.sports_rounded, 'Sport', ann.reservation.sport.label, sc),
                _Divider(), _DetailRow(Icons.stadium_rounded, 'Court', ann.reservation.courtName, sc),
                _Divider(), _DetailRow(Icons.calendar_today_rounded, 'Date', _fmtDate(ann.reservation.date), sc),
                _Divider(), _DetailRow(Icons.access_time_rounded, 'Time',
                    '${ann.reservation.startTime} – ${ann.reservation.endTime}', sc),
              ])),
            const SizedBox(height: 24),

            // CTA
            _buildSheetCta(sc, context),
          ])),
        ]),
      ),
    );
  }

  Widget _buildSheetCta(Color sc, BuildContext ctx) {
    if (ann.isFull && !isAccepted) {
      return _flatBanner(const Color(0xFFF2F4F7), null, Icons.lock_rounded, 'This match is full', _kMid);
    }
    if (isMine) return _flatBanner(sc.withOpacity(0.07), sc.withOpacity(0.2), Icons.edit_note_rounded, 'Your announcement', sc);
    if (isAccepted) {
      return Column(children: [
        _flatBanner(kGreen.withOpacity(0.07), kGreen.withOpacity(0.2), Icons.check_circle_rounded, 'You\'re in! See you on the court 🎉', kGreen),
        if (ann.host.phone.isNotEmpty) ...[
          const SizedBox(height: 10),
          GestureDetector(onTap: () => _callPhone(ann.host.phone),
            child: Container(height: 46, decoration: BoxDecoration(
              color: kGreen, borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: kGreen.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]),
              child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.call_rounded, color: Colors.white, size: 16), const SizedBox(width: 8),
                Text('Call Host: ${ann.host.phone}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
              ])))),
        ],
      ]);
    }
    if (isPending) return _flatBanner(kPrimary.withOpacity(0.06), kPrimary.withOpacity(0.2), Icons.hourglass_top_rounded, 'Request sent — awaiting approval', kPrimary);
    return PrimaryButton('Request to Join', color: sc, icon: Icons.send_rounded, onTap: () { Navigator.pop(ctx); onRequest(); });
  }

  Widget _flatBanner(Color bg, Color? border, IconData icon, String text, Color tc) => Container(
    height: 50, width: double.infinity,
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14),
        border: border != null ? Border.all(color: border) : null),
    child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: tc), const SizedBox(width: 7),
      Flexible(child: Text(text, style: TextStyle(fontSize: 12, color: tc, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
    ])));

  Widget _heroBg(Color c) => Container(decoration: BoxDecoration(gradient: LinearGradient(
      colors: [Color.lerp(c, Colors.black, 0.4)!, c], begin: Alignment.topLeft, end: Alignment.bottomRight)));

  String _fmtDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const w = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${w[d.weekday - 1]}, ${d.day} ${m[d.month - 1]}';
  }
}

// 
// JOIN REQUEST SHEET
// 

class _JoinSheet extends StatefulWidget {
  final AnnouncementModel ann;
  final ValueChanged<String> onSend;
  const _JoinSheet({required this.ann, required this.onSend});
  @override State<_JoinSheet> createState() => _JoinSheetState();
}

class _JoinSheetState extends State<_JoinSheet> {
  final _ctrl   = TextEditingController();
  bool _sending = false;

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final sc  = widget.ann.reservation.sport.color;
    final bot = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bot + 16),
      decoration: const BoxDecoration(color: _kCard, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Center(child: Container(width: 38, height: 4,
          decoration: BoxDecoration(color: _kLight.withOpacity(0.4), borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),

        // Match summary
        Container(padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Container(width: 48, height: 48,
              decoration: BoxDecoration(color: sc.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(widget.ann.reservation.sport.icon, color: sc, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.ann.reservation.courtName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kInk)),
              const SizedBox(height: 2),
              Text('${widget.ann.reservation.startTime} – ${widget.ann.reservation.endTime}',
                  style: const TextStyle(fontSize: 11, color: _kMid)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('Host: ${widget.ann.host.name.split(' ').first}',
                  style: const TextStyle(fontSize: 11, color: _kMid)),
              Text('${widget.ann.spotsLeft} left', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: sc)),
            ]),
          ])),
        const SizedBox(height: 20),

        const Align(alignment: Alignment.centerLeft,
          child: Text('Add a message (optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kInk))),
        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(13)),
          child: TextField(controller: _ctrl, maxLines: 3,
            style: const TextStyle(fontSize: 13, color: _kInk),
            decoration: const InputDecoration(
              hintText: 'e.g. Intermediate level, ready to go!',
              hintStyle: TextStyle(color: _kLight, fontSize: 12),
              border: InputBorder.none, isDense: true,
              contentPadding: EdgeInsets.all(14)))),
        const SizedBox(height: 16),

        // Note: your phone will be shared
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: kPrimary.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Icon(Icons.info_outline_rounded, size: 14, color: kPrimary.withOpacity(0.7)),
            const SizedBox(width: 8),
            const Expanded(child: Text(
              'Your phone number will be visible to the host if your request is accepted.',
              style: TextStyle(fontSize: 11, color: _kMid, height: 1.4))),
          ])),
        const SizedBox(height: 16),

        PrimaryButton('Send Join Request', color: sc, icon: Icons.send_rounded,
          onTap: _sending ? null : () async {
            setState(() => _sending = true);
            widget.onSend(_ctrl.text.trim());
          }, loading: _sending),
      ]),
    );
  }
}

// 
// NOTIFICATION SHEET
// 

class _NotificationSheet extends StatefulWidget {
  final List<AnnouncementModel> myAnnouncements;
  final List<JoinRequestData>   myResponses;
  final AnnouncementService?    svc;
  final VoidCallback            onUpdate;
  const _NotificationSheet({
    required this.myAnnouncements, required this.myResponses,
    required this.svc, required this.onUpdate,
  });
  @override State<_NotificationSheet> createState() => _NotificationSheetState();
}

class _NotificationSheetState extends State<_NotificationSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);
  @override void dispose() { _tab.dispose(); super.dispose(); }

  int get _pendingCount => widget.myAnnouncements.fold(0, (s, a) => s + a.pendingCount);

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: 0.85, minChildSize: 0.5, maxChildSize: 0.95, expand: false,
    builder: (_, ctrl) => Container(
      decoration: const BoxDecoration(color: _kCard, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(children: [
        const SizedBox(height: 12),
        Center(child: Container(width: 38, height: 4,
          decoration: BoxDecoration(color: _kLight.withOpacity(0.4), borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),

        Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Container(width: 36, height: 36,
              decoration: BoxDecoration(
                color: (_pendingCount + widget.myResponses.length) > 0 ? kPrimary.withOpacity(0.08) : _kBg,
                borderRadius: BorderRadius.circular(11)),
              child: Icon(Icons.notifications_rounded,
                color: (_pendingCount + widget.myResponses.length) > 0 ? kPrimary : _kMid, size: 18)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _kInk, letterSpacing: -0.4)),
              Text('$_pendingCount pending · ${widget.myResponses.length} responses',
                  style: const TextStyle(fontSize: 12, color: _kMid)),
            ])),
          ])),
        const SizedBox(height: 8),

        TabBar(controller: _tab, labelColor: kPrimary, unselectedLabelColor: _kMid,
          indicatorColor: kPrimary,
          tabs: [
            Tab(text: 'Received ($_pendingCount)'),
            Tab(text: 'Responses (${widget.myResponses.length})'),
          ]),

        Expanded(child: TabBarView(controller: _tab, children: [
          _ReceivedTab(announcements: widget.myAnnouncements, svc: widget.svc, onUpdate: widget.onUpdate),
          _ResponsesTab(responses: widget.myResponses),
        ])),
      ]),
    ),
  );
}

// Received tab — pending requests on my announcements
class _ReceivedTab extends StatelessWidget {
  final List<AnnouncementModel> announcements;
  final AnnouncementService?    svc;
  final VoidCallback            onUpdate;
  const _ReceivedTab({required this.announcements, required this.svc, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final pending = <({AnnouncementModel ann, JoinRequest req})>[];
    for (final a in announcements) {
      for (final r in a.requests) {
        if (r.status == JoinRequestStatus.pending) pending.add((ann: a, req: r));
      }
    }
    if (pending.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.inbox_rounded, size: 48, color: _kLight),
      const SizedBox(height: 12),
      const Text('No pending requests', style: TextStyle(color: _kMid)),
    ]));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pending.length,
      itemBuilder: (_, i) => _RequestTile(
        ann: pending[i].ann, req: pending[i].req, svc: svc, onUpdate: onUpdate),
    );
  }
}

// Responses tab — how hosts responded to my join requests
class _ResponsesTab extends StatelessWidget {
  final List<JoinRequestData> responses;
  const _ResponsesTab({required this.responses});

  @override
  Widget build(BuildContext context) {
    if (responses.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.check_circle_outline_rounded, size: 48, color: _kLight),
      const SizedBox(height: 12),
      const Text('No responses yet', style: TextStyle(color: _kMid)),
      const SizedBox(height: 4),
      Text('Host decisions appear here', style: TextStyle(fontSize: 12, color: _kLight)),
    ]));

    return ListView.builder(
      padding: const EdgeInsets.all(16), itemCount: responses.length,
      itemBuilder: (_, i) => _ResponseCard(response: responses[i]),
    );
  }
}

// Single request tile with Accept / Decline + player phone
class _RequestTile extends StatefulWidget {
  final AnnouncementModel ann;
  final JoinRequest       req;
  final AnnouncementService? svc;
  final VoidCallback      onUpdate;
  const _RequestTile({required this.ann, required this.req, required this.svc, required this.onUpdate});
  @override State<_RequestTile> createState() => _RequestTileState();
}

class _RequestTileState extends State<_RequestTile> {
  bool _processing = false;

  Future<void> _respond(String status) async {
    if (_processing || widget.svc == null) return;
    setState(() => _processing = true);
    try {
      await widget.svc!.respondToRequest(widget.ann.id, widget.req.id, status);
      setState(() {
        widget.req.status  = status == 'accepted' ? JoinRequestStatus.accepted : JoinRequestStatus.declined;
        _processing        = false;
      });
      widget.onUpdate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(status == 'accepted' ? 'Request accepted!' : 'Request declined'),
          backgroundColor: status == 'accepted' ? kGreen : kRed,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2)));
      }
    } catch (e) {
      setState(() => _processing = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed: ${e.toString().replaceAll('Exception:', '')}'),
        backgroundColor: kRed, behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sc        = widget.ann.reservation.sport.color;
    final isPending = widget.req.status == JoinRequestStatus.pending;
    final phone     = widget.req.player.phone;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isPending ? _kCard : _kBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isPending ? kPrimary.withOpacity(0.12) : Colors.transparent),
        boxShadow: isPending ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))] : []),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AvatarWidget(initials: widget.req.player.avatarInitials, size: 42, bg: sc),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.req.player.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kInk)),
            const SizedBox(height: 2),
            Text('${widget.ann.reservation.courtName}  ·  ${widget.ann.reservation.startTime} – ${widget.ann.reservation.endTime}',
                style: const TextStyle(fontSize: 11, color: _kMid)),
            // Phone number
            if (phone.isNotEmpty) ...[
              const SizedBox(height: 4),
              GestureDetector(onTap: () => _callPhone(phone),
                child: Row(children: [
                  Icon(Icons.call_rounded, size: 12, color: kGreen.withOpacity(0.8)),
                  const SizedBox(width: 4),
                  Text(phone, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kGreen)),
                ])),
            ],
          ])),
          if (!isPending)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: (widget.req.status == JoinRequestStatus.accepted ? kGreen : kRed).withOpacity(0.08),
                borderRadius: BorderRadius.circular(20)),
              child: Text(
                widget.req.status == JoinRequestStatus.accepted ? 'Accepted' : 'Declined',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: widget.req.status == JoinRequestStatus.accepted ? kGreen : kRed)))
          else
            Container(width: 8, height: 8,
              decoration: const BoxDecoration(color: kGreen, shape: BoxShape.circle)),
        ]),

        if (widget.req.message.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(10)),
            child: Text('"${widget.req.message}"',
                style: const TextStyle(fontSize: 12, color: _kMid, fontStyle: FontStyle.italic, height: 1.4))),
        ],

        if (isPending && !_processing) ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: GestureDetector(onTap: () => _respond('declined'),
              child: Container(height: 42,
                decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(11)),
                child: const Center(child: Text('Decline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kMid)))))),
            const SizedBox(width: 10),
            Expanded(child: GestureDetector(onTap: () => _respond('accepted'),
              child: Container(height: 42,
                decoration: BoxDecoration(
                  color: kGreen, borderRadius: BorderRadius.circular(11),
                  boxShadow: [BoxShadow(color: kGreen.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))]),
                child: const Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_rounded, color: Colors.white, size: 15), SizedBox(width: 5),
                  Text('Accept', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                ]))))),
          ]),
        ],

        if (_processing) const Padding(padding: EdgeInsets.only(top: 12),
          child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))),
      ]),
    );
  }
}

// 
// SMALL WIDGETS
// 

class _SportFilter extends StatelessWidget {
  final SportType? selected;
  final ValueChanged<SportType?> onSelect;
  const _SportFilter({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) => SizedBox(height: 34,
    child: ListView(scrollDirection: Axis.horizontal, children: [
      _pill(null, 'All', Icons.sports_rounded, kPrimary),
      ...SportType.values.map((s) => _pill(s, s.label, s.icon, s.color)),
    ]));

  Widget _pill(SportType? sport, String label, IconData icon, Color color) {
    final sel = selected == sport;
    return GestureDetector(
      onTap: () => onSelect(sport),
      child: AnimatedContainer(duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? color : _kBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: sel ? [BoxShadow(color: color.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 2))] : []),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: sel ? Colors.white : _kMid),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : _kMid)),
        ])));
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon; final String value, label; final Color color;
  const _StatTile(this.icon, this.value, this.label, this.color);
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(12)),
    child: Column(children: [
      Icon(icon, size: 18, color: color), const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 10, color: _kMid)),
    ]));
}

class _DetailRow extends StatelessWidget {
  final IconData icon; final String label, value; final Color color;
  const _DetailRow(this.icon, this.label, this.value, this.color);
  @override Widget build(BuildContext context) => Row(children: [
    Container(width: 32, height: 32, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
      child: Icon(icon, size: 14, color: color)),
    const SizedBox(width: 12),
    Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: _kMid))),
    Flexible(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kInk), textAlign: TextAlign.right)),
  ]);
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: Color(0xFFF0F0F0)));
}

class _PlayerRow extends StatelessWidget {
  final String name, phone; final Color color;
  const _PlayerRow({required this.name, required this.phone, required this.color});
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      AvatarWidget(initials: name.isNotEmpty ? name[0].toUpperCase() : 'P', size: 32, bg: color),
      const SizedBox(width: 10),
      Expanded(child: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kInk))),
      if (phone.isNotEmpty)
        GestureDetector(onTap: () => _callPhone(phone),
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: kGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kGreen.withOpacity(0.3))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.call_rounded, size: 12, color: kGreen), const SizedBox(width: 4),
              Text(phone, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kGreen)),
            ]))),
    ]));
}

class _SectionLabel extends StatelessWidget {
  final String text; final IconData icon; final Color color;
  const _SectionLabel(this.text, this.icon, this.color);
  @override Widget build(BuildContext context) => Row(children: [
    Container(width: 28, height: 28, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, size: 13, color: color)),
    const SizedBox(width: 8),
    Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
  ]);
}

class _EmptyState extends StatelessWidget {
  final IconData icon; final String title, subtitle;
  const _EmptyState({required this.icon, required this.title, required this.subtitle});
  @override Widget build(BuildContext context) => Column(children: [
    Container(width: 72, height: 72,
      decoration: BoxDecoration(color: kPrimary.withOpacity(0.07), shape: BoxShape.circle),
      child: Icon(icon, size: 30, color: kPrimary.withOpacity(0.45))),
    const SizedBox(height: 14),
    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kInk)),
    const SizedBox(height: 5),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Text(subtitle, style: const TextStyle(fontSize: 13, color: _kMid), textAlign: TextAlign.center)),
  ]);
}

