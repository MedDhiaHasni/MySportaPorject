import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Models/app_enums.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────
enum TournamentStatus { open, upcoming, closed }

class Tournament {
  final String id, name, date, description, posterUrl;
  final SportType sport;
  final int teams, maxTeams;
  final int entryFee, prizePool;
  final TournamentStatus status;

  Tournament({
    required this.id,
    required this.name,
    required this.date,
    required this.description,
    required this.posterUrl,
    required this.sport,
    required this.teams,
    required this.maxTeams,
    required this.entryFee,
    required this.prizePool,
    required this.status,
  });

  bool get isFull => teams >= maxTeams;
  int get spotsLeft => maxTeams - teams;
  Color get statusColor {
    switch (status) {
      case TournamentStatus.open:
        return kGreen;
      case TournamentStatus.upcoming:
        return kAmber;
      case TournamentStatus.closed:
        return kRed;
    }
  }

  String get statusLabel {
    switch (status) {
      case TournamentStatus.open:
        return 'Open';
      case TournamentStatus.upcoming:
        return 'Upcoming';
      case TournamentStatus.closed:
        return 'Closed';
    }
  }
}

class TeamRegistration {
  final String id;
  final String teamName;
  final String captainName;
  final String captainPhone;
  final DateTime registeredAt;
  bool isConfirmed;

  TeamRegistration({
    required this.id,
    required this.teamName,
    required this.captainName,
    required this.captainPhone,
    required this.registeredAt,
    this.isConfirmed = false,
  });
}

class ConfirmedTeam {
  final String id;
  final String name;
  final String captainName;
  final bool isActive;

