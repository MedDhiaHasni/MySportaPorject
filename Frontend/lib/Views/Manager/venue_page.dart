// venue_page.dart — Views/Manager/venue_page.dart
// Manager owns and manages his own venues + courts fully
// Flow: Venue list → tap venue → venue detail (edit + courts) → add/edit court

import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Models/app_enums.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────
class ManagedVenue {
  final String id;
  String name, location, phone, description, openTime, closeTime;
  List<String> photoUrls;
  List<SportType> sports;
  List<String> amenities;
  List<ManagedCourt> courts;

  ManagedVenue({
    required this.id,
    required this.name,
    required this.location,
    required this.phone,
    required this.description,
    required this.openTime,
    required this.closeTime,
    this.photoUrls = const [],
    required this.sports,
    this.amenities = const [],
    required this.courts,
  });
}

class ManagedCourt {
  final String id;
  String name, description, surface;
  SportType sport;
  double pricePerHour;
  int capacity;
  List<String> photoUrls;
  List<String> amenities;
  bool isActive;

  ManagedCourt({
    required this.id,
    required this.name,
    required this.description,
    required this.sport,
    required this.pricePerHour,
    required this.capacity,
    this.photoUrls = const [],
    required this.surface,
    this.amenities = const [],
    this.isActive = true,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// SAMPLE DATA
// ─────────────────────────────────────────────────────────────────────────────
List<ManagedVenue> _sampleVenues() => [
  ManagedVenue(
    id: 'v1',
    name: 'Arena Sport Center',
    location: 'Lac 2, Tunis',
    phone: '+216 71 234 567',
    description:
        'Modern sports facility with top-quality courts and professional atmosphere.',
    openTime: '08:00',
    closeTime: '23:00',
    photoUrls: [
      'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=1200&q=80',
    ],
    sports: [
      SportType.football,
      SportType.padel,
      SportType.tennis,
      SportType.basketball,
    ],
    amenities: [
      'Parking',
      'Changing Rooms',
      'Showers',
      'Cafe',
      'Wifi',
      'First Aid',
    ],
    courts: [
      ManagedCourt(
        id: 'c1',
        name: 'Court Alpha',
        description: 'Full-size 5v5 pitch with floodlights.',
        sport: SportType.football,
        pricePerHour: 90,
        capacity: 10,
        photoUrls: [
          'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=800&q=80',
          'https://images.unsplash.com/photo-1551958219-acbc1c2edbf8?w=800&q=80',
        ],
        surface: 'Artificial Turf',
        amenities: ['Floodlights', 'Changing Rooms', 'Parking'],
        isActive: true,
      ),
      ManagedCourt(
        id: 'c2',
        name: 'Padel Court A',
        description: 'Glass-walled padel court.',
        sport: SportType.padel,
        pricePerHour: 120,
        capacity: 4,
        photoUrls: [
          'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=800&q=80',
        ],
        surface: 'Artificial Turf',
        amenities: ['Floodlights', 'Equipment Rental', 'AC'],
        isActive: true,
      ),
      ManagedCourt(
        id: 'c3',
        name: 'Tennis Court 1',
        description: 'Outdoor clay court.',
        sport: SportType.tennis,
        pricePerHour: 105,
        capacity: 4,
        photoUrls: [
          'https://images.unsplash.com/photo-1545809074-59472b3f5ecc?w=800&q=80',
        ],
        surface: 'Clay',
        amenities: ['Coaching', 'Equipment Rental'],
        isActive: false,
      ),
    ],
  ),
  ManagedVenue(
    id: 'v2',
    name: 'Padel Club Marsa',
    location: 'La Marsa, Tunis',
    phone: '+216 71 345 678',
    description: 'Premium padel and tennis on the waterfront.',
    openTime: '07:00',
    closeTime: '22:00',
    photoUrls: [
      'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=1200&q=80',
    ],
    sports: [SportType.padel, SportType.tennis],
    amenities: ['Parking', 'Cafe', 'Coaching', 'Wifi', 'Seating'],
    courts: [
      ManagedCourt(
        id: 'c4',
        name: 'Padel Court 1',
        description: 'Panoramic sea views.',
        sport: SportType.padel,
        pricePerHour: 140,
        capacity: 4,
        photoUrls: [
          'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=800&q=80',
        ],
        surface: 'Artificial Turf',
        amenities: ['AC', 'Coaching', 'Cafe'],
        isActive: true,
      ),
    ],
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// ROOT — venue list page
// ─────────────────────────────────────────────────────────────────────────────
class VenuePage extends StatefulWidget {
  const VenuePage({super.key});
  @override
  State<VenuePage> createState() => _VenuePageState();
}

class _VenuePageState extends State<VenuePage> {
  late List<ManagedVenue> _venues;

  @override
  void initState() {
    super.initState();
    _venues = _sampleVenues();
  }

  void _addVenue(ManagedVenue v) => setState(() => _venues.add(v));
  void _updateVenue(ManagedVenue v) => setState(() {
    final i = _venues.indexWhere((x) => x.id == v.id);
    if (i != -1) _venues[i] = v;
  });
  void _deleteVenue(String id) =>
      setState(() => _venues.removeWhere((v) => v.id == id));

  @override
  Widget build(BuildContext context) {
    final navH =
        kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ──────────────────────────────────────────────────────────
          SliverToBoxAdapter(child: _Header(venueCount: _venues.length)),

          // ── Venue list ───────────────────────────────────────────────────────
          _venues.isEmpty
              ? SliverToBoxAdapter(child: _EmptyVenues(onAdd: _openAddVenue))
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _VenueCard(
                        venue: _venues[i],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _VenueDetailPage(
                              venue: _venues[i],
                              onSaved: _updateVenue,
                              onDeleted: () => _deleteVenue(_venues[i].id),
                            ),
                          ),
                        ),
                      ),
                      childCount: _venues.length,
                    ),
                  ),
                ),

          // ── Add Venue button ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, navH + 24),
              child: GestureDetector(
                onTap: _openAddVenue,
                child: Container(
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: kPrimary.withOpacity(0.25),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimary.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [kPrimary, Color(0xFF007B7D)],
                          ),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Add New Venue',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: kPrimary,
                          letterSpacing: -0.2,
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
    );
  }

