import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'dart:ui' as ui;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sporta/Models/app_enums.dart';
import 'package:sporta/Models/app_models.dart';
import 'package:sporta/Models/sample_data.dart';
import 'package:sporta/Views/Player/court_booking_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// VENUE MODEL  (courts live inside venues)
// ─────────────────────────────────────────────────────────────────────────────
class VenueModel {
  final String name;
  final String location;
  final List<String> sports; // e.g. ['Football', 'Padel']
  final List<String> amenities;
  final int minPrice; // lowest court price in this venue
  final int maxPrice;
  final bool available;
  final String openUntil;
  final String image;
  final double lat, lng;
  final List<Map<String, dynamic>> courts; // courts inside this venue

  const VenueModel({
    required this.name,
    required this.location,
    required this.sports,
    required this.amenities,
    required this.minPrice,
    required this.maxPrice,
    required this.available,
    required this.openUntil,
    required this.image,
    required this.lat,
    required this.lng,
    required this.courts,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// SAMPLE VENUE DATA
// ─────────────────────────────────────────────────────────────────────────────
final _sampleVenues = [
  VenueModel(
    name: 'Arena Sport Center',
    location: 'Lac 2, Tunis',
    sports: ['Football', 'Padel'],
    amenities: ['Parking', 'Showers', 'Floodlights', 'Locker'],
    minPrice: 90,
    maxPrice: 120,
    available: true,
    openUntil: '11:00 PM',
    image: 'assets/sportcenter.jpg',
    lat: 36.8425,
    lng: 10.2320,
    courts: [
      {
        'courtName': 'Football Court A',
        'sport': 'Football',
        'price': 90,
        'available': true,
      },
      {
        'courtName': 'Football Court B',
        'sport': 'Football',
        'price': 90,
        'available': false,
      },
      {
        'courtName': 'Padel Court 1',
        'sport': 'Padel',
        'price': 120,
        'available': true,
      },
    ],
  ),
  VenueModel(
    name: 'Padel Club Marsa',
    location: 'La Marsa, Tunis',
    sports: ['Padel', 'Tennis'],
    amenities: ['Cafe', 'Equipment', 'Coaching', 'AC'],
    minPrice: 105,
    maxPrice: 130,
    available: true,
    openUntil: '10:00 PM',
    image: 'assets/padel.jpg',
    lat: 36.8781,
    lng: 10.3244,
    courts: [
      {
        'courtName': 'Padel Court A',
        'sport': 'Padel',
        'price': 120,
        'available': true,
      },
      {
        'courtName': 'Padel Court B',
        'sport': 'Padel',
        'price': 120,
        'available': true,
      },
      {
        'courtName': 'Tennis Court 1',
        'sport': 'Tennis',
        'price': 105,
        'available': false,
      },
    ],
  ),
  VenueModel(
    name: 'City Basketball Arena',
    location: 'Menzah 6, Tunis',
    sports: ['Basketball'],
    amenities: ['Indoor', 'AC', 'Scoreboard', 'Parking'],
    minPrice: 75,
    maxPrice: 75,
    available: false,
    openUntil: '12:00 AM',
    image: 'assets/basketball.jpeg',
    lat: 36.8550,
    lng: 10.1980,
    courts: [
      {
        'courtName': 'Main Court',
        'sport': 'Basketball',
        'price': 75,
        'available': false,
      },
      {
        'courtName': 'Training Court',
        'sport': 'Basketball',
        'price': 75,
        'available': false,
      },
    ],
  ),
  VenueModel(
    name: 'Green Field Complex',
    location: 'Ariana, Tunis',
    sports: ['Football', 'Tennis'],
    amenities: ['Parking', 'Cafe', 'Floodlights', 'Grass'],
    minPrice: 80,
    maxPrice: 105,
    available: true,
    openUntil: '9:00 PM',
    image: 'assets/football.jpg',
    lat: 36.8620,
    lng: 10.1630,
    courts: [
      {
        'courtName': 'Grass Field 1',
        'sport': 'Football',
        'price': 80,
        'available': true,
      },
      {
        'courtName': 'Grass Field 2',
        'sport': 'Football',
        'price': 80,
        'available': true,
      },
      {
        'courtName': 'Tennis Court',
        'sport': 'Tennis',
        'price': 105,
        'available': true,
      },
    ],
  ),
  VenueModel(
    name: 'Tennis Academy Tunis',
    location: 'Gammarth, Tunis',
    sports: ['Tennis'],
    amenities: ['Coaching', 'Equipment', 'Showers', 'Cafe'],
    minPrice: 105,
    maxPrice: 105,
    available: true,
    openUntil: '8:00 PM',
    image: 'assets/tennis.jpg',
    lat: 36.9100,
    lng: 10.2900,
    courts: [
      {
        'courtName': 'Court Central',
        'sport': 'Tennis',
        'price': 105,
        'available': true,
      },
      {
        'courtName': 'Court 2',
        'sport': 'Tennis',
        'price': 105,
        'available': true,
      },
    ],
  ),
  VenueModel(
    name: 'Beach Volleyball Club',
    location: 'La Goulette, Tunis',
    sports: ['Volleyball'],
    amenities: ['Beach', 'Showers', 'Cafe', 'Parking'],
    minPrice: 70,
    maxPrice: 70,
    available: true,
    openUntil: '7:00 PM',
    image: 'assets/beach.jpg',
    lat: 36.8180,
    lng: 10.3050,
    courts: [
      {
        'courtName': 'Sand Court A',
        'sport': 'Volleyball',
        'price': 70,
        'available': true,
      },
      {
        'courtName': 'Sand Court B',
        'sport': 'Volleyball',
        'price': 70,
        'available': false,
      },
    ],
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// EXPLORE PAGE
// ─────────────────────────────────────────────────────────────────────────────
class Explore extends StatefulWidget {
  const Explore({super.key});
  @override
  State<Explore> createState() => _ExploreState();
}

class _ExploreState extends State<Explore> with TickerProviderStateMixin {
  int _selectedSport = 0;
  int _selectedSort = 0;
  int _selectedView = 0; // 0=list, 1=map
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();

  late final List<AnimationController> _markerAnimControllers;
  late final List<Animation<double>> _markerAnims;
  int? _selectedMarkerIndex;

  final List<Map<String, dynamic>> _sports = const [
    {'label': 'All', 'icon': Icons.sports_rounded},
    {'label': 'Football', 'icon': Icons.sports_soccer_rounded},
    {'label': 'Padel', 'icon': Icons.sports_tennis_rounded},
    {'label': 'Basketball', 'icon': Icons.sports_basketball_rounded},
    {'label': 'Tennis', 'icon': Icons.sports_tennis},
    {'label': 'Volleyball', 'icon': Icons.sports_volleyball},
  ];

  List<VenueModel> get _filtered {
    List<VenueModel> result = _selectedSport == 0
        ? List.from(_sampleVenues)
        : _sampleVenues
              .where((v) => v.sports.contains(_sports[_selectedSport]['label']))
              .toList();

    final q = _searchController.text.toLowerCase();
    if (q.isNotEmpty) {
      result = result
          .where(
            (v) =>
                v.name.toLowerCase().contains(q) ||
                v.location.toLowerCase().contains(q),
          )
          .toList();
    }

    switch (_selectedSort) {
      case 2:
        result.sort((a, b) => a.minPrice.compareTo(b.minPrice));
        break;
      case 3:
        result.sort((a, b) => b.maxPrice.compareTo(a.maxPrice));
        break;
      default:
        break;
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    _markerAnimControllers = List.generate(
      _sampleVenues.length,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 400 + i * 80),
      ),
    );
    _markerAnims = _markerAnimControllers
        .map((ctrl) => CurvedAnimation(parent: ctrl, curve: Curves.elasticOut))
        .toList();
  }

  void _startMarkerAnimations() {
    for (int i = 0; i < _markerAnimControllers.length; i++) {
      _markerAnimControllers[i].reset();
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) _markerAnimControllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (final ctrl in _markerAnimControllers) ctrl.dispose();
    super.dispose();
  }

  void _navigateToBooking(VenueModel venue, Map<String, dynamic> court) {
    final sportType = _mapSport(court['sport'] as String);
    final courtModel = CourtModel(
      id: '${venue.name}_${court['courtName']}',
      name: court['courtName'] as String,
      location: venue.location,
      sport: sportType,
      pricePerHour: (court['price'] as int).toDouble(),
      color: sportType.color,
      imageUrl: null,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CourtBookingPage(
          preselectedCourt: courtModel,
          venueName: venue.name,
        ),
      ),
    );
  }

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

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF2F4F7),
    body: Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchBar(),
                const SizedBox(height: 14),
                _buildSportFilter(),
                const SizedBox(height: 16),
                _buildResultsRow(),
                const SizedBox(height: 12),
                _selectedView == 0 ? _buildVenueList() : _buildMapView(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() => Container(
    color: Colors.white,
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Row(
          children: [
            const Text(
              'Explore Venues',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0D0D0D),
                letterSpacing: -0.3,
              ),
            ),
            const Spacer(),
            Container(
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _viewToggleBtn(0, Icons.format_list_bulleted_rounded),
                  _viewToggleBtn(1, Icons.map_rounded),
                ],
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _showFilterSheet,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: kPrimary,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _viewToggleBtn(int index, IconData icon) {
    final selected = _selectedView == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedView = index);
        if (index == 1) _startMarkerAnimations();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: selected ? kPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: selected ? Colors.white : Colors.grey[500],
        ),
      ),
    );
  }

