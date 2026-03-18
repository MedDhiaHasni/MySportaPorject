import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Models/app_enums.dart';
import 'package:sporta/Widgets/Lists/grid_painter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────
class VenueModel {
  String name;
  String location;
  String phone;
  String description;
  String openTime;
  String closeTime;
  String? coverImageUrl;
  String? logoImageUrl;
  List<SportType> sports;
  List<CourtModel> courts;

  VenueModel({
    required this.name,
    required this.location,
    required this.phone,
    required this.description,
    required this.openTime,
    required this.closeTime,
    this.coverImageUrl,
    this.logoImageUrl,
    required this.sports,
    required this.courts,
  });
}

class CourtModel {
  String id;
  String name;
  String description;
  SportType sport;
  double pricePerHour;
  int capacity;
  List<String> photoUrls;
  String surface;
  List<String> amenities;
  bool isActive;

  CourtModel({
    required this.id,
    required this.name,
    required this.description,
    required this.sport,
    required this.pricePerHour,
    required this.capacity,
    required this.photoUrls,
    required this.surface,
    required this.amenities,
    this.isActive = true,
  });

  CourtModel copyWith({
    String? name,
    String? description,
    SportType? sport,
    double? pricePerHour,
    int? capacity,
    List<String>? photoUrls,
    String? surface,
    List<String>? amenities,
    bool? isActive,
  }) => CourtModel(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
    sport: sport ?? this.sport,
    pricePerHour: pricePerHour ?? this.pricePerHour,
    capacity: capacity ?? this.capacity,
    photoUrls: photoUrls ?? this.photoUrls,
    surface: surface ?? this.surface,
    amenities: amenities ?? this.amenities,
    isActive: isActive ?? this.isActive,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// VENUE PAGE — Direct management page (no creation flow)
// ─────────────────────────────────────────────────────────────────────────────
class VenuePage extends StatefulWidget {
  const VenuePage({super.key});
  @override
  State<VenuePage> createState() => _VenuePageState();
}

class _VenuePageState extends State<VenuePage> {
  // Initialize with default venue data
  VenueModel _venue = VenueModel(
    name: 'Arena Sport Center',
    location: 'Lac 2, Tunis, Tunisia',
    phone: '+216 XX XXX XXX',
    description:
        'Modern sports facility with top-quality courts and professional atmosphere.',
    openTime: '08:00',
    closeTime: '23:00',
    sports: [SportType.football, SportType.padel, SportType.tennis],
    courts: [
      CourtModel(
        id: 'c1',
        name: 'Court Alpha',
        description: 'Professional football court with floodlights',
        sport: SportType.football,
        pricePerHour: 90,
        capacity: 10,
        photoUrls: [
          'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=700&q=80',
        ],
        surface: 'Artificial Turf',
        amenities: ['Floodlights', 'Changing Rooms', 'Parking'],
        isActive: true,
      ),
      CourtModel(
        id: 'c2',
        name: 'Court Beta',
        description: 'Premium padel court with glass walls',
        sport: SportType.padel,
        pricePerHour: 120,
        capacity: 4,
        photoUrls: [
          'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=700&q=80',
        ],
        surface: 'Artificial Turf',
        amenities: ['Floodlights', 'Equipment Rental', 'Parking'],
        isActive: true,
      ),
    ],
  );

  void _updateVenue(VenueModel updated) => setState(() => _venue = updated);
  void _addCourt(CourtModel court) => setState(() => _venue.courts.add(court));
  void _updateCourt(CourtModel court) => setState(() {
    final i = _venue.courts.indexWhere((c) => c.id == court.id);
    if (i != -1) _venue.courts[i] = court;
  });
  void _deleteCourt(String id) =>
      setState(() => _venue.courts.removeWhere((c) => c.id == id));
  void _toggleCourt(String id) => setState(() {
    final i = _venue.courts.indexWhere((c) => c.id == id);
    if (i != -1) _venue.courts[i].isActive = !_venue.courts[i].isActive;
  });

  @override
  Widget build(BuildContext context) {
    return _VenueDetailPage(
      venue: _venue,
      onVenueUpdated: _updateVenue,
      onAddCourt: _addCourt,
      onUpdateCourt: _updateCourt,
      onDeleteCourt: _deleteCourt,
      onToggleCourt: _toggleCourt,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VENUE DETAIL PAGE
// ─────────────────────────────────────────────────────────────────────────────
class _VenueDetailPage extends StatefulWidget {
  final VenueModel venue;
  final ValueChanged<VenueModel> onVenueUpdated;
  final ValueChanged<CourtModel> onAddCourt;
  final ValueChanged<CourtModel> onUpdateCourt;
  final ValueChanged<String> onDeleteCourt;
  final ValueChanged<String> onToggleCourt;

  const _VenueDetailPage({
    required this.venue,
    required this.onVenueUpdated,
    required this.onAddCourt,
    required this.onUpdateCourt,
    required this.onDeleteCourt,
    required this.onToggleCourt,
  });

  @override
  State<_VenueDetailPage> createState() => _VenueDetailPageState();
}

class _VenueDetailPageState extends State<_VenueDetailPage> {
  SportType? _filter;

  List<CourtModel> get _filtered => widget.venue.courts
      .where((c) => _filter == null || c.sport == _filter)
      .toList();

  @override
  Widget build(BuildContext context) {
    final v = widget.venue;
    final navH =
        kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: kBg,
      body: CustomScrollView(
        slivers: [
          // ── Venue header ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _VenueHeader(venue: v, onEdit: () => _openEditVenue(v)),
          ),

          // ── Stats bar ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _VenueStats(venue: v),
            ),
          ),

          // ── Courts section title + filter ─────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Courts',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: kTextDark,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${widget.venue.courts.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: kPrimary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _openAddCourt(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: kPrimary,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: kPrimary.withOpacity(0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_rounded,
                                size: 15,
                                color: Colors.white,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Add Court',
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
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Sport filter pills
                  if (widget.venue.sports.isNotEmpty)
                    _SportFilterRow(
                      sports: widget.venue.sports,
                      selected: _filter,
                      onChanged: (s) => setState(() => _filter = s),
                    ),
                ],
              ),
            ),
          ),

          // ── Courts list ───────────────────────────────────────────────────
          _filtered.isEmpty
              ? SliverToBoxAdapter(child: _EmptyCourts(onAdd: _openAddCourt))
              : SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, navH + 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _CourtCard(
                        court: _filtered[i],
                        onEdit: () => _openEditCourt(_filtered[i]),
                        onDelete: () => _confirmDeleteCourt(_filtered[i]),
                        onToggle: () => widget.onToggleCourt(_filtered[i].id),
                      ),
                      childCount: _filtered.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  void _openAddCourt() => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CourtFormSheet(
      venueSports: widget.venue.sports,
      onSave: (court) {
        Navigator.pop(context);
        widget.onAddCourt(court);
      },
    ),
  );