  void _openAddVenue() => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) => _VenueFormSheet(
      onSave: (v) {
        Navigator.pop(context);
        _addVenue(v);
      },
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final int venueCount;
  const _Header({required this.venueCount});

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF001F20), Color(0xFF003D3E), kPrimary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    clipBehavior: Clip.hardEdge,
    child: Stack(
      children: [
        // Grid
        Positioned.fill(
          child: Opacity(
            opacity: 0.04,
            child: CustomPaint(painter: _GridPainter()),
          ),
        ),
        // Circles
        Positioned(
          right: -40,
          top: -40,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.04),
            ),
          ),
        ),
        Positioned(
          left: -20,
          bottom: -30,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.03),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF007B7D), Color(0xFF00A8AB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                          width: 2.5,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'AT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
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
                          Text(
                            'Welcome back,',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                          const Text(
                            'Anis Trabelsi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.phone_rounded,
                                size: 11,
                                color: Colors.white.withOpacity(0.5),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '+216 71 234 567',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 19,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Stats strip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.09),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Row(
                    children: [
                      _HS('$venueCount', 'Venues', Icons.location_city_rounded),
                      _HDivider(),
                      _HS('6', 'Courts', Icons.sports_tennis_rounded),
                      _HDivider(),
                      _HS('5', 'Active', Icons.check_circle_outline_rounded),
                      _HDivider(),
                      _HS('4.8', 'Rating', Icons.star_rounded),
                    ],
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

class _HS extends StatelessWidget {
  final String value, label;
  final IconData icon;
  const _HS(this.value, this.label, this.icon);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Icon(icon, size: 14, color: Colors.white.withOpacity(0.65)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

class _HDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 26,
    color: Colors.white.withOpacity(0.15),
    margin: const EdgeInsets.symmetric(horizontal: 4),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// VENUE CARD — list item
// ─────────────────────────────────────────────────────────────────────────────
class _VenueCard extends StatelessWidget {
  final ManagedVenue venue;
  final VoidCallback onTap;
  const _VenueCard({required this.venue, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = venue.courts.where((c) => c.isActive).length;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: kPrimary.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Photo
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              child: SizedBox(
                height: 165,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    venue.photoUrls.isNotEmpty
                        ? Image.network(
                            venue.photoUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _VenuePh(),
                          )
                        : _VenuePh(),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.65),
                          ],
                          stops: const [0.35, 1.0],
                        ),
                      ),
                    ),
                    // Name
                    Positioned(
                      bottom: 14,
                      left: 14,
                      right: 14,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            venue.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 11,
                                color: Colors.white.withOpacity(0.6),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                venue.location,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.75),
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
              ),
            ),
            // Bottom row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                children: [
                  _VChip(
                    Icons.sports_tennis_rounded,
                    '${venue.courts.length} courts',
                    kPrimary,
                  ),
                  const SizedBox(width: 10),
                  _VChip(Icons.location_on_rounded, venue.location, kTextMid),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [kPrimary, Color(0xFF007B7D)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Manage',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 5),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 13,
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
    );
  }
}

class _VChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _VChip(this.icon, this.label, this.color);
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 11, color: color),
      const SizedBox(width: 4),
      Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    ],
  );
}

class _VenuePh extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF001F20), kPrimary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Center(
      child: Icon(
        Icons.stadium_rounded,
        size: 52,
        color: Colors.white.withOpacity(0.18),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY VENUES
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyVenues extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyVenues({required this.onAdd});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
    child: Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimary.withOpacity(0.09), kPrimary.withOpacity(0.03)],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: kPrimary.withOpacity(0.12), width: 2),
          ),
          child: Icon(
            Icons.add_business_rounded,
            size: 40,
            color: kPrimary.withOpacity(0.4),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'No venues yet',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: kTextDark,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Add your first venue to start managing courts and bookings.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: kTextMid, height: 1.6),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// VENUE DETAIL PAGE