  // ── Search bar ─────────────────────────────────────────────────────────────
  Widget _buildSearchBar() => Container(
    height: 50,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      children: [
        const SizedBox(width: 14),
        Icon(Icons.search_rounded, color: Colors.grey[400], size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search venues, locations...',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
        if (_searchController.text.isNotEmpty)
          GestureDetector(
            onTap: () {
              _searchController.clear();
              setState(() {});
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Icon(
                Icons.close_rounded,
                color: Colors.grey[400],
                size: 18,
              ),
            ),
          )
        else
          const SizedBox(width: 14),
      ],
    ),
  );

  // ── Sport filter ───────────────────────────────────────────────────────────
  Widget _buildSportFilter() => SizedBox(
    height: 36,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: _sports.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, i) {
        final selected = _selectedSport == i;
        return GestureDetector(
          onTap: () => setState(() => _selectedSport = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: selected ? kPrimary : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  _sports[i]['icon'] as IconData,
                  size: 14,
                  color: selected ? Colors.white : Colors.grey[500],
                ),
                const SizedBox(width: 5),
                Text(
                  _sports[i]['label'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  // ── Results row ────────────────────────────────────────────────────────────
  Widget _buildResultsRow() {
    final venues = _filtered;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${venues.length} venue${venues.length == 1 ? '' : 's'} found',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        GestureDetector(
          onTap: _showSortSheet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.sort_rounded, size: 14, color: kPrimary),
                const SizedBox(width: 5),
                Text(
                  _sortLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: kPrimary,
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 14,
                  color: kPrimary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String get _sortLabel {
    switch (_selectedSort) {
      case 2:
        return 'Price ↑';
      case 3:
        return 'Price ↓';
      default:
        return 'Recommended';
    }
  }

  // ── Venue list ─────────────────────────────────────────────────────────────
  Widget _buildVenueList() {
    final venues = _filtered;
    if (venues.isEmpty)
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 12),
            const Text(
              'No venues found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0D0D0D),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try adjusting your filters',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      );

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: venues.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, i) => _VenueCard(
        venue: venues[i],
        onBookCourt: (court) => _navigateToBooking(venues[i], court),
      ),
    );
  }

  // ── MAP VIEW ───────────────────────────────────────────────────────────────
  Widget _buildMapView() {
    final visible = _filtered;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 500,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(36.8560, 10.2210),
                initialZoom: 12.5,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
                onTap: (_, __) => setState(() => _selectedMarkerIndex = null),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.sporta.app',
                ),
                MarkerLayer(
                  markers: visible.asMap().entries.map((entry) {
                    final i = entry.key;
                    final venue = entry.value;
                    final animIndex = _sampleVenues.indexOf(venue);
                    final isSelected = _selectedMarkerIndex == i;
                    return Marker(
                      point: LatLng(venue.lat, venue.lng),
                      width: isSelected ? 140 : 90,
                      height: isSelected ? 52 : 44,
                      child: animIndex >= 0
                          ? AnimatedBuilder(
                              animation: _markerAnims[animIndex],
                              builder: (_, __) => Transform.scale(
                                scale: _markerAnims[animIndex].value,
                                alignment: Alignment.bottomCenter,
                                child: _buildMarkerPin(venue, i, isSelected),
                              ),
                            )
                          : _buildMarkerPin(venue, i, isSelected),
                    );
                  }).toList(),
                ),
              ],
            ),

