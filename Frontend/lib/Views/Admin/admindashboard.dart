import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Models/app_enums.dart';

// ─────────────────────────────────────────────────────────────────────────────
// THEME PROVIDER
// ─────────────────────────────────────────────────────────────────────────────
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false; // Default to light mode
  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setTheme(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// THEME EXTENSIONS
// ─────────────────────────────────────────────────────────────────────────────
class AdminThemeColors extends ThemeExtension<AdminThemeColors> {
  final Color background;
  final Color surface;
  final Color card;
  final Color border;
  final Color text;
  final Color textMid;
  final Color textLight;
  final Color hover;
  final Color divider;

  AdminThemeColors({
    required this.background,
    required this.surface,
    required this.card,
    required this.border,
    required this.text,
    required this.textMid,
    required this.textLight,
    required this.hover,
    required this.divider,
  });

  // Light theme - using app colors
  static final light = AdminThemeColors(
    background: kBg, // Your app background
    surface: Colors.white,
    card: Colors.white,
    border: const Color(0xFFE5E5E5),
    text: kTextDark,
    textMid: kTextMid,
    textLight: kTextLight,
    hover: const Color(0xFFF5F5F5),
    divider: const Color(0xFFEEEEEE),
  );

  // Dark theme - proper dark mode
  static final dark = AdminThemeColors(
    background: const Color(0xFF121212),
    surface: const Color(0xFF1E1E1E),
    card: const Color(0xFF252525),
    border: const Color(0xFF333333),
    text: Colors.white,
    textMid: const Color(0xFFB0B0B0),
    textLight: const Color(0xFF808080),
    hover: const Color(0xFF2A2A2A),
    divider: const Color(0xFF333333),
  );

  @override
  ThemeExtension<AdminThemeColors> copyWith({
    Color? background,
    Color? surface,
    Color? card,
    Color? border,
    Color? text,
    Color? textMid,
    Color? textLight,
    Color? hover,
    Color? divider,
  }) {
    return AdminThemeColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      border: border ?? this.border,
      text: text ?? this.text,
      textMid: textMid ?? this.textMid,
      textLight: textLight ?? this.textLight,
      hover: hover ?? this.hover,
      divider: divider ?? this.divider,
    );
  }

  @override
  ThemeExtension<AdminThemeColors> lerp(
    covariant ThemeExtension<AdminThemeColors>? other,
    double t,
  ) {
    if (other is! AdminThemeColors) return this;
    return AdminThemeColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      card: Color.lerp(card, other.card, t)!,
      border: Color.lerp(border, other.border, t)!,
      text: Color.lerp(text, other.text, t)!,
      textMid: Color.lerp(textMid, other.textMid, t)!,
      textLight: Color.lerp(textLight, other.textLight, t)!,
      hover: Color.lerp(hover, other.hover, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODELS (unchanged)
// ─────────────────────────────────────────────────────────────────────────────
enum AdminSection {
  overview,
  players,
  managers,
  venues,
  bookings,
  tournaments,
  reports,
  settings,
}

class AdminPlayer {
  final String id, name, email, phone, avatar;
  final int bookings, matches;
  final double spent;
  final bool isActive, isVerified;
  final DateTime joined;
  final List<SportType> sports;
  AdminPlayer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.avatar,
    required this.bookings,
    required this.matches,
    required this.spent,
    required this.isActive,
    required this.isVerified,
    required this.joined,
    required this.sports,
  });
  AdminPlayer copyWith({bool? isActive}) => AdminPlayer(
    id: id,
    name: name,
    email: email,
    phone: phone,
    avatar: avatar,
    bookings: bookings,
    matches: matches,
    spent: spent,
    isActive: isActive ?? this.isActive,
    isVerified: isVerified,
    joined: joined,
    sports: sports,
  );
}

class AdminManager {
  final String id, name, email, phone, venueName, venueCity, avatar;
  final int courts, bookingsMonth;
  final double revenue;
  final bool isActive, isVerified;
  final DateTime joined;
  final List<SportType> sports;
  AdminManager({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.venueName,
    required this.venueCity,
    required this.avatar,
    required this.courts,
    required this.bookingsMonth,
    required this.revenue,
    required this.isActive,
    required this.isVerified,
    required this.joined,
    required this.sports,
  });
  AdminManager copyWith({bool? isActive, bool? isVerified}) => AdminManager(
    id: id,
    name: name,
    email: email,
    phone: phone,
    venueName: venueName,
    venueCity: venueCity,
    avatar: avatar,
    courts: courts,
    bookingsMonth: bookingsMonth,
    revenue: revenue,
    isActive: isActive ?? this.isActive,
    isVerified: isVerified ?? this.isVerified,
    joined: joined,
    sports: sports,
  );
}

class AdminBooking {
  final String id, player, venue, court, time, date;
  final SportType sport;
  final double price;
  final String status;
  const AdminBooking({
    required this.id,
    required this.player,
    required this.venue,
    required this.court,
    required this.time,
    required this.date,
    required this.sport,
    required this.price,
    required this.status,
  });
}

class AdminVenue {
  final String id, name, city, manager, address;
  final int courts, bookingsMonth;
  final double revenue, rating;
  final bool isActive;
  final List<SportType> sports;
  AdminVenue({
    required this.id,
    required this.name,
    required this.city,
    required this.manager,
    required this.address,
    required this.courts,
    required this.bookingsMonth,
    required this.revenue,
    required this.rating,
    required this.isActive,
    required this.sports,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// SEED DATA (unchanged)
// ─────────────────────────────────────────────────────────────────────────────
List<AdminPlayer> _seedPlayers() => [
  AdminPlayer(
    id: 'p1',
    name: 'Karim Jaziri',
    email: 'karim@email.com',
    phone: '+216 55 100 001',
    avatar: 'KJ',
    bookings: 34,
    matches: 18,
    spent: 2840,
    isActive: true,
    isVerified: true,
    joined: DateTime(2023, 3, 12),
    sports: [SportType.football, SportType.padel],
  ),
  AdminPlayer(
    id: 'p2',
    name: 'Nadia Ben Salah',
    email: 'nadia@email.com',
    phone: '+216 55 100 002',
    avatar: 'NB',
    bookings: 21,
    matches: 9,
    spent: 1560,
    isActive: true,
    isVerified: true,
    joined: DateTime(2023, 6, 4),
    sports: [SportType.tennis],
  ),
  AdminPlayer(
    id: 'p3',
    name: 'Mehdi Trabelsi',
    email: 'mehdi@email.com',
    phone: '+216 55 100 003',
    avatar: 'MT',
    bookings: 47,
    matches: 31,
    spent: 4120,
    isActive: true,
    isVerified: false,
    joined: DateTime(2023, 1, 28),
    sports: [SportType.basketball, SportType.football],
  ),
  AdminPlayer(
    id: 'p4',
    name: 'Leila Mallouli',
    email: 'leila@email.com',
    phone: '+216 55 100 004',
    avatar: 'LM',
    bookings: 12,
    matches: 5,
    spent: 890,
    isActive: false,
    isVerified: true,
    joined: DateTime(2024, 2, 14),
    sports: [SportType.padel],
  ),
  AdminPlayer(
    id: 'p5',
    name: 'Ahmed Ben Ali',
    email: 'ahmed@email.com',
    phone: '+216 55 100 005',
    avatar: 'AB',
    bookings: 28,
    matches: 14,
    spent: 2100,
    isActive: true,
    isVerified: true,
    joined: DateTime(2023, 9, 7),
    sports: [SportType.football],
  ),
  AdminPlayer(
    id: 'p6',
    name: 'Yasmine Khelifi',
    email: 'yasmine@email.com',
    phone: '+216 55 100 006',
    avatar: 'YK',
    bookings: 19,
    matches: 7,
    spent: 1440,
    isActive: true,
    isVerified: true,
    joined: DateTime(2024, 1, 3),
    sports: [SportType.tennis, SportType.padel],
  ),
  AdminPlayer(
    id: 'p7',
    name: 'Sami Bouazizi',
    email: 'sami@email.com',
    phone: '+216 55 100 007',
    avatar: 'SB',
    bookings: 55,
    matches: 40,
    spent: 5300,
    isActive: true,
    isVerified: true,
    joined: DateTime(2022, 11, 20),
    sports: [SportType.football, SportType.basketball],
  ),
  AdminPlayer(
    id: 'p8',
    name: 'Rania Hammami',
    email: 'rania@email.com',
    phone: '+216 55 100 008',
    avatar: 'RH',
    bookings: 8,
    matches: 2,
    spent: 560,
    isActive: false,
    isVerified: false,
    joined: DateTime(2024, 4, 18),
    sports: [SportType.padel],
  ),
];

List<AdminManager> _seedManagers() => [
  AdminManager(
    id: 'm1',
    name: 'Mohamed Karim',
    email: 'mk@arena.tn',
    phone: '+216 55 200 001',
    venueName: 'Arena Sport Center',
    venueCity: 'Tunis',
    avatar: 'MK',
    courts: 4,
    bookingsMonth: 142,
    revenue: 12800,
    isActive: true,
    isVerified: true,
    joined: DateTime(2022, 8, 1),
    sports: [
      SportType.football,
      SportType.padel,
      SportType.tennis,
      SportType.basketball,
    ],
  ),
  AdminManager(
    id: 'm2',
    name: 'Fares Bouslama',
    email: 'fares@sport.tn',
    phone: '+216 55 200 002',
    venueName: 'Tunis Sport Hub',
    venueCity: 'Ariana',
    avatar: 'FB',
    courts: 3,
    bookingsMonth: 89,
    revenue: 7400,
    isActive: true,
    isVerified: true,
    joined: DateTime(2023, 2, 15),
    sports: [SportType.football, SportType.padel],
  ),
  AdminManager(
    id: 'm3',
    name: 'Inès Sahli',
    email: 'ines@club.tn',
    phone: '+216 55 200 003',
    venueName: 'Padel Club Nord',
    venueCity: 'La Marsa',
    avatar: 'IS',
    courts: 2,
    bookingsMonth: 61,
    revenue: 5200,
    isActive: true,
    isVerified: true,
    joined: DateTime(2023, 5, 22),
    sports: [SportType.padel, SportType.tennis],
  ),
  AdminManager(
    id: 'm4',
    name: 'Walid Cherif',
    email: 'walid@field.tn',
    phone: '+216 55 200 004',
    venueName: 'City Field',
    venueCity: 'Sfax',
    avatar: 'WC',
    courts: 5,
    bookingsMonth: 203,
    revenue: 18600,
    isActive: true,
    isVerified: false,
    joined: DateTime(2022, 12, 3),
    sports: [SportType.football, SportType.basketball],
  ),
  AdminManager(
    id: 'm5',
    name: 'Sara Mrad',
    email: 'sara@fit.tn',
    phone: '+216 55 200 005',
    venueName: 'FitZone Courts',
    venueCity: 'Sousse',
    avatar: 'SM',
    courts: 2,
    bookingsMonth: 44,
    revenue: 3800,
    isActive: false,
    isVerified: true,
    joined: DateTime(2024, 1, 9),
    sports: [SportType.tennis],
  ),
];

List<AdminBooking> _seedBookings() => [
  AdminBooking(
    id: 'b1',
    player: 'Karim Jaziri',
    venue: 'Arena Sport Center',
    court: 'Court Alpha',
    time: '08:00 – 09:00',
    date: 'Today',
    sport: SportType.football,
    price: 90,
    status: 'confirmed',
  ),
  AdminBooking(
    id: 'b2',
    player: 'Nadia Ben Salah',
    venue: 'Padel Club Nord',
    court: 'Court 1',
    time: '09:30 – 11:00',
    date: 'Today',
    sport: SportType.padel,
    price: 180,
    status: 'confirmed',
  ),
  AdminBooking(
    id: 'b3',
    player: 'Mehdi Trabelsi',
    venue: 'Arena Sport Center',
    court: 'Court Gamma',
    time: '11:00 – 13:00',
    date: 'Today',
    sport: SportType.basketball,
    price: 210,
    status: 'pending',
  ),
  AdminBooking(
    id: 'b4',
    player: 'Leila Mallouli',
    venue: 'Tunis Sport Hub',
    court: 'Court B',
    time: '14:00 – 15:00',
    date: 'Today',
    sport: SportType.tennis,
    price: 105,
    status: 'confirmed',
  ),
  AdminBooking(
    id: 'b5',
    player: 'Ahmed Ben Ali',
    venue: 'City Field',
    court: 'Field 3',
    time: '19:00 – 20:00',
    date: 'Today',
    sport: SportType.football,
    price: 75,
    status: 'pending',
  ),
  AdminBooking(
    id: 'b6',
    player: 'Yasmine Khelifi',
    venue: 'Arena Sport Center',
    court: 'Court Beta',
    time: '10:00 – 11:30',
    date: 'Yesterday',
    sport: SportType.padel,
    price: 180,
    status: 'confirmed',
  ),
  AdminBooking(
    id: 'b7',
    player: 'Sami Bouazizi',
    venue: 'City Field',
    court: 'Field 1',
    time: '16:00 – 17:00',
    date: 'Yesterday',
    sport: SportType.football,
    price: 75,
    status: 'cancelled',
  ),
  AdminBooking(
    id: 'b8',
    player: 'Rania Hammami',
    venue: 'FitZone Courts',
    court: 'Court A',
    time: '08:00 – 09:00',
    date: 'Jun 10',
    sport: SportType.tennis,
    price: 95,
    status: 'confirmed',
  ),
];

List<AdminVenue> _seedVenues() => [
  AdminVenue(
    id: 'v1',
    name: 'Arena Sport Center',
    city: 'Tunis',
    manager: 'Mohamed Karim',
    address: 'Lac 2, Tunis',
    courts: 4,
    bookingsMonth: 142,
    revenue: 12800,
    rating: 4.8,
    isActive: true,
    sports: [
      SportType.football,
      SportType.padel,
      SportType.tennis,
      SportType.basketball,
    ],
  ),
  AdminVenue(
    id: 'v2',
    name: 'Tunis Sport Hub',
    city: 'Ariana',
    manager: 'Fares Bouslama',
    address: 'Cité Ennasr, Ariana',
    courts: 3,
    bookingsMonth: 89,
    revenue: 7400,
    rating: 4.5,
    isActive: true,
    sports: [SportType.football, SportType.padel],
  ),
  AdminVenue(
    id: 'v3',
    name: 'Padel Club Nord',
    city: 'La Marsa',
    manager: 'Inès Sahli',
    address: 'Corniche, La Marsa',
    courts: 2,
    bookingsMonth: 61,
    revenue: 5200,
    rating: 4.7,
    isActive: true,
    sports: [SportType.padel, SportType.tennis],
  ),
  AdminVenue(
    id: 'v4',
    name: 'City Field',
    city: 'Sfax',
    manager: 'Walid Cherif',
    address: 'Route Nationale, Sfax',
    courts: 5,
    bookingsMonth: 203,
    revenue: 18600,
    rating: 4.9,
    isActive: true,
    sports: [SportType.football, SportType.basketball],
  ),
  AdminVenue(
    id: 'v5',
    name: 'FitZone Courts',
    city: 'Sousse',
    manager: 'Sara Mrad',
    address: 'Sousse Médina',
    courts: 2,
    bookingsMonth: 44,
    revenue: 3800,
    rating: 4.2,
    isActive: false,
    sports: [SportType.tennis],
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// ROOT — ADMIN DASHBOARD
// ─────────────────────────────────────────────────────────────────────────────
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  AdminSection _section = AdminSection.overview;
  bool _sidebarCollapsed = false;

  late List<AdminPlayer> _players = _seedPlayers();
  late List<AdminManager> _managers = _seedManagers();
  late List<AdminBooking> _bookings = _seedBookings();
  late List<AdminVenue> _venues = _seedVenues();

  void _togglePlayerStatus(String id) => setState(() {
    final i = _players.indexWhere((p) => p.id == id);
    if (i != -1)
      _players[i] = _players[i].copyWith(isActive: !_players[i].isActive);
  });

  void _toggleManagerStatus(String id) => setState(() {
    final i = _managers.indexWhere((m) => m.id == id);
    if (i != -1)
      _managers[i] = _managers[i].copyWith(isActive: !_managers[i].isActive);
  });

  void _verifyManager(String id) => setState(() {
    final i = _managers.indexWhere((m) => m.id == id);
    if (i != -1) _managers[i] = _managers[i].copyWith(isVerified: true);
  });

  void _addManager(AdminManager m) => setState(() => _managers.insert(0, m));
  void _deletePlayer(String id) =>
      setState(() => _players.removeWhere((p) => p.id == id));
  void _deleteManager(String id) =>
      setState(() => _managers.removeWhere((m) => m.id == id));

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            themeMode: themeProvider.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            home: Scaffold(
              backgroundColor:
                  Theme.of(context).extension<AdminThemeColors>()?.background ??
                  kBg,
              body: Row(
                children: [
                  _Sidebar(
                    current: _section,
                    collapsed: _sidebarCollapsed,
                    onSelect: (s) => setState(() => _section = s),
                    onToggle: () =>
                        setState(() => _sidebarCollapsed = !_sidebarCollapsed),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        _TopBar(
                          section: _section,
                          onThemeToggle: themeProvider.toggleTheme,
                          isDarkMode: themeProvider.isDarkMode,
                        ),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            transitionBuilder: (child, anim) => FadeTransition(
                              opacity: anim,
                              child: SlideTransition(
                                position:
                                    Tween(
                                      begin: const Offset(0.015, 0),
                                      end: Offset.zero,
                                    ).animate(
                                      CurvedAnimation(
                                        parent: anim,
                                        curve: Curves.easeOut,
                                      ),
                                    ),
                                child: child,
                              ),
                            ),
                            child: KeyedSubtree(
                              key: ValueKey(_section),
                              child: _buildSection(),
                            ),
                          ),
                        ),
                      ],
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

  ThemeData _buildLightTheme() {
    return ThemeData.light().copyWith(extensions: [AdminThemeColors.light]);
  }

  ThemeData _buildDarkTheme() {
    return ThemeData.dark().copyWith(extensions: [AdminThemeColors.dark]);
  }

  Widget _buildSection() {
    switch (_section) {
      case AdminSection.overview:
        return _OverviewSection(
          players: _players,
          managers: _managers,
          bookings: _bookings,
          venues: _venues,
          onNavigate: (s) => setState(() => _section = s),
        );
      case AdminSection.players:
        return _PlayersSection(
          players: _players,
          onToggle: _togglePlayerStatus,
          onDelete: _deletePlayer,
        );
      case AdminSection.managers:
        return _ManagersSection(
          managers: _managers,
          onToggle: _toggleManagerStatus,
          onVerify: _verifyManager,
          onAdd: _addManager,
          onDelete: _deleteManager,
        );
      case AdminSection.venues:
        return _VenuesSection(venues: _venues);
      case AdminSection.bookings:
        return _BookingsSection(bookings: _bookings);
      case AdminSection.tournaments:
        return _PlaceholderSection(
          icon: Icons.emoji_events_rounded,
          label: 'Tournaments',
          sub: 'Tournament management coming soon',
        );
      case AdminSection.reports:
        return _ReportsSection(
          players: _players,
          managers: _managers,
          bookings: _bookings,
          venues: _venues,
        );
      case AdminSection.settings:
        return _SettingsSection();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SIDEBAR
// ─────────────────────────────────────────────────────────────────────────────
class _Sidebar extends StatefulWidget {
  final AdminSection current;
  final bool collapsed;
  final ValueChanged<AdminSection> onSelect;
  final VoidCallback onToggle;

  const _Sidebar({
    required this.current,
    required this.collapsed,
    required this.onSelect,
    required this.onToggle,
  });

  @override
  State<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<_Sidebar> {
  final List<_NavItem> _items = [
    _NavItem(AdminSection.overview, Icons.grid_view_rounded, 'Overview'),
    _NavItem(AdminSection.players, Icons.person_rounded, 'Players'),
    _NavItem(AdminSection.managers, Icons.manage_accounts_rounded, 'Managers'),
    _NavItem(AdminSection.venues, Icons.stadium_rounded, 'Venues'),
    _NavItem(AdminSection.bookings, Icons.calendar_today_rounded, 'Bookings'),
    _NavItem(
      AdminSection.tournaments,
      Icons.emoji_events_rounded,
      'Tournaments',
    ),
    _NavItem(AdminSection.reports, Icons.bar_chart_rounded, 'Reports'),
  ];

  final List<_NavItem> _bottomItems = [
    _NavItem(AdminSection.settings, Icons.settings_rounded, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AdminThemeColors>()!;
    final w = widget.collapsed ? 72.0 : 240.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
      width: w,
      color: colors.surface,
      child: Column(
        children: [
          _buildLogo(colors),
          const SizedBox(height: 8),
          Expanded(child: _buildNavItems(colors)),
          _buildBottomItems(colors),
          _buildCollapseToggle(colors),
        ],
      ),
    );
  }

  Widget _buildLogo(AdminThemeColors colors) {
    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: widget.collapsed ? 0 : 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Row(
        mainAxisAlignment: widget.collapsed
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimary, kPrimary.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Center(
              child: Text(
                'S',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          if (!widget.collapsed) ...[
            const SizedBox(width: 10),
            Text(
              'Sporta',
              style: TextStyle(
                color: colors.text,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavItems(AdminThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (context, index) {
          return _SidebarItem(
            item: _items[index],
            current: widget.current,
            collapsed: widget.collapsed,
            onTap: () => widget.onSelect(_items[index].section),
          );
        },
      ),
    );
  }

  Widget _buildBottomItems(AdminThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Divider(height: 1, color: colors.divider),
          const SizedBox(height: 8),
          ..._bottomItems.map(
            (item) => _SidebarItem(
              item: item,
              current: widget.current,
              collapsed: widget.collapsed,
              onTap: () => widget.onSelect(item.section),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCollapseToggle(AdminThemeColors colors) {
    return GestureDetector(
      onTap: widget.onToggle,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.divider)),
        ),
        child: Center(
          child: Icon(
            widget.collapsed
                ? Icons.chevron_right_rounded
                : Icons.chevron_left_rounded,
            color: colors.textMid,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final AdminSection section;
  final IconData icon;
  final String label;
  const _NavItem(this.section, this.icon, this.label);
}

class _SidebarItem extends StatefulWidget {
  final _NavItem item;
  final AdminSection current;
  final bool collapsed;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.item,
    required this.current,
    required this.collapsed,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AdminThemeColors>()!;
    final active = widget.current == widget.item.section;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 3),
          padding: EdgeInsets.symmetric(
            horizontal: widget.collapsed ? 0 : 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: active
                ? kPrimary.withOpacity(0.1)
                : _hover
                ? colors.hover
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: active
                ? Border.all(color: kPrimary.withOpacity(0.3))
                : null,
          ),
          child: Row(
            mainAxisAlignment: widget.collapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(
                widget.item.icon,
                size: 18,
                color: active
                    ? kPrimary
                    : (_hover ? colors.text : colors.textMid),
              ),
              if (!widget.collapsed) ...[
                const SizedBox(width: 11),
                Text(
                  widget.item.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active
                        ? colors.text
                        : (_hover ? colors.text : colors.textMid),
                  ),
                ),
                if (active) ...[
                  const Spacer(),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: kPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatefulWidget {
  final AdminSection section;
  final VoidCallback onThemeToggle;
  final bool isDarkMode;

  const _TopBar({
    required this.section,
    required this.onThemeToggle,
    required this.isDarkMode,
  });

  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  bool _searchHover = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.section) {
      case AdminSection.overview:
        return 'Overview';
      case AdminSection.players:
        return 'Players';
      case AdminSection.managers:
        return 'Managers';
      case AdminSection.venues:
        return 'Venues';
      case AdminSection.bookings:
        return 'Bookings';
      case AdminSection.tournaments:
        return 'Tournaments';
      case AdminSection.reports:
        return 'Reports';
      case AdminSection.settings:
        return 'Settings';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AdminThemeColors>()!;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Row(
        children: [
          Text(
            _title,
            style: TextStyle(
              color: colors.text,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          _buildSearchBar(colors),
          const SizedBox(width: 16),
          _TopBtn(
            icon: widget.isDarkMode
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded,
            onTap: widget.onThemeToggle,
          ),
          const SizedBox(width: 8),
          _TopBtn(icon: Icons.notifications_outlined, badge: '3', onTap: () {}),
          const SizedBox(width: 8),
          _buildUserProfile(colors),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AdminThemeColors colors) {
    return MouseRegion(
      onEnter: (_) => setState(() => _searchHover = true),
      onExit: (_) => setState(() => _searchHover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 240,
        height: 36,
        decoration: BoxDecoration(
          color: _searchHover ? colors.hover : colors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.divider),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(Icons.search_rounded, size: 15, color: colors.textLight),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: colors.text, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search anything...',
                  hintStyle: TextStyle(color: colors.textLight, fontSize: 13),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: colors.divider),
              ),
              child: Text(
                '⌘K',
                style: TextStyle(
                  color: colors.textLight,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfile(AdminThemeColors colors) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimary, kPrimary.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Text(
              'A',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin',
              style: TextStyle(
                color: colors.text,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Super Admin',
              style: TextStyle(color: colors.textLight, fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }
}

class _TopBtn extends StatefulWidget {
  final IconData icon;
  final String? badge;
  final VoidCallback onTap;

  const _TopBtn({required this.icon, this.badge, required this.onTap});

  @override
  State<_TopBtn> createState() => _TopBtnState();
}

class _TopBtnState extends State<_TopBtn> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AdminThemeColors>()!;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _hover ? colors.hover : colors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.divider),
              ),
              child: Icon(widget.icon, size: 17, color: colors.textLight),
            ),
            if (widget.badge != null)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE03B3B),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      widget.badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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
// OVERVIEW SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _OverviewSection extends StatefulWidget {
  final List<AdminPlayer> players;
  final List<AdminManager> managers;
  final List<AdminBooking> bookings;
  final List<AdminVenue> venues;
  final ValueChanged<AdminSection> onNavigate;

  const _OverviewSection({
    required this.players,
    required this.managers,
    required this.bookings,
    required this.venues,
    required this.onNavigate,
  });

  @override
  State<_OverviewSection> createState() => _OverviewSectionState();
}

class _OverviewSectionState extends State<_OverviewSection> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AdminThemeColors>()!;
    final totalRevenue = widget.venues.fold(0.0, (s, v) => s + v.revenue);
    final pending = widget.bookings.where((b) => b.status == 'pending').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(pending, colors),
          const SizedBox(height: 24),
          _buildKpiRow(pending, totalRevenue, colors),
          const SizedBox(height: 28),
          _buildTwoColumnRow(colors),
          const SizedBox(height: 18),
          _buildSecondRow(colors),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(int pending, AdminThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimary, kPrimary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good morning, Admin 👋',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Here's what's happening today",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _WelcomePill(
                      '${widget.bookings.where((b) => b.date == 'Today').length} bookings today',
                      Icons.calendar_today_rounded,
                    ),
                    const SizedBox(width: 10),
                    _WelcomePill(
                      '$pending pending approvals',
                      Icons.pending_actions_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow(
    int pending,
    double totalRevenue,
    AdminThemeColors colors,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _KpiCard(
            label: 'Total Players',
            value: '${widget.players.length}',
            icon: Icons.person_rounded,
            color: kPrimary,
            sub: '+3 this week',
            trend: true,
          ),
          const SizedBox(width: 16),
          _KpiCard(
            label: 'Managers',
            value: '${widget.managers.length}',
            icon: Icons.manage_accounts_rounded,
            color: kPurple,
            sub:
                '${widget.managers.where((m) => !m.isVerified).length} pending',
            trend: false,
          ),
          const SizedBox(width: 16),
          _KpiCard(
            label: 'Total Revenue',
            value: '${(totalRevenue / 1000).toStringAsFixed(1)}K DT',
            icon: Icons.payments_rounded,
            color: kGreen,
            sub: '+18% vs last month',
            trend: true,
          ),
          const SizedBox(width: 16),
          _KpiCard(
            label: 'Bookings Today',
            value: '${widget.bookings.where((b) => b.date == 'Today').length}',
            icon: Icons.calendar_today_rounded,
            color: kAmber,
            sub: '$pending pending',
            trend: null,
          ),
          const SizedBox(width: 16),
          _KpiCard(
            label: 'Active Venues',
            value:
                '${widget.venues.where((v) => v.isActive).length}/${widget.venues.length}',
            icon: Icons.stadium_rounded,
            color: kBlue,
            sub: '${widget.venues.fold(0, (s, v) => s + v.courts)} courts',
            trend: null,
          ),
        ],
      ),
    );
  }

  Widget _buildTwoColumnRow(AdminThemeColors colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _SCard(
            title: "Recent Bookings",
            action: 'View all',
            onAction: () => widget.onNavigate(AdminSection.bookings),
            child: Column(
              children: widget.bookings
                  .take(5)
                  .map((b) => _BookingRow(booking: b))
                  .toList(),
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          flex: 2,
          child: _SCard(
            title: 'Top Venues',
            action: 'View all',
            onAction: () => widget.onNavigate(AdminSection.venues),
            child: Column(
              children: widget.venues
                  .take(4)
                  .map((v) => _VenueSnippet(venue: v))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecondRow(AdminThemeColors colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _SCard(
            title: 'New Players',
            action: 'View all',
            onAction: () => widget.onNavigate(AdminSection.players),
            child: Column(
              children: widget.players
                  .take(4)
                  .map((p) => _PlayerSnippet(player: p))
                  .toList(),
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: _SCard(
            title: 'Managers',
            action: 'View all',
            onAction: () => widget.onNavigate(AdminSection.managers),
            child: Column(
              children: widget.managers
                  .take(4)
                  .map((m) => _ManagerSnippet(manager: m))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _WelcomePill extends StatelessWidget {
  final String label;
  final IconData icon;
  const _WelcomePill(this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withOpacity(0.9)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KPI CARD
// ─────────────────────────────────────────────────────────────────────────────
class _KpiCard extends StatefulWidget {
  final String label, value, sub;
  final IconData icon;
  final Color color;
  final bool? trend;
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.sub,
    required this.trend,
  });

  @override
  State<_KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<_KpiCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AdminThemeColors>()!;

    return SizedBox(
      width: 200,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _hover ? colors.hover : colors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hover ? widget.color.withOpacity(0.3) : colors.divider,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon, size: 17, color: widget.color),
                  ),
                  if (widget.trend != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: (widget.trend! ? kGreen : kRed).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.trend!
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 10,
                            color: widget.trend! ? kGreen : kRed,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '18%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: widget.trend! ? kGreen : kRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                widget.value,
                style: TextStyle(
                  color: colors.text,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.label,
                style: TextStyle(
                  color: colors.textLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.sub,
                style: TextStyle(
                  color: widget.color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION CARD
// ─────────────────────────────────────────────────────────────────────────────
class _SCard extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final Widget child;
  const _SCard({
    required this.title,
    required this.child,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AdminThemeColors>()!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (action != null) ...[
                const Spacer(),
                GestureDetector(
                  onTap: onAction,
                  child: Text(
                    action!,
                    style: const TextStyle(
                      color: kPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// Snippet widgets
class _BookingRow extends StatelessWidget {
  final AdminBooking booking;
  const _BookingRow({required this.booking});

  Color get _statusColor {
    switch (booking.status) {
      case 'confirmed':
        return kGreen;
      case 'pending':
        return kAmber;
      case 'cancelled':
        return kRed;
      default:
        return kTextLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AdminThemeColors>()!;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: booking.sport.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              booking.sport.icon,
              size: 16,
              color: booking.sport.color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.player,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${booking.venue} · ${booking.time}',
                  style: TextStyle(color: colors.textLight, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _ABadge(booking.status.capitalize(), _statusColor),
              const SizedBox(height: 3),
              Text(
                '${booking.price.toInt()} DT',
                style: TextStyle(
                  color: colors.textLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VenueSnippet extends StatelessWidget {
  final AdminVenue venue;
  const _VenueSnippet({required this.venue});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AdminThemeColors>()!;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.stadium_rounded, size: 16, color: kPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  venue.name,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${venue.city} · ${venue.courts} courts',
                  style: TextStyle(color: colors.textLight, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(venue.revenue / 1000).toStringAsFixed(1)}K DT',
                style: const TextStyle(
                  color: kGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star_rounded, size: 11, color: kAmber),
                  const SizedBox(width: 2),
                  Text(
                    '${venue.rating}',
                    style: TextStyle(color: colors.textLight, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlayerSnippet extends StatelessWidget {
  final AdminPlayer player;
  const _PlayerSnippet({required this.player});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AdminThemeColors>()!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _Avatar(player.avatar, kPrimary),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  player.email,
                  style: TextStyle(color: colors.textLight, fontSize: 11),
                ),
              ],
            ),
          ),
          _ABadge(
            player.isActive ? 'Active' : 'Inactive',
            player.isActive ? kGreen : kRed,
          ),
        ],
      ),
    );
  }
}

class _ManagerSnippet extends StatelessWidget {
  final AdminManager manager;
  const _ManagerSnippet({required this.manager});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AdminThemeColors>()!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _Avatar(manager.avatar, kPurple),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  manager.name,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  manager.venueName,
                  style: TextStyle(color: colors.textLight, fontSize: 11),
                ),
              ],
            ),
          ),
          if (!manager.isVerified)
            _ABadge('Unverified', kAmber)
          else
            _ABadge('Verified', kGreen),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLAYERS SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _PlayersSection extends StatefulWidget {
  final List<AdminPlayer> players;
  final ValueChanged<String> onToggle;
  final ValueChanged<String> onDelete;
  const _PlayersSection({
    required this.players,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  State<_PlayersSection> createState() => _PlayersSectionState();
}

class _PlayersSectionState extends State<_PlayersSection> {
  String _filter = 'all';
  String _search = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AdminPlayer> get _filtered {
    var list = widget.players;
    if (_search.isNotEmpty) {
      list = list
          .where(
            (p) =>
                p.name.toLowerCase().contains(_search.toLowerCase()) ||
                p.email.toLowerCase().contains(_search.toLowerCase()),
          )
          .toList();
    }
    if (_filter == 'active') return list.where((p) => p.isActive).toList();
    if (_filter == 'inactive') return list.where((p) => !p.isActive).toList();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AdminThemeColors>()!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsRow(),
          const SizedBox(height: 24),
          _buildTable(colors),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _MiniStat(
            'Total Players',
            '${widget.players.length}',
            Icons.person_rounded,
            kPrimary,
          ),
          const SizedBox(width: 14),
          _MiniStat(
            'Active',
            '${widget.players.where((p) => p.isActive).length}',
            Icons.check_circle_rounded,
            kGreen,
          ),
          const SizedBox(width: 14),
          _MiniStat(
            'Inactive',
            '${widget.players.where((p) => !p.isActive).length}',
            Icons.block_rounded,
            kRed,
          ),
          const SizedBox(width: 14),
          _MiniStat(
            'Verified',
            '${widget.players.where((p) => p.isVerified).length}',
            Icons.verified_rounded,
            kAmber,
          ),
        ],
      ),
    );
  }

  Widget _buildTable(AdminThemeColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        children: [
          _buildToolbar(colors),
          _TableHeader(
            cols: const [
              'Player',
              'Email',
              'Sports',
              'Bookings',
              'Spent',
              'Status',
              'Actions',
            ],
          ),
          ..._filtered.map(
            (p) => _PlayerRow(
              player: p,
              onToggle: () => widget.onToggle(p.id),
              onDelete: () =>
                  _confirmDelete(context, p.name, () => widget.onDelete(p.id)),
              onView: () => _showPlayerDetail(context, p),
            ),
          ),
          if (_filtered.isEmpty)
            _EmptyTable('No players match the current filter'),
        ],
      ),
    );
  }

  Widget _buildToolbar(AdminThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Row(
        children: [
          Text(
            'All Players',
            style: TextStyle(
              color: colors.text,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          _TableSearch(
            controller: _searchController,
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(width: 10),
          ...['all', 'active', 'inactive'].map(
            (f) => _FilterPill(
              label: f == 'all' ? 'All' : f.capitalize(),
              active: _filter == f,
              onTap: () => setState(() => _filter = f),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, String name, VoidCallback onConfirm) {
    showDialog(
      context: ctx,
      builder: (_) => _ConfirmDialog(
        title: 'Delete Player',
        body: 'Remove "$name"? This action cannot be undone.',
        color: kRed,
        onConfirm: onConfirm,
      ),
    );
  }

  void _showPlayerDetail(BuildContext ctx, AdminPlayer p) {
    showDialog(
      context: ctx,
      builder: (_) => _PlayerDetailDialog(player: p),
    );
  }
}

class _PlayerRow extends StatefulWidget {
  final AdminPlayer player;
  final VoidCallback onToggle, onDelete, onView;
  const _PlayerRow({
    required this.player,
    required this.onToggle,
    required this.onDelete,
    required this.onView,
  });

  @override
  State<_PlayerRow> createState() => _PlayerRowState();
}

class _PlayerRowState extends State<_PlayerRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AdminThemeColors>()!;
    final p = widget.player;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: _hover ? colors.hover : Colors.transparent,
          border: Border(top: BorderSide(color: colors.divider)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          child: Row(
            children: [
              Expanded(flex: 3, child: _buildPlayerInfo(p, colors)),
              Expanded(
                flex: 3,
                child: Text(
                  p.email,
                  style: TextStyle(color: colors.textLight, fontSize: 12),
                ),
              ),
              Expanded(flex: 2, child: _buildSportBadges(p)),
              Expanded(
                flex: 1,
                child: Text(
                  '${p.bookings}',
                  style: TextStyle(color: colors.text, fontSize: 13),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '${p.spent.toInt()} DT',
                  style: const TextStyle(
                    color: kGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: _ABadge(
                  p.isActive ? 'Active' : 'Inactive',
                  p.isActive ? kGreen : kRed,
                ),
              ),
              Expanded(flex: 2, child: _buildActions(colors)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerInfo(AdminPlayer p, AdminThemeColors colors) {
    return Row(
      children: [
        _Avatar(p.avatar, kPrimary),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    p.name,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (p.isVerified) ...[
                    const SizedBox(width: 5),
                    Icon(Icons.verified_rounded, size: 13, color: kPrimary),
                  ],
                ],
              ),
              Text(
                'Joined ${_formatDate(p.joined)}',
                style: TextStyle(color: colors.textLight, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSportBadges(AdminPlayer p) {
    return Wrap(
      spacing: 4,
      children: p.sports
          .map(
            (s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: s.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                s.label,
                style: TextStyle(
                  color: s.color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildActions(AdminThemeColors colors) {
    return Row(
      children: [
        _ActionBtn(Icons.visibility_outlined, colors.textLight, widget.onView),
        const SizedBox(width: 6),
        _ActionBtn(
          widget.player.isActive
              ? Icons.block_rounded
              : Icons.check_circle_outline_rounded,
          widget.player.isActive ? kAmber : kGreen,
          widget.onToggle,
        ),
        const SizedBox(width: 6),
        _ActionBtn(Icons.delete_outline_rounded, kRed, widget.onDelete),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MANAGERS SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _ManagersSection extends StatefulWidget {
  final List<AdminManager> managers;
  final ValueChanged<String> onToggle, onVerify, onDelete;
  final ValueChanged<AdminManager> onAdd;
  const _ManagersSection({
    required this.managers,
    required this.onToggle,
    required this.onVerify,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  State<_ManagersSection> createState() => _ManagersSectionState();
}

class _ManagersSectionState extends State<_ManagersSection> {
  String _filter = 'all';
  String _search = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AdminManager> get _filtered {
    var list = widget.managers;
    if (_search.isNotEmpty) {
      list = list
          .where(
            (m) =>
                m.name.toLowerCase().contains(_search.toLowerCase()) ||
                m.venueName.toLowerCase().contains(_search.toLowerCase()),
          )
          .toList();
    }
    if (_filter == 'active') return list.where((m) => m.isActive).toList();
    if (_filter == 'inactive') return list.where((m) => !m.isActive).toList();
    if (_filter == 'unverified')
      return list.where((m) => !m.isVerified).toList();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AdminThemeColors>()!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(colors),
          const SizedBox(height: 24),
          _buildTable(colors),
        ],
      ),
    );
  }

  Widget _buildHeader(AdminThemeColors colors) {
    return Row(
      children: [
        _MiniStat(
          'Total',
          '${widget.managers.length}',
          Icons.manage_accounts_rounded,
          kPrimary,
        ),
        const SizedBox(width: 14),
        _MiniStat(
          'Active',
          '${widget.managers.where((m) => m.isActive).length}',
          Icons.check_circle_rounded,
          kGreen,
        ),
        const SizedBox(width: 14),
        _MiniStat(
          'Unverified',
          '${widget.managers.where((m) => !m.isVerified).length}',
          Icons.pending_rounded,
          kAmber,
        ),
        const SizedBox(width: 14),
        _MiniStat(
          'Bookings/mo',
          '${widget.managers.fold(0, (s, m) => s + m.bookingsMonth)}',
          Icons.calendar_today_rounded,
          kPurple,
        ),
        const Spacer(),
        _AdminBtn(
          label: 'Add Manager',
          icon: Icons.add_rounded,
          onTap: () => _showAddManager(context),
        ),
      ],
    );
  }

  Widget _buildTable(AdminThemeColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        children: [
          _buildToolbar(colors),
          _TableHeader(
            cols: const [
              'Manager',
              'Venue',
              'City',
              'Courts',
              'Revenue/mo',
              'Status',
              'Actions',
            ],
          ),
          ..._filtered.map(
            (m) => _ManagerRow(
              manager: m,
              onToggle: () => widget.onToggle(m.id),
              onVerify: () => widget.onVerify(m.id),
              onDelete: () =>
                  _confirmDelete(context, m.name, () => widget.onDelete(m.id)),
              onView: () => _showManagerDetail(context, m),
            ),
          ),
          if (_filtered.isEmpty)
            _EmptyTable('No managers match the current filter'),
        ],
      ),
    );
  }

  Widget _buildToolbar(AdminThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Row(
        children: [
          Text(
            'All Managers',
            style: TextStyle(
              color: colors.text,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          _TableSearch(
            controller: _searchController,
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(width: 10),
          ...['all', 'active', 'inactive', 'unverified'].map(
            (f) => _FilterPill(
              label: f == 'all' ? 'All' : f.capitalize(),
              active: _filter == f,
              onTap: () => setState(() => _filter = f),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddManager(BuildContext ctx) {
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => _AddManagerDialog(onAdd: widget.onAdd),
    );
  }

  void _confirmDelete(BuildContext ctx, String name, VoidCallback onConfirm) {
    showDialog(
      context: ctx,
      builder: (_) => _ConfirmDialog(
        title: 'Remove Manager',
        body: 'Remove "$name" and revoke their access? This cannot be undone.',
        color: kRed,
        onConfirm: onConfirm,
      ),
    );
  }

  void _showManagerDetail(BuildContext ctx, AdminManager m) {
    showDialog(
      context: ctx,
      builder: (_) => _ManagerDetailDialog(manager: m),
    );
  }
}

class _ManagerRow extends StatefulWidget {
  final AdminManager manager;
  final VoidCallback onToggle, onVerify, onDelete, onView;
  const _ManagerRow({
    required this.manager,
    required this.onToggle,
    required this.onVerify,
    required this.onDelete,
    required this.onView,
  });

  @override
  State<_ManagerRow> createState() => _ManagerRowState();
}

class _ManagerRowState extends State<_ManagerRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AdminThemeColors>()!;
    final m = widget.manager;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: _hover ? colors.hover : Colors.transparent,
          border: Border(top: BorderSide(color: colors.divider)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          child: Row(
            children: [
              Expanded(flex: 3, child: _buildManagerInfo(m, colors)),
              Expanded(
                flex: 3,
                child: Text(
                  m.venueName,
                  style: TextStyle(color: colors.text, fontSize: 12),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  m.venueCity,
                  style: TextStyle(color: colors.textLight, fontSize: 12),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  '${m.courts}',
                  style: TextStyle(color: colors.text, fontSize: 13),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '${(m.revenue / 1000).toStringAsFixed(1)}K DT',
                  style: const TextStyle(
                    color: kGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: _ABadge(
                  m.isActive ? 'Active' : 'Inactive',
                  m.isActive ? kGreen : kRed,
                ),
              ),
              Expanded(flex: 2, child: _buildActions(colors)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManagerInfo(AdminManager m, AdminThemeColors colors) {
    return Row(
      children: [
        _Avatar(m.avatar, kPurple),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    m.name,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (m.isVerified) ...[
                    const SizedBox(width: 5),
                    Icon(Icons.verified_rounded, size: 13, color: kPrimary),
                  ],
                  if (!m.isVerified) ...[
                    const SizedBox(width: 5),
                    _ABadge('Pending', kAmber),
                  ],
                ],
              ),
              Text(
                m.email,
                style: TextStyle(color: colors.textLight, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions(AdminThemeColors colors) {
    return Row(
      children: [
        _ActionBtn(Icons.visibility_outlined, colors.textLight, widget.onView),
        const SizedBox(width: 6),
        if (!widget.manager.isVerified)
          _ActionBtn(Icons.verified_rounded, kPrimary, widget.onVerify),
        if (widget.manager.isVerified)
          _ActionBtn(
            widget.manager.isActive
                ? Icons.block_rounded
                : Icons.check_circle_outline_rounded,
            widget.manager.isActive ? kAmber : kGreen,
            widget.onToggle,
          ),
        const SizedBox(width: 6),
        _ActionBtn(Icons.delete_outline_rounded, kRed, widget.onDelete),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VENUES SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _VenuesSection extends StatefulWidget {
  final List<AdminVenue> venues;
  const _VenuesSection({required this.venues});

  @override
  State<_VenuesSection> createState() => _VenuesSectionState();
}

class _VenuesSectionState extends State<_VenuesSection> {
  String _search = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AdminVenue> get _filtered {
    if (_search.isEmpty) return widget.venues;
    return widget.venues
        .where(
          (v) =>
              v.name.toLowerCase().contains(_search.toLowerCase()) ||
              v.city.toLowerCase().contains(_search.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AdminThemeColors>()!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          _buildStatsRow(),
          const SizedBox(height: 24),
          _buildTable(colors),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _MiniStat(
            'Total Venues',
            '${widget.venues.length}',
            Icons.stadium_rounded,
            kPrimary,
          ),
          const SizedBox(width: 14),
          _MiniStat(
            'Active',
            '${widget.venues.where((v) => v.isActive).length}',
            Icons.check_circle_rounded,
            kGreen,
          ),
          const SizedBox(width: 14),
          _MiniStat(
            'Total Courts',
            '${widget.venues.fold(0, (s, v) => s + v.courts)}',
            Icons.sports_tennis_rounded,
            kAmber,
          ),
          const SizedBox(width: 14),
          _MiniStat(
            'Total Revenue',
            '${(widget.venues.fold(0.0, (s, v) => s + v.revenue) / 1000).toStringAsFixed(1)}K DT',
            Icons.payments_rounded,
            kGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildTable(AdminThemeColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        children: [
          _buildToolbar(colors),
          _TableHeader(
            cols: const [
              'Venue',
              'City',
              'Manager',
              'Courts',
              'Bookings/mo',
              'Revenue',
              'Rating',
              'Status',
            ],
          ),
          ..._filtered.map((v) => _VenueRow(venue: v)),
          if (_filtered.isEmpty) _EmptyTable('No venues found'),
        ],
      ),
    );
  }

  Widget _buildToolbar(AdminThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Row(
        children: [
          Text(
            'All Venues',
            style: TextStyle(
              color: colors.text,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          _TableSearch(
            controller: _searchController,
            onChanged: (v) => setState(() => _search = v),
          ),
        ],
      ),
    );
  }
}

class _VenueRow extends StatefulWidget {
  final AdminVenue venue;
  const _VenueRow({required this.venue});

  @override
  State<_VenueRow> createState() => _VenueRowState();
}

class _VenueRowState extends State<_VenueRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AdminThemeColors>()!;
    final v = widget.venue;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: _hover ? colors.hover : Colors.transparent,
          border: Border(top: BorderSide(color: colors.divider)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          child: Row(
            children: [
              Expanded(flex: 3, child: _buildVenueInfo(v, colors)),
              Expanded(
                flex: 1,
                child: Text(
                  v.city,
                  style: TextStyle(color: colors.textLight, fontSize: 12),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  v.manager,
                  style: TextStyle(color: colors.text, fontSize: 12),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  '${v.courts}',
                  style: TextStyle(color: colors.text, fontSize: 13),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '${v.bookingsMonth}',
                  style: TextStyle(color: colors.text, fontSize: 12),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '${(v.revenue / 1000).toStringAsFixed(1)}K DT',
                  style: const TextStyle(
                    color: kGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(flex: 1, child: _buildRating(v)),
              Expanded(
                flex: 1,
                child: _ABadge(
                  v.isActive ? 'Active' : 'Inactive',
                  v.isActive ? kGreen : kRed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVenueInfo(AdminVenue v, AdminThemeColors colors) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(Icons.stadium_rounded, size: 16, color: kPrimary),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                v.name,
                style: TextStyle(
                  color: colors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Wrap(
                spacing: 4,
                children: v.sports
                    .map(
                      (s) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: s.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          s.label,
                          style: TextStyle(
                            color: s.color,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRating(AdminVenue v) {
    return Row(
      children: [
        const Icon(Icons.star_rounded, size: 13, color: kAmber),
        const SizedBox(width: 4),
        Text(
          '${v.rating}',
          style: TextStyle(
            color: Theme.of(context).extension<AdminThemeColors>()!.text,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOOKINGS SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _BookingsSection extends StatefulWidget {
  final List<AdminBooking> bookings;
  const _BookingsSection({required this.bookings});

  @override
  State<_BookingsSection> createState() => _BookingsSectionState();
}

class _BookingsSectionState extends State<_BookingsSection> {
  String _filter = 'all';

  List<AdminBooking> get _filtered {
    if (_filter == 'all') return widget.bookings;
    return widget.bookings.where((b) => b.status == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AdminThemeColors>()!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          _buildStatsRow(),
          const SizedBox(height: 24),
          _buildTable(colors),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _MiniStat(
            'Total',
            '${widget.bookings.length}',
            Icons.calendar_today_rounded,
            kPrimary,
          ),
          const SizedBox(width: 14),
          _MiniStat(
            'Confirmed',
            '${widget.bookings.where((b) => b.status == 'confirmed').length}',
            Icons.check_circle_rounded,
            kGreen,
          ),
          const SizedBox(width: 14),
          _MiniStat(
            'Pending',
            '${widget.bookings.where((b) => b.status == 'pending').length}',
            Icons.pending_rounded,
            kAmber,
          ),
          const SizedBox(width: 14),
          _MiniStat(
            'Cancelled',
            '${widget.bookings.where((b) => b.status == 'cancelled').length}',
            Icons.cancel_rounded,
            kRed,
          ),
        ],
      ),
    );
  }

  Widget _buildTable(AdminThemeColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        children: [
          _buildToolbar(colors),
          _TableHeader(
            cols: const [
              'Player',
              'Venue',
              'Court',
              'Sport',
              'Date',
              'Time',
              'Price',
              'Status',
            ],
          ),
          ..._filtered.map((b) => _BookingTableRow(booking: b)),
          if (_filtered.isEmpty) _EmptyTable('No bookings found'),
        ],
      ),
    );
  }

  Widget _buildToolbar(AdminThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Row(
        children: [
          Text(
            'All Bookings',
            style: TextStyle(
              color: colors.text,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          ...['all', 'confirmed', 'pending', 'cancelled'].map(
            (f) => _FilterPill(
              label: f == 'all' ? 'All' : f.capitalize(),
              active: _filter == f,
              onTap: () => setState(() => _filter = f),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingTableRow extends StatefulWidget {
  final AdminBooking booking;
  const _BookingTableRow({required this.booking});

  @override
  State<_BookingTableRow> createState() => _BookingTableRowState();
}

class _BookingTableRowState extends State<_BookingTableRow> {
  bool _hover = false;

  Color get _statusColor {
    switch (widget.booking.status) {
      case 'confirmed':
        return kGreen;
      case 'pending':
        return kAmber;
      case 'cancelled':
        return kRed;
      default:
        return kTextLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AdminThemeColors>()!;
    final b = widget.booking;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: _hover ? colors.hover : Colors.transparent,
          border: Border(top: BorderSide(color: colors.divider)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  b.player,
                  style: TextStyle(color: colors.text, fontSize: 12),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  b.venue,
                  style: TextStyle(color: colors.textLight, fontSize: 12),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  b.court,
                  style: TextStyle(color: colors.textLight, fontSize: 12),
                ),
              ),
              Expanded(flex: 2, child: _buildSport(b)),
              Expanded(
                flex: 1,
                child: Text(
                  b.date,
                  style: TextStyle(color: colors.textLight, fontSize: 12),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  b.time,
                  style: TextStyle(color: colors.text, fontSize: 12),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  '${b.price.toInt()} DT',
                  style: const TextStyle(color: kGreen, fontSize: 12),
                ),
              ),
              Expanded(
                flex: 2,
                child: _ABadge(b.status.capitalize(), _statusColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSport(AdminBooking b) {
    return Row(
      children: [
        Icon(b.sport.icon, size: 12, color: b.sport.color),
        const SizedBox(width: 5),
        Text(
          b.sport.label,
          style: TextStyle(
            color: b.sport.color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REPORTS SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _ReportsSection extends StatefulWidget {
  final List<AdminPlayer> players;
  final List<AdminManager> managers;
  final List<AdminBooking> bookings;
  final List<AdminVenue> venues;
  const _ReportsSection({
    required this.players,
    required this.managers,
    required this.bookings,
    required this.venues,
  });

  @override
  State<_ReportsSection> createState() => _ReportsSectionState();
}

class _ReportsSectionState extends State<_ReportsSection> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AdminThemeColors>()!;
    final totalRevenue = widget.venues.fold(0.0, (s, v) => s + v.revenue);
    final sportCounts = <SportType, int>{};
    for (final b in widget.bookings) {
      sportCounts[b.sport] = (sportCounts[b.sport] ?? 0) + 1;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Platform Analytics',
            style: TextStyle(
              color: colors.text,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Overview of all platform activity and revenue',
            style: TextStyle(color: colors.textLight, fontSize: 13),
          ),
          const SizedBox(height: 24),
          _buildSummaryGrid(totalRevenue, colors),
          const SizedBox(height: 24),
          _buildChartsRow(sportCounts, colors),
          const SizedBox(height: 18),
          _buildTopManagersTable(colors),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(double totalRevenue, AdminThemeColors colors) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _ReportCard(
            title: 'Total Revenue',
            value: '${(totalRevenue / 1000).toStringAsFixed(1)}K DT',
            icon: Icons.payments_rounded,
            color: kGreen,
            sub: 'Across ${widget.venues.length} venues',
          ),
          const SizedBox(width: 16),
          _ReportCard(
            title: 'Total Bookings',
            value: '${widget.bookings.length}',
            icon: Icons.calendar_today_rounded,
            color: kPrimary,
            sub: 'All time',
          ),
          const SizedBox(width: 16),
          _ReportCard(
            title: 'Platform Users',
            value: '${widget.players.length + widget.managers.length}',
            icon: Icons.people_rounded,
            color: kPurple,
            sub:
                '${widget.players.length} players · ${widget.managers.length} managers',
          ),
          const SizedBox(width: 16),
          _ReportCard(
            title: 'Avg Revenue / Venue',
            value:
                '${(totalRevenue / widget.venues.length / 1000).toStringAsFixed(1)}K DT',
            icon: Icons.analytics_rounded,
            color: kAmber,
            sub: 'Per venue',
          ),
        ],
      ),
    );
  }

  Widget _buildChartsRow(
    Map<SportType, int> sportCounts,
    AdminThemeColors colors,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _SCard(
            title: 'Revenue by Venue',
            child: Column(
              children: widget.venues
                  .map(
                    (v) => _RevenueBar(
                      label: v.name,
                      value: v.revenue,
                      max: widget.venues.fold(
                        0.0,
                        (s, x) => x.revenue > s ? x.revenue : s,
                      ),
                      color: kPrimary,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          flex: 2,
          child: _SCard(
            title: 'Bookings by Sport',
            child: Column(
              children: SportType.values.map((s) {
                final count = sportCounts[s] ?? 0;
                final total = widget.bookings.isEmpty
                    ? 1
                    : widget.bookings.length;
                return _RevenueBar(
                  label: s.label,
                  value: count.toDouble(),
                  max: total.toDouble(),
                  color: s.color,
                  suffix: ' bookings',
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopManagersTable(AdminThemeColors colors) {
    return _SCard(
      title: 'Top Performing Managers',
      child: Column(
        children: [
          _TableHeader(
            cols: const [
              'Manager',
              'Venue',
              'City',
              'Courts',
              'Bookings/mo',
              'Revenue',
            ],
          ),
          ...widget.managers
              .sorted((a, b) => b.revenue.compareTo(a.revenue))
              .map(
                (m) => Container(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: colors.divider)),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            _Avatar(m.avatar, kPurple),
                            const SizedBox(width: 10),
                            Text(
                              m.name,
                              style: TextStyle(
                                color: colors.text,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          m.venueName,
                          style: TextStyle(
                            color: colors.textLight,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          m.venueCity,
                          style: TextStyle(
                            color: colors.textLight,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '${m.courts}',
                          style: TextStyle(color: colors.text, fontSize: 12),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${m.bookingsMonth}',
                          style: TextStyle(color: colors.text, fontSize: 12),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${(m.revenue / 1000).toStringAsFixed(1)}K DT',
                          style: const TextStyle(
                            color: kGreen,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
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

class _ReportCard extends StatelessWidget {
  final String title, value, sub;
  final IconData icon;
  final Color color;
  const _ReportCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AdminThemeColors>()!;

    return SizedBox(
      width: 220,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                color: colors.text,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              style: TextStyle(color: colors.textLight, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Text(
              sub,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RevenueBar extends StatelessWidget {
  final String label;
  final double value, max;
  final Color color;
  final String suffix;
  const _RevenueBar({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    this.suffix = ' DT',
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AdminThemeColors>()!;
    final pct = max == 0 ? 0.0 : (value / max).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${value.toInt()}$suffix',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 5,
              backgroundColor: colors.background,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SETTINGS SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _SettingsSection extends StatefulWidget {
  @override
  State<_SettingsSection> createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<_SettingsSection> {
  final _platformName = TextEditingController(text: 'Sporta');
  final _supportEmail = TextEditingController(text: 'admin@sporta.tn');
  final _commissionRate = TextEditingController(text: '8');
  bool _autoVerify = false;
  bool _allowSignup = true;
  bool _emailNotifs = true;
  bool _maintenanceMode = false;
  bool _saving = false;

  @override
  void dispose() {
    _platformName.dispose();
    _supportEmail.dispose();
    _commissionRate.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Settings saved',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: kPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AdminThemeColors>()!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildLeftColumn(colors)),
          const SizedBox(width: 20),
          Expanded(child: _buildRightColumn(colors)),
        ],
      ),
    );
  }

  Widget _buildLeftColumn(AdminThemeColors colors) {
    return Column(
      children: [
        _SettingsGroup(
          title: 'Platform Settings',
          icon: Icons.settings_rounded,
          children: [
            _SettingsField(
              'Platform Name',
              _platformName,
              Icons.sports_rounded,
            ),
            _SettingsField(
              'Support Email',
              _supportEmail,
              Icons.email_outlined,
            ),
            _SettingsField(
              'Commission Rate (%)',
              _commissionRate,
              Icons.percent_rounded,
              type: TextInputType.number,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _SettingsGroup(
          title: 'Danger Zone',
          icon: Icons.warning_amber_rounded,
          iconColor: kRed,
          children: [
            _SettingsToggle(
              'Maintenance Mode',
              'Disable public access to the platform',
              Icons.construction_rounded,
              _maintenanceMode,
              kRed,
              (v) => setState(() => _maintenanceMode = v),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRightColumn(AdminThemeColors colors) {
    return Column(
      children: [
        _SettingsGroup(
          title: 'Registration & Access',
          icon: Icons.lock_rounded,
          children: [
            _SettingsToggle(
              'Auto-verify Managers',
              'Skip manual verification',
              Icons.verified_rounded,
              _autoVerify,
              kPrimary,
              (v) => setState(() => _autoVerify = v),
            ),
            _SettingsToggle(
              'Allow New Signups',
              'Enable player registration',
              Icons.person_add_rounded,
              _allowSignup,
              kGreen,
              (v) => setState(() => _allowSignup = v),
            ),
            _SettingsToggle(
              'Email Notifications',
              'Send platform alerts',
              Icons.notifications_rounded,
              _emailNotifs,
              kAmber,
              (v) => setState(() => _emailNotifs = v),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _SettingsGroup(
          title: 'Admin Account',
          icon: Icons.admin_panel_settings_rounded,
          children: [
            _SettingsField(
              'Admin Name',
              TextEditingController(text: 'Super Admin'),
              Icons.person_rounded,
            ),
            _SettingsField(
              'Admin Email',
              TextEditingController(text: 'admin@sporta.tn'),
              Icons.email_outlined,
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _saving ? null : _save,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _saving
                ? [kPrimary.withOpacity(0.3), kPrimary.withOpacity(0.3)]
                : [kPrimary, kPrimary.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Center(
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.save_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Save Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? iconColor;
  final List<Widget> children;
  const _SettingsGroup({
    required this.title,
    required this.icon,
    required this.children,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AdminThemeColors>()!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: iconColor ?? kPrimary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: colors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final IconData icon;
  final TextInputType type;
  const _SettingsField(
    this.label,
    this.ctrl,
    this.icon, {
    this.type = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AdminThemeColors>()!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colors.textLight,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.divider),
            ),
            child: TextField(
              controller: ctrl,
              keyboardType: type,
              style: TextStyle(color: colors.text, fontSize: 13),
              decoration: InputDecoration(
                prefixIcon: Icon(icon, size: 15, color: colors.textLight),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  final String label, sub;
  final IconData icon;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChange;
  const _SettingsToggle(
    this.label,
    this.sub,
    this.icon,
    this.value,
    this.color,
    this.onChange,
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AdminThemeColors>()!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  sub,
                  style: TextStyle(color: colors.textLight, fontSize: 11),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChange,
            activeColor: color,
            inactiveThumbColor: colors.textLight,
            inactiveTrackColor: colors.divider,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DIALOGS
// ─────────────────────────────────────────────────────────────────────────────

// Add Manager Dialog
class _AddManagerDialog extends StatefulWidget {
  final ValueChanged<AdminManager> onAdd;
  const _AddManagerDialog({required this.onAdd});

  @override
  State<_AddManagerDialog> createState() => _AddManagerDialogState();
}

class _AddManagerDialogState extends State<_AddManagerDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _venue = TextEditingController();
  final _city = TextEditingController();
  final _courts = TextEditingController(text: '1');
  final Set<SportType> _sports = {SportType.football};
  bool _sending = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _venue.dispose();
    _city.dispose();
    _courts.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_sports.isEmpty) return;
    setState(() => _sending = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    widget.onAdd(
      AdminManager(
        id: 'mgr_${DateTime.now().millisecondsSinceEpoch}',
        name: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        venueName: _venue.text.trim(),
        venueCity: _city.text.trim(),
        avatar: _name.text
            .trim()
            .split(' ')
            .map((w) => w[0])
            .take(2)
            .join()
            .toUpperCase(),
        courts: int.tryParse(_courts.text) ?? 1,
        bookingsMonth: 0,
        revenue: 0,
        isActive: true,
        isVerified: false,
        joined: DateTime.now(),
        sports: _sports.toList(),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AdminThemeColors>()!;

    return Dialog(
      backgroundColor: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: colors.divider),
      ),
      child: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(colors),
                const SizedBox(height: 24),
                Divider(color: colors.divider),
                const SizedBox(height: 20),
                _DlgSLabel('Personal Information'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _DlgField(
                        'Full Name',
                        _name,
                        Icons.person_outlined,
                        required: true,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _DlgField('Phone', _phone, Icons.phone_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _DlgField(
                  'Email',
                  _email,
                  Icons.email_outlined,
                  required: true,
                  type: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                _DlgSLabel('Venue Information'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _DlgField(
                        'Venue Name',
                        _venue,
                        Icons.stadium_outlined,
                        required: true,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _DlgField(
                        'City',
                        _city,
                        Icons.location_on_outlined,
                        required: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _DlgField(
                  'Number of Courts',
                  _courts,
                  Icons.sports_tennis_rounded,
                  type: TextInputType.number,
                ),
                const SizedBox(height: 20),
                _DlgSLabel('Sports Offered'),
                const SizedBox(height: 10),
                _buildSportSelector(),
                const SizedBox(height: 28),
                _buildActions(colors),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AdminThemeColors colors) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: kPrimary.withOpacity(0.3)),
          ),
          child: const Icon(
            Icons.person_add_rounded,
            color: kPrimary,
            size: 19,
          ),
        ),
        const SizedBox(width: 13),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add New Manager',
                style: TextStyle(
                  color: kTextDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Create a manager account and assign their venue',
                style: TextStyle(color: kTextMid, fontSize: 12),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.close_rounded, size: 16, color: colors.textLight),
          ),
        ),
      ],
    );
  }

  Widget _buildSportSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: SportType.values.map((s) {
        final sel = _sports.contains(s);
        return GestureDetector(
          onTap: () => setState(() => sel ? _sports.remove(s) : _sports.add(s)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: sel ? s.color.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: sel ? s.color.withOpacity(0.5) : Colors.grey.shade300,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(s.icon, size: 14, color: sel ? s.color : Colors.grey),
                const SizedBox(width: 6),
                Text(
                  s.label,
                  style: TextStyle(
                    color: sel ? s.color : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActions(AdminThemeColors colors) {
    return Row(
      children: [
        Expanded(
          child: _DlgBtn(
            'Cancel',
            colors.textLight,
            outlined: true,
            onTap: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DlgBtn(
            _sending ? 'Creating...' : 'Create Manager',
            kPrimary,
            icon: Icons.add_rounded,
            onTap: _sending ? null : _submit,
          ),
        ),
      ],
    );
  }
}

// Player Detail Dialog
class _PlayerDetailDialog extends StatelessWidget {
  final AdminPlayer player;
  const _PlayerDetailDialog({required this.player});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AdminThemeColors>()!;
    final p = player;

    return Dialog(
      backgroundColor: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: colors.divider),
      ),
      child: SizedBox(
        width: 460,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, p, colors),
              const SizedBox(height: 20),
              Divider(color: colors.divider),
              const SizedBox(height: 16),
              _buildStats(p),
              const SizedBox(height: 16),
              _InfoRow(Icons.phone_outlined, 'Phone', p.phone),
              _InfoRow(
                Icons.calendar_today_outlined,
                'Joined',
                _formatDate(p.joined),
              ),
              const SizedBox(height: 12),
              _DlgSLabel('Favourite Sports'),
              const SizedBox(height: 8),
              _buildSportBadges(p),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AdminPlayer p,
    AdminThemeColors colors,
  ) {
    return Row(
      children: [
        _Avatar(p.avatar, kPrimary, size: 52),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    p.name,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (p.isVerified) ...[
                    const SizedBox(width: 7),
                    Icon(Icons.verified_rounded, size: 16, color: kPrimary),
                  ],
                ],
              ),
              Text(
                p.email,
                style: TextStyle(color: colors.textLight, fontSize: 13),
              ),
            ],
          ),
        ),
        _ABadge(p.isActive ? 'Active' : 'Inactive', p.isActive ? kGreen : kRed),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.close_rounded, size: 16, color: colors.textLight),
          ),
        ),
      ],
    );
  }

  Widget _buildStats(AdminPlayer p) {
    return Row(
      children: [
        _DetailStat(
          'Bookings',
          '${p.bookings}',
          Icons.calendar_today_rounded,
          kPrimary,
        ),
        _DetailStat('Matches', '${p.matches}', Icons.sports_rounded, kPurple),
        _DetailStat(
          'Total Spent',
          '${p.spent.toInt()} DT',
          Icons.payments_rounded,
          kGreen,
        ),
      ],
    );
  }

  Widget _buildSportBadges(AdminPlayer p) {
    return Wrap(
      spacing: 8,
      children: p.sports
          .map(
            (s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: s.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: s.color.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(s.icon, size: 13, color: s.color),
                  const SizedBox(width: 5),
                  Text(
                    s.label,
                    style: TextStyle(
                      color: s.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

// Manager Detail Dialog
class _ManagerDetailDialog extends StatelessWidget {
  final AdminManager manager;
  const _ManagerDetailDialog({required this.manager});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AdminThemeColors>()!;
    final m = manager;

    return Dialog(
      backgroundColor: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: colors.divider),
      ),
      child: SizedBox(
        width: 480,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, m, colors),
              const SizedBox(height: 20),
              Divider(color: colors.divider),
              const SizedBox(height: 16),
              _buildStats(m),
              const SizedBox(height: 16),
              _InfoRow(Icons.stadium_rounded, 'Venue', m.venueName),
              _InfoRow(Icons.location_on_outlined, 'City', m.venueCity),
              _InfoRow(Icons.phone_outlined, 'Phone', m.phone),
              _InfoRow(
                Icons.calendar_today_outlined,
                'Joined',
                _formatDate(m.joined),
              ),
              const SizedBox(height: 12),
              _DlgSLabel('Sports Offered'),
              const SizedBox(height: 8),
              _buildSportBadges(m),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AdminManager m,
    AdminThemeColors colors,
  ) {
    return Row(
      children: [
        _Avatar(m.avatar, kPurple, size: 52),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    m.name,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (m.isVerified) ...[
                    const SizedBox(width: 7),
                    Icon(Icons.verified_rounded, size: 16, color: kPrimary),
                  ],
                  if (!m.isVerified) ...[
                    const SizedBox(width: 7),
                    _ABadge('Unverified', kAmber),
                  ],
                ],
              ),
              Text(
                m.email,
                style: TextStyle(color: colors.textLight, fontSize: 13),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.close_rounded, size: 16, color: colors.textLight),
          ),
        ),
      ],
    );
  }

  Widget _buildStats(AdminManager m) {
    return Row(
      children: [
        _DetailStat(
          'Courts',
          '${m.courts}',
          Icons.sports_tennis_rounded,
          kPrimary,
        ),
        _DetailStat(
          'Bookings/mo',
          '${m.bookingsMonth}',
          Icons.calendar_today_rounded,
          kPurple,
        ),
        _DetailStat(
          'Revenue',
          '${(m.revenue / 1000).toStringAsFixed(1)}K DT',
          Icons.payments_rounded,
          kGreen,
        ),
      ],
    );
  }

  Widget _buildSportBadges(AdminManager m) {
    return Wrap(
      spacing: 8,
      children: m.sports
          .map(
            (s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: s.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: s.color.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(s.icon, size: 13, color: s.color),
                  const SizedBox(width: 5),
                  Text(
                    s.label,
                    style: TextStyle(
                      color: s.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

// Confirm Dialog
class _ConfirmDialog extends StatelessWidget {
  final String title, body;
  final Color color;
  final VoidCallback onConfirm;
  const _ConfirmDialog({
    required this.title,
    required this.body,
    required this.color,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AdminThemeColors>()!;

    return Dialog(
      backgroundColor: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.warning_rounded, color: color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                body,
                style: TextStyle(
                  color: colors.textLight,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _DlgBtn(
                      'Cancel',
                      colors.textLight,
                      outlined: true,
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: _DlgBtn('Confirm', color, onTap: onConfirm)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLACEHOLDER SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _PlaceholderSection extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  const _PlaceholderSection({
    required this.icon,
    required this.label,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AdminThemeColors>()!;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colors.background,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: colors.textLight),
          ),
          const SizedBox(height: 18),
          Text(
            label,
            style: TextStyle(
              color: colors.text,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(sub, style: TextStyle(color: colors.textLight, fontSize: 14)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED MICRO WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String initials;
  final Color color;
  final double size;
  const _Avatar(this.initials, this.color, {this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: color,
            fontSize: size * 0.33,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ABadge extends StatelessWidget {
  final String label;
  final Color color;
  const _ABadge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _MiniStat(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AdminThemeColors>()!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: colors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: TextStyle(color: colors.textLight, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _AdminBtn({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_AdminBtn> createState() => _AdminBtnState();
}

class _AdminBtnState extends State<_AdminBtn> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _hover
                  ? [kPrimary, kPrimary.withOpacity(0.8)]
                  : [kPrimary, kPrimary],
            ),
            borderRadius: BorderRadius.circular(11),
            boxShadow: _hover
                ? [
                    BoxShadow(
                      color: kPrimary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 15, color: Colors.white),
              const SizedBox(width: 7),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(this.icon, this.color, this.onTap);

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AdminThemeColors>()!;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _hover ? widget.color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(
            widget.icon,
            size: 15,
            color: _hover ? widget.color : colors.textLight,
          ),
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final List<String> cols;
  const _TableHeader({required this.cols});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AdminThemeColors>()!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(
          top: BorderSide(color: colors.divider),
          bottom: BorderSide(color: colors.divider),
        ),
      ),
      child: Row(
        children: cols.asMap().entries.map((e) {
          final flex = e.key == 0 ? 3 : (e.key == cols.length - 1 ? 2 : 2);
          return Expanded(
            flex: flex,
            child: Text(
              e.value,
              style: TextStyle(
                color: colors.textLight,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TableSearch extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _TableSearch({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AdminThemeColors>()!;

    return SizedBox(
      width: 200,
      height: 34,
      child: Container(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: colors.divider),
        ),
        child: Row(
          children: [
            const SizedBox(width: 10),
            const Icon(Icons.search_rounded, size: 14, color: kTextLight),
            const SizedBox(width: 7),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: TextStyle(color: colors.text, fontSize: 12),
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: kTextLight, fontSize: 12),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterPill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AdminThemeColors>()!;

    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: active ? kPrimary.withOpacity(0.1) : colors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active ? kPrimary.withOpacity(0.3) : colors.divider,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? kPrimary : colors.textLight,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyTable extends StatelessWidget {
  final String message;
  const _EmptyTable(this.message);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AdminThemeColors>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_rounded, size: 36, color: colors.textLight),
            const SizedBox(height: 10),
            Text(
              message,
              style: TextStyle(color: colors.textLight, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// Dialog helpers
class _DlgSLabel extends StatelessWidget {
  final String t;
  const _DlgSLabel(this.t);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AdminThemeColors>()!;

    return Text(
      t,
      style: TextStyle(
        color: colors.textLight,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _DlgField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final IconData icon;
  final bool required;
  final TextInputType type;
  const _DlgField(
    this.label,
    this.ctrl,
    this.icon, {
    this.required = false,
    this.type = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AdminThemeColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DlgSLabel(label),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.divider),
          ),
          child: TextFormField(
            controller: ctrl,
            keyboardType: type,
            style: TextStyle(color: colors.text, fontSize: 13),
            validator: required
                ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
                : null,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 15, color: colors.textLight),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _DlgBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool outlined;
  final IconData? icon;
  const _DlgBtn(
    this.label,
    this.color, {
    this.onTap,
    this.outlined = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AdminThemeColors>()!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: outlined
            ? BoxDecoration(
                border: Border.all(color: colors.divider),
                borderRadius: BorderRadius.circular(11),
              )
            : BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: outlined ? colors.textLight : Colors.white,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: outlined ? colors.textLight : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _DetailStat(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AdminThemeColors>()!;

    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(height: 7),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: colors.textLight, fontSize: 10)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AdminThemeColors>()!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: colors.textLight),
          ),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: TextStyle(color: colors.textLight, fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              color: colors.text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────
String _formatDate(DateTime d) {
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
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

extension _ListSorted<T> on List<T> {
  List<T> sorted(int Function(T a, T b) compare) => [...this]..sort(compare);
}

extension _StringExt on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