// ─────────────────────────────────────────────────────────────────────────────
class _VenueDetailPage extends StatefulWidget {
  final ManagedVenue venue;
  final ValueChanged<ManagedVenue> onSaved;
  final VoidCallback onDeleted;
  const _VenueDetailPage({
    required this.venue,
    required this.onSaved,
    required this.onDeleted,
  });
  @override
  State<_VenueDetailPage> createState() => _VenueDetailPageState();
}

class _VenueDetailPageState extends State<_VenueDetailPage> {
  late ManagedVenue _v;
  SportType? _filter;

  @override
  void initState() {
    super.initState();
    _v = widget.venue;
  }

  void _persist() => widget.onSaved(_v);

  List<ManagedCourt> get _filtered =>
      _v.courts.where((c) => _filter == null || c.sport == _filter).toList();

  @override
  Widget build(BuildContext context) {
    final navH =
        kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    final active = _v.courts.where((c) => c.isActive).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Hero photo
          SliverToBoxAdapter(
            child: _VenueHero(
              venue: _v,
              onBack: () => Navigator.pop(context),
              onEdit: () => _openEditVenue(),
              onDelete: () => _confirmDeleteVenue(),
            ),
          ),

          // Info strip
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: _VenueInfoStrip(venue: _v),
            ),
          ),

          // Stats
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _VenueStats(
                courts: _v.courts.length,
                active: active,
                sports: _v.sports.length,
              ),
            ),
          ),

          // Courts header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Courts',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: kTextDark,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            '${_v.courts.length} courts · $active active',
                            style: const TextStyle(
                              fontSize: 12,
                              color: kTextMid,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      _GradBtn(
                        icon: Icons.add_rounded,
                        label: 'Add Court',
                        onTap: () => _openCourtForm(null),
                      ),
                    ],
                  ),
                  if (_v.sports.length > 1) ...[
                    const SizedBox(height: 14),
                    _SportFilter(
                      sports: _v.sports,
                      selected: _filter,
                      onChanged: (s) => setState(() => _filter = s),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Courts list
          _filtered.isEmpty
              ? SliverToBoxAdapter(
                  child: _EmptyCourts(onAdd: () => _openCourtForm(null)),
                )
              : SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 14, 16, navH + 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _CourtCard(
                        court: _filtered[i],
                        onEdit: () => _openCourtForm(_filtered[i]),
                        onDelete: () => _confirmDeleteCourt(_filtered[i]),
                        onToggle: () {
                          setState(() {
                            final idx = _v.courts.indexWhere(
                              (c) => c.id == _filtered[i].id,
                            );
                            if (idx != -1)
                              _v.courts[idx].isActive =
                                  !_v.courts[idx].isActive;
                          });
                          _persist();
                        },
                      ),
                      childCount: _filtered.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  void _openEditVenue() => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) => _VenueFormSheet(
      existing: _v,
      onSave: (u) {
        Navigator.pop(context);
        setState(() => _v = u);
        _persist();
      },
    ),
  );

  void _openCourtForm(ManagedCourt? existing) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) => _CourtFormSheet(
      existing: existing,
      venueSports: _v.sports,
      onSave: (c) {
        Navigator.pop(context);
        setState(() {
          if (existing == null) {
            _v.courts.add(c);
          } else {
            final i = _v.courts.indexWhere((x) => x.id == c.id);
            if (i != -1) _v.courts[i] = c;
          }
        });
        _persist();
      },
    ),
  );

  void _confirmDeleteVenue() => showDialog(
    context: context,
    builder: (_) => _ConfirmDialog(
      icon: Icons.delete_forever_rounded,
      iconColor: kRed,
      title: 'Delete Venue',
      message: 'Remove "${_v.name}" and all its courts permanently?',
      confirmLabel: 'Delete',
      confirmColor: kRed,
      onConfirm: () {
        Navigator.pop(context);
        Navigator.pop(context);
        widget.onDeleted();
      },
    ),
  );

  void _confirmDeleteCourt(ManagedCourt c) => showDialog(
    context: context,
    builder: (_) => _ConfirmDialog(
      icon: Icons.delete_outline_rounded,
      iconColor: kRed,
      title: 'Delete Court',
      message: 'Remove "${c.name}" permanently?',
      confirmLabel: 'Delete',
      confirmColor: kRed,
      onConfirm: () {
        Navigator.pop(context);
        setState(() => _v.courts.removeWhere((x) => x.id == c.id));
        _persist();
      },
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// VENUE HERO
// ─────────────────────────────────────────────────────────────────────────────
class _VenueHero extends StatefulWidget {
  final ManagedVenue venue;
  final VoidCallback onBack, onEdit, onDelete;
  const _VenueHero({
    required this.venue,
    required this.onBack,
    required this.onEdit,
    required this.onDelete,
  });
  @override
  State<_VenueHero> createState() => _VenueHeroState();
}

class _VenueHeroState extends State<_VenueHero> {
  int _idx = 0;
  @override
  Widget build(BuildContext context) {
    final photos = widget.venue.photoUrls;
    return SizedBox(
      height: 285,
      child: Stack(
        fit: StackFit.expand,
        children: [
          photos.isEmpty
              ? _VenuePh()
              : PageView.builder(
                  itemCount: photos.length,
                  onPageChanged: (i) => setState(() => _idx = i),
                  itemBuilder: (_, i) => Image.network(
                    photos[i],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _VenuePh(),
                  ),
                ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.12),
                  Colors.black.withOpacity(0.78),
                ],
                stops: const [0.25, 1.0],
              ),
            ),
          ),
          // Top bar
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
                    _HeroBtn(Icons.arrow_back_ios_rounded, widget.onBack),
                    const Spacer(),
                    _HeroPill(Icons.edit_rounded, 'Edit', widget.onEdit),
                    const SizedBox(width: 8),
                    _HeroBtn(
                      Icons.delete_outline_rounded,
                      widget.onDelete,
                      color: kRed.withOpacity(0.85),
                    ),
                  ],
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
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: widget.venue.sports
                        .take(4)
                        .map(
                          (s) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: s.color,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(s.icon, size: 10, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  s.label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.venue.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                    ),
                  ),
                  if (photos.length > 1) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(
                        photos.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 5),
                          width: _idx == i ? 18 : 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: _idx == i
                                ? Colors.white
                                : Colors.white.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  const _HeroBtn(this.icon, this.onTap, {this.color});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color ?? Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white, size: 16),
    ),
  );
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _HeroPill(this.icon, this.label, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// VENUE INFO STRIP
// ─────────────────────────────────────────────────────────────────────────────
class _VenueInfoStrip extends StatelessWidget {
  final ManagedVenue venue;
  const _VenueInfoStrip({required this.venue});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _IR(Icons.location_on_rounded, venue.location, kPrimary),
            const SizedBox(width: 16),
            _IR(
              Icons.access_time_rounded,
              '${venue.openTime}–${venue.closeTime}',
              kGreen,
            ),
            const SizedBox(width: 16),
            _IR(Icons.phone_rounded, venue.phone, kTextMid),
          ],
        ),
        if (venue.description.isNotEmpty) ...[
          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 12),
          Text(
            venue.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: kTextMid, height: 1.5),
          ),
        ],
        if (venue.amenities.isNotEmpty) ...[
          const SizedBox(height: 14),
          Divider(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.workspace_premium_rounded, size: 13, color: kPrimary),
              const SizedBox(width: 6),
              const Text(
                'Amenities',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: kTextDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: venue.amenities
                .map(
                  (a) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kPrimary.withOpacity(0.15)),
                    ),
                    child: Text(
                      a,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: kPrimary,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    ),
  );
}

