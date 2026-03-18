// matches_page.dart — place at Views/Player/matches_page.dart
// Tab 1: Announcements (tappable cards → detail sheet, no pay chips, venue+court shown)
// Tab 2: Tournaments  (venue posters → detail sheet + join/register)

import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Models/app_enums.dart';
import 'package:sporta/Models/app_models.dart';
import 'package:sporta/Models/sample_data.dart';
import 'package:sporta/Widgets/Buttons/primary_button.dart';
import 'package:sporta/Widgets/Lists/avatar_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TOURNAMENT MODEL
// ─────────────────────────────────────────────────────────────────────────────
class TournamentModel {
  final String id, title, venueName, location, posterUrl, description, format;
  final SportType sport;
  final DateTime date;
  final String time;
  final int maxTeams, prizePool, entryFee;
  int registeredTeams;
  final List<String> prizes;
  bool joined;

  TournamentModel({
    required this.id,
    required this.title,
    required this.venueName,
    required this.location,
    required this.sport,
    required this.date,
    required this.time,
    required this.maxTeams,
    required this.registeredTeams,
    required this.prizePool,
    required this.entryFee,
    required this.posterUrl,
    required this.description,
    required this.format,
    required this.prizes,
    this.joined = false,
  });

  int get spotsLeft => maxTeams - registeredTeams;
  bool get isFull => spotsLeft <= 0;

