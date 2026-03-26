import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Models/app_enums.dart';
import 'package:sporta/Views/Player/HomeSettings.dart';
import 'ai_assistant.dart';
import 'Explore.dart';
import 'matches_page.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedSport = 0;

  // Search state
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
      'minPrice': 20,
      'maxPrice': 30,
      'rating': 4.8,
      'distance': '1.2 km',
      'available': true,
      'image': 'assets/sportcenter.jpg',
      'amenities': ['Parking', 'Showers', 'Floodlights'],
    },
    {
      'name': 'Padel Club Marsa',
      'location': 'La Marsa, Tunis',
      'sport': 'Padel',
      'minPrice': 25,
      'maxPrice': 25,
      'rating': 4.9,
      'distance': '3.5 km',
      'available': true,
      'image': 'assets/padel.jpg',
      'amenities': ['Cafe', 'Equipment', 'Coaching'],
    },
    {
      'name': 'City Basketball Arena',
      'location': 'Menzah 6, Tunis',
      'sport': 'Basketball',
      'minPrice': 18,
      'maxPrice': 18,
      'rating': 4.7,
      'distance': '2.8 km',
      'available': false,
      'image': 'assets/basketball.jpeg',
      'amenities': ['Indoor', 'AC', 'Scoreboard'],
    },
    {
      'name': 'Green Field Complex',
      'location': 'Ariana, Tunis',
      'sport': 'Football',
      'minPrice': 15,
      'maxPrice': 22,
      'rating': 4.5,
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
      'price': 20,
      'image': 'assets/sportcenter.jpg',
      'status': 'Confirmed',
    },
    {
      'court': 'Padel Club Marsa',
      'day': 'Sat, Mar 1',
      'time': '18:00 - 19:00',
      'players': 4,
      'price': 25,
      'image': 'assets/padel.jpg',
      'status': 'Pending', // filtered out — only Confirmed shown
    },
  ];

  // Filter courts by sport tab AND search query
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

  // Only confirmed bookings
  List<Map<String, dynamic>> get _confirmedBookings =>
      _bookings.where((b) => b['status'] == 'Confirmed').toList();

  void _navigate(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

                _buildSectionTitle('Nearby Venues'),
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
  }

  // Top bar
  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 450),
                      reverseTransitionDuration: const Duration(
                        milliseconds: 320,
                      ),
                      pageBuilder: (_, anim, __) => const HomeSettings(
                        username: 'Mohamed Dhia',
                        email: 'mohamed.dhia@gmail.com',
                        avatarPath: profileImagePath,
                      ),
                      transitionsBuilder: (_, anim, __, child) {
                        final curved = CurvedAnimation(
                          parent: anim,
                          curve: Curves.easeOutCubic,
                        );
                        return FadeTransition(
                          opacity: curved,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.07),
                              end: Offset.zero,
                            ).animate(curved),
                            child: child,
                          ),
                        );
                      },
                    ),
                  );
                },
                child: Hero(
                  tag: 'profile_avatar',
                  child: Container(
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
                ),
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
  }

  // Search bar — functional, filters courts live
  Widget _buildSearchBar() {
    return Container(
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
          // Clear button when typing
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () => setState(() {
                _searchQuery = '';
                _searchController.clear();
              }),
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Colors.grey[400],
                ),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.all(6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.tune_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Filter',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // title
  Widget _buildSectionTitle(String title) {
    return Row(
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
        GestureDetector(
          onTap: () {
            _navigate(const Explore());
          },
          child: const Text(
            'See all',
            style: TextStyle(
              fontSize: 13,
              color: kPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // filter
  Widget _buildSportFilter() {
    return SizedBox(
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
  }

  // venues cards
  Widget _buildCourtCards() {
    final courts = _filteredCourts;

    // Empty state when search returns nothing
    if (courts.isEmpty) {
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
    }

    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: courts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) {
          final c = courts[i];
          final amenities = c['amenities'] as List;
          final imgPath = c['image'] as String;
          final minPrice = c['minPrice'] as int;
          final maxPrice = c['maxPrice'] as int;

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
                // Icon area — court photo (no tags)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: SizedBox(
                    height: 90,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildImage(imgPath),
                        Container(color: Colors.black.withOpacity(0.15)),
                      ],
                    ),
                  ),
                ),

                // Info
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c['name'] as String,
                        maxLines: 1, // prevent overflow if name is too long
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0D0D0D),
                        ),
                      ),
                      const SizedBox(height: 3),
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
                              c['location'] as String,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          Text(
                            c['distance'] as String,
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
                        // wrap means
                        spacing: 4,
                        children: (amenities).take(2).map((tag) {
                          return Container(
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
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Price display - range or single
                          if (minPrice != maxPrice) ...[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'From',
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '$minPrice',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: kPrimary,
                                      ),
                                    ),
                                    Text(
                                      ' - $maxPrice DT',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ] else ...[
                            Text(
                              '$minPrice DT',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: kPrimary,
                              ),
                            ),
                          ],
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 12,
                                color: Color(0xFFFFC107),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${c['rating']}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0D0D0D),
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
          );
        },
      ),
    );
  }

  // Bookings — only confirmed ones shown
  Widget _buildBookings() {
    return Column(
      children: _confirmedBookings.map((b) {
        final imgPath = b['image'] as String;

        return Container(
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
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: SizedBox(
                  width: 70,
                  height: 80,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildImage(imgPath),
                      Container(color: Colors.black.withOpacity(0.12)),
                    ],
                  ),
                ),
              ),

              // Info
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

              // Confirmed badge only
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
        );
      }).toList(),
    );
  }

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
