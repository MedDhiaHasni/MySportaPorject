import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Widgets/Lists/avatar_widget.dart';
import 'package:sporta/Widgets/Lists/grid_painter.dart';
import 'package:sporta/Widgets/Buttons/outline_button.dart';
import 'package:sporta/Widgets/Lists/status_badge.dart';
import 'package:sporta/Widgets/Lists/section_title.dart';
import 'package:sporta/Widgets/Buttons/primary_button.dart';
import 'package:sporta/Models/app_enums.dart';
import 'package:sporta/Models/app_models.dart'; 
import 'package:sporta/Models/sample_data.dart';

// ─────────────────────────────────────────────────────────────────────────────
// match_detail_page.dart  —  Full match view: host controls + player join view
// All widgets StatefulWidget for backend readiness
// ─────────────────────────────────────────────────────────────────────────────


class MatchDetailPage extends StatefulWidget {
  final MatchModel match;
  final bool isHost;
  const MatchDetailPage({super.key, required this.match, this.isHost = false});
  @override
  State<MatchDetailPage> createState() => _MatchDetailPageState();
}

class _MatchDetailPageState extends State<MatchDetailPage> {
  late MatchModel _match;
  late bool _isHost;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    _match = widget.match;
    _isHost = widget.isHost;
    // TODO: replace with API fetch → setState(() { _match = result; })
  }

  void _cancelMatch() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Cancel Match',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: kTextDark,
          ),
        ),
        content: const Text(
          'Are you sure? All players will be notified.',
          style: TextStyle(color: kTextMid, fontSize: 14, height: 1.5),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: _OBtn('Keep Match', () => Navigator.pop(context)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FBtn('Cancel Match', kRed, () {
                  Navigator.pop(context);
                  setState(
                    () =>
                        _match = _match.copyWith(status: MatchStatus.cancelled),
                  );
                  _snack('Match cancelled', kRed);
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _removePlayer(MatchPlayer mp) => setState(() {
    _match = _match.copyWith(
      players: _match.players
          .where((p) => p.player.id != mp.player.id)
          .toList(),
    );
  });

  void _joinMatch() async {
    setState(() => _confirming = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    final me = samplePlayers.last;
    final updated = [
      ..._match.players,
      MatchPlayer(
        player: me,
        hasPaid: _match.hasCourt,
        paymentMethod: _match.hasCourt ? 'online' : 'pending',
      ),
    ];
    final newStatus = updated.length >= _match.maxPlayers
        ? MatchStatus.confirmed
        : null;
    setState(() {
      _confirming = false;
      _match = _match.copyWith(players: updated, status: newStatus);
    });
    _snack(
      newStatus == MatchStatus.confirmed
          ? 'Match is full & confirmed!'
          : 'You joined the match!',
      newStatus == MatchStatus.confirmed ? kGreen : kPrimary,
    );
  }

  void _editDescription() {
    final ctrl = TextEditingController(text: _match.description);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Edit Description',
          style: TextStyle(fontWeight: FontWeight.w800, color: kTextDark),
        ),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          style: const TextStyle(fontSize: 13, color: kTextDark),
          decoration: InputDecoration(
            hintText: 'Match description...',
            hintStyle: const TextStyle(color: kTextLight),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBg),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kPrimary),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: kTextMid)),
          ),
          TextButton(
            onPressed: () {
              setState(() => _match = _match.copyWith(description: ctrl.text));
              Navigator.pop(context);
            },
            child: const Text(
              'Save',
              style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _snack(
    String msg,
    Color color,
  ) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ),
  );

  void _showHostMenu() => showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _HostMenuSheet(
      onEdit: () {
        Navigator.pop(context);
        _editDescription();
      },
      onCancel: () {
        Navigator.pop(context);
        _cancelMatch();
      },
      onClose: () {
        Navigator.pop(context);
        setState(() => _match = _match.copyWith(status: MatchStatus.cancelled));
      },
    ),
  );

  void _showInviteSheet() => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _QuickInviteSheet(
      currentPlayers: _match.players,
      onInvite: (p) => setState(
        () => _match = _match.copyWith(
          players: [
            ..._match.players,
            MatchPlayer(player: p),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final navBarH =
        kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    final live = _match.computeStatus();
    final isCancelled = _match.status == MatchStatus.cancelled;
    final isConfirmed = live == MatchStatus.confirmed;

    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          _MatchHeroBanner(
            match: _match,
            isHost: _isHost,
            status: live,
            onBack: () => Navigator.pop(context),
            onMenu: _isHost ? _showHostMenu : null,
          ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 18, 16, navBarH + 90),
              children: [
                _MatchStatusBar(match: _match, status: live),
                const SizedBox(height: 20),

                SectionTitle(_match.hasCourt ? 'Court' : 'Location TBD'),
                const SizedBox(height: 10),
                if (_match.hasCourt)
                  _CourtInfoCard(res: _match.reservation!)
                else
                  _NoCourt(sport: _match.sport),
                const SizedBox(height: 20),

                SectionTitle('Match Details'),
                const SizedBox(height: 10),
                _MatchInfoCard(
                  match: _match,
                  isHost: _isHost,
                  onEditDesc: _isHost ? _editDescription : null,
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    SectionTitle(
                      'Players',
                      sub: '${_match.joinedCount}/${_match.maxPlayers}',
                    ),
                    const Spacer(),
                    if (_isHost && !isCancelled)
                      _InviteChip(onTap: _showInviteSheet),
                  ],
                ),
                const SizedBox(height: 10),
                _PlayersSection(
                  match: _match,
                  isHost: _isHost,
                  isCancelled: isCancelled,
                  onRemove: _removePlayer,
                ),
                const SizedBox(height: 20),

                SectionTitle('Payment'),
                const SizedBox(height: 10),
                _PaymentCard(match: _match, isHost: _isHost),

                if (isCancelled) ...[
                  const SizedBox(height: 20),
                  _CancelledBanner(),
                ],
              ],
            ),
          ),

          // ── Bottom CTA ────────────────────────────────────────────────
          if (!isCancelled)
            Container(
              color: kCard,
              padding: EdgeInsets.fromLTRB(16, 14, 16, navBarH + 8),
              child: _isHost
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Public still filling
                        if (_match.isPublic && !isConfirmed)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: kPurple.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: kPurple.withOpacity(0.15),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.people_outline_rounded,
                                  size: 14,
                                  color: kPurple,
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    '${_match.joinedCount}/${_match.maxPlayers} joined · Confirms when full',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: kPurple,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        // Pay at venue reminder (private + confirmed + payAtVenue)
                        else if (isConfirmed &&
                            _match.reservation?.paymentOption ==
                                PaymentOption.payAtVenue)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: kAmber.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: kAmber.withOpacity(0.15),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.storefront_rounded,
                                  size: 14,
                                  color: kAmber,
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    'Reminder: pay ${_match.totalCourtCost.toStringAsFixed(0)} DT at the venue on match day',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: kAmber,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Confirmed pill
                        if (isConfirmed)
                          Container(
                            height: 52,
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: kGreen.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: kGreen,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Match Confirmed',
                                  style: TextStyle(
                                    color: kGreen,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        AppOutlineButton('Cancel Match', onTap: _cancelMatch),
                      ],
                    )
                  // Non-host: join button
                  : PrimaryButton(
                      _match.isFull
                          ? 'Match is Full'
                          : _match.hasCourt
                          ? 'Join & Pay ${_match.pricePerPlayer.toStringAsFixed(2)} DT'
                          : 'Join Match',
                      color: _match.isFull ? kTextLight : kPrimary,
                      icon: _match.isFull ? null : Icons.sports_rounded,
                      onTap: _match.isFull ? null : _joinMatch,
                      loading: _confirming,
                    ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO BANNER
// ─────────────────────────────────────────────────────────────────────────────

class _MatchHeroBanner extends StatefulWidget {
  final MatchModel match;
  final MatchStatus status;
  final bool isHost;
  final VoidCallback onBack;
  final VoidCallback? onMenu;
  const _MatchHeroBanner({
    required this.match,
    required this.status,
    required this.isHost,
    required this.onBack,
    this.onMenu,
  });
  @override
  State<_MatchHeroBanner> createState() => _MatchHeroBannerState();
}

class _MatchHeroBannerState extends State<_MatchHeroBanner> {
  String _fmtDate(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    final color = m.sport.color;
    final dateLabel = m.hasCourt
        ? m.reservation!.dateLabel
        : _fmtDate(m.scheduledDate);
    final timeLabel = m.hasCourt
        ? '${m.reservation!.startTime} – ${m.reservation!.endTime}'
        : m.scheduledTime;
    final courtLabel = m.hasCourt
        ? m.reservation!.courtName
        : '${m.sport.label} Match';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(color, Colors.black, 0.45)!, color],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            const Positioned.fill(child: CustomPaint(painter: GridPainter())),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                children: [
                  // top row
                  Row(
                    children: [
                      GestureDetector(
                        onTap: widget.onBack,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (widget.isHost)
                        StatusBadge(label: 'Host', color: kAmber),
                      if (widget.onMenu != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: widget.onMenu,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.more_vert_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // main info row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          m.sport.icon,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.sport.label,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.65),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              courtLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 12,
                                  color: Colors.white.withOpacity(0.65),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  dateLabel,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.75),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 12,
                                  color: Colors.white.withOpacity(0.65),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  timeLabel,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.75),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            if (!m.hasCourt) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: kAmber.withOpacity(0.28),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.location_searching_rounded,
                                      size: 11,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      'No court booked yet',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS BAR
// ─────────────────────────────────────────────────────────────────────────────

class _MatchStatusBar extends StatefulWidget {
  final MatchModel match;
  final MatchStatus status;
  const _MatchStatusBar({required this.match, required this.status});
  @override
  State<_MatchStatusBar> createState() => _MatchStatusBarState();
}

class _MatchStatusBarState extends State<_MatchStatusBar> {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: kCardDeco(14),
    child: Row(
      children: [
        SizedBox(
          width: 46,
          height: 46,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: widget.match.fillRatio,
                strokeWidth: 4,
                backgroundColor: widget.status.color.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation(widget.status.color),
              ),
              Text(
                '${(widget.match.fillRatio * 100).round()}%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: widget.status.color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatusBadge(
                label: widget.status.label,
                color: widget.status.color,
              ),
              const SizedBox(height: 4),
              Text(
                widget.match.isPublic
                    ? '${widget.match.joinedCount}/${widget.match.maxPlayers} joined · fills to confirm'
                    : widget.match.hasCourt
                    ? 'Private match · Court confirmed'
                    : 'Looking for players · No court yet',
                style: const TextStyle(
                  fontSize: 12,
                  color: kTextMid,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        _AvatarStack(players: widget.match.players),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// AVATAR STACK
// ─────────────────────────────────────────────────────────────────────────────

class _AvatarStack extends StatefulWidget {
  final List<MatchPlayer> players;
  const _AvatarStack({required this.players});
  @override
  State<_AvatarStack> createState() => _AvatarStackState();
}

class _AvatarStackState extends State<_AvatarStack> {
  @override
  Widget build(BuildContext context) {
    final show = widget.players.take(4).toList();
    return SizedBox(
      width: show.length * 22.0 + 14,
      height: 34,
      child: Stack(
        children: show
            .asMap()
            .entries
            .map(
              (e) => Positioned(
                left: e.key * 22.0,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: kCard, width: 2),
                  ),
                  child: AvatarWidget(
                    initials: e.value.player.avatarInitials,
                    size: 30,
                    bg: kPrimary,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NO COURT PLACEHOLDER
// ─────────────────────────────────────────────────────────────────────────────

class _NoCourt extends StatefulWidget {
  final SportType sport;
  const _NoCourt({required this.sport});
  @override
  State<_NoCourt> createState() => _NoCourtState();
}

class _NoCourtState extends State<_NoCourt> {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: kAmber.withOpacity(0.05),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kAmber.withOpacity(0.2)),
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: kAmber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.location_searching_rounded,
            color: kAmber,
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No court booked yet',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: kTextDark,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Once enough players join, a court will be arranged — or book one separately.',
                style: TextStyle(fontSize: 11, color: kTextMid, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// COURT INFO CARD
// ─────────────────────────────────────────────────────────────────────────────

class _CourtInfoCard extends StatefulWidget {
  final CourtReservation res;
  const _CourtInfoCard({required this.res});
  @override
  State<_CourtInfoCard> createState() => _CourtInfoCardState();
}

class _CourtInfoCardState extends State<_CourtInfoCard> {
  @override
  Widget build(BuildContext context) {
    final res = widget.res;
    final isPaid = res.paymentOption == PaymentOption.payNow;
    return Container(
      decoration: kCardDeco(14),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: res.sport.color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(res.sport.icon, color: res.sport.color, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  res.courtName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: kTextDark,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    _pill(Icons.calendar_today_rounded, res.dateLabel),
                    const SizedBox(width: 8),
                    _pill(
                      Icons.access_time_rounded,
                      '${res.startTime}–${res.endTime}',
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isPaid
                        ? kGreen.withOpacity(0.08)
                        : kAmber.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPaid ? Icons.bolt_rounded : Icons.storefront_rounded,
                        size: 10,
                        color: isPaid ? kGreen : kAmber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPaid ? 'Paid online' : 'Pay at venue',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isPaid ? kGreen : kAmber,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${res.totalPrice.toStringAsFixed(0)} DT',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: kPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const Text(
                'total',
                style: TextStyle(fontSize: 10, color: kTextMid),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String t) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 10, color: kTextLight),
      const SizedBox(width: 4),
      Text(
        t,
        style: const TextStyle(
          fontSize: 10,
          color: kTextMid,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// MATCH INFO CARD
// ─────────────────────────────────────────────────────────────────────────────

class _MatchInfoCard extends StatefulWidget {
  final MatchModel match;
  final bool isHost;
  final VoidCallback? onEditDesc;
  const _MatchInfoCard({
    required this.match,
    required this.isHost,
    this.onEditDesc,
  });
  @override
  State<_MatchInfoCard> createState() => _MatchInfoCardState();
}

class _MatchInfoCardState extends State<_MatchInfoCard> {
  @override
  Widget build(BuildContext context) => Container(
    decoration: kCardDeco(14),
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            _tag(widget.match.matchType.label, kPrimary),
            _tag(
              widget.match.isPublic ? 'Public' : 'Private',
              widget.match.isPublic ? kPurple : kTextMid,
            ),
            if (widget.match.hasCourt && widget.match.pricePerPlayer > 0)
              _tag(
                '${widget.match.pricePerPlayer.toStringAsFixed(2)} DT / player',
                kGreen,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                widget.match.description,
                style: const TextStyle(
                  fontSize: 13,
                  color: kTextMid,
                  height: 1.5,
                ),
              ),
            ),
            if (widget.isHost && widget.onEditDesc != null)
              GestureDetector(
                onTap: widget.onEditDesc,
                child: Container(
                  width: 30,
                  height: 30,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: kBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 14,
                    color: kTextMid,
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );

  Widget _tag(String l, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: c.withOpacity(0.09),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: c.withOpacity(0.2)),
    ),
    child: Text(
      l,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PLAYERS SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _PlayersSection extends StatefulWidget {
  final MatchModel match;
  final bool isHost, isCancelled;
  final ValueChanged<MatchPlayer> onRemove;
  const _PlayersSection({
    required this.match,
    required this.isHost,
    required this.isCancelled,
    required this.onRemove,
  });
  @override
  State<_PlayersSection> createState() => _PlayersSectionState();
}

class _PlayersSectionState extends State<_PlayersSection> {
  @override
  Widget build(BuildContext context) {
    final slotCount = widget.match.maxPlayers.clamp(0, 20);
    final slots = List.generate(
      slotCount,
      (i) => i < widget.match.players.length ? widget.match.players[i] : null,
    );
    return Container(
      decoration: kCardDeco(14),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: slots.asMap().entries.map((e) {
          final i = e.key;
          final mp = e.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                child: mp != null
                    ? _FilledSlot(
                        mp: mp,
                        isHost: widget.isHost,
                        isCancelled: widget.isCancelled,
                        onRemove: () => widget.onRemove(mp),
                      )
                    : _EmptySlot(
                        number: i + 1,
                        isPublic: widget.match.isPublic,
                      ),
              ),
              if (i < slotCount - 1) Divider(height: 1, color: kBg),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _FilledSlot extends StatefulWidget {
  final MatchPlayer mp;
  final bool isHost, isCancelled;
  final VoidCallback onRemove;
  const _FilledSlot({
    required this.mp,
    required this.isHost,
    required this.isCancelled,
    required this.onRemove,
  });
  @override
  State<_FilledSlot> createState() => _FilledSlotState();
}

class _FilledSlotState extends State<_FilledSlot> {
  @override
  Widget build(BuildContext context) {
    final mp = widget.mp;

    // Simple payment label — no InviteStatus, just hasPaid + paymentMethod
    final String payLabel;
    final Color payColor;
    if (mp.isHost) {
      payLabel = 'Host';
      payColor = kAmber;
    } else if (mp.hasPaid) {
      payLabel = 'Paid';
      payColor = kGreen;
    } else if (mp.paymentMethod == 'venue') {
      payLabel = 'Pay at venue';
      payColor = kAmber;
    } else {
      payLabel = 'Pending';
      payColor = kTextMid;
    }

    return Row(
      children: [
        AvatarWidget(
          initials: mp.player.avatarInitials,
          size: 36,
          bg: mp.isHost ? kAmber : kPrimary,
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Row(
            children: [
              Text(
                mp.player.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: kTextDark,
                ),
              ),
              if (mp.isHost) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: kAmber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Host',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: kAmber,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        StatusBadge(label: payLabel, color: payColor),
        if (widget.isHost && !mp.isHost && !widget.isCancelled) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: widget.onRemove,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: kRed.withOpacity(0.07),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.person_remove_rounded,
                size: 14,
                color: kRed,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptySlot extends StatefulWidget {
  final int number;
  final bool isPublic;
  const _EmptySlot({required this.number, required this.isPublic});
  @override
  State<_EmptySlot> createState() => _EmptySlotState();
}

class _EmptySlotState extends State<_EmptySlot> {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: kBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kTextLight.withOpacity(0.3), width: 1.5),
        ),
        child: Center(
          child: Text(
            '${widget.number}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kTextLight,
            ),
          ),
        ),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Text(
          widget.isPublic
              ? 'Open slot — join from the app'
              : 'Waiting for invite...',
          style: const TextStyle(fontSize: 12, color: kTextLight),
        ),
      ),
      Icon(
        widget.isPublic ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
        size: 15,
        color: kTextLight,
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PAYMENT CARD
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentCard extends StatefulWidget {
  final MatchModel match;
  final bool isHost;
  const _PaymentCard({required this.match, required this.isHost});
  @override
  State<_PaymentCard> createState() => _PaymentCardState();
}

class _PaymentCardState extends State<_PaymentCard> {
  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    final paid = m.players.where((p) => p.hasPaid).length;
    final pending = m.players.where((p) => !p.hasPaid).length;
    final ppp = m.pricePerPlayer;
    final collected = paid * ppp;

    final String note;
    if (!m.hasCourt) {
      note =
          'No court booked yet — payment will apply once a court is confirmed.';
    } else if (m.reservation!.paymentOption == PaymentOption.payAtVenue) {
      note =
          'All players pay ${m.totalCourtCost.toStringAsFixed(0)} DT total at the venue on match day.';
    } else if (m.isPublic) {
      note =
          'Each player pays ${ppp.toStringAsFixed(2)} DT online when joining.';
    } else {
      note = pending > 0
          ? '$pending player${pending == 1 ? '' : 's'} still pending payment.'
          : 'All players have paid.';
    }

    return Container(
      decoration: kCardDeco(14),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _stat(
                  'Per Player',
                  m.hasCourt ? '${ppp.toStringAsFixed(2)} DT' : '—',
                  kPrimary,
                ),
              ),
              _vd(),
              Expanded(child: _stat('Paid', '$paid', kGreen)),
              _vd(),
              Expanded(
                child: _stat(
                  'Pending',
                  '$pending',
                  pending > 0 ? kAmber : kTextMid,
                ),
              ),
              _vd(),
              Expanded(
                child: _stat(
                  'Collected',
                  m.hasCourt ? '${collected.toStringAsFixed(0)} DT' : '—',
                  kGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: kBg),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, size: 14, color: kAmber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  note,
                  style: const TextStyle(
                    fontSize: 11,
                    color: kTextMid,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String l, String v, Color c) => Column(
    children: [
      Text(
        v,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: c,
          letterSpacing: -0.3,
        ),
      ),
      const SizedBox(height: 2),
      Text(l, style: const TextStyle(fontSize: 9.5, color: kTextMid)),
    ],
  );

  Widget _vd() => Container(
    width: 1,
    height: 32,
    color: kBg,
    margin: const EdgeInsets.symmetric(horizontal: 4),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// MISC WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _InviteChip extends StatefulWidget {
  final VoidCallback onTap;
  const _InviteChip({required this.onTap});
  @override
  State<_InviteChip> createState() => _InviteChipState();
}

class _InviteChipState extends State<_InviteChip> {
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: widget.onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: kPrimary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(9),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_add_rounded, size: 12, color: kPrimary),
          SizedBox(width: 5),
          Text(
            'Invite',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: kPrimary,
            ),
          ),
        ],
      ),
    ),
  );
}

class _CancelledBanner extends StatefulWidget {
  const _CancelledBanner();
  @override
  State<_CancelledBanner> createState() => _CancelledBannerState();
}

class _CancelledBannerState extends State<_CancelledBanner> {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: kRed.withOpacity(0.05),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: kRed.withOpacity(0.2)),
    ),
    child: const Row(
      children: [
        Icon(Icons.cancel_rounded, color: kRed, size: 20),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'This match has been cancelled.',
            style: TextStyle(fontSize: 12, color: kRed, height: 1.4),
          ),
        ),
      ],
    ),
  );
}

class _HostMenuSheet extends StatefulWidget {
  final VoidCallback onEdit, onCancel, onClose;
  const _HostMenuSheet({
    required this.onEdit,
    required this.onCancel,
    required this.onClose,
  });
  @override
  State<_HostMenuSheet> createState() => _HostMenuSheetState();
}

class _HostMenuSheetState extends State<_HostMenuSheet> {
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: kCard,
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    child: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 32,
            height: 3.5,
            decoration: BoxDecoration(
              color: kTextLight.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.manage_accounts_rounded, color: kPrimary, size: 20),
                SizedBox(width: 10),
                Text(
                  'Host Controls',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: kTextDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: kBg),
          _item(
            Icons.edit_rounded,
            'Edit Description',
            kPrimary,
            widget.onEdit,
          ),
          _item(
            Icons.lock_outline_rounded,
            'Close Registration',
            kAmber,
            widget.onClose,
          ),
          _item(Icons.cancel_rounded, 'Cancel Match', kRed, widget.onCancel),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );

  Widget _item(IconData icon, String label, Color color, VoidCallback fn) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: fn,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 13),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color == kRed ? kRed : kTextDark,
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right_rounded, size: 16, color: kTextLight),
              ],
            ),
          ),
        ),
      );
}

class _QuickInviteSheet extends StatefulWidget {
  final List<MatchPlayer> currentPlayers;
  final ValueChanged<AppPlayer> onInvite;
  const _QuickInviteSheet({
    required this.currentPlayers,
    required this.onInvite,
  });
  @override
  State<_QuickInviteSheet> createState() => _QuickInviteSheetState();
}

class _QuickInviteSheetState extends State<_QuickInviteSheet> {
  @override
  Widget build(BuildContext context) {
    final current = widget.currentPlayers.map((p) => p.player.id).toSet();
    final available = samplePlayers
        .where((p) => !current.contains(p.id))
        .toList();
    return Container(
      decoration: const BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 32,
              height: 3.5,
              decoration: BoxDecoration(
                color: kTextLight.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Invite Players',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: kTextDark,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (available.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No more contacts to invite.',
                  style: TextStyle(color: kTextMid),
                ),
              )
            else
              ...available.map(
                (p) => Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      widget.onInvite(p);
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 11,
                      ),
                      child: Row(
                        children: [
                          AvatarWidget(
                            initials: p.avatarInitials,
                            size: 36,
                            bg: kPrimary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              p.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: kTextDark,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: kPrimary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Invite',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ── Dialog button helpers ──────────────────────────────────────────────────────

class _OBtn extends StatelessWidget {
  final String l;
  final VoidCallback fn;
  const _OBtn(this.l, this.fn);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: fn,
    child: Container(
      height: 44,
      decoration: BoxDecoration(
        border: Border.all(color: kTextLight.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          l,
          style: const TextStyle(color: kTextMid, fontWeight: FontWeight.w700),
        ),
      ),
    ),
  );
}

class _FBtn extends StatelessWidget {
  final String l;
  final Color c;
  final VoidCallback fn;
  const _FBtn(this.l, this.c, this.fn);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: fn,
    child: Container(
      height: 44,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          l,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );
}