            // Top overlay
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: kPrimary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${visible.length} venues nearby',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0D0D0D),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _mapController.move(
                      const LatLng(36.8560, 10.2210),
                      12.5,
                    ),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.my_location_rounded,
                        size: 18,
                        color: kPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Zoom buttons
            Positioned(
              right: 14,
              bottom: _selectedMarkerIndex != null ? 120 : 16,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _mapController.move(
                      _mapController.camera.center,
                      (_mapController.camera.zoom + 1).clamp(1.0, 18.0),
                    ),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.10),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        size: 20,
                        color: kPrimary,
                      ),
                    ),
                  ),
                  Container(width: 40, height: 1, color: Colors.grey.shade200),
                  GestureDetector(
                    onTap: () => _mapController.move(
                      _mapController.camera.center,
                      (_mapController.camera.zoom - 1).clamp(1.0, 18.0),
                    ),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(12),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.10),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.remove_rounded,
                        size: 20,
                        color: kPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom mini card
            if (_selectedMarkerIndex != null &&
                _selectedMarkerIndex! < visible.length)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: _buildMapCardPreview(visible[_selectedMarkerIndex!]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkerPin(VenueModel venue, int index, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedMarkerIndex = isSelected ? null : index);
        _mapController.move(LatLng(venue.lat, venue.lng), 14.0);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: EdgeInsets.symmetric(
              horizontal: isSelected ? 12 : 8,
              vertical: isSelected ? 8 : 6,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? kPrimary
                  : (venue.available ? Colors.white : Colors.red.shade50),
              borderRadius: BorderRadius.circular(isSelected ? 16 : 12),
              border: Border.all(
                color: isSelected
                    ? kPrimary
                    : (venue.available
                          ? kPrimary.withOpacity(0.3)
                          : Colors.red.withOpacity(0.3)),
                width: isSelected ? 0 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isSelected ? kPrimary : Colors.black).withOpacity(
                    isSelected ? 0.3 : 0.12,
                  ),
                  blurRadius: isSelected ? 14 : 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              '${venue.minPrice} DT',
              style: TextStyle(
                fontSize: isSelected ? 11 : 10,
                fontWeight: FontWeight.w800,
                color: isSelected
                    ? Colors.white
                    : (venue.available ? kPrimary : Colors.red),
              ),
            ),
          ),
          CustomPaint(
            size: const Size(10, 6),
            painter: _PinTailPainter(
              color: isSelected ? kPrimary : Colors.white,
              hasBorder: !isSelected,
              borderColor: venue.available
                  ? kPrimary.withOpacity(0.3)
                  : Colors.red.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCardPreview(VenueModel venue) {
    void goToBooking() {
      final firstAvailable = venue.courts.firstWhere(
        (c) => c['available'] == true,
        orElse: () => venue.courts.first,
      );
      _navigateToBooking(venue, firstAvailable);
    }

    return GestureDetector(
      onTap: goToBooking,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 56,
                height: 56,
                child: _buildImage(venue.image),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    venue.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0D0D0D),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    venue.location,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: venue.available
                              ? const Color(0xFF4ADE80).withOpacity(0.12)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          venue.available ? 'Open' : 'Full',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: venue.available
                                ? const Color(0xFF16A34A)
                                : Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${venue.courts.length} courts',
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${venue.minPrice} DT',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: kPrimary,
                  ),
                ),
                if (venue.minPrice != venue.maxPrice)
                  Text(
                    '– ${venue.maxPrice} DT',
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: goToBooking,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: kPrimary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Book Now',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMapPreview(VenueModel venue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VenuePreviewSheet(
        venue: venue,
        onBookCourt: (court) {
          Navigator.pop(context);
          _navigateToBooking(venue, court);
        },
      ),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sort By',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            _sortOption(0, 'Recommended', Icons.star_rounded),
            _sortOption(2, 'Price: Low to High', Icons.trending_up_rounded),
            _sortOption(3, 'Price: High to Low', Icons.trending_down_rounded),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sortOption(int index, String label, IconData icon) {
    final selected = _selectedSort == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedSort = index);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? kPrimary.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? kPrimary : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: selected ? kPrimary : Colors.grey[500]),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? kPrimary : const Color(0xFF0D0D0D),
              ),
            ),
            const Spacer(),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: kPrimary, size: 18),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet() {
    final amenityOptions = [
      'Parking',
      'Showers',
      'Cafe',
      'Equipment',
      'Floodlights',
      'Indoor',
      'AC',
      'Coaching',
    ];
    final selectedAmenities = <String>{};
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (_, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Filters',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      const Text(
                        'Amenities',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: amenityOptions.map((a) {
                          final isSel = selectedAmenities.contains(a);
                          return GestureDetector(
                            onTap: () => setModalState(
                              () => isSel
                                  ? selectedAmenities.remove(a)
                                  : selectedAmenities.add(a),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSel ? kPrimary : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSel
                                      ? kPrimary
                                      : Colors.grey.shade200,
                                ),
                              ),
                              child: Text(
                                a,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSel
                                      ? Colors.white
                                      : Colors.grey[700],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Availability',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: ['Available Now', 'Open Today', 'Weekends']
                            .map(
                              (label) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: kPrimary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Reset',
                          style: TextStyle(
                            color: kPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Apply',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String path) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Container(color: kPrimary.withOpacity(0.07)),
      );
    }
    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          Container(color: kPrimary.withOpacity(0.07)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VENUE CARD  — Home-page style: photo on top, amenities, price + Open/Full
// ─────────────────────────────────────────────────────────────────────────────
class _VenueCard extends StatelessWidget {
  final VenueModel venue;
  final ValueChanged<Map<String, dynamic>> onBookCourt;
  const _VenueCard({required this.venue, required this.onBookCourt});

  Widget _buildImage(String path) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Container(color: kPrimary.withOpacity(0.07)),
      );
    }
    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          Container(color: kPrimary.withOpacity(0.07)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Photo ──────────────────────────────────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SizedBox(
              height: 130,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImage(venue.image),
                  Container(color: Colors.black.withOpacity(0.15)),

                  // Open until — bottom right
                  Positioned(
                    bottom: 8,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 9,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Until ${venue.openUntil}',
                            style: const TextStyle(
                              fontSize: 8,
                              color: Colors.white,
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

          // ── Details ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  venue.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D0D0D),
                  ),
                ),
                const SizedBox(height: 5),

                // Location
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 12,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        venue.location,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Amenities
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    ...venue.amenities
                        .take(3)
                        .map(
                          (a) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: kPrimary.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              a,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: kPrimary,
                              ),
                            ),
                          ),
                        ),
                    if (venue.amenities.length > 3)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '+${venue.amenities.length - 3} more',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Price + Book
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${venue.minPrice} DT',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: kPrimary,
                      ),
                    ),

                    // Book Now — goes directly to booking with first available court
                    GestureDetector(
                      onTap: () {
                        final firstAvailable = venue.courts.firstWhere(
                          (c) => c['available'] == true,
                          orElse: () => venue.courts.first,
                        );
                        onBookCourt(firstAvailable);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: kPrimary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'Book Now',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
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
    );
  }

  // Sheet: pick which court inside this venue to book
  void _showCourtsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _CourtsPickerSheet(venue: venue, onBookCourt: onBookCourt),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COURTS PICKER SHEET — shown when tapping "Book Now" on a venue card
// ─────────────────────────────────────────────────────────────────────────────
class _CourtsPickerSheet extends StatelessWidget {
  final VenueModel venue;
  final ValueChanged<Map<String, dynamic>> onBookCourt;
  const _CourtsPickerSheet({required this.venue, required this.onBookCourt});

  Widget _buildImage(String path) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Container(color: kPrimary.withOpacity(0.07)),
      );
    }
    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          Container(color: kPrimary.withOpacity(0.07)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bot = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
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
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Venue header
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: _buildImage(venue.image),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venue.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0D0D0D),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 11,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          venue.location,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade100),
          const SizedBox(height: 8),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Choose a court',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0D0D0D),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Courts list
          ...venue.courts.map((court) {
            final available = court['available'] as bool;
            return GestureDetector(
              onTap: available
                  ? () {
                      Navigator.pop(context);
                      onBookCourt(court);
                    }
                  : null,
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: available ? Colors.white : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: available
                        ? Colors.grey.shade200
                        : Colors.grey.shade100,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: available
                            ? kPrimary.withOpacity(0.08)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _sportIcon(court['sport'] as String),
                        size: 16,
                        color: available ? kPrimary : Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            court['courtName'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: available
                                  ? const Color(0xFF0D0D0D)
                                  : Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            court['sport'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              color: available
                                  ? Colors.grey
                                  : Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${court['price']} DT',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: available ? kPrimary : Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: available
                                ? const Color(0xFF4ADE80).withOpacity(0.12)
                                : Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            available ? 'Open' : 'Full',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: available
                                  ? const Color(0xFF16A34A)
                                  : Colors.red.shade300,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
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
}

// ─────────────────────────────────────────────────────────────────────────────
// VENUE PREVIEW SHEET — shown when tapping from map mini-card
// ─────────────────────────────────────────────────────────────────────────────
class _VenuePreviewSheet extends StatelessWidget {
  final VenueModel venue;
  final ValueChanged<Map<String, dynamic>> onBookCourt;
  const _VenuePreviewSheet({required this.venue, required this.onBookCourt});

  @override
  Widget build(BuildContext context) {
    final bot = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
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
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: Image.asset(
                    venue.image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: kPrimary.withOpacity(0.07)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venue.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      venue.location,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(
                Icons.location_on_rounded,
                venue.location.split(',').last.trim(),
              ),
              _chip(Icons.access_time_rounded, venue.openUntil),
              _chip(
                Icons.payments_outlined,
                '${venue.minPrice}–${venue.maxPrice} DT',
              ),
              _chip(Icons.sports_rounded, venue.sports.join(', ')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: kPrimary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text('Close', style: TextStyle(color: kPrimary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => _CourtsPickerSheet(
                        venue: venue,
                        onBookCourt: onBookCourt,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text(
                    'Book Now',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: kPrimary.withOpacity(0.07),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: kPrimary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0D0D0D),
          ),
        ),
      ],
    ),
  );
}

// ── Pin tail painter ──────────────────────────────────────────────────────────
class _PinTailPainter extends CustomPainter {
  final Color color;
  final bool hasBorder;
  final Color borderColor;
  const _PinTailPainter({
    required this.color,
    this.hasBorder = false,
    this.borderColor = Colors.transparent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (hasBorder) {
      final bp = Paint()
        ..color = borderColor
        ..style = PaintingStyle.fill;
      final bPath = ui.Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height + 1)
        ..close();
      canvas.drawPath(bPath, bp);
    }
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = ui.Path()
      ..moveTo(1, 0)
      ..lineTo(size.width - 1, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_PinTailPainter old) =>
      old.color != color || old.hasBorder != hasBorder;
}