  void _openEditCourt(CourtModel court) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CourtFormSheet(
      existing: court,
      venueSports: widget.venue.sports,
      onSave: (updated) {
        Navigator.pop(context);
        widget.onUpdateCourt(updated);
      },
    ),
  );

  void _openEditVenue(VenueModel v) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EditVenueSheet(
      venue: v,
      onSave: (updated) {
        Navigator.pop(context);
        widget.onVenueUpdated(updated);
      },
    ),
  );

  void _confirmDeleteCourt(CourtModel c) => showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: const Text(
        'Delete Court',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: kTextDark,
        ),
      ),
      content: Text(
        'Remove "${c.name}" permanently?',
        style: const TextStyle(color: kTextMid, fontSize: 14, height: 1.5),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Row(
          children: [
            Expanded(
              child: _Btn(
                'Cancel',
                outlined: true,
                onTap: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Btn(
                'Delete',
                color: kRed,
                onTap: () {
                  Navigator.pop(context);
                  widget.onDeleteCourt(c.id);
                },
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// VENUE HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _VenueHeader extends StatelessWidget {
  final VenueModel venue;
  final VoidCallback onEdit;
  const _VenueHeader({required this.venue, required this.onEdit});

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF00272A), kPrimary, Color(0xFF007B7D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    clipBehavior: Clip.hardEdge,
    child: Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: GridPainter())),
        // Decorative circles
        Positioned(
          right: -30,
          top: -30,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.04),
            ),
          ),
        ),
        Positioned(
          left: -15,
          bottom: -20,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.03),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row
                Row(
                  children: [
                    // Logo
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: const Icon(
                        Icons.stadium_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            venue.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 12,
                                color: Colors.white.withOpacity(0.6),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  venue.location,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.65),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: onEdit,
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Pills row
                Wrap(
                  spacing: 6,
                  children: [
                    _HPill(
                      Icons.access_time_rounded,
                      '${venue.openTime} – ${venue.closeTime}',
                    ),
                    _HPill(Icons.phone_rounded, venue.phone),
                    ...venue.sports
                        .take(3)
                        .map((s) => _HPill(s.icon, s.label, color: s.color)),
                  ],
                ),
                if (venue.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    venue.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                      height: 1.5,
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

class _HPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _HPill(this.icon, this.label, {this.color});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.15)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color ?? Colors.white.withOpacity(0.8)),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color ?? Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// VENUE STATS BAR
// ─────────────────────────────────────────────────────────────────────────────
class _VenueStats extends StatelessWidget {
  final VenueModel venue;
  const _VenueStats({required this.venue});

  @override
  Widget build(BuildContext context) {
    final active = venue.courts.where((c) => c.isActive).length;
    final sports = venue.sports.length;
    final stats = [
      _S(
        'Courts',
        '${venue.courts.length}',
        Icons.sports_tennis_rounded,
        kPrimary,
      ),
      _S('Active', '$active', Icons.check_circle_rounded, kGreen),
      _S('Sports', '$sports', Icons.sports_rounded, kPurple),
      _S('Rating', '4.8', Icons.star_rounded, kAmber),
    ];
    return Row(
      children: stats.asMap().entries.map((e) {
        final last = e.key == stats.length - 1;
        final s = e.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: last ? 0 : 8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
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
              child: Column(
                children: [
                  Icon(s.icon, size: 18, color: s.color),
                  const SizedBox(height: 6),
                  Text(
                    s.value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: s.color,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
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

class _S {
  final String label, value;
  final IconData icon;
  final Color color;
  const _S(this.label, this.value, this.icon, this.color);
}

// ─────────────────────────────────────────────────────────────────────────────
// COURT CARD
// ─────────────────────────────────────────────────────────────────────────────
class _CourtCard extends StatelessWidget {
  final CourtModel court;
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
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // ── Photo strip ───────────────────────────────────────────────
          SizedBox(
            height: 155,
            child: c.photoUrls.isEmpty
                ? Container(
                    color: sc.withOpacity(0.06),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          c.sport.icon,
                          size: 44,
                          color: sc.withOpacity(0.35),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No photos yet',
                          style: TextStyle(
                            fontSize: 12,
                            color: sc.withOpacity(0.5),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : PageView.builder(
                    itemCount: c.photoUrls.length,
                    itemBuilder: (_, i) => Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          c.photoUrls[i],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: sc.withOpacity(0.07),
                            child: Icon(c.sport.icon, color: sc, size: 40),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.45),
                              ],
                              stops: const [0.5, 1.0],
                            ),
                          ),
                        ),
                        // Photo count badge
                        if (c.photoUrls.length > 1)
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${i + 1}/${c.photoUrls.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),

          // ── Info ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sport icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: sc.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(c.sport.icon, color: sc, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              c.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: kTextDark,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          _ActiveSwitch(
                            value: c.isActive,
                            onChanged: (_) => onToggle(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: sc.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              c.sport.label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: sc,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (c.surface.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: kBg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                c.surface,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: kTextMid,
                                ),
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

          // ── Details row ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Row(
              children: [
                _Detail(Icons.people_rounded, '${c.capacity} players'),
                const SizedBox(width: 16),
                _Detail(
                  Icons.payments_rounded,
                  '${c.pricePerHour.toInt()} DT/hr',
                ),
                const Spacer(),
                if (c.amenities.isNotEmpty)
                  Text(
                    '+${c.amenities.length} amenities',
                    style: TextStyle(
                      fontSize: 10,
                      color: kTextMid.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),

          if (c.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Text(
                c.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: kTextMid,
                  height: 1.4,
                ),
              ),
            ),

          // ── Action buttons ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: _Btn(
                    'Edit',
                    color: kPrimary,
                    icon: Icons.edit_rounded,
                    onTap: onEdit,
                  ),
                ),
                const SizedBox(width: 10),
                _IconBtn(Icons.delete_outline_rounded, kRed, onDelete),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Detail(this.icon, this.label);
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: kTextLight),
      const SizedBox(width: 4),
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: kTextMid,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

class _ActiveSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ActiveSwitch({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        value ? 'Active' : 'Inactive',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: value ? kGreen : kTextLight,
        ),
      ),
      const SizedBox(width: 6),
      Transform.scale(
        scale: 0.75,
        child: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: kGreen,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// COURT FORM SHEET  — add OR edit
// ─────────────────────────────────────────────────────────────────────────────
class _CourtFormSheet extends StatefulWidget {
  final CourtModel? existing;
  final List<SportType> venueSports;
  final ValueChanged<CourtModel> onSave;
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
  late String _surface = widget.existing?.surface ?? 'Grass';
  late final Set<String> _amenities = Set.from(
    widget.existing?.amenities ?? [],
  );
  late final List<String> _photos = List.from(widget.existing?.photoUrls ?? []);

  final _formKey = GlobalKey<FormState>();

  static const _surfaces = [
    'Grass',
    'Artificial Turf',
    'Hard Court',
    'Clay',
    'Parquet',
    'Rubber',
  ];
  static const _allAmenities = [
    'Parking',
    'Showers',
    'Changing Rooms',
    'Floodlights',
    'Cafe',
    'Equipment Rental',
    'Seating',
    'First Aid',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _capCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave(
      CourtModel(
        id: widget.existing?.id ?? 'c_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        sport: _sport,
        pricePerHour: double.tryParse(_priceCtrl.text.trim()) ?? 0,
        capacity: int.tryParse(_capCtrl.text.trim()) ?? 0,
        photoUrls: _photos,
        surface: _surface,
        amenities: _amenities.toList(),
        isActive: widget.existing?.isActive ?? true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Container(
      decoration: const BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.92,
        maxChildSize: 0.97,
        minChildSize: 0.5,
        expand: false,
        builder: (_, ctrl) => Column(
          children: [
            // Handle + title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 32,
                      height: 3.5,
                      decoration: BoxDecoration(
                        color: kTextLight.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isEdit ? Icons.edit_rounded : Icons.add_rounded,
                          color: kPrimary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isEdit ? 'Edit Court' : 'Add New Court',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: kTextDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: kBg,
                            borderRadius: BorderRadius.circular(8),
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
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                ],
              ),
            ),

            // Scrollable form
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: ctrl,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  children: [
                    // Photos
                    _SLabel('Court Photos'),
                    const SizedBox(height: 10),
                    _PhotoPicker(
                      photos: _photos,
                      onAdd: () => setState(
                        () => _photos.add(
                          'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=700&q=80',
                        ),
                      ),
                      onRemove: (i) => setState(() => _photos.removeAt(i)),
                    ),
                    const SizedBox(height: 20),

                    // Name
                    _SLabel('Court Name'),
                    const SizedBox(height: 8),
                    _FormField(
                      ctrl: _nameCtrl,
                      hint: 'e.g. Court A, Padel 1',
                      icon: Icons.sports_tennis_rounded,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Sport + Surface
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SLabel('Sport'),
                              const SizedBox(height: 8),
                              _DropField<SportType>(
                                value: _sport,
                                items: widget.venueSports.isEmpty
                                    ? SportType.values
                                    : widget.venueSports,
                                label: (s) => s.label,
                                icon: (s) => s.icon,
                                onChanged: (v) => setState(() => _sport = v),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SLabel('Surface'),
                              const SizedBox(height: 8),
                              _DropField<String>(
                                value: _surface,
                                items: _surfaces,
                                label: (s) => s,
                                icon: (_) => Icons.layers_rounded,
                                onChanged: (v) => setState(() => _surface = v),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Price + Capacity
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SLabel('Price (DT/hr)'),
                              const SizedBox(height: 8),
                              _FormField(
                                ctrl: _priceCtrl,
                                hint: '0',
                                icon: Icons.payments_rounded,
                                type: TextInputType.number,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'Required'
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SLabel('Capacity'),
                              const SizedBox(height: 8),
                              _FormField(
                                ctrl: _capCtrl,
                                hint: 'Max players',
                                icon: Icons.people_rounded,
                                type: TextInputType.number,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'Required'
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Description
                    _SLabel('Description'),
                    const SizedBox(height: 8),
                    _FormField(
                      ctrl: _descCtrl,
                      hint: 'Surface type, lighting, any special features...',
                      icon: Icons.description_outlined,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),

                    // Amenities
                    _SLabel('Amenities'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _allAmenities.map((a) {
                        final on = _amenities.contains(a);
                        return GestureDetector(
                          onTap: () => setState(
                            () => on ? _amenities.remove(a) : _amenities.add(a),
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: on ? kPrimary : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: on
                                    ? kPrimary
                                    : kTextLight.withOpacity(0.4),
                              ),
                              boxShadow: on
                                  ? [
                                      BoxShadow(
                                        color: kPrimary.withOpacity(0.15),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Text(
                              a,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: on ? Colors.white : kTextMid,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // Save button
            Container(
              color: kCard,
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              child: _Btn(
                isEdit ? 'Save Changes' : 'Add Court',
                color: kPrimary,
                icon: isEdit ? Icons.check_rounded : Icons.add_rounded,
                onTap: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EDIT VENUE SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _EditVenueSheet extends StatefulWidget {
  final VenueModel venue;
  final ValueChanged<VenueModel> onSave;
  const _EditVenueSheet({required this.venue, required this.onSave});
  @override
  State<_EditVenueSheet> createState() => _EditVenueSheetState();
}

class _EditVenueSheetState extends State<_EditVenueSheet> {
  late final _nameCtrl = TextEditingController(text: widget.venue.name);
  late final _locCtrl = TextEditingController(text: widget.venue.location);
  late final _phoneCtrl = TextEditingController(text: widget.venue.phone);
  late final _descCtrl = TextEditingController(text: widget.venue.description);
  late String _openTime = widget.venue.openTime;
  late String _closeTime = widget.venue.closeTime;
  late final Set<SportType> _sports = Set.from(widget.venue.sports);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locCtrl.dispose();
    _phoneCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final updated = VenueModel(
      name: _nameCtrl.text.trim(),
      location: _locCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      openTime: _openTime,
      closeTime: _closeTime,
      sports: _sports.toList(),
      courts: widget.venue.courts,
      coverImageUrl: widget.venue.coverImageUrl,
      logoImageUrl: widget.venue.logoImageUrl,
    );
    widget.onSave(updated);
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: kCard,
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    child: DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.97,
      minChildSize: 0.5,
      expand: false,
      builder: (_, ctrl) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 32,
                    height: 3.5,
                    decoration: BoxDecoration(
                      color: kTextLight.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: kPrimary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: kPrimary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Edit Venue',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: kTextDark,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: kBg,
                          borderRadius: BorderRadius.circular(8),
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
                const SizedBox(height: 16),
                const Divider(height: 1),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              children: [
                _SLabel('Venue Name'),
                const SizedBox(height: 8),
                _FormField(
                  ctrl: _nameCtrl,
                  hint: 'Arena Sport Center',
                  icon: Icons.stadium_rounded,
                ),
                const SizedBox(height: 16),
                _SLabel('Location'),
                const SizedBox(height: 8),
                _FormField(
                  ctrl: _locCtrl,
                  hint: 'Address',
                  icon: Icons.location_on_rounded,
                ),
                const SizedBox(height: 16),
                _SLabel('Phone'),
                const SizedBox(height: 8),
                _FormField(
                  ctrl: _phoneCtrl,
                  hint: '+216 XX XXX XXX',
                  icon: Icons.phone_outlined,
                  type: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                _SLabel('Opening Hours'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _TimeSelector(
                        label: 'Opens at',
                        value: _openTime,
                        onChanged: (v) => setState(() => _openTime = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TimeSelector(
                        label: 'Closes at',
                        value: _closeTime,
                        onChanged: (v) => setState(() => _closeTime = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SLabel('Sports'),
                const SizedBox(height: 10),
                ...SportType.values.map(
                  (s) => _SportToggle(
                    sport: s,
                    selected: _sports.contains(s),
                    onToggle: (v) =>
                        setState(() => v ? _sports.add(s) : _sports.remove(s)),
                  ),
                ),
                const SizedBox(height: 16),
                _SLabel('Description'),
                const SizedBox(height: 8),
                _FormField(
                  ctrl: _descCtrl,
                  hint: 'Venue description...',
                  icon: Icons.description_outlined,
                  maxLines: 4,
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
          Container(
            color: kCard,
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            child: _Btn(
              'Save Changes',
              color: kPrimary,
              icon: Icons.check_rounded,
              onTap: _save,
            ),
          ),
        ],
      ),
    ),
  );
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
        // Add button
        GestureDetector(
          onTap: onAdd,
          child: Container(
            width: 100,
            height: 100,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kPrimary.withOpacity(0.2), width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_rounded,
                  color: kPrimary.withOpacity(0.7),
                  size: 26,
                ),
                const SizedBox(height: 6),
                Text(
                  'Add Photo',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: kPrimary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Existing photos
        ...photos.asMap().entries.map(
          (e) => Container(
            width: 100,
            height: 100,
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
                    color: kBg,
                    child: const Icon(
                      Icons.broken_image_rounded,
                      color: kTextLight,
                      size: 24,
                    ),
                  ),
                ),
                Positioned(
                  top: 5,
                  right: 5,
                  child: GestureDetector(
                    onTap: () => onRemove(e.key),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 12,
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
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyCourts extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyCourts({required this.onAdd});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(32, 32, 32, 32),
    child: Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.06),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.sports_tennis_rounded,
            size: 36,
            color: kPrimary.withOpacity(0.4),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'No courts yet',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: kTextDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Add your first court so players can book it',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: kTextMid.withOpacity(0.8),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: kPrimary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: kPrimary.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: Colors.white, size: 18),
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
// SPORT FILTER ROW
// ─────────────────────────────────────────────────────────────────────────────
class _SportFilterRow extends StatelessWidget {
  final List<SportType> sports;
  final SportType? selected;
  final ValueChanged<SportType?> onChanged;
  const _SportFilterRow({
    required this.sports,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 34,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: [
        _FPill(
          'All',
          Icons.apps_rounded,
          selected == null,
          () => onChanged(null),
        ),
        ...sports.map(
          (s) => _FPill(
            s.label,
            s.icon,
            selected == s,
            () => onChanged(selected == s ? null : s),
            color: s.color,
          ),
        ),
      ],
    ),
  );
}

class _FPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool on;
  final VoidCallback onTap;
  final Color? color;
  const _FPill(this.label, this.icon, this.on, this.onTap, {this.color});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: on ? (color ?? kPrimary) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: on ? Colors.white : kTextMid),
          const SizedBox(width: 5),
          Text(
            label,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED SMALL WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _SportToggle extends StatelessWidget {
  final SportType sport;
  final bool selected;
  final ValueChanged<bool> onToggle;
  const _SportToggle({
    required this.sport,
    required this.selected,
    required this.onToggle,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => onToggle(!selected),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: selected ? sport.color.withOpacity(0.06) : kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? sport.color.withOpacity(0.35)
              : kTextLight.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: sport.color.withOpacity(selected ? 0.12 : 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(sport.icon, color: sport.color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              sport.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: selected ? sport.color : kTextDark,
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: selected ? sport.color : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? sport.color : kTextLight.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: selected
                ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                : null,
          ),
        ],
      ),
    ),
  );
}

class _TimeSelector extends StatelessWidget {
  final String label, value;
  final ValueChanged<String> onChanged;
  const _TimeSelector({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () async {
      final parts = value.split(':');
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        ),
      );
      if (picked != null) {
        onChanged(
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
        );
      }
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kTextLight.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time_rounded, size: 16, color: kPrimary),
          const SizedBox(width: 8),
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
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: kTextLight,
          ),
        ],
      ),
    ),
  );
}

class _SLabel extends StatelessWidget {
  final String t;
  const _SLabel(this.t);
  @override
  Widget build(BuildContext context) => Text(
    t,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: kTextDark,
    ),
  );
}

class _FormField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final TextInputType type;
  final int maxLines;
  final String? Function(String?)? validator;
  const _FormField({
    required this.ctrl,
    required this.hint,
    required this.icon,
    this.type = TextInputType.text,
    this.maxLines = 1,
    this.validator,
  });
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl,
    keyboardType: type,
    maxLines: maxLines,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: kTextDark,
    ),
    validator: validator,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: kTextLight, fontSize: 13),
      prefixIcon: Icon(icon, color: kPrimary, size: 18),
      filled: true,
      fillColor: kCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: kTextLight.withOpacity(0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kRed, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kRed, width: 1.5),
      ),
    ),
  );
}

class _DropField<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) label;
  final IconData Function(T) icon;
  final ValueChanged<T> onChanged;
  const _DropField({
    required this.value,
    required this.items,
    required this.label,
    required this.icon,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color: kCard,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: kTextLight.withOpacity(0.25)),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: kTextMid,
          size: 18,
        ),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: kTextDark,
        ),
        items: items
            .map(
              (i) => DropdownMenuItem(
                value: i,
                child: Row(
                  children: [
                    Icon(icon(i), size: 14, color: kPrimary),
                    const SizedBox(width: 8),
                    Text(label(i)),
                  ],
                ),
              ),
            )
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    ),
  );
}

class _Btn extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;
  final VoidCallback onTap;
  final bool outlined;
  const _Btn(
    this.label, {
    this.color,
    this.icon,
    required this.onTap,
    this.outlined = false,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 50,
      decoration: outlined
          ? BoxDecoration(
              border: Border.all(color: kTextLight.withOpacity(0.4)),
              borderRadius: BorderRadius.circular(14),
            )
          : BoxDecoration(
              color: color ?? kPrimary,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: (color ?? kPrimary).withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(icon, size: 16, color: outlined ? kTextMid : Colors.white),
            if (icon != null) const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: outlined ? kTextMid : Colors.white,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconBtn(this.icon, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Icon(icon, color: color, size: 18),
    ),
  );
}
