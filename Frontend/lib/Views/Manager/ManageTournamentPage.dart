// manage_tournament_page.dart — Views/Manager/manage_tournament_page.dart
// Full tournament management: overview, teams, matches, settings

import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Models/app_enums.dart';
import 'package:sporta/Views/Manager/dashboard.dart' show TournamentData;

// ─────────────────────────────────────────────────────────────────────────────
// MANAGE TOURNAMENT PAGE
// ─────────────────────────────────────────────────────────────────────────────
class ManageTournamentPage extends StatefulWidget {
  final TournamentData tournament;
  const ManageTournamentPage({super.key, required this.tournament});
  @override
  State<ManageTournamentPage> createState() => _ManageTournamentPageState();
}

class _ManageTournamentPageState extends State<ManageTournamentPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  late TournamentData _t;

  // Sample teams - Updated to include captain name
  final List<_Team> _teams = [
    _Team('FC Lions', 'Karim Jaziri', true, 'https://i.pravatar.cc/150?img=1'),
    _Team(
      'Coastal Wolves',
      'Nadia Ben Salah',
      true,
      'https://i.pravatar.cc/150?img=2',
    ),
    _Team(
      'Sky Eagles',
      'Mehdi Trabelsi',
      false,
      'https://i.pravatar.cc/150?img=3',
    ),
    _Team(
      'Red Storm',
      'Leila Mallouli',
      true,
      'https://i.pravatar.cc/150?img=4',
    ),
    _Team(
      'Green Blazers',
      'Ahmed Ben Ali',
      true,
      'https://i.pravatar.cc/150?img=5',
    ),
    _Team(
      'Night Hawks',
      'Sami Khelif',
      false,
      'https://i.pravatar.cc/150?img=6',
    ),
  ];

  // Sample matches
  final List<_Match> _matches = [
    _Match('FC Lions', 'Coastal Wolves', '2', '1', true),
    _Match('Sky Eagles', 'Red Storm', '', '', false),
    _Match('Green Blazers', 'Night Hawks', '', '', false),
    _Match('FC Lions', 'Sky Eagles', '', '', false),
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

  @override
  Widget build(BuildContext context) {
    final navH =
        kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: kBg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(child: _buildHero()),
        ],
        body: Column(
          children: [
            // Tab bar
            Container(
              color: kCard,
              child: TabBar(
                controller: _tabs,
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
                indicatorColor: _sc,
                indicatorWeight: 3,
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
                    sportColor: _sc,
                    onStatusChanged: () => setState(() {}),
                  ),
                  _TeamsTab(teams: _teams, sportColor: _sc),
                  _MatchesTab(
                    matches: _matches,
                    sportColor: _sc,
                    onUpdate: (i, h, a) => setState(() {
                      _matches[i] = _Match(
                        _matches[i].home,
                        _matches[i].away,
                        h,
                        a,
                        true,
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Stack(
      children: [
        // Poster
        SizedBox(
          height: 260,
          width: double.infinity,
          child: Image.network(
            _t.posterUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color.lerp(_sc, Colors.black, 0.5)!, _sc],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
        ),

        // Gradient
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.80),
                ],
              ),
            ),
          ),
        ),

        // Back button
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showDeleteConfirm(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: kRed.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Content
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sport + status row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
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
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _t.isFull
                          ? kRed.withOpacity(0.85)
                          : kGreen.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _t.isFull ? 'Full' : '${_t.spotsLeft} spots',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Name
              Text(
                _t.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 8),

              // Quick stats row
              Row(
                children: [
                  _HeroStat(Icons.calendar_today_rounded, _t.date),
                  const SizedBox(width: 14),
                  _HeroStat(
                    Icons.groups_rounded,
                    '${_t.teams}/${_t.max} teams',
                  ),
                  const SizedBox(width: 14),
                  _HeroStat(
                    Icons.emoji_events_rounded,
                    '${_t.prizePool} DT prize',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirm() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'Delete Tournament',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: kTextDark,
          ),
        ),
        content: Text(
          'Remove "${_t.name}" permanently?',
          style: const TextStyle(color: kTextMid, fontSize: 14, height: 1.5),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: _DlgBtn(
                  'Cancel',
                  kTextMid,
                  outlined: true,
                  onTap: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DlgBtn(
                  'Delete',
                  kRed,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String text;
  const _HeroStat(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: Colors.white70),
      const SizedBox(width: 4),
      Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// OVERVIEW TAB
// ─────────────────────────────────────────────────────────────────────────────
class _OverviewTab extends StatefulWidget {
  final TournamentData tournament;
  final Color sportColor;
  final VoidCallback onStatusChanged;
  const _OverviewTab({
    required this.tournament,
    required this.sportColor,
    required this.onStatusChanged,
  });
  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  String _status = 'Open'; // Changed default to 'Open'

  // Updated statuses: removed 'Paused', added 'Open' and 'Closed'
  final _statuses = ['Open', 'Closed', 'Completed', 'Cancelled'];

  @override
  Widget build(BuildContext context) {
    final t = widget.tournament;
    final sc = widget.sportColor;
    final navH =
        kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 20, 16, navH + 20),
      children: [
        // Stats grid
        Row(
          children: [
            _OverviewCard(
              Icons.groups_rounded,
              '${t.teams}',
              'Teams Joined',
              sc,
            ),
            const SizedBox(width: 10),
            _OverviewCard(
              Icons.emoji_events_rounded,
              '${t.prizePool} DT',
              'Prize Pool',
              kAmber,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _OverviewCard(
              Icons.payments_rounded,
              '${t.entryFee} DT',
              'Entry Fee',
              kGreen,
            ),
            const SizedBox(width: 10),
            _OverviewCard(
              Icons.people_outline_rounded,
              '${t.max - t.teams}',
              'Spots Left',
              t.isFull ? kRed : kPrimary,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Description
        _InfoSection('About', t.description),
        const SizedBox(height: 20),

        // Status picker - Updated to show Open/Closed
        const Text(
          'Tournament Status',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: kTextDark,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _statuses.map((s) {
            final sel = _status == s;
            final color = _statusColor(s);
            return GestureDetector(
              onTap: () => setState(() {
                _status = s;
                widget.onStatusChanged();
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: sel ? color : color.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: sel
                      ? null
                      : Border.all(color: color.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _statusIcon(s),
                      size: 14,
                      color: sel ? Colors.white : color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      s,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: sel ? Colors.white : color,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Quick actions - Removed Share Poster
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: kTextDark,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                Icons.edit_rounded,
                'Edit Details',
                kPrimary,
                () => _showEditSheet(context, t),
              ),
            ),
            // Removed Share Poster action
          ],
        ),
      ],
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Open':
        return kGreen;
      case 'Closed':
        return kRed;
      case 'Completed':
        return kPrimary;
      case 'Cancelled':
        return kRed.withOpacity(0.7);
      default:
        return kTextMid;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'Open':
        return Icons.lock_open_rounded;
      case 'Closed':
        return Icons.lock_rounded;
      case 'Completed':
        return Icons.check_circle_rounded;
      case 'Cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.circle;
    }
  }

  void _showEditSheet(BuildContext context, TournamentData t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditSheet(tournament: t),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;
  const _OverviewCard(this.icon, this.value, this.label, this.color);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: kElevation,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: -0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: kTextMid,
                    fontWeight: FontWeight.w500,
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

class _InfoSection extends StatelessWidget {
  final String title, content;
  const _InfoSection(this.title, this.content);
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: kTextDark,
        ),
      ),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14),
          boxShadow: kElevation,
        ),
        child: Text(
          content,
          style: const TextStyle(fontSize: 13, color: kTextMid, height: 1.55),
        ),
      ),
    ],
  );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile(this.icon, this.label, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TEAMS TAB - Updated to show only team name and captain name
// ─────────────────────────────────────────────────────────────────────────────
class _TeamsTab extends StatelessWidget {
  final List<_Team> teams;
  final Color sportColor;
  const _TeamsTab({required this.teams, required this.sportColor});

  @override
  Widget build(BuildContext context) {
    final navH =
        kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, 20, 16, navH + 20),
      itemCount: teams.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final team = teams[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(16),
            boxShadow: kElevation,
          ),
          child: Row(
            children: [
              // Rank
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: i == 0
                      ? kAmber.withOpacity(0.12)
                      : sportColor.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: i == 0 ? kAmber : sportColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Avatar placeholder
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [sportColor, sportColor.withOpacity(0.5)],
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
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
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
                          'Captain: ${team.captainName}', // Changed to show captain name only
                          style: const TextStyle(fontSize: 12, color: kTextMid),
                        ),
                      ],
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
                  color: (team.confirmed ? kGreen : kAmber).withOpacity(0.09),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (team.confirmed ? kGreen : kAmber).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  team.confirmed ? 'Confirmed' : 'Pending',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: team.confirmed ? kGreen : kAmber,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MATCHES TAB
// ─────────────────────────────────────────────────────────────────────────────
class _MatchesTab extends StatelessWidget {
  final List<_Match> matches;
  final Color sportColor;
  final Function(int, String, String) onUpdate;
  const _MatchesTab({
    required this.matches,
    required this.sportColor,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final navH =
        kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 20, 16, navH + 20),
      children: [
        // Stage label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: sportColor.withOpacity(0.07),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sports_score_rounded, size: 13, color: sportColor),
              const SizedBox(width: 6),
              Text(
                'Quarter Finals',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: sportColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        ...matches.asMap().entries.map((entry) {
          final i = entry.key;
          final m = entry.value;
          return GestureDetector(
            onTap: m.played ? null : () => _showScoreEntry(context, i, m),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(16),
                boxShadow: kElevation,
                border: m.played
                    ? Border.all(color: kGreen.withOpacity(0.2))
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      m.home,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: kTextDark,
                      ),
                    ),
                  ),
                  Container(
                    width: 70,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: m.played ? sportColor.withOpacity(0.08) : kBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: m.played
                          ? Text(
                              '${m.homeScore} – ${m.awayScore}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: sportColor,
                                letterSpacing: -0.5,
                              ),
                            )
                          : const Text(
                              'vs',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: kTextLight,
                              ),
                            ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      m.away,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: kTextDark,
                      ),
                    ),
                  ),
                  if (!m.played) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: sportColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        size: 13,
                        color: sportColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showScoreEntry(BuildContext context, int idx, _Match m) {
    final homeCtrl = TextEditingController();
    final awayCtrl = TextEditingController();
    final bot = MediaQuery.of(context).padding.bottom;
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
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(20, 20, 20, bot + 20),
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
              const SizedBox(height: 16),
              const Text(
                'Enter Score',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: kTextDark,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          m.home,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: kTextMid,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        _ScoreField(ctrl: homeCtrl),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 28),
                    child: Text(
                      '–',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: kTextLight,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          m.away,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: kTextMid,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        _ScoreField(ctrl: awayCtrl),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  final h = homeCtrl.text.trim();
                  final a = awayCtrl.text.trim();
                  if (h.isNotEmpty && a.isNotEmpty) {
                    onUpdate(idx, h, a);
                    Navigator.pop(context);
                  }
                },
                child: Container(
                  height: 50,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: sportColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: sportColor.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Save Score',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreField extends StatelessWidget {
  final TextEditingController ctrl;
  const _ScoreField({required this.ctrl});
  @override
  Widget build(BuildContext context) => Container(
    height: 64,
    decoration: BoxDecoration(
      color: const Color(0xFFF7F8FA),
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
        hintText: '0',
        hintStyle: TextStyle(
          color: kTextLight,
          fontSize: 28,
          fontWeight: FontWeight.w900,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 14),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// EDIT SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _EditSheet extends StatefulWidget {
  final TournamentData tournament;
  const _EditSheet({required this.tournament});
  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final TextEditingController _name;
  late final TextEditingController _date;
  late final TextEditingController _desc;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.tournament.name);
    _date = TextEditingController(text: widget.tournament.date);
    _desc = TextEditingController(text: widget.tournament.description);
  }

  @override
  void dispose() {
    _name.dispose();
    _date.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bot = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, bot + 20),
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
          const Text(
            'Edit Tournament',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: kTextDark,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 20),
          _EditField('Tournament Name', Icons.sports_score_outlined, _name),
          const SizedBox(height: 12),
          _EditField('Start Date', Icons.calendar_today_rounded, _date),
          const SizedBox(height: 12),
          _EditField(
            'Description',
            Icons.description_outlined,
            _desc,
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              height: 52,
              width: double.infinity,
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: kPrimary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'Save Changes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController ctrl;
  final int maxLines;
  const _EditField(this.label, this.icon, this.ctrl, {this.maxLines = 1});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: kTextMid,
          letterSpacing: 0.3,
        ),
      ),
      const SizedBox(height: 6),
      Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(13),
        ),
        child: TextField(
          controller: ctrl,
          maxLines: maxLines,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: kTextDark,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 16, color: kTextMid),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// MODELS - Updated Team model to include captainName
// ─────────────────────────────────────────────────────────────────────────────
class _Team {
  final String name, captainName, avatarUrl;
  final bool confirmed;
  const _Team(this.name, this.captainName, this.confirmed, this.avatarUrl);
}

class _Match {
  final String home, away, homeScore, awayScore;
  final bool played;
  const _Match(
    this.home,
    this.away,
    this.homeScore,
    this.awayScore,
    this.played,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED
// ─────────────────────────────────────────────────────────────────────────────
class _DlgBtn extends StatelessWidget {
  final String label;
  final Color color;
  final bool outlined;
  final VoidCallback onTap;
  const _DlgBtn(
    this.label,
    this.color, {
    required this.onTap,
    this.outlined = false,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 46,
      decoration: outlined
          ? BoxDecoration(
              border: Border.all(color: kTextLight.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(12),
            )
          : BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: outlined ? kTextMid : Colors.white,
          ),
        ),
      ),
    ),
  );
}
