import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Widgets/Lists/avatar_widget.dart';
import 'package:sporta/Widgets/Lists/status_badge.dart';
import 'package:sporta/Widgets/Buttons/primary_button.dart';
import 'package:sporta/Models/app_enums.dart';
import 'package:sporta/Models/app_models.dart';
import 'package:sporta/Models/sample_data.dart';
import 'package:sporta/Views/Player/match_detail_page.dart';

// open_matches_page.dart
// Two flows on one page:
//   1. Browse & join public matches (existing)
//   2. "Create a Match" — player-first: pick sport, date, time → post publicly
//      Court gets assigned when the venue confirms (or auto-matched from available slots)


class OpenMatchesPage extends StatefulWidget {
  const OpenMatchesPage({super.key});
  @override
  State<OpenMatchesPage> createState() => _OpenMatchesPageState();
}

class _OpenMatchesPageState extends State<OpenMatchesPage> {
  SportType? _filter;
  bool _loading = false;
  late List<MatchModel> _matches;

  @override
  void initState() {
    super.initState();
    _matches = _sampleMatches();
  }

  List<MatchModel> _sampleMatches() {
    // ── Courts with photos ────────────────────────────────────────────────
    final resA = CourtReservation(
      id: 'res1',
      courtId: 'c1',
      courtName: 'Arena Sport Center',
      hostId: 'p1',
      sport: SportType.football,
      date: DateTime.now().add(const Duration(days: 1)),
      startTime: '18:00',
      endTime: '19:30',
      durationHours: 1.5,
      totalPrice: 135,
      paymentOption: PaymentOption.payNow,
      courtImageUrl:
          'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=700&q=80',
    );
    final resB = CourtReservation(
      id: 'res2',
      courtId: 'c2',
      courtName: 'Padel Club Marsa',
      hostId: 'p2',
      sport: SportType.padel,
      date: DateTime.now().add(const Duration(days: 1)),
      startTime: '20:00',
      endTime: '21:00',
      durationHours: 1.0,
      totalPrice: 120,
      paymentOption: PaymentOption.payNow,
      courtImageUrl:
          'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=700&q=80',
    );
    final resC = CourtReservation(
      id: 'res3',
      courtId: 'c3',
      courtName: 'Court Gamma',
      hostId: 'p3',
      sport: SportType.tennis,
      date: DateTime.now().add(const Duration(days: 2)),
      startTime: '10:00',
      endTime: '11:30',
      durationHours: 1.5,
      totalPrice: 157.5,
      paymentOption: PaymentOption.payNow,
      courtImageUrl:
          'https://images.unsplash.com/photo-1545809074-59472b3f5ecc?w=700&q=80',
    );
    final resD = CourtReservation(
      id: 'res4',
      courtId: 'c4',
      courtName: 'City Basketball Arena',
      hostId: 'p4',
      sport: SportType.basketball,
      date: DateTime.now().add(const Duration(days: 2)),
      startTime: '19:00',
      endTime: '20:00',
      durationHours: 1.0,
      totalPrice: 75,
      paymentOption: PaymentOption.payAtVenue,
      courtImageUrl:
          'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=700&q=80',
    );
    final resE = CourtReservation(
      id: 'res5',
      courtId: 'c1',
      courtName: 'Arena Sport Center',
      hostId: 'p5',
      sport: SportType.football,
      date: DateTime.now().add(const Duration(days: 3)),
      startTime: '21:00',
      endTime: '22:00',
      durationHours: 1.0,
      totalPrice: 90,
      paymentOption: PaymentOption.payNow,
      courtImageUrl:
          'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=700&q=80',
    );

    return [
      // Football — 3/10 joined, plenty of spots
      MatchModel(
        id: 'm1',
        reservation: resA,
        visibility: MatchVisibility.public,
        matchType: MatchType.team,
        maxPlayers: 10,
        sport: SportType.football,
        description:
            'Friendly 5v5. All levels welcome — just good vibes and a clean game!',
        scheduledDate: resA.date,
        scheduledTime: '18:00',
        players: [
          MatchPlayer(
            player: samplePlayers[0],
            isHost: true,
            hasPaid: true,
            paymentMethod: 'online',
          ),
          MatchPlayer(
            player: samplePlayers[2],
            hasPaid: true,
            paymentMethod: 'online',
          ),
          MatchPlayer(
            player: samplePlayers[4],
            hasPaid: true,
            paymentMethod: 'online',
          ),
        ],
        status: MatchStatus.open,
      ),

      // Padel doubles — 2/4, need 2 more
      MatchModel(
        id: 'm2',
        reservation: resB,
        visibility: MatchVisibility.public,
        matchType: MatchType.doubles,
        maxPlayers: 4,
        sport: SportType.padel,
        description:
            'Competitive padel doubles. Intermediate level preferred — come ready to sweat!',
        scheduledDate: resB.date,
        scheduledTime: '20:00',
        players: [
          MatchPlayer(
            player: samplePlayers[1],
            isHost: true,
            hasPaid: true,
            paymentMethod: 'online',
          ),
          MatchPlayer(
            player: samplePlayers[3],
            hasPaid: true,
            paymentMethod: 'online',
          ),
        ],
        status: MatchStatus.halfFull,
      ),

      // Tennis singles — no court yet, player-first
      MatchModel(
        id: 'm3',
        reservation: null,
        visibility: MatchVisibility.public,
        matchType: MatchType.singles,
        maxPlayers: 2,
        sport: SportType.tennis,
        description:
            'Looking for a tennis partner for a casual hit. All levels welcome, just bring good energy.',
        scheduledDate: DateTime.now().add(const Duration(days: 2)),
        scheduledTime: '09:00',
        players: [
          MatchPlayer(player: samplePlayers[3], isHost: true, hasPaid: false),
        ],
        status: MatchStatus.open,
      ),

      // Tennis doubles — 1/4
      MatchModel(
        id: 'm4',
        reservation: resC,
        visibility: MatchVisibility.public,
        matchType: MatchType.doubles,
        maxPlayers: 4,
        sport: SportType.tennis,
        description:
            'Doubles tennis session at Court Gamma. Bring a partner or join solo — we\'ll pair you up!',
        scheduledDate: resC.date,
        scheduledTime: '10:00',
        players: [
          MatchPlayer(
            player: samplePlayers[5],
            isHost: true,
            hasPaid: true,
            paymentMethod: 'online',
          ),
        ],
        status: MatchStatus.open,
      ),

      // Basketball — 4/10, half full
      MatchModel(
        id: 'm5',
        reservation: resD,
        visibility: MatchVisibility.public,
        matchType: MatchType.team,
        maxPlayers: 10,
        sport: SportType.basketball,
        description:
            '5v5 street-style basketball. Casual but competitive — ballers of all ages welcome.',
        scheduledDate: resD.date,
        scheduledTime: '19:00',
        players: [
          MatchPlayer(
            player: samplePlayers[4],
            isHost: true,
            hasPaid: false,
            paymentMethod: 'venue',
          ),
          MatchPlayer(
            player: samplePlayers[0],
            hasPaid: false,
            paymentMethod: 'venue',
          ),
          MatchPlayer(
            player: samplePlayers[2],
            hasPaid: false,
            paymentMethod: 'venue',
          ),
          MatchPlayer(
            player: samplePlayers[1],
            hasPaid: false,
            paymentMethod: 'venue',
          ),
        ],
        status: MatchStatus.halfFull,
      ),

      // Football — no court yet, player-first, evening
      MatchModel(
        id: 'm6',
        reservation: null,
        visibility: MatchVisibility.public,
        matchType: MatchType.team,
        maxPlayers: 6,
        sport: SportType.football,
        description:
            '3v3 quick football session. Looking for 4 more players — location to be confirmed.',
        scheduledDate: DateTime.now().add(const Duration(days: 3)),
        scheduledTime: '20:00',
        players: [
          MatchPlayer(player: samplePlayers[2], isHost: true, hasPaid: false),
        ],
        status: MatchStatus.open,
      ),

      // Football evening — 8/10, almost full
      MatchModel(
        id: 'm7',
        reservation: resE,
        visibility: MatchVisibility.public,
        matchType: MatchType.team,
        maxPlayers: 10,
        sport: SportType.football,
        description:
            'Last 2 spots! Competitive 5v5 — intermediate to advanced level. Court secured.',
        scheduledDate: resE.date,
        scheduledTime: '21:00',
        players: [
          MatchPlayer(
            player: samplePlayers[1],
            isHost: true,
            hasPaid: true,
            paymentMethod: 'online',
          ),
          MatchPlayer(
            player: samplePlayers[2],
            hasPaid: true,
            paymentMethod: 'online',
          ),
          MatchPlayer(
            player: samplePlayers[3],
            hasPaid: true,
            paymentMethod: 'online',
          ),
          MatchPlayer(
            player: samplePlayers[4],
            hasPaid: true,
            paymentMethod: 'online',
          ),
          MatchPlayer(
            player: samplePlayers[5],
            hasPaid: true,
            paymentMethod: 'online',
          ),
          MatchPlayer(
            player: samplePlayers[0],
            hasPaid: true,
            paymentMethod: 'online',
          ),
          MatchPlayer(
            player: samplePlayers[2],
            hasPaid: true,
            paymentMethod: 'online',
          ),
          MatchPlayer(
            player: samplePlayers[3],
            hasPaid: true,
            paymentMethod: 'online',
          ),
        ],
        status: MatchStatus.halfFull,
      ),
    ];
  }