  ConfirmedTeam({
    required this.id,
    required this.name,
    required this.captainName,
    this.isActive = true,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// TOURNAMENTS PAGE
// ─────────────────────────────────────────────────────────────────────────────
class Tournaments extends StatefulWidget {
  const Tournaments({super.key});
  @override
  State<Tournaments> createState() => _TournamentsState();
}

class _TournamentsState extends State<Tournaments> {
  // Sample tournament data - using same style as dashboard
  List<Tournament> _tournaments = [
    Tournament(
      id: 't1',
      name: 'Summer Padel Cup',
      sport: SportType.padel,
      date: 'Jun 15 - Jun 22',
      description: 'Annual padel championship open to all levels.',
      posterUrl:
          'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=700&q=80',
      teams: 8,
      maxTeams: 16,
      entryFee: 60,
      prizePool: 1200,
      status: TournamentStatus.open,
    ),
    Tournament(
      id: 't2',
      name: 'Friday Football 5v5',
      sport: SportType.football,
      date: 'Jun 21',
      description: 'Weekly 5-a-side league. Fast-paced, competitive.',
      posterUrl:
          'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=700&q=80',
      teams: 6,
      maxTeams: 8,
      entryFee: 80,
      prizePool: 2000,
      status: TournamentStatus.open,
    ),
    Tournament(
      id: 't3',
      name: 'Tennis Open Singles',
      sport: SportType.tennis,
      date: 'Jul 5 - Jul 12',
      description: 'Open singles bracket for all skill levels.',
      posterUrl:
          'https://images.unsplash.com/photo-1545809074-59472b3f5ecc?w=700&q=80',
      teams: 12,
      maxTeams: 32,
      entryFee: 100,
      prizePool: 3000,
      status: TournamentStatus.upcoming,
    ),
    Tournament(
      id: 't4',
      name: 'Basketball 3x3',
      sport: SportType.basketball,
      date: 'Jul 18',
      description: 'Fast-paced 3x3 basketball tournament.',
      posterUrl:
          'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=700&q=80',
      teams: 8,
      maxTeams: 8,
      entryFee: 40,
      prizePool: 800,
      status: TournamentStatus.closed,
    ),
  ];

  void _updateTournament(Tournament updated) => setState(() {
    final i = _tournaments.indexWhere((t) => t.id == updated.id);
    if (i != -1) _tournaments[i] = updated;
  });

  void _deleteTournament(String id) =>
      setState(() => _tournaments.removeWhere((t) => t.id == id));

  @override
  Widget build(BuildContext context) {
    final navBarH =
        kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;

    final openCount = _tournaments
        .where((t) => t.status == TournamentStatus.open)
        .length;
    final upcomingCount = _tournaments
        .where((t) => t.status == TournamentStatus.upcoming)
        .length;

    return Scaffold(
      backgroundColor: kBg,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _TournamentsHeader(
              openCount: openCount,
              upcomingCount: upcomingCount,
              onCreate: () => _openCreateTournament(),
            ),
          ),

          // ── Tournament List ─────────────────────────────────────────────
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, navBarH + 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _TournamentPosterCard(
                  tournament: _tournaments[i],
                  onManage: () => _openManageTournament(_tournaments[i]),
                ),
                childCount: _tournaments.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openCreateTournament() async {
    final result = await Navigator.push<Tournament>(
      context,
      MaterialPageRoute(builder: (_) => const CreateTournamentPage()),
    );
    if (result != null) {
      setState(() => _tournaments.add(result));
    }
  }

  void _openManageTournament(Tournament t) async {
    final result = await Navigator.push<Tournament>(
      context,
      MaterialPageRoute(
        builder: (_) => ManageTournamentPage(
          tournament: t,
          onUpdate: _updateTournament,
          onDelete: _deleteTournament,
        ),
      ),
    );
    if (result != null) _updateTournament(result);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOURNAMENTS HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _TournamentsHeader extends StatelessWidget {
  final int openCount, upcomingCount;
  final VoidCallback onCreate;
  const _TournamentsHeader({
    required this.openCount,
    required this.upcomingCount,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF001F20), Color(0xFF003D3E), kPrimary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: Colors.white.withOpacity(0.18)),
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tournaments',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Manage your competitions',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Create button
                  GestureDetector(
                    onTap: onCreate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                        ),
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
                            'Create',
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
              const SizedBox(height: 16),
              // Stats row
              Row(
                children: [
                  _StatChip('$openCount Open', kGreen, Icons.lock_open_rounded),
                  const SizedBox(width: 8),
                  _StatChip(
                    '$upcomingCount Upcoming',
                    kAmber,
                    Icons.schedule_rounded,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _StatChip(this.label, this.color, this.icon);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TOURNAMENT POSTER CARD — same as dashboard
// ─────────────────────────────────────────────────────────────────────────────
class _TournamentPosterCard extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback onManage;
  const _TournamentPosterCard({
    required this.tournament,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    final t = tournament;
    final sc = t.sport.color;

    return GestureDetector(
      onTap: onManage,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // Poster image
            SizedBox(
              height: 200,
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

            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.80),
                    ],
                  ),
                ),
              ),
            ),

            // Sport badge top-left
            Positioned(
              top: 14,
              left: 14,
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

            // Status badge top-right
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: t.statusColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      t.status == TournamentStatus.open
                          ? Icons.lock_open_rounded
                          : t.status == TournamentStatus.upcoming
                          ? Icons.schedule_rounded
                          : Icons.lock_rounded,
                      size: 10,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      t.statusLabel,
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

            // Spots badge (if not closed)
            if (t.status != TournamentStatus.closed)
              Positioned(
                top: 54,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: t.isFull
                        ? kRed.withOpacity(0.9)
                        : kGreen.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    t.isFull ? 'Full' : '${t.spotsLeft} spots',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            // Bottom info
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.name,
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
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 11,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                t.date,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(
                                Icons.groups_rounded,
                                size: 11,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${t.teams}/${t.maxTeams}',
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
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: onManage,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.tune_rounded, size: 13, color: sc),
                            const SizedBox(width: 5),
                            Text(
                              'Manage',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: sc,
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
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CREATE TOURNAMENT PAGE — New separate page
// ─────────────────────────────────────────────────────────────────────────────
class CreateTournamentPage extends StatefulWidget {
  const CreateTournamentPage({super.key});
  @override
  State<CreateTournamentPage> createState() => _CreateTournamentPageState();
}

class _CreateTournamentPageState extends State<CreateTournamentPage> {
  final _nameCtrl = TextEditingController();
  final _maxTeamsCtrl = TextEditingController(text: '16');
  final _entryFeeCtrl = TextEditingController(text: '50');
  final _prizeCtrl = TextEditingController();
  SportType _sport = SportType.football;
  String _startDate = 'Jun 15, 2026';
  String _endDate = 'Jun 22, 2026';
  bool _isCreating = false;

  final List<String> _samplePosters = [
    'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=700&q=80',
    'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=700&q=80',
    'https://images.unsplash.com/photo-1545809074-59472b3f5ecc?w=700&q=80',
    'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=700&q=80',
  ];
  String _selectedPoster = '';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _maxTeamsCtrl.dispose();
    _entryFeeCtrl.dispose();
    _prizeCtrl.dispose();
    super.dispose();
  }

  void _createTournament() {
    if (_nameCtrl.text.trim().isEmpty || _selectedPoster.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: kAmber,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    // Simulate creation delay
    Future.delayed(const Duration(milliseconds: 800), () {
      final newTournament = Tournament(
        id: 't${DateTime.now().millisecondsSinceEpoch}',
        name: _nameCtrl.text.trim(),
        sport: _sport,
        date: '$_startDate - $_endDate',
        description: 'New tournament created by manager.',
        posterUrl: _selectedPoster,
        teams: 0,
        maxTeams: int.tryParse(_maxTeamsCtrl.text) ?? 16,
        entryFee: int.tryParse(_entryFeeCtrl.text) ?? 50,
        prizePool: int.tryParse(_prizeCtrl.text) ?? 0,
        status: TournamentStatus.upcoming,
      );

      Navigator.pop(context, newTournament);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          // Header
          Container(
            color: kCard,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 12, 16, 14),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 17,
                        color: kTextDark,
                      ),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Create Tournament',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: kTextDark,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero banner
                  Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF002B2C),
                          kPrimary,
                          Color(0xFF006869),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(painter: GridPainter()),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.emoji_events_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'New Tournament',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Fill in the details below',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 12,
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
                  ),
                  const SizedBox(height: 20),

                  // Poster selection
                  const Text(
                    'Select Poster',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: kTextDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _samplePosters.map((url) {
                        final isSelected = _selectedPoster == url;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedPoster = url),
                          child: Container(
                            width: 120,
                            height: 100,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
                                  ? Border.all(color: kPrimary, width: 3)
                                  : null,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                url,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: kPrimary.withOpacity(0.1),
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: kTextLight,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tournament name
                  _InputLabel('Tournament Name'),
                  const SizedBox(height: 6),
                  _InputField(
                    controller: _nameCtrl,
                    hint: 'e.g. Summer Cup 2026',
                    icon: Icons.sports_score_outlined,
                  ),
                  const SizedBox(height: 16),

                  // Sport
                  _InputLabel('Sport Type'),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: kCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kTextLight.withOpacity(0.2)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<SportType>(
                        value: _sport,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: kTextMid,
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: kTextDark,
                        ),
                        items: SportType.values.map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: Row(
                              children: [
                                Icon(s.icon, size: 16, color: s.color),
                                const SizedBox(width: 8),
                                Text(s.label),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _sport = v!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Max teams and entry fee
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _InputLabel('Max Teams'),
                            const SizedBox(height: 6),
                            _InputField(
                              controller: _maxTeamsCtrl,
                              hint: '16',
                              icon: Icons.groups_rounded,
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _InputLabel('Entry Fee (DT)'),
                            const SizedBox(height: 6),
                            _InputField(
                              controller: _entryFeeCtrl,
                              hint: '50',
                              icon: Icons.payments_rounded,
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Prize
                  _InputLabel('Prize Pool (DT)'),
                  const SizedBox(height: 6),
                  _InputField(
                    controller: _prizeCtrl,
                    hint: 'e.g. 1000',
                    icon: Icons.emoji_events_rounded,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // Dates
                  Row(
                    children: [
                      Expanded(
                        child: _DateSelector(
                          label: 'Start Date',
                          value: _startDate,
                          onTap: () async {
                            // In a real app, show date picker
                            setState(() => _startDate = 'Jun 15, 2026');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DateSelector(
                          label: 'End Date',
                          value: _endDate,
                          onTap: () async {
                            setState(() => _endDate = 'Jun 22, 2026');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Create button
                  GestureDetector(
                    onTap: _isCreating ? null : _createTournament,
                    child: Container(
                      height: 54,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF004748),
                            kPrimary,
                            Color(0xFF007677),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: kPrimary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isCreating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Create Tournament',
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
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EDIT TOURNAMENT PAGE — New separate page
// ─────────────────────────────────────────────────────────────────────────────
class EditTournamentPage extends StatefulWidget {
  final Tournament tournament;
  const EditTournamentPage({super.key, required this.tournament});
  @override
  State<EditTournamentPage> createState() => _EditTournamentPageState();
}

class _EditTournamentPageState extends State<EditTournamentPage> {
  late TextEditingController _nameCtrl;
  late TextEditingController _maxTeamsCtrl;
  late TextEditingController _entryFeeCtrl;
  late TextEditingController _prizeCtrl;
  late SportType _sport;
  late String _startDate;
  late String _endDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.tournament;
    _nameCtrl = TextEditingController(text: t.name);
    _maxTeamsCtrl = TextEditingController(text: t.maxTeams.toString());
    _entryFeeCtrl = TextEditingController(text: t.entryFee.toString());
    _prizeCtrl = TextEditingController(text: t.prizePool.toString());
    _sport = t.sport;

    final dates = t.date.split(' - ');
    _startDate = dates[0];
    _endDate = dates.length > 1 ? dates[1] : dates[0];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _maxTeamsCtrl.dispose();
    _entryFeeCtrl.dispose();
    _prizeCtrl.dispose();
    super.dispose();
  }

  void _saveChanges() {
    setState(() => _isSaving = true);

    Future.delayed(const Duration(milliseconds: 800), () {
      final updated = Tournament(
        id: widget.tournament.id,
        name: _nameCtrl.text.trim(),
        sport: _sport,
        date: '$_startDate - $_endDate',
        description: widget.tournament.description,
        posterUrl: widget.tournament.posterUrl,
        teams: widget.tournament.teams,
        maxTeams:
            int.tryParse(_maxTeamsCtrl.text) ?? widget.tournament.maxTeams,
        entryFee:
            int.tryParse(_entryFeeCtrl.text) ?? widget.tournament.entryFee,
        prizePool: int.tryParse(_prizeCtrl.text) ?? widget.tournament.prizePool,
        status: widget.tournament.status,
      );

      Navigator.pop(context, updated);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          // Header
          Container(
            color: kCard,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 12, 16, 14),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 17,
                        color: kTextDark,
                      ),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Edit Tournament',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: kTextDark,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current poster preview
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: NetworkImage(widget.tournament.posterUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.4),
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        'Current Poster',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tournament name
                  _InputLabel('Tournament Name'),
                  const SizedBox(height: 6),
                  _InputField(
                    controller: _nameCtrl,
                    hint: 'Tournament name',
                    icon: Icons.sports_score_outlined,
                  ),
                  const SizedBox(height: 16),

                  // Sport
                  _InputLabel('Sport Type'),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: kCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kTextLight.withOpacity(0.2)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<SportType>(
                        value: _sport,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: kTextMid,
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: kTextDark,
                        ),
                        items: SportType.values.map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: Row(
                              children: [
                                Icon(s.icon, size: 16, color: s.color),
                                const SizedBox(width: 8),
                                Text(s.label),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _sport = v!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Max teams and entry fee
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _InputLabel('Max Teams'),
                            const SizedBox(height: 6),
                            _InputField(
                              controller: _maxTeamsCtrl,
                              hint: '16',
                              icon: Icons.groups_rounded,
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _InputLabel('Entry Fee (DT)'),
                            const SizedBox(height: 6),
                            _InputField(
                              controller: _entryFeeCtrl,
                              hint: '50',
                              icon: Icons.payments_rounded,
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Prize
                  _InputLabel('Prize Pool (DT)'),
                  const SizedBox(height: 6),
                  _InputField(
                    controller: _prizeCtrl,
                    hint: 'e.g. 1000',
                    icon: Icons.emoji_events_rounded,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // Dates
                  Row(
                    children: [
                      Expanded(
                        child: _DateSelector(
                          label: 'Start Date',
                          value: _startDate,
                          onTap: () async {
                            // In a real app, show date picker
                            setState(() => _startDate = 'Jun 15, 2026');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DateSelector(
                          label: 'End Date',
                          value: _endDate,
                          onTap: () async {
                            setState(() => _endDate = 'Jun 22, 2026');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Save button
                  GestureDetector(
                    onTap: _isSaving ? null : _saveChanges,
                    child: Container(
                      height: 54,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: kPrimary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: kPrimary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
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
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MANAGE TOURNAMENT PAGE — Only 3 tabs now: Overview, Requests, Teams
// ─────────────────────────────────────────────────────────────────────────────
class ManageTournamentPage extends StatefulWidget {
  final Tournament tournament;
  final Function(Tournament) onUpdate;
  final Function(String) onDelete;

  const ManageTournamentPage({
    super.key,
    required this.tournament,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<ManageTournamentPage> createState() => _ManageTournamentPageState();
}

class _ManageTournamentPageState extends State<ManageTournamentPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Tournament _tournament;

  // Sample registration requests
  final List<TeamRegistration> _requests = [
    TeamRegistration(
      id: 'r1',
      teamName: 'FC Lions',
      captainName: 'Karim Jaziri',
      captainPhone: '+216 98 765 432',
      registeredAt: DateTime.now().subtract(const Duration(days: 2)),
      isConfirmed: false,
    ),
    TeamRegistration(
      id: 'r2',
      teamName: 'Coastal Wolves',
      captainName: 'Nadia Ben Salah',
      captainPhone: '+216 97 123 456',
      registeredAt: DateTime.now().subtract(const Duration(days: 1)),
      isConfirmed: false,
    ),
    TeamRegistration(
      id: 'r3',
      teamName: 'Sky Eagles',
      captainName: 'Mehdi Trabelsi',
      captainPhone: '+216 99 456 789',
      registeredAt: DateTime.now(),
      isConfirmed: false,
    ),
    TeamRegistration(
      id: 'r4',
      teamName: 'Red Storm',
      captainName: 'Leila Mallouli',
      captainPhone: '+216 98 111 222',
      registeredAt: DateTime.now().subtract(const Duration(hours: 5)),
      isConfirmed: false,
    ),
  ];

  // Sample confirmed teams
  final List<ConfirmedTeam> _confirmedTeams = [
    ConfirmedTeam(id: 'c1', name: 'Red Storm', captainName: 'Leila Mallouli'),
    ConfirmedTeam(
      id: 'c2',
      name: 'Green Blazers',
      captainName: 'Ahmed Ben Ali',
    ),
    ConfirmedTeam(id: 'c3', name: 'Night Hawks', captainName: 'Sami Khelif'),
  ];

  @override
  void initState() {
    super.initState();
    _tournament = widget.tournament;
    _tabController = TabController(
      length: 3,
      vsync: this,
    ); // 3 tabs: Overview, Requests, Teams
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _confirmRequest(String requestId) {
    setState(() {
      final request = _requests.firstWhere((r) => r.id == requestId);
      request.isConfirmed = true;

      // Add to confirmed teams
      _confirmedTeams.add(
        ConfirmedTeam(
          id: 'ct_${DateTime.now().millisecondsSinceEpoch}',
          name: request.teamName,
          captainName: request.captainName,
        ),
      );

      // Remove from requests
      _requests.removeWhere((r) => r.id == requestId);
    });
  }

  void _declineRequest(String requestId) {
    setState(() {
      _requests.removeWhere((r) => r.id == requestId);
    });
  }

  void _openEditTournament() async {
    final result = await Navigator.push<Tournament>(
      context,
      MaterialPageRoute(
        builder: (_) => EditTournamentPage(tournament: _tournament),
      ),
    );
    if (result != null) {
      setState(() => _tournament = result);
      widget.onUpdate(result);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                controller: _tabController,
                labelColor: _tournament.sport.color,
                unselectedLabelColor: kTextMid,
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                indicatorColor: _tournament.sport.color,
                indicatorWeight: 3,
                tabs: [
                  const Tab(text: 'Overview'),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Requests'),
                        if (_requests.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: kAmber,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${_requests.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Tab(text: 'Teams'),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _OverviewTab(
                    tournament: _tournament,
                    sportColor: _tournament.sport.color,
                  ),
                  _RequestsTab(
                    requests: _requests,
                    sportColor: _tournament.sport.color,
                    onConfirm: _confirmRequest,
                    onDecline: _declineRequest,
                  ),
                  _TeamsTab(
                    teams: _confirmedTeams,
                    sportColor: _tournament.sport.color,
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
    final t = _tournament;
    final sc = t.sport.color;

    return Stack(
      children: [
        // Poster
        SizedBox(
          height: 260,
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
                    onTap: () => Navigator.pop(context, _tournament),
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
                  // Edit button - now opens new page
                  GestureDetector(
                    onTap: _openEditTournament,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Delete button
                  GestureDetector(
                    onTap: _showDeleteConfirm,
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
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: t.statusColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      t.statusLabel,
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
                t.name,
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
                  _HeroStat(Icons.calendar_today_rounded, t.date),
                  const SizedBox(width: 14),
                  _HeroStat(
                    Icons.groups_rounded,
                    '${t.teams}/${t.maxTeams} teams',
                  ),
                  const SizedBox(width: 14),
                  _HeroStat(
                    Icons.emoji_events_rounded,
                    '${t.prizePool} DT prize',
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
          'Remove "${_tournament.name}" permanently?',
          style: const TextStyle(color: kTextMid, fontSize: 14, height: 1.5),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: _DialogBtn(
                  'Cancel',
                  onTap: () => Navigator.pop(context),
                  outlined: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DialogBtn(
                  'Delete',
                  color: kRed,
                  onTap: () {
                    Navigator.pop(context);
                    widget.onDelete(_tournament.id);
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
class _OverviewTab extends StatelessWidget {
  final Tournament tournament;
  final Color sportColor;
  const _OverviewTab({required this.tournament, required this.sportColor});

  @override
  Widget build(BuildContext context) {
    final t = tournament;
    final sc = sportColor;
    final navH =
        kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 20, 16, navH + 20),
      children: [
        // Stats grid
        Row(
          children: [
            _OverviewCard(
              icon: Icons.groups_rounded,
              value: '${t.teams}',
              label: 'Teams Joined',
              color: sc,
            ),
            const SizedBox(width: 10),
            _OverviewCard(
              icon: Icons.emoji_events_rounded,
              value: '${t.prizePool} DT',
              label: 'Prize Pool',
              color: kAmber,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _OverviewCard(
              icon: Icons.payments_rounded,
              value: '${t.entryFee} DT',
              label: 'Entry Fee',
              color: kGreen,
            ),
            const SizedBox(width: 10),
            _OverviewCard(
              icon: Icons.people_outline_rounded,
              value: '${t.spotsLeft}',
              label: 'Spots Left',
              color: t.isFull ? kRed : kPrimary,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Description
        _InfoSection('About', t.description),
        const SizedBox(height: 20),

        // Dates
        _InfoSection(
          'Schedule',
          'Start: ${t.date.split(' - ')[0]}\nEnd: ${t.date.split(' - ').length > 1 ? t.date.split(' - ')[1] : t.date}',
        ),
        const SizedBox(height: 20),

        // Registration progress
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Registration Progress',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: kTextDark,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${t.teams}/${t.maxTeams} teams',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kTextMid,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(t.teams / t.maxTeams * 100).round()}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: sc,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: t.teams / t.maxTeams,
                  minHeight: 8,
                  backgroundColor: sc.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation(sc),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;
  const _OverviewCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          content,
          style: const TextStyle(fontSize: 13, color: kTextMid, height: 1.55),
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// REQUESTS TAB — Fixed overflow, removed player count
// ─────────────────────────────────────────────────────────────────────────────
class _RequestsTab extends StatelessWidget {
  final List<TeamRegistration> requests;
  final Color sportColor;
  final Function(String) onConfirm;
  final Function(String) onDecline;

  const _RequestsTab({
    required this.requests,
    required this.sportColor,
    required this.onConfirm,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final navH =
        kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;

    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: sportColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.how_to_reg_rounded,
                size: 32,
                color: sportColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No pending requests',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: kTextDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'New team registrations will appear here',
              style: TextStyle(fontSize: 12, color: kTextMid.withOpacity(0.8)),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, navH + 16),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: sportColor.withOpacity(0.07),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.how_to_reg_rounded, size: 14, color: sportColor),
              const SizedBox(width: 6),
              Text(
                '${requests.length} pending ${requests.length == 1 ? 'request' : 'requests'}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: sportColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Request cards
        ...requests.map(
          (request) => _RequestCard(
            request: request,
            sportColor: sportColor,
            onConfirm: () => onConfirm(request.id),
            onDecline: () => onDecline(request.id),
          ),
        ),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  final TeamRegistration request;
  final Color sportColor;
  final VoidCallback onConfirm;
  final VoidCallback onDecline;

  const _RequestCard({
    required this.request,
    required this.sportColor,
    required this.onConfirm,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: kAmber.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          // Team info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [sportColor, sportColor.withOpacity(0.6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      request.teamName
                          .split(' ')
                          .map((e) => e[0])
                          .take(2)
                          .join(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Team name and captain
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.teamName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: kTextDark,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline_rounded,
                            size: 11,
                            color: kTextLight,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              request.captainName,
                              style: const TextStyle(
                                fontSize: 11,
                                color: kTextMid,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Pending badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: kAmber.withOpacity(0.09),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.hourglass_top_rounded,
                        size: 10,
                        color: kAmber,
                      ),
                      SizedBox(width: 3),
                      Text(
                        'Pending',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: kAmber,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Phone and time row only (removed player count)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.phone_rounded, size: 11, color: kTextLight),
                const SizedBox(width: 4),
                Text(
                  request.captainPhone,
                  style: const TextStyle(fontSize: 11, color: kTextMid),
                ),
                const Spacer(),
                Text(
                  _timeAgo(request.registeredAt),
                  style: const TextStyle(
                    fontSize: 10,
                    color: kTextLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 24, indent: 16, endIndent: 16),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Decline',
                    icon: Icons.close_rounded,
                    color: kRed,
                    onTap: onDecline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    label: 'Confirm',
                    icon: Icons.check_rounded,
                    color: kGreen,
                    filled: true,
                    onTap: onConfirm,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TEAMS TAB — Removed wins/losses
// ─────────────────────────────────────────────────────────────────────────────
class _TeamsTab extends StatelessWidget {
  final List<ConfirmedTeam> teams;
  final Color sportColor;

  const _TeamsTab({required this.teams, required this.sportColor});

  @override
  Widget build(BuildContext context) {
    final navH =
        kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;

    if (teams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: sportColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.groups_rounded,
                size: 32,
                color: sportColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No teams yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: kTextDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Confirmed teams will appear here',
              style: TextStyle(fontSize: 12, color: kTextMid.withOpacity(0.8)),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, 16, 16, navH + 16),
      itemCount: teams.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final team = teams[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
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
              // Team avatar
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
              // Team info
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
                          'Captain: ${team.captainName}',
                          style: const TextStyle(fontSize: 11, color: kTextMid),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Removed wins/losses, just show active badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: kGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: kGreen,
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
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 44,
      decoration: BoxDecoration(
        color: filled ? color : color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: filled ? null : Border.all(color: color.withOpacity(0.3)),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: filled ? Colors.white : color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: filled ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DialogBtn extends StatelessWidget {
  final String label;
  final Color? color;
  final VoidCallback onTap;
  final bool outlined;

  const _DialogBtn(
    this.label, {
    required this.onTap,
    this.color,
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
              color: color ?? kPrimary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: (color ?? kPrimary).withOpacity(0.25),
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

class _InputLabel extends StatelessWidget {
  final String text;
  const _InputLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: kTextDark,
    ),
  );
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: kCard,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: kTextLight.withOpacity(0.2)),
    ),
    child: TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: kTextDark,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: kTextLight),
        prefixIcon: Icon(icon, size: 18, color: kTextMid),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
  );
}

class _DateSelector extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _DateSelector({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kTextLight.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: kTextMid,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kTextDark,
                  ),
                ),
              ),
              const Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: kTextLight,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

// Simple GridPainter for backgrounds
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 0.5;

    const spacing = 20.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
