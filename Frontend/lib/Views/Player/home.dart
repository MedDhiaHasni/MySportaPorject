import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Models/app_enums.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedSport = 0;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const String profileImagePath = 'assets/moi.jpg';

  final List<Map<String, dynamic>> _sports = const [
    {'label': 'All', 'icon': Icons.sports_rounded},
    {'label': 'Football', 'icon': Icons.sports_soccer_rounded},
    {'label': 'Padel', 'icon': Icons.sports_tennis_rounded},
    {'label': 'Basketball', 'icon': Icons.sports_basketball_rounded},
  ];

  final List<Map<String, dynamic>> _courts = [
    {
      'name': 'Arena Sport Center',
      'location': 'Lac 2, Tunis',
      'sport': 'Football',
      'price': 100,
      'distance': '1.2 km',
      'available': true,
      'image': 'assets/sportcenter.jpg',
      'amenities': ['Parking', 'Showers', 'Floodlights'],
    },
    {
      'name': 'Padel Club Marsa',
      'location': 'La Marsa, Tunis',
      'sport': 'Padel',
      'price': 80,
      'distance': '3.5 km',
      'available': true,
      'image': 'assets/padel.jpg',
      'amenities': ['Cafe', 'Equipment', 'Coaching'],
    },
    {
      'name': 'City Basketball Arena',
      'location': 'Menzah 6, Tunis',
      'sport': 'Basketball',
      'price': 75,
      'distance': '2.8 km',
      'available': false,
      'image': 'assets/basketball.jpeg',
      'amenities': ['Indoor', 'AC', 'Scoreboard'],
    },
    {
      'name': 'Green Field Complex',
      'location': 'Ariana, Tunis',
      'sport': 'Football',
      'price': 90,
      'distance': '4.1 km',
      'available': true,
      'image': 'assets/football.jpg',
      'amenities': ['Parking', 'Cafe', 'Floodlights'],
    },
  ];

  final List<Map<String, dynamic>> _bookings = [
    {
      'court': 'Arena Sport Center',
      'day': 'Tomorrow',
      'time': '20:00 - 21:00',
      'players': 8,
      'price': 100,
      'image': 'assets/sportcenter.jpg',
      'status': 'Confirmed',
    },
    {
      'court': 'Padel Club Marsa',
      'day': 'Sat, Mar 1',
      'time': '18:00 - 19:00',
      'players': 4,
      'price': 80,
      'image': 'assets/padel.jpg',
      'status': 'Pending',
    },
  ];

  List<Map<String, dynamic>> get _filteredCourts {
    final sportLabel = _sports[_selectedSport]['label'] as String;
    return _courts.where((c) {
      final matchesSport = sportLabel == 'All' || c['sport'] == sportLabel;
      final query = _searchQuery.toLowerCase();
      final matchesSearch =
          query.isEmpty ||
          (c['name'] as String).toLowerCase().contains(query) ||
          (c['location'] as String).toLowerCase().contains(query);
      return matchesSport && matchesSearch;
    }).toList();
  }

  List<Map<String, dynamic>> get _confirmedBookings =>
      _bookings.where((b) => b['status'] == 'Confirmed').toList();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF2F4F7),
    body: CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildTopBar()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildSearchBar(),
              const SizedBox(height: 28),

              _buildSectionTitle('Nearby Courts'),
              const SizedBox(height: 12),
              _buildSportFilter(),
              const SizedBox(height: 12),
              _buildCourtCards(),
              const SizedBox(height: 28),

              if (_confirmedBookings.isNotEmpty) ...[
                _buildSectionTitle('Upcoming Bookings'),
                const SizedBox(height: 12),
                _buildBookings(),
              ],

              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    ),
  );

  // ── Top bar ─────────────────────────────────────────────────────────────────
  Widget _buildTopBar() => Container(
    color: Colors.white,
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade300,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildImage(profileImagePath),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good evening 👋',
                    style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 1),
                  const Text(
                    'Mohamed Dhia',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0D0D0D),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_outlined,
                    color: Colors.grey.shade600,
                    size: 21,
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ADE80),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  // ── Search bar — no filter button, only clear × when typing ─────────────────
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
        Icon(Icons.search_rounded, color: Colors.grey[400], size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            style: const TextStyle(fontSize: 14, color: Color(0xFF0D0D0D)),
            decoration: InputDecoration(
              hintText: 'Search courts, locations...',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
        if (_searchQuery.isNotEmpty)
          GestureDetector(
            onTap: () => setState(() {
              _searchQuery = '';
              _searchController.clear();
            }),
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: Colors.grey[400],
              ),
            ),
          )
        else
          const SizedBox(width: 14),
      ],
    ),
  );

  // ── Section title ───────────────────────────────────────────────────────────
  Widget _buildSectionTitle(String title) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: Color(0xFF0D0D0D),
        ),
      ),
      const Text(
        'See all',
        style: TextStyle(
          fontSize: 13,
          color: kPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );

  // ── Sport filter ────────────────────────────────────────────────────────────
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

  // ── Court cards ─────────────────────────────────────────────────────────────
  Widget _buildCourtCards() {
    final courts = _filteredCourts;

    if (courts.isEmpty)
      return Container(
        height: 120,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 32, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Text(
              'No courts found',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );

    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: courts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) =>
            _CourtCard(court: courts[i], onImage: _buildImage),
      ),
    );
  }

  // ── Upcoming bookings ───────────────────────────────────────────────────────
  Widget _buildBookings() => Column(
    children: _confirmedBookings
        .map(
          (b) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16),
                  ),
                  child: SizedBox(
                    width: 70,
                    height: 80,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildImage(b['image'] as String),
                        Container(color: Colors.black.withOpacity(0.12)),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b['court'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0D0D0D),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${b['day']} • ${b['time']}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.group_rounded,
                              size: 11,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${b['players']} players',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${b['price']} DT',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: kPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ADE80).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Confirmed',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList(),
  );

  Widget _buildImage(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
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
// COURT CARD
// ─────────────────────────────────────────────────────────────────────────────
class _CourtCard extends StatelessWidget {
  final Map<String, dynamic> court;
  final Widget Function(String) onImage;
  const _CourtCard({required this.court, required this.onImage});

  @override
  Widget build(BuildContext context) {
    final available = court['available'] as bool;
    final amenities = court['amenities'] as List;

    return Container(
      width: 190,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Photo ──────────────────────────────────────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SizedBox(
              height: 90,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  onImage(court['image'] as String),
                  Container(color: Colors.black.withOpacity(0.15)),
                ],
              ),
            ),
          ),

          // ── Info ───────────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  court['name'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D0D0D),
                  ),
                ),
                const SizedBox(height: 3),

                // Location + distance
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 11,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        court['location'] as String,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    Text(
                      court['distance'] as String,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: kPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Amenities
                Wrap(
                  spacing: 4,
                  children: amenities
                      .take(2)
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tag as String,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: kPrimary,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),

                // Price + Open/Full  ← was Price + Rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${court['price']} DT',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: kPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: available
                            ? const Color(0xFF4ADE80).withOpacity(0.12)
                            : Colors.red.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        available ? 'Open' : 'Full',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: available
                              ? const Color(0xFF16A34A)
                              : Colors.red,
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
}