  List<MatchModel> get _filtered =>
      _matches.where((m) => _filter == null || m.sport == _filter).toList();

  void _openCreateMatch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateMatchSheet(
        onCreated: (match) {
          setState(() => _matches.insert(0, match));
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MatchDetailPage(match: match, isHost: true),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navH =
        kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          Container(
            color: kCard,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 16, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Open Matches',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: kTextDark,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              Text(
                                '${_filtered.length} available near you',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: kTextMid,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Create match (player-first)
                        GestureDetector(
                          onTap: _openCreateMatch,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: kPrimary,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: kPrimary.withOpacity(0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Create Match',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Sport filter
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _SportFilter(
                      selected: _filter,
                      onSelect: (s) => setState(() => _filter = s),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Body ───────────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: kPrimary),
                  )
                : _filtered.isEmpty
                ? const _Empty()
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, navH + 16),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final m = _filtered[i];
                      return _MatchCard(
                        match: m,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                MatchDetailPage(match: m, isHost: false),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CREATE MATCH SHEET — player-first flow
// Sport → Date → Time → Player count → Post publicly
// Court assigned later by venue / auto-matching
// ─────────────────────────────────────────────────────────────────────────────
class _CreateMatchSheet extends StatefulWidget {
  final ValueChanged<MatchModel> onCreated;
  const _CreateMatchSheet({required this.onCreated});
  @override
  State<_CreateMatchSheet> createState() => _CreateMatchSheetState();
}

class _CreateMatchSheetState extends State<_CreateMatchSheet> {
  SportType _sport = SportType.football;
  MatchType _type = MatchType.doubles;
  int _players = 4;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  String? _time;
  bool _posting = false;
  final _descCtrl = TextEditingController();

  final _times = [
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
    '19:00',
    '20:00',
    '21:00',
  ];

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  bool get _canPost => _time != null;

  Future<void> _post() async {
    setState(() => _posting = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    final match = MatchModel(
      id: 'match_${DateTime.now().millisecondsSinceEpoch}',
      reservation: null, // no court yet
      visibility: MatchVisibility.public,
      matchType: _type,
      maxPlayers: _players,
      sport: _sport,
      description: _descCtrl.text.isNotEmpty
          ? _descCtrl.text
          : 'Looking for players — join us!',
      scheduledDate: _date,
      scheduledTime: _time!,
      players: [MatchPlayer(player: samplePlayers.first, isHost: true)],
      status: MatchStatus.open,
    );
    widget.onCreated(match);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final p = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: kPrimary,
            onPrimary: Colors.white,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: kPrimary),
          ),
        ),
        child: child!,
      ),
    );
    if (p != null)
      setState(() {
        _date = p;
        _time = null;
      });
  }

  String get _dateLabel {
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
    return '${days[_date.weekday - 1]}, ${_date.day} ${months[_date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final bot = MediaQuery.of(context).padding.bottom;
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
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
            // handle
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
            // title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.group_add_rounded,
                      color: kPrimary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create a Match',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: kTextDark,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Text(
                          "Post publicly — players join you",
                          style: TextStyle(fontSize: 12, color: kTextMid),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Divider(color: Colors.black.withOpacity(0.05)),

            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                children: [
                  // ── Sport ──────────────────────────────────────────────────
                  const _SheetLabel('Sport'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: SportType.values.map((s) {
                      final sel = s == _sport;
                      return GestureDetector(
                        onTap: () => setState(() => _sport = s),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: sel ? s.color.withOpacity(0.1) : kBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: sel
                                  ? s.color.withOpacity(0.4)
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                s.icon,
                                size: 14,
                                color: sel ? s.color : kTextMid,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                s.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: sel ? s.color : kTextMid,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // ── Match type ─────────────────────────────────────────────
                  const _SheetLabel('Format'),
                  const SizedBox(height: 10),
                  Row(
                    children: MatchType.values.map((t) {
                      final sel = t == _type;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _type = t;
                            _players = t.defaultPlayers;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            margin: EdgeInsets.only(
                              right: t != MatchType.team ? 8 : 0,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: sel ? kPrimary : kBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                t.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: sel ? Colors.white : kTextMid,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // ── Players ────────────────────────────────────────────────
                  Row(
                    children: [
                      const Expanded(child: _SheetLabel('Players needed')),
                      Row(
                        children: [
                          _StepBtn(
                            icon: Icons.remove_rounded,
                            fn: () {
                              if (_players > 2) setState(() => _players--);
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              '$_players',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: kTextDark,
                              ),
                            ),
                          ),
                          _StepBtn(
                            icon: Icons.add_rounded,
                            fn: () {
                              if (_players < 22) setState(() => _players++);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Date ──────────────────────────────────────────────────
                  const _SheetLabel('Date'),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: kBg,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: kPrimary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _dateLabel,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: kTextDark,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: kTextLight,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Time ──────────────────────────────────────────────────
                  const _SheetLabel('Preferred time'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _times.map((t) {
                      final sel = t == _time;
                      return GestureDetector(
                        onTap: () => setState(() => _time = t),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: sel ? kPrimary : kBg,
                            borderRadius: BorderRadius.circular(11),
                            boxShadow: sel
                                ? [
                                    BoxShadow(
                                      color: kPrimary.withOpacity(0.2),
                                      blurRadius: 6,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Text(
                            t,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: sel ? Colors.white : kTextDark,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // ── Description ────────────────────────────────────────────
                  const _SheetLabel('Description (optional)'),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: kBg,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: TextField(
                      controller: _descCtrl,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 13, color: kTextDark),
                      decoration: const InputDecoration(
                        hintText: 'e.g. Friendly game, all levels welcome…',
                        hintStyle: TextStyle(color: kTextLight, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.all(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── No court note ──────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: kAmber.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kAmber.withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 15,
                          color: kAmber,
                        ),
                        const SizedBox(width: 9),
                        const Expanded(
                          child: Text(
                            'No court booking needed now. Once your match fills up, we\'ll help you secure a court — or you can book one separately.',
                            style: TextStyle(
                              fontSize: 11,
                              color: kTextMid,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Post button ────────────────────────────────────────────
                  PrimaryButton(
                    _canPost
                        ? 'Post Match Publicly'
                        : 'Pick a time to continue',
                    color: kPrimary,
                    icon: Icons.public_rounded,
                    onTap: _canPost ? _post : null,
                    loading: _posting,
                  ),

                  SizedBox(height: bot + 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback fn;
  const _StepBtn({required this.icon, required this.fn});
  @override
  State<_StepBtn> createState() => _StepBtnState();
}

class _StepBtnState extends State<_StepBtn> {
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: widget.fn,
    child: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: kPrimary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(widget.icon, size: 17, color: kPrimary),
    ),
  );
}

class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: kTextDark,
      letterSpacing: -0.2,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// MATCH CARD
// ─────────────────────────────────────────────────────────────────────────────
class _MatchCard extends StatefulWidget {
  final MatchModel match;
  final VoidCallback onTap;
  const _MatchCard({required this.match, required this.onTap});
  @override
  State<_MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<_MatchCard> {
  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    final sc = m.sport.color;
    final live = m.computeStatus();
    final imgUrl = m.hasCourt ? m.reservation!.courtImageUrl : null;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: kCardDeco(18),
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: [
            // ── Court photo banner ──────────────────────────────────────
            Stack(
              children: [
                SizedBox(
                  height: 110,
                  width: double.infinity,
                  child: imgUrl != null
                      ? Image.network(
                          imgUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _gradientBg(sc),
                        )
                      : _gradientBg(sc),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.65),
                        ],
                      ),
                    ),
                  ),
                ),
                // Top: status badge or "no court" chip
                Positioned(
                  top: 10,
                  right: 12,
                  child: m.hasCourt
                      ? StatusBadge(label: live.label, color: Colors.white)
                      : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: kAmber.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_searching_rounded,
                                size: 9,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'No court yet',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                // Bottom: sport icon + court/match name + date
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
                          m.sport.icon,
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
                              m.hasCourt
                                  ? m.reservation!.courtName
                                  : '${m.sport.label} Match',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              m.hasCourt
                                  ? '${m.reservation!.dateLabel}  ·  ${m.reservation!.startTime}–${m.reservation!.endTime}'
                                  : '${_dateLabel(m.scheduledDate)}  ·  ${m.scheduledTime}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 10,
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

            // Body
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _chip(
                        Icons.access_time_rounded,
                        m.hasCourt
                            ? '${m.reservation!.startTime}–${m.reservation!.endTime}'
                            : m.scheduledTime,
                      ),
                      const SizedBox(width: 6),
                      _chip(
                        Icons.format_list_bulleted_rounded,
                        m.matchType.label,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    m.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: kTextMid,
                      height: 1.45,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _AvatarStack(players: m.players),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${m.joinedCount}/${m.maxPlayers} joined',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: sc,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: m.fillRatio,
                                minHeight: 4,
                                backgroundColor: sc.withOpacity(0.08),
                                valueColor: AlwaysStoppedAnimation(sc),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (m.hasCourt) ...[
                            Text(
                              '${m.pricePerPlayer.toStringAsFixed(2)} DT',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: sc,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const Text(
                              'per player',
                              style: TextStyle(fontSize: 9, color: kTextMid),
                            ),
                            const SizedBox(height: 6),
                          ] else ...[
                            const Text(
                              'Free to join',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: kAmber,
                              ),
                            ),
                            const Text(
                              'no court yet',
                              style: TextStyle(fontSize: 9, color: kTextMid),
                            ),
                            const SizedBox(height: 6),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: m.isFull ? kBg : sc,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: m.isFull
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: sc.withOpacity(0.2),
                                        blurRadius: 6,
                                      ),
                                    ],
                            ),
                            child: Text(
                              m.isFull ? 'Full' : 'Join',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: m.isFull ? kTextMid : Colors.white,
                              ),
                            ),
                          ),
                        ],
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
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: kTextMid.withOpacity(0.07),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: kTextMid),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: kTextMid,
          ),
        ),
      ],
    ),
  );

  Widget _gradientBg(Color sc) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Color.lerp(sc, Colors.black, 0.38)!, sc],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  );

  String _dateLabel(DateTime d) {
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
}

class _AvatarStack extends StatefulWidget {
  final List<MatchPlayer> players;
  const _AvatarStack({required this.players});
  @override
  State<_AvatarStack> createState() => _AvatarStackState();
}

class _AvatarStackState extends State<_AvatarStack> {
  @override
  Widget build(BuildContext context) {
    final show = widget.players.take(3).toList();
    return SizedBox(
      width: show.length * 18.0 + 12,
      height: 28,
      child: Stack(
        children: show
            .asMap()
            .entries
            .map(
              (e) => Positioned(
                left: e.key * 18.0,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: kCard, width: 1.5),
                  ),
                  child: AvatarWidget(
                    initials: e.value.player.avatarInitials,
                    size: 26,
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

class _SportFilter extends StatefulWidget {
  final SportType? selected;
  final ValueChanged<SportType?> onSelect;
  const _SportFilter({required this.selected, required this.onSelect});
  @override
  State<_SportFilter> createState() => _SportFilterState();
}

class _SportFilterState extends State<_SportFilter> {
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 32,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: [
        _pill(null, 'All'),
        ...SportType.values.map((s) => _pill(s, s.label)),
      ],
    ),
  );

  Widget _pill(SportType? s, String label) {
    final sel = widget.selected == s;
    final color = s?.color ?? kPrimary;
    return GestureDetector(
      onTap: () => widget.onSelect(s),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: sel ? color : kBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: sel ? Colors.white : kTextMid,
            ),
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatefulWidget {
  const _Empty();
  @override
  State<_Empty> createState() => _EmptyState();
}

class _EmptyState extends State<_Empty> {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.search_off_rounded,
            color: kPrimary,
            size: 26,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'No matches found',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: kTextDark,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Try different filters or create a match',
          style: TextStyle(fontSize: 12, color: kTextMid),
        ),
      ],
    ),
  );
}
