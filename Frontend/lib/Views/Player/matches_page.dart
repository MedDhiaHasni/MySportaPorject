// lib/Views/Player/matches_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sporta/Core/Theme/app_tokens.dart';
import 'package:sporta/Models/app_enums.dart';
import 'package:sporta/Models/app_models.dart';
import 'package:sporta/Services/announcement_service.dart';
import 'package:sporta/Services/booking_store.dart';
import 'package:sporta/Services/player_manager_auth_service.dart';
import 'package:sporta/Widgets/Buttons/app_buttons.dart';
import 'package:sporta/Widgets/Cards/app_card.dart';
import 'package:sporta/Widgets/Inputs/app_text_field.dart';
import 'package:sporta/Widgets/booking_components.dart';
import 'package:sporta/Widgets/feedback_components.dart';
import 'package:sporta/Core/Utils/app_logger.dart';

SportType _parseSport(String sport) {
  switch (sport.toLowerCase()) {
    case 'football':
      return SportType.football;
    case 'tennis':
      return SportType.tennis;
    case 'padel':
      return SportType.padel;
    case 'basketball':
      return SportType.basketball;
    default:
      return SportType.football;
  }
}

AnnouncementModel _toModel(AnnouncementData d) {
  final reservation = CourtReservation(
    id: d.reservationId,
    courtId: '',
    courtName: d.courtName,
    hostId: d.hostPlayerId,
    sport: _parseSport(d.sport),
    date: DateTime.tryParse(d.date) ?? DateTime.now(),
    startTime: d.startTime,
    endTime: d.endTime,
    durationHours: 1,
    totalPrice: 0,
    paymentOption: PaymentOption.payAtVenue,
    courtImageUrl: d.courtImageUrl.isNotEmpty ? d.courtImageUrl : null,
  );
  final requests = d.joinRequests
      .map(
        (jr) => JoinRequest(
          id: jr.id,
          player: AppPlayer(
            id: jr.playerId,
            name: jr.playerName,
            avatarInitials: jr.playerInitials,
            phone: jr.playerPhone,
          ),
          message: jr.message,
          status: _parseStatus(jr.status),
        ),
      )
      .toList();
  final model = AnnouncementModel(
    id: d.id,
    reservation: reservation,
    host: AppPlayer(
      id: d.hostPlayerId,
      name: d.hostName,
      avatarInitials: d.hostInitials,
      phone: d.hostPhone,
    ),
    playersNeeded: d.playersNeeded,
    description: d.description,
    createdAt: DateTime.now(),
    requests: requests,
  );
  _announcementStatusMap[d.id] = d.status;
  _announcementVenueMap[d.id] = d.venueName;
  return model;
}

final Map<String, String> _announcementStatusMap = {};
final Map<String, String> _announcementVenueMap = {};

JoinRequestStatus _parseStatus(String s) {
  switch (s.toLowerCase()) {
    case 'accepted':
      return JoinRequestStatus.accepted;
    case 'declined':
      return JoinRequestStatus.declined;
    default:
      return JoinRequestStatus.pending;
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
      await Process.run('am', [
        'start',
        '-a',
        'android.intent.action.DIAL',
        '-d',
        'tel:$encoded',
      ]);
    } else if (Platform.isIOS) {
      await Process.run('open', ['tel://$encoded']);
    }
  } catch (_) {}
}

String _formatMatchDate(DateTime d) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
}

class Matches extends StatefulWidget {
  final String? playerToken;
  const Matches({super.key, this.playerToken});
  @override
  State<Matches> createState() => _MatchesState();
}

