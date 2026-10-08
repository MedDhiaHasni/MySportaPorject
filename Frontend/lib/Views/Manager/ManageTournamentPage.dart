/*// manage_tournament_page.dart — Views/Manager/manage_tournament_page.dart
// Uses TournamentModel (shared with player side) → no TournamentData dependency
// Tabs: Overview · Teams · Matches

import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Models/app_enums.dart';
import 'package:sporta/Views/Player/matches_page.dart' show TournamentModel;

// ─────────────────────────────────────────────────────────────────────────────
// LOCAL MODELS — tournament_registrations + matches tables
// ─────────────────────────────────────────────────────────────────────────────

/// Maps to tournament_registrations table
class TournamentTeam {
  final String id, name, captain, avatarUrl;
  final int players;
  bool paidEntry;
  TournamentTeam({
    required this.id,
    required this.name,
    required this.captain,
    required this.avatarUrl,
    required this.players,
    this.paidEntry = false,
  });
}

/// Maps to a future tournament_matches table
class TournamentMatch {
  final String id, teamA, teamB;
  String scoreA, scoreB;
  bool isPlayed;
  TournamentMatch({
    required this.id,
    required this.teamA,
    required this.teamB,
    this.scoreA = '',
    this.scoreB = '',
    this.isPlayed = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────────────────────
class ManageTournamentPage extends StatefulWidget {
  final TournamentModel tournament;
  const ManageTournamentPage({super.key, required this.tournament});
  @override
  State<ManageTournamentPage> createState() => _ManageTournamentPageState();
}

class _ManageTournamentPageState extends State<ManageTournamentPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  late TournamentModel _t;

  final List<TournamentTeam> _teams = [
    TournamentTeam(
      id: 'tm1',
      name: 'FC Lions',
      captain: 'Karim Jaziri',
      avatarUrl: 'https://i.pravatar.cc/150?img=1',
      players: 6,
      paidEntry: true,
    ),
    TournamentTeam(
      id: 'tm2',
      name: 'Coastal Wolves',
      captain: 'Nadia Ben Salah',
      avatarUrl: 'https://i.pravatar.cc/150?img=2',
      players: 5,
      paidEntry: true,
    ),
    TournamentTeam(
      id: 'tm3',
      name: 'Sky Eagles',
      captain: 'Mehdi Trabelsi',
      avatarUrl: 'https://i.pravatar.cc/150?img=3',
      players: 6,
      paidEntry: false,
    ),
    TournamentTeam(
      id: 'tm4',
      name: 'Red Storm',
      captain: 'Leila Mallouli',
      avatarUrl: 'https://i.pravatar.cc/150?img=4',
      players: 5,
      paidEntry: true,
    ),
    TournamentTeam(
      id: 'tm5',
      name: 'Green Blazers',
      captain: 'Ahmed Ben Ali',
      avatarUrl: 'https://i.pravatar.cc/150?img=5',
      players: 6,
      paidEntry: true,
    ),
    TournamentTeam(
      id: 'tm6',
      name: 'Night Hawks',
      captain: 'Sara Mzali',
      avatarUrl: 'https://i.pravatar.cc/150?img=6',
      players: 5,
      paidEntry: false,
    ),
  ];

  final List<TournamentMatch> _matches = [
    TournamentMatch(
      id: 'm1',
      teamA: 'FC Lions',
      teamB: 'Coastal Wolves',
      scoreA: '2',
      scoreB: '1',
      isPlayed: true,
    ),
    TournamentMatch(
      id: 'm2',
      teamA: 'Sky Eagles',
      teamB: 'Red Storm',
      isPlayed: false,
    ),
    TournamentMatch(
      id: 'm3',
      teamA: 'Green Blazers',
      teamB: 'Night Hawks',
      isPlayed: false,
    ),
    TournamentMatch(
      id: 'm4',
      teamA: 'FC Lions',
      teamB: 'Sky Eagles',
      isPlayed: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _t = widget.tournament;
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Color get _sc => _t.sport.color;
  int get _paidCount => _teams.where((t) => t.paidEntry).length;
  int get _playedCount => _matches.where((m) => m.isPlayed).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [_buildHero()],
        body: Column(
          children: [
            // Tab bar
            Container(
              color: kCard,
              child: TabBar(
                controller: _tabs,
                indicatorColor: _sc,
                indicatorWeight: 3,
                labelColor: _sc,
                unselectedLabelColor: kTextMid,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Teams'),
                  Tab(text: 'Matches'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _OverviewTab(
                    tournament: _t,
                    teams: _teams,
                    matches: _matches,
                    paidCount: _paidCount,
                    onEdit: () => _showEditSheet(),
                  ),
                  _TeamsTab(
                    teams: _teams,
                    entryFee: _t.entryFee,
                    sc: _sc,
                    onTogglePaid: (id) => setState(() {
                      final i = _teams.indexWhere((t) => t.id == id);
                      if (i != -1) _teams[i].paidEntry = !_teams[i].paidEntry;
                    }),
                  ),
                  _MatchesTab(
                    matches: _matches,
                    sc: _sc,
                    onEnterScore: (match) => _showScoreSheet(match),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero ────────────────────────────────────────────────────────────────────
  Widget _buildHero() => SliverAppBar(
    expandedHeight: 240,
    pinned: true,
    backgroundColor: _sc,
    leading: GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.25),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.arrow_back_ios_rounded,
          color: Colors.white,
          size: 16,
        ),
      ),
    ),
    flexibleSpace: FlexibleSpaceBar(
      collapseMode: CollapseMode.parallax,
      background: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _t.posterUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color.lerp(_sc, Colors.black, 0.4)!, _sc],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Container(
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
          // Sport + spots badges
          Positioned(
            top: 56,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _sc,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_t.sport.icon, size: 11, color: Colors.white),
                  const SizedBox(width: 5),
                  Text(
                    _t.sport.label,
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
            top: 56,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _t.isFull
                    ? kRed.withOpacity(0.9)
                    : kGreen.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _t.isFull ? 'Full' : '${_t.spotsLeft} spots left',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // Title block
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _HeroBadge(Icons.calendar_today_rounded, _t.dateLabel),
                    const SizedBox(width: 10),
                    _HeroBadge(Icons.access_time_rounded, _t.time),
                    const SizedBox(width: 10),
                    _HeroBadge(
                      Icons.groups_rounded,
                      '${_t.registeredTeams}/${_t.maxTeams} teams',
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

  // ── Edit sheet ───────────────────────────────────────────────────────────────
  void _showEditSheet() {
    final titleCtrl = TextEditingController(text: _t.title);
    final descCtrl = TextEditingController(text: _t.description);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              const SizedBox(height: 18),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Edit Tournament',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: kTextDark,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _InputField(
                ctrl: titleCtrl,
                label: 'Tournament Name',
                hint: 'e.g. Summer Padel Cup',
              ),
              const SizedBox(height: 12),
              _InputField(
                ctrl: descCtrl,
                label: 'Description',
                hint: 'Describe the tournament...',
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              _ActionBtn(
                'Save Changes',
                _sc,
                Icons.check_rounded,
                () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Score sheet ──────────────────────────────────────────────────────────────
  void _showScoreSheet(TournamentMatch match) {
    final aCtrl = TextEditingController(text: match.scoreA);
    final bCtrl = TextEditingController(text: match.scoreB);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              const SizedBox(height: 18),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Enter Score',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: kTextDark,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          match.teamA,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: kTextDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _ScoreInput(ctrl: aCtrl),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'vs',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _sc,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          match.teamB,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: kTextDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _ScoreInput(ctrl: bCtrl),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _ActionBtn('Save Score', _sc, Icons.sports_score_rounded, () {
                setState(() {
                  match.scoreA = aCtrl.text;
                  match.scoreB = bCtrl.text;
                  match.isPlayed =
                      aCtrl.text.isNotEmpty && bCtrl.text.isNotEmpty;
                });
                Navigator.pop(context);
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OVERVIEW TAB
// ─────────────────────────────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final TournamentModel tournament;
  final List<TournamentTeam> teams;
  final List<TournamentMatch> matches;
  final int paidCount;
  final VoidCallback onEdit;
  const _OverviewTab({
    required this.tournament,
    required this.teams,
    required this.matches,
    required this.paidCount,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final t = tournament;
    final sc = t.sport.color;
    final playedCount = matches.where((m) => m.isPlayed).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      children: [
        // ── Quick stats ────────────────────────────────────────────────────
        Row(
          children: [
            _StatCard(
              Icons.groups_rounded,
              '${t.registeredTeams}/${t.maxTeams}',
              'Teams',
              sc,
            ),
            const SizedBox(width: 10),
            _StatCard(
              Icons.sports_score_rounded,
              '$playedCount/${matches.length}',
              'Matches',
              sc,
            ),
            const SizedBox(width: 10),
            _StatCard(
              Icons.payments_rounded,
              '$paidCount/${teams.length}',
              'Paid',
              sc,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ── Info card ──────────────────────────────────────────────────────
        _InfoCard(
          children: [
            _InfoRow(Icons.calendar_today_rounded, 'Date', t.dateLabel, sc),
            _divider(),
            _InfoRow(Icons.access_time_rounded, 'Time', t.time, sc),
            _divider(),
            _InfoRow(Icons.sports_rounded, 'Format', t.format, sc),
            _divider(),
            _InfoRow(Icons.location_on_rounded, 'Venue', t.venueName, sc),
            _divider(),
            _InfoRow(
              Icons.payments_outlined,
              'Entry Fee',
              '${t.entryFee} DT',
              sc,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Prize pool ─────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(16),
            boxShadow: kElevation,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.emoji_events_rounded, size: 16, color: kAmber),
                  const SizedBox(width: 8),
                  const Text(
                    'Prize Pool',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: kTextDark,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${t.prizePool} DT total',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: sc,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...t.prizes.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Text(
                        p.split(':').first,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        p.split(':').last.trim(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: kTextDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Description ─────────────────────────────────────────────────────
        _InfoCard(
          children: [
            Row(
              children: [
                Icon(Icons.description_rounded, size: 15, color: sc),
                const SizedBox(width: 8),
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: kTextDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              t.description,
              style: const TextStyle(
                fontSize: 13,
                color: kTextMid,
                height: 1.55,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ── Edit button ─────────────────────────────────────────────────────
        _ActionBtn('Edit Tournament', sc, Icons.edit_rounded, onEdit),
      ],
    );
  }

  Widget _divider() => Divider(height: 1, color: kBg, indent: 0, endIndent: 0);
}

// ─────────────────────────────────────────────────────────────────────────────
// TEAMS TAB
// ─────────────────────────────────────────────────────────────────────────────
class _TeamsTab extends StatelessWidget {
  final List<TournamentTeam> teams;
  final int entryFee;
  final Color sc;
  final ValueChanged<String> onTogglePaid;
  const _TeamsTab({
    required this.teams,
    required this.entryFee,
    required this.sc,
    required this.onTogglePaid,
  });

  @override
  Widget build(BuildContext context) {
    final paidCount = teams.where((t) => t.paidEntry).length;
    final revenue = paidCount * entryFee;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      children: [
        // Revenue summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: sc.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: sc.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: sc.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: sc,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Entry Revenue',
                      style: TextStyle(fontSize: 11, color: kTextMid),
                    ),
                    Text(
                      '$revenue DT collected',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: kTextDark,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: sc,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$paidCount/${teams.length} paid',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Teams list
        ...teams.map(
          (team) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(14),
              boxShadow: kElevation,
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [sc, sc.withOpacity(0.6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        team.name.split(' ').map((e) => e[0]).take(2).join(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
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
                          team.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: kTextDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline_rounded,
                              size: 11,
                              color: kTextLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              team.captain,
                              style: const TextStyle(
                                fontSize: 11,
                                color: kTextMid,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.group_outlined,
                              size: 11,
                              color: kTextLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${team.players} players',
                              style: const TextStyle(
                                fontSize: 11,
                                color: kTextMid,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Paid toggle
                  GestureDetector(
                    onTap: () => onTogglePaid(team.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: team.paidEntry
                            ? kGreen.withOpacity(0.1)
                            : kAmber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: team.paidEntry
                              ? kGreen.withOpacity(0.4)
                              : kAmber.withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            team.paidEntry
                                ? Icons.check_circle_rounded
                                : Icons.hourglass_top_rounded,
                            size: 11,
                            color: team.paidEntry ? kGreen : kAmber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            team.paidEntry ? 'Paid' : 'Pending',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: team.paidEntry ? kGreen : kAmber,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MATCHES TAB
// ─────────────────────────────────────────────────────────────────────────────
class _MatchesTab extends StatelessWidget {
  final List<TournamentMatch> matches;
  final Color sc;
  final ValueChanged<TournamentMatch> onEnterScore;
  const _MatchesTab({
    required this.matches,
    required this.sc,
    required this.onEnterScore,
  });

  @override
  Widget build(BuildContext context) {
    final played = matches.where((m) => m.isPlayed).toList();
    final pending = matches.where((m) => !m.isPlayed).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      children: [
        if (pending.isNotEmpty) ...[
          _MatchSectionHeader('Upcoming', Icons.schedule_rounded, kAmber),
          const SizedBox(height: 10),
          ...pending.map(
            (m) => _MatchTile(match: m, sc: sc, onTap: () => onEnterScore(m)),
          ),
          const SizedBox(height: 20),
        ],
        if (played.isNotEmpty) ...[
          _MatchSectionHeader('Played', Icons.sports_score_rounded, kGreen),
          const SizedBox(height: 10),
          ...played.map(
            (m) => _MatchTile(match: m, sc: sc, onTap: () => onEnterScore(m)),
          ),
        ],
        if (matches.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Column(
                children: [
                  Icon(
                    Icons.sports_rounded,
                    size: 48,
                    color: kTextLight.withOpacity(0.4),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No matches yet',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: kTextDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Generate the bracket to get started',
                    style: TextStyle(fontSize: 12, color: kTextMid),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _MatchSectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _MatchSectionHeader(this.label, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 6),
      Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    ],
  );
}

class _MatchTile extends StatelessWidget {
  final TournamentMatch match;
  final Color sc;
  final VoidCallback onTap;
  const _MatchTile({
    required this.match,
    required this.sc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: kElevation,
        border: !match.isPlayed
            ? Border.all(color: kAmber.withOpacity(0.25))
            : null,
      ),
      child: Row(
        children: [
          // Team A
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.teamA,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kTextDark,
                  ),
                ),
                if (match.isPlayed && match.scoreA.isNotEmpty)
                  Text(
                    match.scoreA,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: sc,
                    ),
                  ),
              ],
            ),
          ),
          // VS / scores
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: match.isPlayed
                  ? sc.withOpacity(0.08)
                  : kAmber.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              match.isPlayed ? 'FT' : 'vs',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: match.isPlayed ? sc : kAmber,
              ),
            ),
          ),
          // Team B
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  match.teamB,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kTextDark,
                  ),
                ),
                if (match.isPlayed && match.scoreB.isNotEmpty)
                  Text(
                    match.scoreB,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: sc,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            match.isPlayed
                ? Icons.edit_rounded
                : Icons.add_circle_outline_rounded,
            size: 16,
            color: match.isPlayed ? kTextLight : kAmber,
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED MICRO WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeroBadge(this.icon, this.label);
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 11, color: Colors.white70),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    ],
  );
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;
  const _StatCard(this.icon, this.value, this.label, this.color);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: kElevation,
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 10, color: kTextMid)),
        ],
      ),
    ),
  );
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: kCard,
      borderRadius: BorderRadius.circular(16),
      boxShadow: kElevation,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _InfoRow(this.icon, this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 11),
    child: Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 13, color: kTextMid)),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: kTextDark,
          ),
        ),
      ],
    ),
  );
}

class _InputField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final int maxLines;
  const _InputField({
    required this.ctrl,
    required this.label,
    required this.hint,
    this.maxLines = 1,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: kTextDark,
        ),
      ),
      const SizedBox(height: 6),
      Container(
        decoration: BoxDecoration(
          color: kBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: ctrl,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13, color: kTextDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: kTextLight, fontSize: 12),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(14),
            isDense: true,
          ),
        ),
      ),
    ],
  );
}

class _ScoreInput extends StatelessWidget {
  final TextEditingController ctrl;
  const _ScoreInput({required this.ctrl});
  @override
  Widget build(BuildContext context) => Container(
    height: 64,
    decoration: BoxDecoration(
      color: kBg,
      borderRadius: BorderRadius.circular(14),
    ),
    child: TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w900,
        color: kTextDark,
      ),
      decoration: const InputDecoration(
        border: InputBorder.none,
        hintText: '0',
        hintStyle: TextStyle(fontSize: 28, color: kTextLight),
        contentPadding: EdgeInsets.zero,
        isDense: true,
      ),
    ),
  );
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionBtn(this.label, this.color, this.icon, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 52,
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}*/