class _IR extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _IR(this.icon, this.label, this.color);
  @override
  Widget build(BuildContext context) => Flexible(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// VENUE STATS
// ─────────────────────────────────────────────────────────────────────────────
class _VenueStats extends StatelessWidget {
  final int courts, active, sports;
  const _VenueStats({
    required this.courts,
    required this.active,
    required this.sports,
  });
  @override
  Widget build(BuildContext context) {
    final items = [
      _VSI('$courts', 'Courts', Icons.grid_view_rounded, kPrimary),
      _VSI('$active', 'Active', Icons.check_circle_outline_rounded, kGreen),
      _VSI('$sports', 'Sports', Icons.sports_rounded, kPurple),
    ];
    return Row(
      children: items.asMap().entries.map((e) {
        final last = e.key == items.length - 1;
        final s = e.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: last ? 0 : 10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: s.color.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: s.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(s.icon, size: 15, color: s.color),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: s.color,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    s.label,
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: kTextMid,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _VSI {
  final String value, label;
  final IconData icon;
  final Color color;
  const _VSI(this.value, this.label, this.icon, this.color);
}

// ─────────────────────────────────────────────────────────────────────────────
// SPORT FILTER
// ─────────────────────────────────────────────────────────────────────────────
class _SportFilter extends StatelessWidget {
  final List<SportType> sports;
  final SportType? selected;
  final ValueChanged<SportType?> onChanged;
  const _SportFilter({
    required this.sports,
    required this.selected,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 36,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: [
        _Pill(
          'All',
          Icons.apps_rounded,
          selected == null,
          kPrimary,
          () => onChanged(null),
        ),
        ...sports.map(
          (s) => _Pill(
            s.label,
            s.icon,
            selected == s,
            s.color,
            () => onChanged(selected == s ? null : s),
          ),
        ),
      ],
    ),
  );
}

class _Pill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool on;
  final Color color;
  final VoidCallback onTap;
  const _Pill(this.label, this.icon, this.on, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: on ? color : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: on
                ? color.withOpacity(0.25)
                : Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: on ? Colors.white : kTextMid),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: on ? Colors.white : kTextMid,
            ),
          ),
        ],
      ),
    ),
  );
}