class _MatchesState extends State<Matches>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final TabController _tab;

  SportType? _sportFilter;

  List<AnnouncementModel> _community = [];
  List<AnnouncementModel> _mine = [];
  List<JoinRequestData> _myResponses = [];

  bool _loading = true;
  bool _initialized = false;
  String? _communityError;
  String? _mineError;
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

  Future<void> _init() async {
    if (_initialized) return;
    String? token = widget.playerToken;
    if (token == null || token.isEmpty) {
      token = await const FlutterSecureStorage().read(key: 'jwt_token');
    }
    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() {
          _loading = false;
          _communityError = 'Sign in to browse community matches.';
          _mineError = 'Sign in to see your matches.';
        });
      }
      return;
    }
    await BookingStore.instance.initialize(token);
    _svc = AnnouncementService(token: token);
    try {
      final me = await PlayerManagerAuthService.getMe(token);
      _currentUsername =
          me['user']?['username']?.toString() ?? me['username']?.toString();
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
    try {
      _community = (await _svc!.fetchFeed()).map(_toModel).toList();
      _communityError = null;
    } catch (e) {
      AppLogger.error('_loadCommunity: $e');
      _communityError = 'Could not load community matches.';
    }
  }

  Future<void> _loadMine() async {
    if (_svc == null) return;
    try {
      _mine = (await _svc!.fetchMine()).map(_toModel).toList();
      _mineError = null;
    } catch (e) {
      AppLogger.error('_loadMine: $e');
      _mineError = 'Could not load your matches.';
    }
  }

  Future<void> _loadMyResponses() async {
    if (_svc == null) return;
    try {
      _myResponses = (await _svc!.fetchMyRequests())
          .where((r) => r.status != 'pending')
          .toList();
    } catch (e) {
      AppLogger.error('_loadMyResponses: $e');
    }
  }

  bool _isMine(AnnouncementModel a) =>
      _currentUsername != null && a.host.name == _currentUsername;

  bool _hasRequested(AnnouncementModel a) =>
      _currentUsername != null &&
      a.requests.any((r) => r.player.name == _currentUsername);

  bool _isAccepted(AnnouncementModel a) =>
      _currentUsername != null &&
      a.requests.any(
        (r) =>
            r.player.name == _currentUsername &&
            r.status == JoinRequestStatus.accepted,
      );

  bool _isPending(AnnouncementModel a) =>
      _currentUsername != null &&
      a.requests.any(
        (r) =>
            r.player.name == _currentUsername &&
            r.status == JoinRequestStatus.pending,
      );

  List<AnnouncementModel> get _filteredCommunity => _community.where((a) {
    if (_sportFilter != null && a.reservation.sport != _sportFilter) {
      return false;
    }
    return true;
  }).toList();

  List<AnnouncementModel> get _filteredMine => _mine.where((a) {
    if (_sportFilter != null && a.reservation.sport != _sportFilter) {
      return false;
    }
    return true;
  }).toList();

  int get _pendingCount => _mine.fold(0, (s, a) => s + a.pendingCount);
  int get _totalBell => _pendingCount + _myResponses.length;

  void _openBell() => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _NotificationSheet(
      myAnnouncements: _mine,
      myResponses: _myResponses,
      svc: _svc,
      onUpdate: _loadAll,
    ),
  );

  void _openDetail(AnnouncementModel ann) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DetailSheet(
      ann: ann,
      isMine: _isMine(ann),
      hasRequested: _hasRequested(ann),
      isAccepted: _isAccepted(ann),
      isPending: _isPending(ann),
      onRequest: () => _requestJoin(ann),
    ),
  );

  void _requestJoin(AnnouncementModel ann) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _JoinSheet(
      ann: ann,
      onSend: (msg) async {
        Navigator.pop(context);
        if (_svc == null) return;
        try {
          final jr = await _svc!.requestJoin(ann.id, message: msg);
          setState(() {
            ann.requests.add(
              JoinRequest(
                id: jr.id,
                player: AppPlayer(
                  id: _currentUsername ?? '',
                  name: _currentUsername ?? 'You',
                  avatarInitials: _currentUsername?.isNotEmpty == true
                      ? _currentUsername![0].toUpperCase()
                      : 'Y',
                  phone: '',
                ),
                message: jr.message,
                status: JoinRequestStatus.pending,
              ),
            );
          });
          _snack('Request sent! Waiting for approval.');
        } catch (e) {
          _snack(
            'Failed: ${e.toString().replaceAll('Exception:', '')}',
            error: true,
          );
        }
      },
    ),
  );

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? scheme.error : scheme.inverseSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
        ),
        margin: const EdgeInsetsDirectional.all(AppSpacing.md),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navH =
        AppLayout.bottomNavigationHeight + MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: _MatchesTabBar(controller: _tab),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _CommunityTab(
                  loading: _loading,
                  error: _communityError,
                  announcements: _filteredCommunity,
                  isMine: _isMine,
                  hasRequested: _hasRequested,
                  isAccepted: _isAccepted,
                  isPending: _isPending,
                  onTap: _openDetail,
                  onRequest: _requestJoin,
                  onRefresh: _refreshAll,
                  navH: navH,
                ),
                _MyMatchesTab(
                  loading: _loading,
                  error: _mineError,
                  announcements: _filteredMine,
                  onTap: _openDetail,
                  onRefresh: _refreshAll,
                  myResponses: _myResponses,
                  navH: navH,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Community', style: theme.textTheme.headlineSmall),
                      Text(
                        _loading
                            ? 'Loading…'
                            : '${_filteredCommunity.length} open near you',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh matches',
                  onPressed: _refreshAll,
                  icon: const Icon(Icons.refresh_rounded),
                ),
                Semantics(
                  button: true,
                  label: _totalBell > 0
                      ? 'Notifications, $_totalBell unread'
                      : 'Notifications',
                  child: IconButton(
                    tooltip: 'Notifications',
                    onPressed: _openBell,
                    icon: Badge(
                      isLabelVisible: _totalBell > 0,
                      backgroundColor: NightMatchColors.actionLime,
                      textColor: NightMatchColors.onAction,
                      label: Text('$_totalBell'),
                      child: Icon(
                        _totalBell > 0
                            ? Icons.notifications_rounded
                            : Icons.notifications_outlined,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _SportFilter(
              selected: _sportFilter,
              onSelect: (s) => setState(() => _sportFilter = s),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchesTabBar extends StatelessWidget {
  const _MatchesTabBar({required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          children: [
            Expanded(
              child: SportChip(
                label: 'Community',
                icon: Icons.campaign_outlined,
                selected: controller.index == 0,
                onTap: () => controller.animateTo(0),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: SportChip(
                label: 'My Matches',
                icon: Icons.sports_rounded,
                selected: controller.index == 1,
                onTap: () => controller.animateTo(1),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CommunityTab extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<AnnouncementModel> announcements;
  final bool Function(AnnouncementModel) isMine,
      hasRequested,
      isAccepted,
      isPending;
  final void Function(AnnouncementModel) onTap, onRequest;
  final Future<void> Function() onRefresh;
  final double navH;

  const _CommunityTab({
    required this.loading,
    required this.error,
    required this.announcements,
    required this.isMine,
    required this.hasRequested,
    required this.isAccepted,
    required this.isPending,
    required this.onTap,
    required this.onRequest,
    required this.onRefresh,
    required this.navH,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (loading) {
      return ListView(
        padding: EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          navH + AppSpacing.md,
        ),
        children: const [
          LoadingSkeleton(height: 220, borderRadius: AppRadius.card),
          SizedBox(height: AppSpacing.md),
          LoadingSkeleton(height: 220, borderRadius: AppRadius.card),
        ],
      );
    }
    if (error != null && announcements.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.18),
          ErrorState(
            title: 'Could not load matches',
            message: error!,
            onRetry: () {
              onRefresh();
            },
          ),
        ],
      );
    }
    if (announcements.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          navH + AppSpacing.md,
        ),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.12),
          const EmptyState(
            icon: Icons.campaign_outlined,
            title: 'No matches nearby',
            message:
                'Book a court and post an announcement to find players for your session.',
          ),
        ],
      );
    }

    return ListView.builder(
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        navH + AppSpacing.md,
      ),
      itemCount: announcements.length,
      itemBuilder: (_, i) => _AnnouncementCard(
        ann: announcements[i],
        isMine: isMine(announcements[i]),
        hasRequested: hasRequested(announcements[i]),
        isAccepted: isAccepted(announcements[i]),
        isPending: isPending(announcements[i]),
        onTap: () => onTap(announcements[i]),
        onRequest: () => onRequest(announcements[i]),
      ),
    );
  }
}

class _MyMatchesTab extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<AnnouncementModel> announcements;
  final List<JoinRequestData> myResponses;
  final void Function(AnnouncementModel) onTap;
  final Future<void> Function() onRefresh;
  final double navH;

  const _MyMatchesTab({
    required this.loading,
    required this.error,
    required this.announcements,
    required this.myResponses,
    required this.onTap,
    required this.onRefresh,
    required this.navH,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (loading) {
      return ListView(
        padding: EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          navH + AppSpacing.md,
        ),
        children: const [
          LoadingSkeleton(height: 120, borderRadius: AppRadius.card),
          SizedBox(height: AppSpacing.md),
          LoadingSkeleton(height: 120, borderRadius: AppRadius.card),
        ],
      );
    }
    if (error != null && announcements.isEmpty && myResponses.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.18),
          ErrorState(
            title: 'Could not load your matches',
            message: error!,
            onRetry: () {
              onRefresh();
            },
          ),
        ],
      );
    }
    if (announcements.isEmpty && myResponses.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.12),
          const EmptyState(
            icon: Icons.sports_rounded,
            title: 'No matches yet',
            message:
                'Book a court and post an announcement or join one from the Community tab.',
          ),
        ],
      );
    }

    return ListView(
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        navH + AppSpacing.md,
      ),
      children: [
        if (announcements.isNotEmpty) ...[
          const SectionHeader(title: 'My announcements'),
          const SizedBox(height: AppSpacing.sm),
          ...announcements.map(
            (a) => _MyAnnouncementCard(ann: a, onTap: () => onTap(a)),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (myResponses.isNotEmpty) ...[
          const SectionHeader(title: "Matches I've joined"),
          const SizedBox(height: AppSpacing.sm),
          ...myResponses.map((r) => _ResponseCard(response: r)),
        ],
      ],
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final AnnouncementModel ann;
  final bool isMine, hasRequested, isAccepted, isPending;
  final VoidCallback onTap, onRequest;

  const _AnnouncementCard({
    required this.ann,
    required this.isMine,
    required this.hasRequested,
    required this.isAccepted,
    required this.isPending,
    required this.onTap,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final imgUrl = _fixImageUrl(ann.reservation.courtImageUrl);
    final dateStr = _formatMatchDate(ann.reservation.date);

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
      child: Semantics(
        button: true,
        label:
            '${ann.reservation.courtName}, ${ann.reservation.sport.label}, $dateStr',
        child: AppCard(
          padding: EdgeInsets.zero,
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadiusDirectional.vertical(
                  top: Radius.circular(AppRadius.card),
                ),
                child: SizedBox(
                  height: 168,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      imgUrl.isNotEmpty
                          ? Image.network(
                              imgUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => ColoredBox(
                                color: scheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.stadium_outlined,
                                  color: scheme.secondary,
                                ),
                              ),
                              loadingBuilder: (_, child, p) => p == null
                                  ? child
                                  : const LoadingSkeleton(height: 168),
                            )
                          : ColoredBox(
                              color: scheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.stadium_outlined,
                                color: scheme.secondary,
                              ),
                            ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: AlignmentDirectional.topCenter,
                            end: AlignmentDirectional.bottomCenter,
                            colors: [
                              NightMatchColors.heroScrimTop,
                              NightMatchColors.heroScrimBottom,
                            ],
                          ),
                        ),
                      ),
                      PositionedDirectional(
                        top: AppSpacing.sm,
                        start: AppSpacing.sm,
                        child: SportChip(
                          label: ann.reservation.sport.label,
                          icon: ann.reservation.sport.icon,
                        ),
                      ),
                      PositionedDirectional(
                        top: AppSpacing.sm,
                        end: AppSpacing.sm,
                        child: ReservationStatusBadge(
                          status: ann.isFull
                              ? ReservationStatus.cancelled
                              : ReservationStatus.confirmed,
                          label: ann.isFull ? 'Full' : '${ann.spotsLeft} left',
                        ),
                      ),
                      PositionedDirectional(
                        start: AppSpacing.md,
                        end: AppSpacing.md,
                        bottom: AppSpacing.md,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ann.reservation.courtName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: NightMatchColors.text,
                              ),
                            ),
                            Text(
                              '$dateStr · ${ann.reservation.startTime} – ${ann.reservation.endTime}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: NightMatchColors.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _NmAvatar(initials: ann.host.avatarInitials),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ann.host.name,
                                style: theme.textTheme.titleSmall,
                              ),
                              Text(
                                _announcementVenueMap[ann.id] ??
                                    'Looking for players',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        SportChip(label: '${ann.playersNeeded} needed'),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      ann.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildCta(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCta(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (ann.isFull && !hasRequested) {
      return _StatusBanner(
        icon: Icons.lock_rounded,
        text: 'This match is full',
        color: scheme.onSurfaceVariant,
        background: scheme.surfaceContainerHighest,
      );
    }
    if (isMine) {
      return _StatusBanner(
        icon: Icons.edit_note_rounded,
        text:
            '${ann.spotsLeft} spot${ann.spotsLeft == 1 ? '' : 's'} left — tap to manage',
        color: scheme.onSecondaryContainer,
        background: scheme.secondaryContainer,
      );
    }
    if (isAccepted) {
      return const ReservationStatusBadge(
        status: ReservationStatus.confirmed,
        label: "You're in",
      );
    }
    if (isPending) {
      return const ReservationStatusBadge(
        status: ReservationStatus.pending,
        label: 'Request sent — awaiting approval',
      );
    }
    return AppPrimaryButton(
      label: 'Request to join',
      icon: Icons.send_rounded,
      onPressed: onRequest,
    );
  }
}

class _MyAnnouncementCard extends StatelessWidget {
  final AnnouncementModel ann;
  final VoidCallback onTap;
  const _MyAnnouncementCard({required this.ann, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accepted = ann.requests
        .where((r) => r.status == JoinRequestStatus.accepted)
        .toList();
    final pending = ann.requests
        .where((r) => r.status == JoinRequestStatus.pending)
        .toList();
    final s = _announcementStatusMap[ann.id] ?? 'open';
    final isOpen = !ann.isFull && s == 'open';

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.input),
                  ),
                  child: Icon(
                    ann.reservation.sport.icon,
                    color: scheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ann.reservation.courtName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        '${ann.reservation.startTime} – ${ann.reservation.endTime}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                ReservationStatusBadge(
                  status: ann.isFull
                      ? ReservationStatus.cancelled
                      : isOpen
                      ? ReservationStatus.confirmed
                      : ReservationStatus.pending,
                  label: ann.isFull
                      ? 'Full'
                      : isOpen
                      ? '${ann.spotsLeft} left'
                      : 'Closed',
                ),
              ],
            ),
            if (pending.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              _StatusBanner(
                icon: Icons.notifications_active_outlined,
                text:
                    '${pending.length} pending request${pending.length == 1 ? '' : 's'} — tap to review',
                color: scheme.onSecondaryContainer,
                background: scheme.secondaryContainer,
              ),
            ],
            if (accepted.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text('Accepted players', style: theme.textTheme.labelMedium),
              const SizedBox(height: AppSpacing.xs),
              ...accepted.map(
                (r) => _PlayerRow(name: r.player.name, phone: r.player.phone),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResponseCard extends StatelessWidget {
  final JoinRequestData response;
  const _ResponseCard({required this.response});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAccepted = response.status == 'accepted';
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isAccepted
                    ? Theme.of(context).colorScheme.secondaryContainer
                    : Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(AppRadius.input),
              ),
              child: Icon(
                isAccepted ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: isAccepted
                    ? Theme.of(context).colorScheme.onSecondaryContainer
                    : Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAccepted ? 'Request accepted' : 'Request declined',
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(
                    response.courtName?.isNotEmpty == true
                        ? '${response.courtName}'
                        : isAccepted
                        ? "You're in"
                        : 'Better luck next time',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            ReservationStatusBadge(
              status: isAccepted
                  ? ReservationStatus.confirmed
                  : ReservationStatus.cancelled,
              label: isAccepted ? 'Accepted' : 'Declined',
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailSheet extends StatelessWidget {
  final AnnouncementModel ann;
  final bool isMine, hasRequested, isAccepted, isPending;
  final VoidCallback onRequest;

  const _DetailSheet({
    required this.ann,
    required this.isMine,
    required this.hasRequested,
    required this.isAccepted,
    required this.isPending,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bot = MediaQuery.of(context).padding.bottom;
    final imgUrl = _fixImageUrl(ann.reservation.courtImageUrl);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, ctrl) => ClipRRect(
        borderRadius: const BorderRadiusDirectional.vertical(
          top: Radius.circular(AppRadius.card),
        ),
        child: Material(
          color: scheme.surface,
          child: Column(
            children: [
              ClipRRect(
                borderRadius: const BorderRadiusDirectional.vertical(
                  top: Radius.circular(AppRadius.card),
                ),
                child: Stack(
                  children: [
                    SizedBox(
                      height: 220,
                      width: double.infinity,
                      child: imgUrl.isNotEmpty
                          ? Image.network(
                              imgUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => ColoredBox(
                                color: scheme.surfaceContainerHighest,
                              ),
                            )
                          : ColoredBox(color: scheme.surfaceContainerHighest),
                    ),
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: AlignmentDirectional.topCenter,
                            end: AlignmentDirectional.bottomCenter,
                            colors: [
                              NightMatchColors.heroScrimTop,
                              NightMatchColors.heroScrimBottom,
                            ],
                          ),
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      top: AppSpacing.sm,
                      start: 0,
                      end: 0,
                      child: Center(
                        child: Container(
                          width: 36,
                          height: AppSpacing.xxs,
                          decoration: BoxDecoration(
                            color: NightMatchColors.text.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      top: AppSpacing.lg,
                      end: AppSpacing.md,
                      child: SportChip(
                        label: ann.reservation.sport.label,
                        icon: ann.reservation.sport.icon,
                      ),
                    ),
                    PositionedDirectional(
                      top: AppSpacing.lg,
                      start: AppSpacing.md,
                      child: ReservationStatusBadge(
                        status: ann.isFull
                            ? ReservationStatus.cancelled
                            : ReservationStatus.confirmed,
                        label: ann.isFull
                            ? 'Full'
                            : '${ann.spotsLeft} spots left',
                      ),
                    ),
                    PositionedDirectional(
                      start: AppSpacing.md,
                      end: AppSpacing.md,
                      bottom: AppSpacing.md,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ann.reservation.courtName,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: NightMatchColors.text,
                            ),
                          ),
                          Text(
                            '${_formatMatchDate(ann.reservation.date)} · ${ann.reservation.startTime} – ${ann.reservation.endTime}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: NightMatchColors.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: ctrl,
                  padding: EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    bot + AppSpacing.md,
                  ),
                  children: [
                    Row(
                      children: [
                        _NmAvatar(
                          initials: ann.host.avatarInitials,
                          size: 48,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ann.host.name, style: theme.textTheme.titleMedium),
                              Text('Match host', style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                        if (isAccepted && ann.host.phone.isNotEmpty)
                          AppSecondaryButton(
                            label: 'Call',
                            icon: Icons.call_rounded,
                            expand: false,
                            onPressed: () => _callPhone(ann.host.phone),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            Icons.people_rounded,
                            '${ann.playersNeeded}',
                            'Needed',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: _StatTile(
                            Icons.check_circle_rounded,
                            '${ann.acceptedCount}',
                            'Joined',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: _StatTile(
                            Icons.hourglass_top_rounded,
                            '${ann.spotsLeft}',
                            'Left',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppCard(
                      child: Text(
                        ann.description,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppCard(
                      child: Column(
                        children: [
                          _DetailRow(
                            Icons.sports_rounded,
                            'Sport',
                            ann.reservation.sport.label,
                          ),
                          const Divider(),
                          _DetailRow(
                            Icons.stadium_rounded,
                            'Court',
                            ann.reservation.courtName,
                          ),
                          const Divider(),
                          _DetailRow(
                            Icons.calendar_today_rounded,
                            'Date',
                            _formatMatchDate(ann.reservation.date),
                          ),
                          const Divider(),
                          _DetailRow(
                            Icons.access_time_rounded,
                            'Time',
                            '${ann.reservation.startTime} – ${ann.reservation.endTime}',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSheetCta(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetCta(BuildContext ctx) {
    final scheme = Theme.of(ctx).colorScheme;
    if (ann.isFull && !isAccepted) {
      return _StatusBanner(
        icon: Icons.lock_rounded,
        text: 'This match is full',
        color: scheme.onSurfaceVariant,
        background: scheme.surfaceContainerHighest,
      );
    }
    if (isMine) {
      return _StatusBanner(
        icon: Icons.edit_note_rounded,
        text: 'Your announcement',
        color: scheme.onSecondaryContainer,
        background: scheme.secondaryContainer,
      );
    }
    if (isAccepted) {
      return Column(
        children: [
          const ReservationStatusBadge(
            status: ReservationStatus.confirmed,
            label: "You're in! See you on the court",
          ),
          if (ann.host.phone.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            AppPrimaryButton(
              label: 'Call host: ${ann.host.phone}',
              icon: Icons.call_rounded,
              onPressed: () => _callPhone(ann.host.phone),
            ),
          ],
        ],
      );
    }
    if (isPending) {
      return const ReservationStatusBadge(
        status: ReservationStatus.pending,
        label: 'Request sent — awaiting approval',
      );
    }
    return AppPrimaryButton(
      label: 'Request to join',
      icon: Icons.send_rounded,
      onPressed: () {
        Navigator.pop(ctx);
        onRequest();
      },
    );
  }
}

class _JoinSheet extends StatefulWidget {
  final AnnouncementModel ann;
  final ValueChanged<String> onSend;
  const _JoinSheet({required this.ann, required this.onSend});
  @override
  State<_JoinSheet> createState() => _JoinSheetState();
}

class _JoinSheetState extends State<_JoinSheet> {
  final _ctrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bot = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: bot),
      child: AppBottomSheet(
        title: 'Request to join',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              child: Row(
                children: [
                  Icon(
                    widget.ann.reservation.sport.icon,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.ann.reservation.courtName,
                          style: theme.textTheme.titleSmall,
                        ),
                        Text(
                          '${widget.ann.reservation.startTime} – ${widget.ann.reservation.endTime}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${widget.ann.spotsLeft} left',
                    style: theme.textTheme.labelMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _ctrl,
              label: 'Add a message (optional)',
              hint: 'e.g. Intermediate level, ready to go!',
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your phone number will be visible to the host if your request is accepted.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            AppPrimaryButton(
              label: 'Send join request',
              icon: Icons.send_rounded,
              isLoading: _sending,
              onPressed: _sending
                  ? null
                  : () {
                      setState(() => _sending = true);
                      widget.onSend(_ctrl.text.trim());
                    },
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationSheet extends StatefulWidget {
  final List<AnnouncementModel> myAnnouncements;
  final List<JoinRequestData> myResponses;
  final AnnouncementService? svc;
  final VoidCallback onUpdate;
  const _NotificationSheet({
    required this.myAnnouncements,
    required this.myResponses,
    required this.svc,
    required this.onUpdate,
  });
  @override
  State<_NotificationSheet> createState() => _NotificationSheetState();
}

class _NotificationSheetState extends State<_NotificationSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);
  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  int get _pendingCount =>
      widget.myAnnouncements.fold(0, (s, a) => s + a.pendingCount);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, _) => ClipRRect(
        borderRadius: const BorderRadiusDirectional.vertical(
          top: Radius.circular(AppRadius.card),
        ),
        child: Material(
          color: theme.colorScheme.surface,
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Container(
                  width: 36,
                  height: AppSpacing.xxs,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_rounded,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notifications',
                            style: theme.textTheme.titleLarge,
                          ),
                          Text(
                            '$_pendingCount pending · ${widget.myResponses.length} responses',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.md,
                ),
                child: AnimatedBuilder(
                  animation: _tab,
                  builder: (context, _) => Row(
                    children: [
                      Expanded(
                        child: SportChip(
                          label: 'Received ($_pendingCount)',
                          selected: _tab.index == 0,
                          onTap: () => _tab.animateTo(0),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: SportChip(
                          label: 'Responses (${widget.myResponses.length})',
                          selected: _tab.index == 1,
                          onTap: () => _tab.animateTo(1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: [
                    _ReceivedTab(
                      announcements: widget.myAnnouncements,
                      svc: widget.svc,
                      onUpdate: widget.onUpdate,
                    ),
                    _ResponsesTab(responses: widget.myResponses),
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

class _ReceivedTab extends StatelessWidget {
  final List<AnnouncementModel> announcements;
  final AnnouncementService? svc;
  final VoidCallback onUpdate;
  const _ReceivedTab({
    required this.announcements,
    required this.svc,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final pending = <({AnnouncementModel ann, JoinRequest req})>[];
    for (final a in announcements) {
      for (final r in a.requests) {
        if (r.status == JoinRequestStatus.pending) {
          pending.add((ann: a, req: r));
        }
      }
    }
    if (pending.isEmpty) {
      return const EmptyState(
        icon: Icons.inbox_rounded,
        title: 'No pending requests',
        message: 'Join requests from other players will show up here.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      itemCount: pending.length,
      itemBuilder: (_, i) => _RequestTile(
        ann: pending[i].ann,
        req: pending[i].req,
        svc: svc,
        onUpdate: onUpdate,
      ),
    );
  }
}

class _ResponsesTab extends StatelessWidget {
  final List<JoinRequestData> responses;
  const _ResponsesTab({required this.responses});

  @override
  Widget build(BuildContext context) {
    if (responses.isEmpty) {
      return const EmptyState(
        icon: Icons.check_circle_outline_rounded,
        title: 'No responses yet',
        message: 'Host decisions appear here.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      itemCount: responses.length,
      itemBuilder: (_, i) => _ResponseCard(response: responses[i]),
    );
  }
}

class _RequestTile extends StatefulWidget {
  final AnnouncementModel ann;
  final JoinRequest req;
  final AnnouncementService? svc;
  final VoidCallback onUpdate;
  const _RequestTile({
    required this.ann,
    required this.req,
    required this.svc,
    required this.onUpdate,
  });
  @override
  State<_RequestTile> createState() => _RequestTileState();
}

class _RequestTileState extends State<_RequestTile> {
  bool _processing = false;

  Future<void> _respond(String status) async {
    if (_processing || widget.svc == null) return;
    setState(() => _processing = true);
    try {
      await widget.svc!.respondToRequest(widget.ann.id, widget.req.id, status);
      setState(() {
        widget.req.status = status == 'accepted'
            ? JoinRequestStatus.accepted
            : JoinRequestStatus.declined;
        _processing = false;
      });
      widget.onUpdate();
      if (mounted) {
        final scheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'accepted' ? 'Request accepted!' : 'Request declined',
            ),
            backgroundColor: scheme.inverseSurface,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _processing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed: ${e.toString().replaceAll('Exception:', '')}',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPending = widget.req.status == JoinRequestStatus.pending;
    final phone = widget.req.player.phone;

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _NmAvatar(initials: widget.req.player.avatarInitials, size: 48),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.req.player.name,
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        '${widget.ann.reservation.courtName} · ${widget.ann.reservation.startTime} – ${widget.ann.reservation.endTime}',
                        style: theme.textTheme.bodySmall,
                      ),
                      if (phone.isNotEmpty)
                        AppTextButton(
                          label: phone,
                          icon: Icons.call_rounded,
                          onPressed: () => _callPhone(phone),
                        ),
                    ],
                  ),
                ),
                if (!isPending)
                  ReservationStatusBadge(
                    status: widget.req.status == JoinRequestStatus.accepted
                        ? ReservationStatus.confirmed
                        : ReservationStatus.cancelled,
                    label: widget.req.status == JoinRequestStatus.accepted
                        ? 'Accepted'
                        : 'Declined',
                  ),
              ],
            ),
            if (widget.req.message.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                '"${widget.req.message}"',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (isPending && !_processing) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: AppSecondaryButton(
                      label: 'Decline',
                      onPressed: () => _respond('declined'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppPrimaryButton(
                      label: 'Accept',
                      icon: Icons.check_rounded,
                      onPressed: () => _respond('accepted'),
                    ),
                  ),
                ],
              ),
            ],
            if (_processing)
              const Padding(
                padding: EdgeInsetsDirectional.only(top: AppSpacing.sm),
                child: LoadingSkeleton(height: 48, borderRadius: AppRadius.pill),
              ),
          ],
        ),
      ),
    );
  }
}

class _SportFilter extends StatelessWidget {
  final SportType? selected;
  final ValueChanged<SportType?> onSelect;
  const _SportFilter({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: [
        SportChip(
          label: 'All',
          icon: Icons.sports_rounded,
          selected: selected == null,
          onTap: () => onSelect(null),
        ),
        const SizedBox(width: AppSpacing.xs),
        ...SportType.values.map(
          (s) => Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
            child: SportChip(
              label: s.label,
              icon: s.icon,
              selected: selected == s,
              onTap: () => onSelect(s),
            ),
          ),
        ),
      ],
    ),
  );
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value, label;
  const _StatTile(this.icon, this.value, this.label);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        children: [
          Icon(icon, color: theme.colorScheme.secondary),
          Text(value, style: theme.textTheme.titleLarge),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _DetailRow(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.secondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.titleSmall,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final String name, phone;
  const _PlayerRow({required this.name, required this.phone});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          _NmAvatar(
            initials: name.isNotEmpty ? name[0].toUpperCase() : 'P',
            size: 40,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(name, style: theme.textTheme.titleSmall)),
          if (phone.isNotEmpty)
            Semantics(
              button: true,
              label: 'Call $name',
              child: IconButton(
                tooltip: 'Call $name',
                onPressed: () => _callPhone(phone),
                icon: const Icon(Icons.call_rounded),
              ),
            ),
        ],
      ),
    );
  }
}

class _NmAvatar extends StatelessWidget {
  const _NmAvatar({required this.initials, this.size = 40});
  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Avatar $initials',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.input),
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: scheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.icon,
    required this.text,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String text;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      width: double.infinity,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.input),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
