// court_booking_page.dart — Views/Player/court_booking_page.dart
// Shows venue info, manager details, list of courts with sport filter
// Tapping a court → CourtDetailPage (images + booking flow)

import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Models/app_enums.dart';
import 'package:sporta/Models/app_models.dart';
import 'package:sporta/Models/sample_data.dart';
import 'package:sporta/Views/Player/court_detail.dart';
import 'package:sporta/Models/venue_model.dart';

class CourtBookingPage extends StatefulWidget {
  final VenueModel venue;
  const CourtBookingPage({super.key, required this.venue});
  @override
  State<CourtBookingPage> createState() => _CourtBookingPageState();
}

class _CourtBookingPageState extends State<CourtBookingPage> {
  String? _selectedSport; // null = All

  SportType _mapSport(String sport) {
    switch (sport) {
      case 'Padel':
        return SportType.padel;
      case 'Tennis':
        return SportType.tennis;
      case 'Basketball':
        return SportType.basketball;
      default:
        return SportType.football;
    }
  }

  List<String> get _sports {
    final seen = <String>{};
    for (final c in widget.venue.courts) seen.add(c['sport'] as String);
    return seen.toList();
  }

  List<Map<String, dynamic>> get _filteredCourts {
    final all = widget.venue.courts;
    final filtered = _selectedSport == null
        ? all
        : all.where((c) => c['sport'] == _selectedSport).toList();
    final avail = filtered.where((c) => c['available'] == true).toList();
    final unavail = filtered.where((c) => c['available'] == false).toList();
    return [...avail, ...unavail];
  }

  IconData _sportIcon(String sport) {
    switch (sport) {
      case 'Padel':
        return Icons.sports_tennis_rounded;
      case 'Tennis':
        return Icons.sports_tennis;
      case 'Basketball':
        return Icons.sports_basketball_rounded;
      case 'Volleyball':
        return Icons.sports_volleyball;
      default:
        return Icons.sports_soccer_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final courts = _filteredCourts;
    final venue = widget.venue;

    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              children: [
                _VenueHeroCard(venue: venue),
                const SizedBox(height: 20),
                _ManagerCard(venue: venue),
                const SizedBox(height: 24),

                // ── Courts header ─────────────────────────────────────────────
                Row(
                  children: [
                    const Text(
                      'Courts',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: kTextDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: kPrimary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${venue.courts.length} courts',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: kPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Sport filter chips ────────────────────────────────────────
                if (_sports.length > 1) ...[
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        // All chip
                        GestureDetector(
                          onTap: () => setState(() => _selectedSport = null),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: _selectedSport == null ? kPrimary : kCard,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: kElevation,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.sports_rounded,
                                  size: 13,
                                  color: _selectedSport == null
                                      ? Colors.white
                                      : kTextMid,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'All',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _selectedSport == null
                                        ? Colors.white
                                        : kTextMid,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Per-sport chips
                        ..._sports.map((sport) {
                          final sel = _selectedSport == sport;
                          final color = _mapSport(sport).color;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedSport = sport),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: sel ? color : kCard,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: kElevation,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _sportIcon(sport),
                                    size: 13,
                                    color: sel ? Colors.white : kTextMid,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    sport,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: sel ? Colors.white : kTextMid,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // ── Court cards ───────────────────────────────────────────────
                ...courts.map((court) {
                  final sportType = _mapSport(court['sport'] as String);
                  final isAvailable = court['available'] as bool;
                  final courtModel = CourtModel(
                    id: '${venue.name}_${court['courtName']}',
                    name: court['courtName'] as String,
                    location: venue.location,
                    sport: sportType,
                    pricePerHour: (court['price'] as int).toDouble(),
                    color: sportType.color,
                    imageUrl: court['imageUrl'] as String?,
                  );
                  return _CourtListCard(
                    court: courtModel,
                    venue: venue,
                    available: isAvailable,
                    onTap: isAvailable
                        ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CourtDetailPage(
                                court: courtModel,
                                venue: venue,
                                courtData: court,
                              ),
                            ),
                          )
                        : null,
                  );
                }),

                if (courts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.sports_rounded,
                          size: 48,
                          color: kTextLight.withOpacity(0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _selectedSport != null
                              ? 'No $_selectedSport courts available'
                              : 'No courts listed',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: kTextDark,
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
    );
  }

  Widget _buildHeader(BuildContext context) => Container(
    color: kCard,
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 20, 14),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: kBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_rounded,
                  size: 16,
                  color: kTextDark,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.venue.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: kTextDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    widget.venue.location,
                    style: const TextStyle(fontSize: 12, color: kTextMid),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: widget.venue.available
                    ? kGreen.withOpacity(0.1)
                    : kRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: widget.venue.available ? kGreen : kRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    widget.venue.available ? 'Open' : 'Closed',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: widget.venue.available ? kGreen : kRed,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// VENUE HERO CARD
// ─────────────────────────────────────────────────────────────────────────────
class _VenueHeroCard extends StatelessWidget {
  final VenueModel venue;
  const _VenueHeroCard({required this.venue});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: kCard,
      borderRadius: BorderRadius.circular(20),
      boxShadow: kElevation,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: SizedBox(
            height: 160,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  venue.image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: kPrimary.withOpacity(0.08)),
                ),
                Container(color: Colors.black.withOpacity(0.15)),
                Positioned(
                  bottom: 10,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 11,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Until ${venue.openUntil}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 12,
                  child: Row(
                    children: venue.sports
                        .take(3)
                        .map(
                          (s) => Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              s,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: venue.amenities
                .map(
                  (a) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      a,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: kPrimary,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// MANAGER CARD
// ─────────────────────────────────────────────────────────────────────────────
class _ManagerCard extends StatelessWidget {
  final VenueModel venue;
  const _ManagerCard({required this.venue});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: kCard,
      borderRadius: BorderRadius.circular(16),
      boxShadow: kElevation,
    ),
    child: Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimary, Color(0xFF007B7D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              venue.managerAvatar,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Venue Manager',
                style: TextStyle(
                  fontSize: 11,
                  color: kTextMid,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                venue.managerName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kTextDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                venue.managerPhone,
                style: const TextStyle(fontSize: 12, color: kTextMid),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: kPrimary,
              size: 20,
            ),
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// COURT LIST CARD
// ─────────────────────────────────────────────────────────────────────────────
class _CourtListCard extends StatelessWidget {
  final CourtModel court;
  final VenueModel venue;
  final bool available;
  final VoidCallback? onTap;
  const _CourtListCard({
    required this.court,
    required this.venue,
    required this.available,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = available ? court.color : kTextLight;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: kElevation,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: SizedBox(
                width: 90,
                height: 92,
                child: court.imageUrl != null
                    ? Image.network(
                        court.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(color),
                      )
                    : _placeholder(color),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            court.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: available ? kTextDark : kTextLight,
                            ),
                          ),
                        ),
                        if (!available)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: kRed.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Full',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: kRed,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            court.sport.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${court.pricePerHour.toStringAsFixed(0)} DT',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    if (available) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.touch_app_rounded,
                            size: 12,
                            color: color.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'View details & book',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: color.withOpacity(0.65),
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: color.withOpacity(0.4),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(Color color) => Container(
    color: color.withOpacity(0.07),
    child: Icon(court.sport.icon, color: color.withOpacity(0.3), size: 28),
  );
}