  String get dateLabel {
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
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SAMPLE TOURNAMENTS
// ─────────────────────────────────────────────────────────────────────────────
final sampleTournaments = [
  TournamentModel(
    id: 't1',
    title: 'Tunis Football Cup',
    venueName: 'Arena Sport Center',
    location: 'Lac 2, Tunis',
    sport: SportType.football,
    date: DateTime.now().add(const Duration(days: 10)),
    time: '09:00',
    maxTeams: 16,
    registeredTeams: 11,
    prizePool: 2000,
    entryFee: 80,
    posterUrl:
        'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=700&q=80',
    description:
        'The biggest 5v5 football tournament in Tunis. 16 teams compete in knockout format. Open to all skill levels!',
    format: '5v5 Knockout',
    prizes: ['🥇 1st: 1 000 DT', '🥈 2nd: 600 DT', '🥉 3rd: 400 DT'],
  ),
  TournamentModel(
    id: 't2',
    title: 'Padel Masters Marsa',
    venueName: 'Padel Club Marsa',
    location: 'La Marsa, Tunis',
    sport: SportType.padel,
    date: DateTime.now().add(const Duration(days: 7)),
    time: '10:00',
    maxTeams: 8,
    registeredTeams: 6,
    prizePool: 1200,
    entryFee: 60,
    posterUrl:
        'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=700&q=80',
    description:
        'Elite padel doubles tournament. 8 pairs compete in round-robin + finals. Intermediate to advanced level.',
    format: 'Doubles Round-Robin',
    prizes: ['🥇 1st: 700 DT', '🥈 2nd: 300 DT', '🥉 3rd: 200 DT'],
  ),
  TournamentModel(
    id: 't3',
    title: '3v3 Basketball Clash',
    venueName: 'City Basketball Arena',
    location: 'Menzah 6, Tunis',
    sport: SportType.basketball,
    date: DateTime.now().add(const Duration(days: 14)),
    time: '14:00',
    maxTeams: 12,
    registeredTeams: 4,
    prizePool: 800,
    entryFee: 40,
    posterUrl:
        'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=700&q=80',
    description:
        'Fast-paced 3v3 basketball open to all. Indoor AC court. Compete for the trophy and cash prize.',
    format: '3v3 Group + Finals',
    prizes: ['🥇 1st: 500 DT', '🥈 2nd: 200 DT', '🥉 3rd: 100 DT'],
  ),
  TournamentModel(
    id: 't4',
    title: 'Tennis Open Gammarth',
    venueName: 'Tennis Academy Tunis',
    location: 'Gammarth, Tunis',
    sport: SportType.tennis,
    date: DateTime.now().add(const Duration(days: 21)),
    time: '08:00',
    maxTeams: 16,
    registeredTeams: 16,
    prizePool: 3000,
    entryFee: 100,
    posterUrl:
        'https://images.unsplash.com/photo-1545809074-59472b3f5ecc?w=700&q=80',
    description:
        'Singles tennis on clay courts. All levels welcome. Match play with seedings. Registration now full.',
    format: 'Singles Knockout',
    prizes: ['🥇 1st: 1 500 DT', '🥈 2nd: 900 DT', '🥉 3rd: 600 DT'],
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// MAIN PAGE — tabbed Announcements | Tournaments
// ─────────────────────────────────────────────────────────────────────────────
class Matches extends StatefulWidget {
  const Matches({super.key});
  @override
  State<Matches> createState() => _MatchesState();
}

class _MatchesState extends State<Matches> with SingleTickerProviderStateMixin {
  late TabController _tab;
  SportType? _filter;
  late List<AnnouncementModel> _announcements;
  late List<TournamentModel> _tournaments;
  static const _myId = 'p1';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
    _announcements = List.from(sampleAnnouncements);
    _tournaments = List.from(sampleTournaments);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  List<AnnouncementModel> get _feed => _announcements.where((a) {
    if (a.host.id == _myId) return false;
    if (_filter != null && a.reservation.sport != _filter) return false;
    return true;
  }).toList();

  List<AnnouncementModel> get _myAnnouncements =>
      _announcements.where((a) => a.host.id == _myId).toList();

  int get _totalPending =>
      _myAnnouncements.fold(0, (s, a) => s + a.pendingCount);

  void _openBell() => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _NotificationSheet(
      announcements: _myAnnouncements,
      onUpdate: () => setState(() {}),
    ),
  );

  void _sendRequest(AnnouncementModel ann) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _JoinRequestSheet(
      announcement: ann,
      onSend: (msg) {
        setState(
          () => ann.requests.add(
            JoinRequest(
              id: 'jr_${DateTime.now().millisecondsSinceEpoch}',
              player: samplePlayers.firstWhere((p) => p.id == _myId),
              message: msg,
            ),
          ),
        );
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request sent! Waiting for host approval.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    ),
  );

  bool _alreadyRequested(AnnouncementModel ann) =>
      ann.requests.any((r) => r.player.id == _myId);

  void _openDetail(AnnouncementModel ann) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AnnouncementDetailSheet(
      ann: ann,
      alreadyRequested: _alreadyRequested(ann),
      onRequest: () {
        Navigator.pop(context);
        _sendRequest(ann);
      },
    ),
  );

  void _openTournament(TournamentModel t) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TournamentDetailSheet(
      tournament: t,
      onJoin: () {
        setState(() {
          t.joined = true;
          t.registeredTeams++;
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registered! Check your notifications for updates.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final navH =
        kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    final feed = _feed;

    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          Container(
            color: kCard,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Community',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: kTextDark,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              Text(
                                _tab.index == 0
                                    ? '${feed.length} open near you'
                                    : '${_tournaments.length} upcoming',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: kTextMid,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_tab.index == 0)
                          GestureDetector(
                            onTap: _openBell,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: _totalPending > 0
                                        ? kPrimary.withOpacity(0.08)
                                        : kBg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _totalPending > 0
                                        ? Icons.notifications_rounded
                                        : Icons.notifications_outlined,
                                    color: _totalPending > 0
                                        ? kPrimary
                                        : kTextMid,
                                    size: 22,
                                  ),
                                ),
                                if (_totalPending > 0)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      width: 9,
                                      height: 9,
                                      decoration: BoxDecoration(
                                        color: kGreen,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: kCard,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_tab.index == 0)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      child: _SportFilter(
                        selected: _filter,
                        onSelect: (s) => setState(() => _filter = s),
                      ),
                    ),
                  const SizedBox(height: 12),
                  TabBar(
                    controller: _tab,
                    labelColor: kPrimary,
                    unselectedLabelColor: kTextMid,
                    labelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    indicatorColor: kPrimary,
                    indicatorWeight: 2.5,
                    tabs: const [
                      Tab(text: 'Announcements'),
                      Tab(text: 'Tournaments'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                feed.isEmpty
                    ? _Empty()
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, navH + 16),
                        itemCount: feed.length,
                        itemBuilder: (_, i) => _AnnouncementCard(
                          ann: feed[i],
                          alreadyRequested: _alreadyRequested(feed[i]),
                          onRequest: () => _sendRequest(feed[i]),
                          onTap: () => _openDetail(feed[i]),
                        ),
                      ),

                _tournaments.isEmpty
                    ? _EmptyTournaments()
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, navH + 16),
                        itemCount: _tournaments.length,
                        itemBuilder: (_, i) => _TournamentCard(
                          tournament: _tournaments[i],
                          onTap: () => _openTournament(_tournaments[i]),
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
// ANNOUNCEMENT CARD — tappable, venue+court shown, no pay chip
// ─────────────────────────────────────────────────────────────────────────────
class _AnnouncementCard extends StatelessWidget {
  final AnnouncementModel ann;
  final bool alreadyRequested;
  final VoidCallback onRequest, onTap;
  const _AnnouncementCard({
    required this.ann,
    required this.alreadyRequested,
    required this.onRequest,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final a = ann;
    final sc = a.reservation.sport.color;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: kCardDeco(20),
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: a.reservation.courtImageUrl != null
                      ? Image.network(
                          a.reservation.courtImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _gradBg(sc),
                        )
                      : _gradBg(sc),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.62),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: a.isFull
                          ? kRed.withOpacity(0.85)
                          : kGreen.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          a.isFull ? Icons.lock_rounded : Icons.people_rounded,
                          size: 11,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          a.isFull
                              ? 'Full'
                              : '${a.spotsLeft} spot${a.spotsLeft == 1 ? '' : 's'} left',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          a.reservation.sport.icon,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.reservation.courtName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              '${a.reservation.sport.label}  ·  ${a.reservation.dateLabel}  ·  ${a.reservation.startTime}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.72),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AvatarWidget(
                        initials: a.host.avatarInitials,
                        size: 28,
                        bg: sc,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 12,
                              color: kTextDark,
                            ),
                            children: [
                              TextSpan(
                                text: a.host.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const TextSpan(
                                text: ' is looking for players',
                                style: TextStyle(color: kTextMid),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Text(
                        _timeAgo(a.createdAt),
                        style: const TextStyle(fontSize: 10, color: kTextLight),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    a.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: kTextMid,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _Chip(a.reservation.sport.label, color: sc),
                      const SizedBox(width: 6),
                      _Chip('${a.playersNeeded} needed'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (a.isFull)
                    _banner(kBg, null, 'This announcement is full', kTextMid)
                  else if (alreadyRequested)
                    _banner(
                      kPrimary.withOpacity(0.06),
                      kPrimary.withOpacity(0.2),
                      'Request sent — awaiting approval',
                      kPrimary,
                      icon: Icons.hourglass_top_rounded,
                    )
                  else
                    GestureDetector(
                      onTap: onRequest,
                      child: Container(
                        height: 44,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: sc,
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: [
                            BoxShadow(
                              color: sc.withOpacity(0.28),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 15,
                              ),
                              SizedBox(width: 7),
                              Text(
                                'Request to Join',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradBg(Color sc) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Color.lerp(sc, Colors.black, 0.4)!, sc],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  );

  Widget _banner(
    Color bg,
    Color? border,
    String text,
    Color textColor, {
    IconData? icon,
  }) => Container(
    height: 44,
    width: double.infinity,
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(13),
      border: border != null ? Border.all(color: border) : null,
    ),
    child: Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 7),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ANNOUNCEMENT DETAIL SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _AnnouncementDetailSheet extends StatelessWidget {
  final AnnouncementModel ann;
  final bool alreadyRequested;
  final VoidCallback onRequest;
  const _AnnouncementDetailSheet({
    required this.ann,
    required this.alreadyRequested,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    final a = ann;
    final sc = a.reservation.sport.color;
    final bot = MediaQuery.of(context).padding.bottom;
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Color(0x28000000),
              blurRadius: 30,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: Stack(
                children: [
                  SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: a.reservation.courtImageUrl != null
                        ? Image.network(
                            a.reservation.courtImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _heroBg(sc),
                          )
                        : _heroBg(sc),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.70),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 28,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: a.isFull
                            ? kRed.withOpacity(0.85)
                            : kGreen.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        a.isFull
                            ? 'Full'
                            : '${a.spotsLeft} spot${a.spotsLeft == 1 ? '' : 's'} left',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 14,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.reservation.courtName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              a.reservation.sport.icon,
                              color: Colors.white.withOpacity(0.8),
                              size: 13,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${a.reservation.sport.label}  ·  ${a.reservation.dateLabel}  ·  ${a.reservation.startTime}–${a.reservation.endTime}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                                fontSize: 12,
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

            Expanded(
              child: ListView(
                controller: ctrl,
                padding: EdgeInsets.fromLTRB(20, 20, 20, bot + 20),
                children: [
                  Row(
                    children: [
                      AvatarWidget(
                        initials: a.host.avatarInitials,
                        size: 42,
                        bg: sc,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.host.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: kTextDark,
                              ),
                            ),
                            Text(
                              'Posted ${_timeAgo(a.createdAt)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: kTextMid,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _Chip(a.reservation.sport.label, color: sc),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _infoTile(
                        Icons.people_rounded,
                        '${a.playersNeeded} needed',
                        sc,
                      ),
                      const SizedBox(width: 10),
                      _infoTile(
                        Icons.check_circle_rounded,
                        '${a.spotsLeft} left',
                        a.isFull ? kRed : kGreen,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'About this match',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: kTextDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      a.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: kTextMid,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: sc.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: sc.withOpacity(0.15)),
                    ),
                    child: Column(
                      children: [
                        _detailRow(
                          Icons.location_on_rounded,
                          'Venue',
                          a.reservation.courtName,
                          sc,
                        ),
                        Divider(height: 16, color: sc.withOpacity(0.1)),
                        _detailRow(
                          Icons.calendar_today_rounded,
                          'Date',
                          a.reservation.dateLabel,
                          sc,
                        ),
                        Divider(height: 16, color: sc.withOpacity(0.1)),
                        _detailRow(
                          Icons.access_time_rounded,
                          'Time',
                          '${a.reservation.startTime} – ${a.reservation.endTime}',
                          sc,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (a.isFull)
                    Container(
                      height: 50,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: kBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text(
                          'This match is full',
                          style: TextStyle(
                            fontSize: 13,
                            color: kTextMid,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  else if (alreadyRequested)
                    Container(
                      height: 50,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: kPrimary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: kPrimary.withOpacity(0.2)),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.hourglass_top_rounded,
                              size: 15,
                              color: kPrimary,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Request sent — awaiting approval',
                              style: TextStyle(
                                fontSize: 13,
                                color: kPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    PrimaryButton(
                      'Request to Join',
                      color: sc,
                      icon: Icons.send_rounded,
                      onTap: onRequest,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroBg(Color sc) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Color.lerp(sc, Colors.black, 0.4)!, sc],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  );

  Widget _infoTile(IconData icon, String label, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _detailRow(IconData icon, String label, String value, Color color) =>
      Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: kTextMid),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: kTextDark,
            ),
          ),
        ],
      );

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOURNAMENT CARD — poster style
// ─────────────────────────────────────────────────────────────────────────────
class _TournamentCard extends StatelessWidget {
  final TournamentModel tournament;
  final VoidCallback onTap;
  const _TournamentCard({required this.tournament, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = tournament;
    final sc = t.sport.color;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: kCardDeco(20),
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: Image.network(
                    t.posterUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color.lerp(sc, Colors.black, 0.5)!, sc],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.1),
                          Colors.black.withOpacity(0.75),
                        ],
                      ),
                    ),
                  ),
                ),
                // Sport badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: sc,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(t.sport.icon, size: 11, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(
                          t.sport.label,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Prize badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.90),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.emoji_events_rounded,
                          size: 11,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${t.prizePool} DT',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Spots left
                Positioned(
                  bottom: 52,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: t.isFull
                          ? kRed.withOpacity(0.85)
                          : kGreen.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      t.isFull ? 'Full' : '${t.spotsLeft} spots left',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // Title + venue
                Positioned(
                  bottom: 14,
                  left: 14,
                  right: 80,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 11,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            t.venueName,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Row(
                children: [
                  _chip(Icons.calendar_today_rounded, t.dateLabel),
                  const SizedBox(width: 8),
                  _chip(Icons.sports_rounded, t.format),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Entry fee',
                        style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                      ),
                      Text(
                        '${t.entryFee} DT',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: kPrimary,
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

  Widget _chip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: kBg,
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: kTextMid),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: kTextMid,
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TOURNAMENT DETAIL SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _TournamentDetailSheet extends StatelessWidget {
  final TournamentModel tournament;
  final VoidCallback onJoin;
  const _TournamentDetailSheet({
    required this.tournament,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final t = tournament;
    final sc = t.sport.color;
    final bot = MediaQuery.of(context).padding.bottom;
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Color(0x28000000),
              blurRadius: 30,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: Stack(
                children: [
                  SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: Image.network(
                      t.posterUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color.lerp(sc, Colors.black, 0.5)!, sc],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.80),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 28,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.emoji_events_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${t.prizePool} DT Prize',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: sc,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(t.sport.icon, size: 11, color: Colors.white),
                              const SizedBox(width: 5),
                              Text(
                                t.sport.label,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          t.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 12,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${t.venueName}  ·  ${t.location}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
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

            Expanded(
              child: ListView(
                controller: ctrl,
                padding: EdgeInsets.fromLTRB(20, 20, 20, bot + 20),
                children: [
                  Row(
                    children: [
                      _stat(
                        Icons.calendar_today_rounded,
                        t.dateLabel,
                        'Date',
                        sc,
                      ),
                      const SizedBox(width: 10),
                      _stat(Icons.access_time_rounded, t.time, 'Start', sc),
                      const SizedBox(width: 10),
                      _stat(
                        Icons.groups_rounded,
                        '${t.registeredTeams}/${t.maxTeams}',
                        'Teams',
                        sc,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: kBg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Format',
                                style: TextStyle(fontSize: 11, color: kTextMid),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                t.format,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: kTextDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Entry Fee',
                                style: TextStyle(fontSize: 11, color: kTextMid),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${t.entryFee} DT / team',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: kPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'About',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: kTextDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      t.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: kTextMid,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Prizes',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: kTextDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.amber.withOpacity(0.08),
                          Colors.amber.withOpacity(0.03),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.amber.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: t.prizes
                          .map(
                            (p) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Text(
                                    p,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: kTextDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (t.joined)
                    Container(
                      height: 52,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: kGreen.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: kGreen.withOpacity(0.25)),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: kGreen,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'You\'re registered!',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: kGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (t.isFull)
                    Container(
                      height: 52,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: kBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text(
                          'Registration is full',
                          style: TextStyle(
                            fontSize: 13,
                            color: kTextMid,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  else
                    PrimaryButton(
                      'Register — ${t.entryFee} DT',
                      color: sc,
                      icon: Icons.emoji_events_rounded,
                      onTap: onJoin,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(IconData icon, String value, String label, Color color) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(height: 5),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: kTextMid),
              ),
            ],
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// JOIN REQUEST SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _JoinRequestSheet extends StatefulWidget {
  final AnnouncementModel announcement;
  final ValueChanged<String> onSend;
  const _JoinRequestSheet({required this.announcement, required this.onSend});
  @override
  State<_JoinRequestSheet> createState() => _JoinRequestSheetState();
}

class _JoinRequestSheetState extends State<_JoinRequestSheet> {
  final _ctrl = TextEditingController();
  bool _sending = false;
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) widget.onSend(_ctrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.announcement;
    final sc = a.reservation.sport.color;
    final bot = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bot + 16),
      decoration: const BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x28000000),
            blurRadius: 30,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: kTextLight.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: sc.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(a.reservation.sport.icon, color: sc, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.reservation.courtName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: kTextDark,
                        ),
                      ),
                      Text(
                        '${a.reservation.dateLabel}  ·  ${a.reservation.startTime}',
                        style: const TextStyle(fontSize: 11, color: kTextMid),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Host: ${a.host.name.split(' ').first}',
                      style: const TextStyle(fontSize: 11, color: kTextMid),
                    ),
                    Text(
                      '${a.spotsLeft} spot${a.spotsLeft == 1 ? '' : 's'} left',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: sc,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Add a message (optional)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: kTextDark,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: kBg,
              borderRadius: BorderRadius.circular(13),
            ),
            child: TextField(
              controller: _ctrl,
              maxLines: 3,
              style: const TextStyle(fontSize: 13, color: kTextDark),
              decoration: const InputDecoration(
                hintText: 'e.g. Intermediate level, available and ready to go!',
                hintStyle: TextStyle(color: kTextLight, fontSize: 12),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.all(14),
              ),
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            'Send Join Request',
            color: sc,
            icon: Icons.send_rounded,
            onTap: _sending ? null : _send,
            loading: _sending,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFICATION SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _NotificationSheet extends StatefulWidget {
  final List<AnnouncementModel> announcements;
  final VoidCallback onUpdate;
  const _NotificationSheet({
    required this.announcements,
    required this.onUpdate,
  });
  @override
  State<_NotificationSheet> createState() => _NotificationSheetState();
}

class _NotificationSheetState extends State<_NotificationSheet> {
  void _accept(AnnouncementModel ann, JoinRequest req) {
    setState(() => req.status = JoinRequestStatus.accepted);
    widget.onUpdate();
  }

  void _decline(AnnouncementModel ann, JoinRequest req) {
    setState(() => req.status = JoinRequestStatus.declined);
    widget.onUpdate();
  }

  @override
  Widget build(BuildContext context) {
    final bot = MediaQuery.of(context).padding.bottom;
    final allRequests = <({AnnouncementModel ann, JoinRequest req})>[];
    for (final ann in widget.announcements) {
      for (final req in ann.requests) allRequests.add((ann: ann, req: req));
    }
    allRequests.sort((a, b) {
      if (a.req.status == JoinRequestStatus.pending &&
          b.req.status != JoinRequestStatus.pending)
        return -1;
      if (b.req.status == JoinRequestStatus.pending &&
          a.req.status != JoinRequestStatus.pending)
        return 1;
      return 0;
    });
    final pending = allRequests
        .where((r) => r.req.status == JoinRequestStatus.pending)
        .length;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Color(0x28000000),
              blurRadius: 30,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: kTextLight.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: pending > 0 ? kPrimary.withOpacity(0.08) : kBg,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      Icons.notifications_rounded,
                      color: pending > 0 ? kPrimary : kTextMid,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Join Requests',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: kTextDark,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Text(
                          pending > 0
                              ? '$pending pending request${pending == 1 ? '' : 's'}'
                              : 'No pending requests',
                          style: const TextStyle(fontSize: 12, color: kTextMid),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 24, color: Colors.black.withOpacity(0.05)),
            Expanded(
              child: allRequests.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: kPrimary.withOpacity(0.07),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.notifications_off_outlined,
                              size: 28,
                              color: kPrimary.withOpacity(0.4),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No requests yet',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: kTextDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'When players request to join your\nannouncements they appear here',
                            style: TextStyle(fontSize: 12, color: kTextMid),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: ctrl,
                      padding: EdgeInsets.fromLTRB(16, 0, 16, bot + 16),
                      itemCount: allRequests.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final item = allRequests[i];
                        return _RequestTile(
                          ann: item.ann,
                          req: item.req,
                          onAccept: () => _accept(item.ann, item.req),
                          onDecline: () => _decline(item.ann, item.req),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestTile extends StatefulWidget {
  final AnnouncementModel ann;
  final JoinRequest req;
  final VoidCallback onAccept, onDecline;
  const _RequestTile({
    required this.ann,
    required this.req,
    required this.onAccept,
    required this.onDecline,
  });
  @override
  State<_RequestTile> createState() => _RequestTileState();
}

class _RequestTileState extends State<_RequestTile> {
  @override
  Widget build(BuildContext context) {
    final req = widget.req;
    final ann = widget.ann;
    final sc = ann.reservation.sport.color;
    final isPending = req.status == JoinRequestStatus.pending;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isPending ? kCard : kBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending ? kPrimary.withOpacity(0.12) : Colors.transparent,
        ),
        boxShadow: isPending ? kElevation : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarWidget(
                initials: req.player.avatarInitials,
                size: 38,
                bg: sc,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req.player.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: kTextDark,
                      ),
                    ),
                    Text(
                      '${ann.reservation.courtName}  ·  ${ann.reservation.startTime}',
                      style: const TextStyle(fontSize: 11, color: kTextMid),
                    ),
                  ],
                ),
              ),
              if (!isPending)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (req.status == JoinRequestStatus.accepted
                                ? kGreen
                                : kRed)
                            .withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    req.status == JoinRequestStatus.accepted
                        ? 'Accepted'
                        : 'Declined',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: req.status == JoinRequestStatus.accepted
                          ? kGreen
                          : kRed,
                    ),
                  ),
                )
              else
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: kGreen,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          if (req.message.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '"${req.message}"',
                style: const TextStyle(
                  fontSize: 12,
                  color: kTextMid,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ),
          ],
          if (isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: widget.onDecline,
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: kBg,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Center(
                        child: Text(
                          'Decline',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: kTextMid,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: widget.onAccept,
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: kGreen,
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: [
                          BoxShadow(
                            color: kGreen.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 15,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Accept',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SPORT FILTER + SMALL WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _SportFilter extends StatelessWidget {
  final SportType? selected;
  final ValueChanged<SportType?> onSelect;
  const _SportFilter({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 34,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: [
        _pill(null, 'All', Icons.sports_rounded),
        ...SportType.values.map((s) => _pill(s, s.label, s.icon)),
      ],
    ),
  );

  Widget _pill(SportType? sport, String label, IconData icon) {
    final sel = selected == sport;
    final color = sport?.color ?? kPrimary;
    return GestureDetector(
      onTap: () => onSelect(sport),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? color : kBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: sel ? Colors.white : kTextMid),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: sel ? Colors.white : kTextMid,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color? color;
  const _Chip(this.label, {this.color});
  @override
  Widget build(BuildContext context) {
    final c = color ?? kTextMid;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.07),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.campaign_outlined,
            size: 30,
            color: kPrimary.withOpacity(0.45),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'No announcements yet',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: kTextDark,
          ),
        ),
        const SizedBox(height: 5),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Book a court and post an announcement\nto find players',
            style: TextStyle(fontSize: 13, color: kTextMid),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
  );
}

class _EmptyTournaments extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: kAmber.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.emoji_events_outlined,
            size: 30,
            color: kAmber.withOpacity(0.55),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'No tournaments yet',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: kTextDark,
          ),
        ),
        const SizedBox(height: 5),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Venue managers will post upcoming\ntournaments here',
            style: TextStyle(fontSize: 13, color: kTextMid),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
  );
}