class _GradBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _GradBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [kPrimary, Color(0xFF007B7D)]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// COURT CARD
// ─────────────────────────────────────────────────────────────────────────────
class _CourtCard extends StatelessWidget {
  final ManagedCourt court;
  final VoidCallback onEdit, onDelete, onToggle;
  const _CourtCard({
    required this.court,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final c = court;
    final sc = c.sport.color;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: sc.withOpacity(0.07),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Photo gallery
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: SizedBox(
              height: 180,
              child: c.photoUrls.isEmpty
                  ? _CourtPh(sc)
                  : _CourtGallery(
                      photos: c.photoUrls,
                      sc: sc,
                      isActive: c.isActive,
                    ),
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [_CTag(c.sport.label, c.sport.icon, sc)],
                          ),
                          const SizedBox(height: 7),
                          Text(
                            c.name,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: kTextDark,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: onToggle,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: c.isActive
                              ? kGreen.withOpacity(0.09)
                              : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: c.isActive
                                ? kGreen.withOpacity(0.3)
                                : const Color(0xFFE0E0E0),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: c.isActive ? kGreen : kTextLight,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              c.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: c.isActive ? kGreen : kTextLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (c.description.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(
                    c.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: kTextMid,
                      height: 1.5,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                // Stats bar
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FB),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _CStat(Icons.people_rounded, '${c.capacity}', 'players'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _ActBtn(
                        Icons.edit_rounded,
                        'Edit Court',
                        kPrimary,
                        filled: true,
                        onTap: onEdit,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _DelBtn(onTap: onDelete),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CourtGallery extends StatefulWidget {
  final List<String> photos;
  final Color sc;
  final bool isActive;
  const _CourtGallery({
    required this.photos,
    required this.sc,
    required this.isActive,
  });
  @override
  State<_CourtGallery> createState() => _CourtGalleryState();
}

class _CourtGalleryState extends State<_CourtGallery> {
  int _i = 0;
  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      PageView.builder(
        itemCount: widget.photos.length,
        onPageChanged: (i) => setState(() => _i = i),
        itemBuilder: (_, i) => Image.network(
          widget.photos[i],
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _CourtPh(widget.sc),
        ),
      ),
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.22)],
            stops: const [0.5, 1.0],
          ),
        ),
      ),
      Positioned(
        top: 12,
        right: 12,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: widget.isActive
                ? kGreen.withOpacity(0.88)
                : Colors.black.withOpacity(0.55),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                widget.isActive ? 'Active' : 'Inactive',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
      if (widget.photos.length > 1)
        Positioned(
          bottom: 10,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.photos.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: _i == i ? 14 : 5,
                height: 5,
                decoration: BoxDecoration(
                  color: _i == i
                      ? Colors.white
                      : Colors.white.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

class _CourtPh extends StatelessWidget {
  final Color sc;
  const _CourtPh(this.sc);
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Color.lerp(sc, Colors.black, 0.4)!, sc],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_rounded,
          size: 40,
          color: Colors.white.withOpacity(0.28),
        ),
        const SizedBox(height: 8),
        Text(
          'No photos',
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4)),
        ),
      ],
    ),
  );
}

class _CTag extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _CTag(this.label, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
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

class _CTagPlain extends StatelessWidget {
  final String label;
  const _CTagPlain(this.label);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFF0F2F5),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: kTextMid,
      ),
    ),
  );
}

class _CStat extends StatelessWidget {
  final IconData icon;
  final String value, label;
  const _CStat(this.icon, this.value, this.label);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Icon(icon, size: 14, color: kTextMid),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: kTextDark,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: kTextMid,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

class _CVDiv extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 26,
    color: const Color(0xFFE8EAF0),
    margin: const EdgeInsets.symmetric(horizontal: 6),
  );
}

class _ActBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;
  const _ActBtn(
    this.icon,
    this.label,
    this.color, {
    required this.onTap,
    this.filled = false,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 44,
      decoration: filled
          ? BoxDecoration(
              gradient: LinearGradient(
                colors: color == kPrimary
                    ? [kPrimary, const Color(0xFF007B7D)]
                    : [color, color],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            )
          : BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: filled ? Colors.white : color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
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

class _DelBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _DelBtn({required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: kRed.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kRed.withOpacity(0.2)),
      ),
      child: const Icon(Icons.delete_outline_rounded, color: kRed, size: 18),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY COURTS
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyCourts extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyCourts({required this.onAdd});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
    child: Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimary.withOpacity(0.08), kPrimary.withOpacity(0.03)],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: kPrimary.withOpacity(0.1), width: 2),
          ),
          child: Icon(
            Icons.add_business_rounded,
            size: 36,
            color: kPrimary.withOpacity(0.4),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'No courts yet',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: kTextDark,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Add your first court so players can book it.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: kTextMid, height: 1.6),
        ),
        const SizedBox(height: 22),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kPrimary, Color(0xFF007B7D)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: kPrimary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: Colors.white, size: 17),
                SizedBox(width: 8),
                Text(
                  'Add First Court',
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
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// VENUE FORM SHEET — add or edit
// ─────────────────────────────────────────────────────────────────────────────
class _VenueFormSheet extends StatefulWidget {
  final ManagedVenue? existing;
  final ValueChanged<ManagedVenue> onSave;
  const _VenueFormSheet({this.existing, required this.onSave});
  @override
  State<_VenueFormSheet> createState() => _VenueFormSheetState();
}

class _VenueFormSheetState extends State<_VenueFormSheet> {
  late final _nameCtrl = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late final _locCtrl = TextEditingController(
    text: widget.existing?.location ?? '',
  );
  late final _phoneCtrl = TextEditingController(
    text: widget.existing?.phone ?? '',
  );
  late final _descCtrl = TextEditingController(
    text: widget.existing?.description ?? '',
  );
  late String _openTime = widget.existing?.openTime ?? '08:00';
  late String _closeTime = widget.existing?.closeTime ?? '23:00';
  late final Set<SportType> _sports = Set.from(widget.existing?.sports ?? []);
  late final Set<String> _amenities = Set.from(
    widget.existing?.amenities ?? [],
  );
  late final List<String> _photos = List.from(widget.existing?.photoUrls ?? []);
  final _key = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locCtrl.dispose();
    _phoneCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_key.currentState!.validate()) return;
    widget.onSave(
      ManagedVenue(
        id: widget.existing?.id ?? 'v_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameCtrl.text.trim(),
        location: _locCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        openTime: _openTime,
        closeTime: _closeTime,
        photoUrls: _photos,
        sports: _sports.toList(),
        amenities: _amenities.toList(),
        courts: widget.existing?.courts ?? [],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final bot = MediaQuery.of(context).padding.bottom;
    return _FormShell(
      title: isEdit ? 'Edit Venue' : 'Add New Venue',
      subtitle: isEdit ? 'Update your venue details' : 'Set up your new venue',
      icon: isEdit ? Icons.edit_rounded : Icons.add_business_rounded,
      bot: bot,
      onSave: _save,
      formKey: _key,
      child: Column(
        children: [
          _Sec(
            'Photos',
            Icons.photo_library_rounded,
            child: _PhotoPicker(
              photos: _photos,
              onAdd: () => setState(
                () => _photos.add(
                  'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=1200&q=80',
                ),
              ),
              onRemove: (i) => setState(() => _photos.removeAt(i)),
            ),
          ),
          const SizedBox(height: 14),
          _Sec(
            'Venue Info',
            Icons.stadium_rounded,
            child: Column(
              children: [
                _TF(
                  ctrl: _nameCtrl,
                  label: 'Venue Name',
                  hint: 'e.g. Arena Sport Center',
                  icon: Icons.label_rounded,
                  required: true,
                ),
                const SizedBox(height: 12),
                _TF(
                  ctrl: _locCtrl,
                  label: 'Location',
                  hint: 'e.g. Lac 2, Tunis',
                  icon: Icons.location_on_rounded,
                  required: true,
                ),
                const SizedBox(height: 12),
                _TF(
                  ctrl: _phoneCtrl,
                  label: 'Phone',
                  hint: '+216 XX XXX XXX',
                  icon: Icons.phone_rounded,
                  type: TextInputType.phone,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _Sec(
            'Opening Hours',
            Icons.schedule_rounded,
            child: Row(
              children: [
                Expanded(
                  child: _TP(
                    label: 'Opens at',
                    value: _openTime,
                    onChanged: (v) => setState(() => _openTime = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TP(
                    label: 'Closes at',
                    value: _closeTime,
                    onChanged: (v) => setState(() => _closeTime = v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _Sec(
            'Sports',
            Icons.sports_rounded,
            child: Column(
              children: SportType.values.map((s) {
                final on = _sports.contains(s);
                return GestureDetector(
                  onTap: () =>
                      setState(() => on ? _sports.remove(s) : _sports.add(s)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: on ? s.color.withOpacity(0.07) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: on
                            ? s.color.withOpacity(0.3)
                            : const Color(0xFFE8EAF0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: s.color.withOpacity(on ? 0.12 : 0.06),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(s.icon, color: s.color, size: 17),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            s.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: on ? s.color : kTextDark,
                            ),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 21,
                          height: 21,
                          decoration: BoxDecoration(
                            color: on ? s.color : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: on ? s.color : const Color(0xFFD0D3DB),
                              width: 1.5,
                            ),
                          ),
                          child: on
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 12,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          _Sec(
            'Description',
            Icons.description_rounded,
            child: _TF(
              ctrl: _descCtrl,
              label: 'About the venue',
              hint: 'Tell players what makes your venue special...',
              icon: Icons.edit_note_rounded,
              maxLines: 4,
            ),
          ),
          const SizedBox(height: 14),
          _Sec(
            'Amenities',
            Icons.workspace_premium_rounded,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  [
                    'Parking',
                    'Showers',
                    'Changing Rooms',
                    'Cafe',
                    'Wifi',
                    'First Aid',
                    'Seating',
                    'Coaching',
                    'Equipment Rental',
                    'AC',
                    'Lockers',
                    'Pro Shop',
                  ].map((a) {
                    final on = _amenities.contains(a);
                    return GestureDetector(
                      onTap: () => setState(
                        () => on ? _amenities.remove(a) : _amenities.add(a),
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: on ? kPrimary : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: on ? kPrimary : const Color(0xFFE0E3E8),
                          ),
                          boxShadow: on
                              ? [
                                  BoxShadow(
                                    color: kPrimary.withOpacity(0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (on) ...[
                              const Icon(
                                Icons.check_rounded,
                                size: 11,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              a,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: on ? Colors.white : kTextMid,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COURT FORM SHEET — add or edit
// ─────────────────────────────────────────────────────────────────────────────
class _CourtFormSheet extends StatefulWidget {
  final ManagedCourt? existing;
  final List<SportType> venueSports;
  final ValueChanged<ManagedCourt> onSave;
  const _CourtFormSheet({
    this.existing,
    required this.venueSports,
    required this.onSave,
  });
  @override
  State<_CourtFormSheet> createState() => _CourtFormSheetState();
}

class _CourtFormSheetState extends State<_CourtFormSheet> {
  late final _nameCtrl = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late final _descCtrl = TextEditingController(
    text: widget.existing?.description ?? '',
  );
  late final _priceCtrl = TextEditingController(
    text: widget.existing?.pricePerHour.toStringAsFixed(0) ?? '',
  );
  late final _capCtrl = TextEditingController(
    text: widget.existing?.capacity.toString() ?? '',
  );
  late SportType _sport =
      widget.existing?.sport ??
      (widget.venueSports.isNotEmpty
          ? widget.venueSports.first
          : SportType.football);
  late String _surface = widget.existing?.surface ?? 'Artificial Turf';
  late final List<String> _photos = List.from(widget.existing?.photoUrls ?? []);
  final _key = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _capCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_key.currentState!.validate()) return;
    widget.onSave(
      ManagedCourt(
        id: widget.existing?.id ?? 'c_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        sport: _sport,
        pricePerHour: double.tryParse(_priceCtrl.text) ?? 0,
        capacity: int.tryParse(_capCtrl.text) ?? 0,
        photoUrls: _photos,
        surface: _surface,
        amenities: const [],
        isActive: widget.existing?.isActive ?? true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final bot = MediaQuery.of(context).padding.bottom;
    return _FormShell(
      title: isEdit ? 'Edit Court' : 'Add New Court',
      subtitle: isEdit
          ? 'Update court details'
          : 'Fill in the court information',
      icon: isEdit ? Icons.edit_rounded : Icons.add_rounded,
      bot: bot,
      onSave: _save,
      formKey: _key,
      child: Column(
        children: [
          _Sec(
            'Photos',
            Icons.photo_library_rounded,
            child: _PhotoPicker(
              photos: _photos,
              onAdd: () => setState(
                () => _photos.add(
                  'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=800&q=80',
                ),
              ),
              onRemove: (i) => setState(() => _photos.removeAt(i)),
            ),
          ),
          const SizedBox(height: 14),
          _Sec(
            'Basic Info',
            Icons.info_outline_rounded,
            child: Column(
              children: [
                _TF(
                  ctrl: _nameCtrl,
                  label: 'Court Name',
                  hint: 'e.g. Court Alpha, Padel 1',
                  icon: Icons.label_rounded,
                  required: true,
                ),
                const SizedBox(height: 12),
                _TF(
                  ctrl: _descCtrl,
                  label: 'Description',
                  hint: 'Describe surface, lighting, size...',
                  icon: Icons.description_rounded,
                  maxLines: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _Sec(
            'Sport',
            Icons.sports_rounded,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  (widget.venueSports.isEmpty
                          ? SportType.values
                          : widget.venueSports)
                      .map((s) {
                        final sel = _sport == s;
                        return GestureDetector(
                          onTap: () => setState(() => _sport = s),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: sel ? s.color : const Color(0xFFF0F2F5),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: sel
                                  ? [
                                      BoxShadow(
                                        color: s.color.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  s.icon,
                                  size: 13,
                                  color: sel ? Colors.white : kTextMid,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  s.label,
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
                      })
                      .toList(),
            ),
          ),
          const SizedBox(height: 14),
          _Sec(
            'Pricing & Capacity',
            Icons.tune_rounded,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _TF(
                    ctrl: _priceCtrl,
                    label: 'Price (DT)',
                    hint: '0',
                    icon: Icons.payments_rounded,
                    type: TextInputType.number,
                    required: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TF(
                    ctrl: _capCtrl,
                    label: 'Max Players',
                    hint: '0',
                    icon: Icons.people_rounded,
                    type: TextInputType.number,
                    required: true,
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
// PHOTO PICKER
// ─────────────────────────────────────────────────────────────────────────────
class _PhotoPicker extends StatelessWidget {
  final List<String> photos;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  const _PhotoPicker({
    required this.photos,
    required this.onAdd,
    required this.onRemove,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 100,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: [
        GestureDetector(
          onTap: onAdd,
          child: Container(
            width: 100,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kPrimary.withOpacity(0.2), width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_rounded,
                  color: kPrimary.withOpacity(0.5),
                  size: 26,
                ),
                const SizedBox(height: 5),
                Text(
                  'Add Photo',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: kPrimary.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
        ...photos.asMap().entries.map(
          (e) => Container(
            width: 100,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
            clipBehavior: Clip.hardEdge,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  e.value,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFF0F2F5),
                    child: const Icon(
                      Icons.broken_image_rounded,
                      color: kTextLight,
                      size: 22,
                    ),
                  ),
                ),
                Positioned(
                  top: 5,
                  right: 5,
                  child: GestureDetector(
                    onTap: () => onRemove(e.key),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 11,
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

// ─────────────────────────────────────────────────────────────────────────────
// CONFIRM DIALOG
// ─────────────────────────────────────────────────────────────────────────────
class _ConfirmDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, message, confirmLabel;
  final Color confirmColor;
  final VoidCallback onConfirm;
  const _ConfirmDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmColor,
    required this.onConfirm,
  });
  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
    actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.09),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: kTextDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: kTextMid, height: 1.5),
        ),
      ],
    ),
    actions: [
      Row(
        children: [
          Expanded(
            child: _ActBtn(
              Icons.close_rounded,
              'Cancel',
              kTextMid,
              onTap: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActBtn(
              Icons.delete_rounded,
              confirmLabel,
              confirmColor,
              filled: true,
              onTap: onConfirm,
            ),
          ),
        ],
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// FORM SHELL — shared bottom sheet wrapper
// ─────────────────────────────────────────────────────────────────────────────
class _FormShell extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final double bot;
  final VoidCallback onSave;
  final Widget child;
  final GlobalKey<FormState>? formKey;
  const _FormShell({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.bot,
    required this.onSave,
    required this.child,
    this.formKey,
  });
  @override
  Widget build(BuildContext context) => Container(
    height: MediaQuery.of(context).size.height * 0.93,
    decoration: const BoxDecoration(
      color: Color(0xFFF0F2F5),
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    child: Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E5EA),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [kPrimary, Color(0xFF007B7D)],
                      ),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, color: Colors.white, size: 19),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: kTextDark,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(fontSize: 12, color: kTextMid),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: kTextMid,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: formKey != null
              ? Form(key: formKey, child: _scrollBody())
              : _scrollBody(),
        ),
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 16,
                offset: Offset(0, -4),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(20, 14, 20, bot + 16),
          child: _ActBtn(
            Icons.check_rounded,
            'Save',
            kPrimary,
            filled: true,
            onTap: onSave,
          ),
        ),
      ],
    ),
  );

  Widget _scrollBody() => ListView(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
    children: [child, const SizedBox(height: 100)],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED FORM WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _Sec extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _Sec(this.title, this.icon, {required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.025),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: kPrimary),
            const SizedBox(width: 7),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: kTextDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(height: 1, color: const Color(0xFFF0F2F5)),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}

class _SL extends StatelessWidget {
  final String t;
  const _SL(this.t);
  @override
  Widget build(BuildContext context) => Text(
    t,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: kTextMid,
    ),
  );
}

class _TF extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final IconData icon;
  final TextInputType type;
  final int maxLines;
  final bool required;
  const _TF({
    required this.ctrl,
    required this.label,
    required this.hint,
    required this.icon,
    this.type = TextInputType.text,
    this.maxLines = 1,
    this.required = false,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: kTextDark,
          ),
        ),
      ),
      TextFormField(
        controller: ctrl,
        keyboardType: type,
        maxLines: maxLines,
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: kTextDark,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: kTextLight, fontSize: 13),
          prefixIcon: Icon(icon, color: kPrimary, size: 17),
          filled: true,
          fillColor: const Color(0xFFF7F8FB),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE8EAF0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kPrimary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kRed),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kRed, width: 1.5),
          ),
        ),
      ),
    ],
  );
}

class _TP extends StatelessWidget {
  final String label, value;
  final ValueChanged<String> onChanged;
  const _TP({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () async {
      final p = value.split(':');
      final t = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1])),
      );
      if (t != null)
        onChanged(
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
        );
    },
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EAF0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time_rounded, size: 15, color: kPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: kTextMid,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: kTextDark,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 15, color: kTextLight),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// GRID PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  const _GridPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withOpacity(0.055)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 32)
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    for (double y = 0; y < size.height; y += 32)
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
  }

  @override
  bool shouldRepaint(_) => false;
}
