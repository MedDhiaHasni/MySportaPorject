// lib/Views/Admin/admin_dashboard.dart
// Fully wired admin dashboard:
//   - Add / Edit / Delete players, managers, workers
//   - Block / Unblock any user
//   - Admin profile view + update
//   - Logout
//   - Real data from backend
import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Core/Constants/api_constants.dart';
import 'package:sporta/Models/app_enums.dart';
import 'package:sporta/Services/admin_auth_service.dart';
import 'package:sporta/Views/Admin/admin_login.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────
enum AdminSection { overview, players, managers, workers, complexes, bookings, settings }

class AdminPlayer {
  final String id, name, email, phone;
  final int bookings;
  final double spent;
  final bool isActive;
  final DateTime joined;
  const AdminPlayer({required this.id, required this.name, required this.email, required this.phone, required this.bookings, required this.spent, required this.isActive, required this.joined});
  AdminPlayer copyWith({bool? isActive}) => AdminPlayer(id: id, name: name, email: email, phone: phone, bookings: bookings, spent: spent, isActive: isActive ?? this.isActive, joined: joined);
}

class AdminManager {
  final String id, name, email, phone;
  final List<dynamic> complexes;
  final int totalCourts, totalBookings;
  final double revenue;
  final bool isActive;
  final DateTime joined;
  const AdminManager({required this.id, required this.name, required this.email, required this.phone, required this.complexes, required this.totalCourts, required this.totalBookings, required this.revenue, required this.isActive, required this.joined});
  AdminManager copyWith({bool? isActive, double? revenue, int? totalCourts, int? totalBookings}) => AdminManager(id: id, name: name, email: email, phone: phone, complexes: complexes, totalCourts: totalCourts ?? this.totalCourts, totalBookings: totalBookings ?? this.totalBookings, revenue: revenue ?? this.revenue, isActive: isActive ?? this.isActive, joined: joined);
}

class AdminWorker {
  final String id, name, email, phone, managerId, managerName;
  final List<dynamic> courts;
  final bool isActive;
  final DateTime joined;
  const AdminWorker({required this.id, required this.name, required this.email, required this.phone, required this.managerId, required this.managerName, required this.courts, required this.isActive, required this.joined});
  AdminWorker copyWith({bool? isActive}) => AdminWorker(id: id, name: name, email: email, phone: phone, managerId: managerId, managerName: managerName, courts: courts, isActive: isActive ?? this.isActive, joined: joined);
}

class AdminComplex {
  final String id, name, city, manager, managerId;
  final int courts, bookingsMonth;
  final double revenue, rating;
  final bool isActive;
  final List<SportType> sports;
  const AdminComplex({required this.id, required this.name, required this.city, required this.manager, required this.managerId, required this.courts, required this.bookingsMonth, required this.revenue, required this.rating, required this.isActive, required this.sports});
}

class AdminBooking {
  final String id, player, complex, court, time, date, status;
  final SportType sport;
  final double price;
  const AdminBooking({required this.id, required this.player, required this.complex, required this.court, required this.time, required this.date, required this.status, required this.sport, required this.price});
}

class MonthlyRevenue {
  final String month;
  final double amount;
  const MonthlyRevenue({required this.month, required this.amount});
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────
String _initials(String name) {
  final p = name.trim().split(' ');
  if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
  return name.isNotEmpty ? name[0].toUpperCase() : 'U';
}

String _fmtDate(DateTime d) {
  const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}

// ─────────────────────────────────────────────────────────────────────────────
// FIX 1: Robust sport parser — handles plain strings, objects, and any casing
// ─────────────────────────────────────────────────────────────────────────────
SportType? _parseSport(dynamic raw) {
  // Extract the string value whether raw is a String or a Map {id, name}
  String s;
  if (raw is Map) {
    s = (raw['name'] ?? raw['sport'] ?? raw['type'] ?? '').toString();
  } else {
    s = raw.toString();
  }

  switch (s.trim().toLowerCase()) {
    case 'football':   return SportType.football;
    case 'tennis':     return SportType.tennis;
    case 'padel':      return SportType.padel;
    case 'basketball': return SportType.basketball;
    default:           return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FIX 2: Robust sports list extractor — handles all backend formats
// ─────────────────────────────────────────────────────────────────────────────
List<SportType> _parseSportsList(dynamic raw) {
  if (raw == null) return [];

  List<dynamic> list;

  if (raw is List) {
    list = raw;
  } else if (raw is String) {
    // Sometimes a JSON array is accidentally returned as a string
    try {
      final decoded = json.decode(raw);
      if (decoded is List) {
        list = decoded;
      } else {
        // Single sport as a plain string e.g. "football"
        final sp = _parseSport(raw);
        return sp != null ? [sp] : [];
      }
    } catch (_) {
      final sp = _parseSport(raw);
      return sp != null ? [sp] : [];
    }
  } else {
    return [];
  }

  final result = <SportType>[];
  for (final item in list) {
    final sp = _parseSport(item);
    if (sp != null) result.add(sp);
  }
  return result;
}

extension _Cap on String {
  String get cap => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

// ─────────────────────────────────────────────────────────────────────────────
// THEME
// ─────────────────────────────────────────────────────────────────────────────
class AdminTheme extends ThemeExtension<AdminTheme> {
  final Color bg, surface, card, border, text, mid, light, hover, divider;
  const AdminTheme({
    required this.bg,
    required this.surface,
    required this.card,
    required this.border,
    required this.text,
    required this.mid,
    required this.light,
    required this.hover,
    required this.divider,
  });

  static const AdminTheme lightTheme = AdminTheme(
    bg: Color(0xFFF2F4F7),
    surface: Colors.white,
    card: Colors.white,
    border: Color(0xFFE5E5E5),
    text: Color(0xFF0A0E1A),
    mid: Color(0xFF64748B),
    light: Color(0xFFB0B7C3),
    hover: Color(0xFFF5F5F5),
    divider: Color(0xFFEEEEEE),
  );

  @override
  ThemeExtension<AdminTheme> copyWith({
    Color? bg, Color? surface, Color? card, Color? border,
    Color? text, Color? mid, Color? light, Color? hover, Color? divider,
  }) {
    return AdminTheme(
      bg: bg ?? this.bg, surface: surface ?? this.surface, card: card ?? this.card,
      border: border ?? this.border, text: text ?? this.text, mid: mid ?? this.mid,
      light: light ?? this.light, hover: hover ?? this.hover, divider: divider ?? this.divider,
    );
  }

  @override
  ThemeExtension<AdminTheme> lerp(covariant ThemeExtension<AdminTheme>? other, double t) => this;
}

// ─────────────────────────────────────────────────────────────────────────────
// DASHBOARD ROOT
// ─────────────────────────────────────────────────────────────────────────────
class AdminDashboard extends StatefulWidget {
  final String adminToken;
  const AdminDashboard({super.key, required this.adminToken, required Null Function() onLogout});
  @override State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  AdminSection _section = AdminSection.overview;
  bool _sidebarCollapsed = false;

  List<AdminPlayer> _players = [];
  List<AdminManager> _managers = [];
  List<AdminWorker> _workers = [];
  List<AdminComplex> _complexes = [];
  List<AdminBooking> _bookings = [];

  bool _loadingPlayers = false;
  bool _loadingManagers = false;
  bool _loadingWorkers = false;
  bool _loadingComplexes = false;
  bool _loadingBookings = false;

  String? _errPlayers, _errManagers, _errWorkers, _errComplexes, _errBookings;

  List<MonthlyRevenue> _monthlyRevenues = [];
  Map<SportType, int> _bookingsBySport = {};
  double _totalRevenue = 0;

  String _adminUsername = 'Admin';
  String _adminEmail = '';

  final _smKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _loadAll();
    _loadAdminProfile();
  }

  // ── Loaders ───────────────────────────────────────────────────────────────

  Future<void> _loadAll() async {
    await Future.wait([_loadPlayers(), _loadManagers(), _loadWorkers(), _loadComplexes(), _loadBookings()]);
    _calcAnalytics();
  }

  Future<void> _loadAdminProfile() async {
    try {
      final me = await AdminAuthService.getMe(widget.adminToken);
      final user = me['user'] ?? me;
      setState(() {
        _adminUsername = user['username']?.toString() ?? 'Admin';
        _adminEmail = user['email']?.toString() ?? '';
      });
    } catch (_) {}
  }

  Future<void> _loadPlayers() async {
    setState(() { _loadingPlayers = true; _errPlayers = null; });
    try {
      final raw = await AdminAuthService.getPlayers(widget.adminToken);
      setState(() {
        _players = raw.map((j) {
          final m = j as Map<String, dynamic>;
          return AdminPlayer(
            id: m['id'].toString(),
            name: m['username']?.toString() ?? 'Unknown',
            email: m['email']?.toString() ?? '',
            phone: m['phone']?.toString() ?? '',
            bookings: (m['bookings'] as num?)?.toInt() ?? 0,
            spent: (m['totalSpent'] as num?)?.toDouble() ?? 0,
            isActive: m['isActive'] ?? true,
            joined: m['createdAt'] != null
                ? DateTime.tryParse(m['createdAt'].toString()) ?? DateTime.now()
                : DateTime.now(),
          );
        }).toList();
        _loadingPlayers = false;
      });
    } catch (e) {
      setState(() {
        _errPlayers = e.toString().replaceAll('Exception: ', '');
        _loadingPlayers = false;
      });
    }
  }

  Future<void> _loadManagers() async {
    setState(() { _loadingManagers = true; _errManagers = null; });
    try {
      final raw = await AdminAuthService.getManagers(widget.adminToken);
      setState(() {
        _managers = raw.map((j) {
          final m = j as Map<String, dynamic>;
          return AdminManager(
            id: m['id'].toString(),
            name: m['username']?.toString() ?? 'Unknown',
            email: m['email']?.toString() ?? '',
            phone: m['phone']?.toString() ?? '',
            complexes: (m['complexes'] as List?) ?? [],
            totalCourts: (m['totalCourts'] as num?)?.toInt() ?? 0,
            totalBookings: (m['totalBookings'] as num?)?.toInt() ?? 0,
            revenue: (m['totalRevenue'] as num?)?.toDouble() ?? 0,
            isActive: m['isActive'] ?? true,
            joined: m['createdAt'] != null
                ? DateTime.tryParse(m['createdAt'].toString()) ?? DateTime.now()
                : DateTime.now(),
          );
        }).toList();
        _loadingManagers = false;
      });
    } catch (e) {
      setState(() {
        _errManagers = e.toString().replaceAll('Exception: ', '');
        _loadingManagers = false;
      });
    }
  }

  Future<void> _loadWorkers() async {
    setState(() { _loadingWorkers = true; _errWorkers = null; });
    try {
      final raw = await AdminAuthService.getWorkers(widget.adminToken);
      setState(() {
        _workers = raw.map((j) {
          final m = j as Map<String, dynamic>;
          return AdminWorker(
            id: m['id'].toString(),
            name: m['username']?.toString() ?? m['nom']?.toString() ?? 'Unknown',
            email: m['email']?.toString() ?? '',
            phone: m['phone']?.toString() ?? '',
            managerId: m['managerId']?.toString() ?? '',
            managerName: m['managerName']?.toString() ?? 'Unknown',
            courts: (m['courts'] as List?) ?? [],
            isActive: m['isActive'] ?? true,
            joined: m['joinedAt'] != null
                ? DateTime.tryParse(m['joinedAt'].toString()) ?? DateTime.now()
                : DateTime.now(),
          );
        }).toList();
        _loadingWorkers = false;
      });
    } catch (e) {
      setState(() {
        _errWorkers = e.toString().replaceAll('Exception: ', '');
        _loadingWorkers = false;
      });
    }
  }

  Future<void> _loadComplexes() async {
    setState(() { _loadingComplexes = true; _errComplexes = null; });
    try {
      final r = await http.get(
        Uri.parse(ApiConstants.publicVenues), // API endpoint remains the same but we treat response as complexes
        headers: {'Authorization': 'Bearer ${widget.adminToken}'},
      );
      if (r.statusCode == 200) {
        final list = json.decode(r.body) as List<dynamic>;
        setState(() {
          _complexes = list.map((j) {
            final m = j as Map<String, dynamic>;

            // ─────────────────────────────────────────────────────────────
            // FIX 3: Use _parseSportsList for robust sports extraction.
            // Handles: null, [], ["football"], ["Football"], [{id,name}], "football"
            // ─────────────────────────────────────────────────────────────
            final sports = _parseSportsList(m['sports']);

            final mgr = m['manager'];
            return AdminComplex(
              id: m['id'].toString(),
              name: m['name']?.toString() ?? '',
              city: m['location']?.toString().split(',').first ?? '',
              manager: mgr is Map ? (mgr['username']?.toString() ?? '') : '',
              managerId: mgr is Map ? (mgr['id']?.toString() ?? '') : '',
              courts: (m['courts'] as List?)?.length ?? 0,
              bookingsMonth: 0,
              revenue: 0,
              rating: (m['avg_rating'] as num?)?.toDouble() ?? 0,
              isActive: m['isActive'] ?? true,
              sports: sports,
            );
          }).toList();
          _loadingComplexes = false;
        });
      } else {
        throw Exception('Failed to load complexes');
      }
    } catch (e) {
      setState(() {
        _errComplexes = e.toString().replaceAll('Exception: ', '');
        _loadingComplexes = false;
      });
    }
  }

  Future<void> _loadBookings() async {
    setState(() { _loadingBookings = true; _errBookings = null; });
    try {
      final r = await http.get(
        Uri.parse('${ApiConstants.reservations}?populate[court][populate][complex]=*&populate[player][populate][player]=*&populate[time_slot]=*'),
        headers: {'Authorization': 'Bearer ${widget.adminToken}'},
      );
      if (r.statusCode == 200) {
        final data = json.decode(r.body);
        final list = (data is Map ? data['data'] : data) as List<dynamic>? ?? [];
        setState(() {
          _bookings = list.map((item) {
            final raw = item is Map && item['attributes'] != null
                ? Map<String, dynamic>.from(item['attributes'] as Map)['id'] = item['id']
                : Map<String, dynamic>.from(item as Map);
            final court = _nested(raw, 'court');
            final complex = _nested(court, 'complex');
            final player = _nested(raw, 'player');
            final user = _nested(player, 'player');
            final ts = _nested(raw, 'time_slot');
            return AdminBooking(
              id: raw['id']?.toString() ?? '',
              player: user['username']?.toString() ?? player['nom']?.toString() ?? 'Unknown',
              complex: complex['name']?.toString() ?? '',
              court: court['name']?.toString() ?? '',
              time: '${ts['startTime'] ?? raw['start_time'] ?? '--'} – ${ts['endTime'] ?? raw['end_time'] ?? '--'}',
              date: raw['booking_date_play']?.toString().split('T')[0] ?? '',
              status: raw['booking_status']?.toString() ?? 'pending',
              sport: _parseSport(court['sport']?.toString() ?? '') ?? SportType.football,
              price: (raw['total_price'] as num?)?.toDouble() ?? 0,
            );
          }).toList();
          _loadingBookings = false;
        });
      } else {
        throw Exception('Failed to load bookings');
      }
    } catch (e) {
      setState(() {
        _errBookings = e.toString().replaceAll('Exception: ', '');
        _loadingBookings = false;
      });
    }
  }

  Map<String, dynamic> _nested(Map<String, dynamic>? m, String key) {
    if (m == null) return {};
    final v = m[key];
    if (v is Map) {
      final d = v['data'] ?? v;
      if (d is Map) return (d['attributes'] ?? d) as Map<String, dynamic>;
    }
    return {};
  }

  void _calcAnalytics() {
    _totalRevenue = _bookings.fold(0.0, (s, b) => s + b.price);
    _bookingsBySport = {};
    for (final b in _bookings) {
      _bookingsBySport[b.sport] = (_bookingsBySport[b.sport] ?? 0) + 1;
    }
    final monthly = <String, double>{};
    for (final b in _bookings) {
      if (b.date.length >= 7) {
        final mo = b.date.substring(0, 7);
        monthly[mo] = (monthly[mo] ?? 0) + b.price;
      }
    }
    final keys = monthly.keys.toList()..sort();
    _monthlyRevenues = keys.map((k) {
      try {
        return MonthlyRevenue(
          month: DateFormat('MMM yy').format(DateTime.parse('$k-01')),
          amount: monthly[k]!,
        );
      } catch (_) {
        return MonthlyRevenue(month: k, amount: monthly[k]!);
      }
    }).toList();
    if (mounted) setState(() {});
  }

  // ── Snackbar ──────────────────────────────────────────────────────────────

  void _snack(String msg, Color color) {
    _smKey.currentState?.showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  // ── Actions — Players ─────────────────────────────────────────────────────

  Future<void> _createPlayer(Map<String, String> data) async {
    try {
      await AdminAuthService.createPlayer(
        adminToken: widget.adminToken,
        username: data['username']!,
        email: data['email']!,
        password: data['password']!,
        phone: data['phone'] ?? '',
      );
      _snack('Player created!', kGreen);
      await _loadPlayers();
    } catch (e) {
      _snack(e.toString().replaceAll('Exception: ', ''), kRed);
    }
  }

  Future<void> _updatePlayer(String id, Map<String, String> data) async {
    try {
      await AdminAuthService.updatePlayer(
        adminToken: widget.adminToken,
        playerId: id,
        data: data,
      );
      _snack('Player updated!', kGreen);
      await _loadPlayers();
    } catch (e) {
      _snack(e.toString().replaceAll('Exception: ', ''), kRed);
    }
  }

  Future<void> _deletePlayer(String id) async {
    final ok = await _confirmDialog('Delete Player', 'This will permanently delete the player. Continue?');
    if (!ok) return;
    try {
      await AdminAuthService.deletePlayer(adminToken: widget.adminToken, playerId: id);
      _snack('Player deleted.', kGreen);
      await _loadPlayers();
    } catch (e) {
      _snack(e.toString().replaceAll('Exception: ', ''), kRed);
    }
  }

  // ── Actions — Managers ────────────────────────────────────────────────────

  Future<void> _createManager(Map<String, String> data) async {
    try {
      await AdminAuthService.createManager(
        adminToken: widget.adminToken,
        username: data['username']!,
        email: data['email']!,
        password: data['password']!,
        phone: data['phone'] ?? '',
      );
      _snack('Manager created!', kGreen);
      await _loadManagers();
    } catch (e) {
      _snack(e.toString().replaceAll('Exception: ', ''), kRed);
    }
  }

  Future<void> _updateManager(String id, Map<String, String> data) async {
    try {
      await AdminAuthService.updateManager(
        adminToken: widget.adminToken,
        managerId: id,
        data: data,
      );
      _snack('Manager updated!', kGreen);
      await _loadManagers();
    } catch (e) {
      _snack(e.toString().replaceAll('Exception: ', ''), kRed);
    }
  }

  Future<void> _deleteManager(String id) async {
    final ok = await _confirmDialog('Delete Manager', 'This will permanently delete the manager and their profile. Continue?');
    if (!ok) return;
    try {
      await AdminAuthService.deleteManager(adminToken: widget.adminToken, managerId: id);
      _snack('Manager deleted.', kGreen);
      await _loadManagers();
    } catch (e) {
      _snack(e.toString().replaceAll('Exception: ', ''), kRed);
    }
  }

  // ── Actions — Workers ─────────────────────────────────────────────────────

  Future<void> _createWorker(Map<String, String> data) async {
    try {
      await AdminAuthService.createWorker(
        adminToken: widget.adminToken,
        username: data['username']!,
        email: data['email']!,
        password: data['password']!,
        phone: data['phone'] ?? '',
        nom: data['nom'] ?? data['username']!,
        managerId: data['managerId']!,
      );
      _snack('Worker created!', kGreen);
      await _loadWorkers();
    } catch (e) {
      _snack(e.toString().replaceAll('Exception: ', ''), kRed);
    }
  }

  Future<void> _updateWorker(String id, Map<String, String> data) async {
    try {
      await AdminAuthService.updateWorker(
        adminToken: widget.adminToken,
        workerId: id,
        data: data,
      );
      _snack('Worker updated!', kGreen);
      await _loadWorkers();
    } catch (e) {
      _snack(e.toString().replaceAll('Exception: ', ''), kRed);
    }
  }

  Future<void> _deleteWorker(String id) async {
    final ok = await _confirmDialog('Delete Worker', 'This will permanently delete the worker. Continue?');
    if (!ok) return;
    try {
      await AdminAuthService.deleteWorker(adminToken: widget.adminToken, workerId: id);
      _snack('Worker deleted.', kGreen);
      await _loadWorkers();
    } catch (e) {
      _snack(e.toString().replaceAll('Exception: ', ''), kRed);
    }
  }

  // ── Toggle status ─────────────────────────────────────────────────────────

  Future<void> _toggleStatus(String userId, String label) async {
    try {
      await AdminAuthService.toggleUserStatus(token: widget.adminToken, userId: userId);
      _snack('$label status updated.', kGreen);
      await _loadAll();
    } catch (e) {
      _snack(e.toString().replaceAll('Exception: ', ''), kRed);
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> _logout() async {
    await const FlutterSecureStorage().deleteAll();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AdminLoginPage()),
        (_) => false,
      );
    }
  }

  // ── Confirm dialog ────────────────────────────────────────────────────────

  Future<bool> _confirmDialog(String title, String body) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ConfirmDialog(title: title, body: body),
    );
    return ok == true;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _smKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(extensions: [AdminTheme.lightTheme]),
      home: Scaffold(
        backgroundColor: AdminTheme.lightTheme.bg,
        body: Row(
          children: [
            _Sidebar(
              current: _section,
              collapsed: _sidebarCollapsed,
              onSelect: (s) => setState(() => _section = s),
              onToggle: () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
            ),
            Expanded(
              child: Column(
                children: [
                  _TopBar(
                    section: _section,
                    adminName: _adminUsername,
                    onLogout: () async {
                      final ok = await _confirmDialog('Logout', 'Are you sure you want to log out?');
                      if (ok) _logout();
                    },
                    onSettings: () => setState(() => _section = AdminSection.settings),
                  ),
                  Expanded(child: _buildSection()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection() {
    switch (_section) {
      case AdminSection.overview:
        return _OverviewSection(
          players: _players,
          managers: _managers,
          workers: _workers,
          bookings: _bookings,
          complexes: _complexes,
          monthlyRevenues: _monthlyRevenues,
          bookingsBySport: _bookingsBySport,
          totalRevenue: _totalRevenue,
          onNavigate: (s) => setState(() => _section = s),
        );
      case AdminSection.players:
        return _PlayersSection(
          players: _players,
          loading: _loadingPlayers,
          error: _errPlayers,
          onAdd: _createPlayer,
          onEdit: _updatePlayer,
          onDelete: _deletePlayer,
          onToggle: (id) => _toggleStatus(id, 'Player'),
          onRefresh: _loadPlayers,
        );
      case AdminSection.managers:
        return _ManagersSection(
          managers: _managers,
          loading: _loadingManagers,
          error: _errManagers,
          onAdd: _createManager,
          onEdit: _updateManager,
          onDelete: _deleteManager,
          onToggle: (id) => _toggleStatus(id, 'Manager'),
          onRefresh: _loadManagers,
        );
      case AdminSection.workers:
        return _WorkersSection(
          workers: _workers,
          managers: _managers,
          loading: _loadingWorkers,
          error: _errWorkers,
          onAdd: _createWorker,
          onEdit: _updateWorker,
          onDelete: _deleteWorker,
          onToggle: (id) => _toggleStatus(id, 'Worker'),
          onRefresh: _loadWorkers,
        );
      case AdminSection.complexes:
        return _ComplexesSection(
          complexes: _complexes,
          loading: _loadingComplexes,
          error: _errComplexes,
          onRefresh: _loadComplexes,
        );
      case AdminSection.bookings:
        return _BookingsSection(
          bookings: _bookings,
          loading: _loadingBookings,
          error: _errBookings,
          onRefresh: _loadBookings,
        );
      case AdminSection.settings:
        return _SettingsSection(
          adminName: _adminUsername,
          adminEmail: _adminEmail,
          token: widget.adminToken,
          onSaved: (name, email, pw) async {
            try {
              await AdminAuthService.updateAdminProfile(
                token: widget.adminToken,
                username: name.isEmpty ? null : name,
                email: email.isEmpty ? null : email,
                password: pw.isEmpty ? null : pw,
              );
              _snack('Profile updated!', kGreen);
              await _loadAdminProfile();
            } catch (e) {
              _snack(e.toString().replaceAll('Exception: ', ''), kRed);
            }
          },
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SIDEBAR
// ─────────────────────────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
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

  static const _items = [
    (AdminSection.overview, Icons.grid_view_rounded, 'Report'),
    (AdminSection.players, Icons.person_rounded, 'Players'),
    (AdminSection.managers, Icons.manage_accounts_rounded, 'Managers'),
    (AdminSection.workers, Icons.engineering_rounded, 'Workers'),
    (AdminSection.complexes, Icons.stadium_rounded, 'Complexes'),
    (AdminSection.bookings, Icons.calendar_today_rounded, 'Bookings'),
    (AdminSection.settings, Icons.settings_rounded, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = AdminTheme.lightTheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: collapsed ? 68.0 : 232.0,
      color: theme.surface,
      child: Column(
        children: [
          Container(
            height: 64,
            padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 20),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.divider))),
            child: Row(
              mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(9)),
                  child: const Center(
                    child: Text('S', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  ),
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 10),
                  Text('Sporta', style: TextStyle(color: theme.text, fontSize: 17, fontWeight: FontWeight.w800)),
                ],
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Column(
                children: _items.map((item) {
                  final active = current == item.$1;
                  return _SidebarItem(
                    icon: item.$2,
                    label: item.$3,
                    active: active,
                    collapsed: collapsed,
                    onTap: () => onSelect(item.$1),
                  );
                }).toList(),
              ),
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: Container(
              height: 44,
              decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.divider))),
              child: Center(
                child: Icon(
                  collapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
                  color: theme.light,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool collapsed;
  final VoidCallback onTap;
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.active,
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
    final theme = AdminTheme.lightTheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          margin: const EdgeInsets.only(bottom: 3),
          padding: EdgeInsets.symmetric(horizontal: widget.collapsed ? 0 : 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.active
                ? kPrimary.withOpacity(0.1)
                : (_hover ? theme.hover : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
            border: widget.active ? Border.all(color: kPrimary.withOpacity(0.25)) : null,
          ),
          child: Row(
            mainAxisAlignment: widget.collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(widget.icon, size: 18, color: widget.active ? kPrimary : (_hover ? theme.text : theme.light)),
              if (!widget.collapsed) ...[
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: widget.active ? FontWeight.w700 : FontWeight.w500,
                      color: widget.active ? theme.text : (_hover ? theme.text : theme.light),
                    ),
                  ),
                ),
                if (widget.active)
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle)),
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
class _TopBar extends StatelessWidget {
  final AdminSection section;
  final String adminName;
  final VoidCallback onLogout, onSettings;
  const _TopBar({
    required this.section,
    required this.adminName,
    required this.onLogout,
    required this.onSettings,
  });

  String get _title => section.name.cap;

  @override
  Widget build(BuildContext context) {
    final theme = AdminTheme.lightTheme;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(bottom: BorderSide(color: theme.divider)),
      ),
      child: Row(
        children: [
          Text(_title, style: TextStyle(color: theme.text, fontSize: 20, fontWeight: FontWeight.w800)),
          const Spacer(),
          GestureDetector(
            onTap: onSettings,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(10)),
                  child: Center(
                    child: Text(_initials(adminName), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(adminName, style: TextStyle(color: theme.text, fontSize: 12, fontWeight: FontWeight.w700)),
                    Text('Super Admin', style: TextStyle(color: theme.light, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _HoverBtn(icon: Icons.logout_rounded, color: kRed, onTap: onLogout),
        ],
      ),
    );
  }
}

class _HoverBtn extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _HoverBtn({required this.icon, required this.color, required this.onTap});
  @override
  State<_HoverBtn> createState() => _HoverBtnState();
}

class _HoverBtnState extends State<_HoverBtn> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final theme = AdminTheme.lightTheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _hover ? widget.color.withOpacity(0.1) : theme.bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _hover ? widget.color.withOpacity(0.3) : theme.divider),
          ),
          child: Icon(widget.icon, size: 16, color: _hover ? widget.color : theme.light),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OVERVIEW SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _OverviewSection extends StatelessWidget {
  final List<AdminPlayer> players;
  final List<AdminManager> managers;
  final List<AdminWorker> workers;
  final List<AdminBooking> bookings;
  final List<AdminComplex> complexes;
  final List<MonthlyRevenue> monthlyRevenues;
  final Map<SportType, int> bookingsBySport;
  final double totalRevenue;
  final ValueChanged<AdminSection> onNavigate;
  const _OverviewSection({
    required this.players,
    required this.managers,
    required this.workers,
    required this.bookings,
    required this.complexes,
    required this.monthlyRevenues,
    required this.bookingsBySport,
    required this.totalRevenue,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AdminTheme.lightTheme;
    final pending = bookings.where((b) => b.status == 'pending').length;
    final today = DateTime.now().toString().split(' ')[0];
    final todayBk = bookings.where((b) => b.date == today).length;
    final totalCts = complexes.fold(0, (s, v) => s + v.courts);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [kPrimary, kPrimary.withOpacity(0.8)]),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome back, Admin 👋', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
                    const SizedBox(height: 6),
                    const Text("Here's your platform at a glance", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _Pill('$todayBk bookings today', Icons.calendar_today_rounded),
                        const SizedBox(width: 10),
                        _Pill('$pending pending', Icons.pending_actions_rounded),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.shield_rounded, color: Colors.white, size: 32),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _KPI('Players', '${players.length}', Icons.person_rounded, kPrimary),
              const SizedBox(width: 14),
              _KPI('Managers', '${managers.length}', Icons.manage_accounts_rounded, const Color(0xFF9333EA)),
              const SizedBox(width: 14),
              _KPI('Workers', '${workers.length}', Icons.engineering_rounded, kAmber),
              const SizedBox(width: 14),
              _KPI('Revenue', '${(totalRevenue / 1000).toStringAsFixed(1)}K DT', Icons.payments_rounded, kGreen),
              const SizedBox(width: 14),
              _KPI('Complexes', '${complexes.length}', Icons.stadium_rounded, Colors.blue),
              const SizedBox(width: 14),
              _KPI('Courts', '$totalCts', Icons.sports_tennis_rounded, kOrange),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _Card(
                title: 'Revenue by Month',
                child: monthlyRevenues.isEmpty
                    ? const _Empty('No revenue data')
                    : Column(
                        children: monthlyRevenues.take(6).map((m) {
                          return _Bar(
                            label: m.month,
                            value: m.amount,
                            max: monthlyRevenues.fold(0.0, (s, x) => x.amount > s ? x.amount : s),
                            color: kPrimary,
                            suffix: ' DT',
                          );
                        }).toList(),
                      ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              flex: 2,
              child: _Card(
                title: 'By Sport',
                child: bookingsBySport.isEmpty
                    ? const _Empty('No booking data')
                    : Column(
                        children: SportType.values.map((s) {
                          final count = bookingsBySport[s] ?? 0;
                          final total = bookingsBySport.values.fold(0, (a, b) => a + b);
                          return _Bar(
                            label: s.label,
                            value: count.toDouble(),
                            max: total.toDouble(),
                            color: s.color,
                            suffix: '',
                          );
                        }).toList(),
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _Card(
                title: 'Recent Players',
                action: 'View all',
                onAction: () => onNavigate(AdminSection.players),
                child: Column(
                  children: players.take(5).map((p) {
                    return _SnippetRow(
                      initials: _initials(p.name),
                      color: kPrimary,
                      title: p.name,
                      sub: p.email,
                      badge: p.isActive ? 'Active' : 'Inactive',
                      badgeColor: p.isActive ? kGreen : kRed,
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: _Card(
                title: 'Recent Managers',
                action: 'View all',
                onAction: () => onNavigate(AdminSection.managers),
                child: Column(
                  children: managers.take(5).map((m) {
                    return _SnippetRow(
                      initials: _initials(m.name),
                      color: const Color(0xFF9333EA),
                      title: m.name,
                      sub: '${m.complexes.length} complexes · ${m.totalCourts} courts',
                      badge: m.isActive ? 'Active' : 'Inactive',
                      badgeColor: m.isActive ? kGreen : kRed,
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLAYERS SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _PlayersSection extends StatefulWidget {
  final List<AdminPlayer> players;
  final bool loading;
  final String? error;
  final Future<void> Function(Map<String, String>) onAdd;
  final Future<void> Function(String, Map<String, String>) onEdit;
  final Future<void> Function(String) onDelete;
  final Future<void> Function(String) onToggle;
  final Future<void> Function() onRefresh;
  const _PlayersSection({
    required this.players, required this.loading, this.error,
    required this.onAdd, required this.onEdit, required this.onDelete,
    required this.onToggle, required this.onRefresh,
  });
  @override
  State<_PlayersSection> createState() => _PlayersSectionState();
}

class _PlayersSectionState extends State<_PlayersSection> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final filtered = widget.players.where((p) {
      return _query.isEmpty || p.name.toLowerCase().contains(_query) || p.email.toLowerCase().contains(_query);
    }).toList();
    return _ListLayout(
      title: 'Players',
      count: widget.players.length,
      stats: [
        ('Total', '${widget.players.length}', kPrimary, Icons.person_rounded),
        ('Active', '${widget.players.where((p) => p.isActive).length}', kGreen, Icons.check_circle_rounded),
        ('Blocked', '${widget.players.where((p) => !p.isActive).length}', kRed, Icons.block_rounded),
      ],
      onAdd: () => showDialog(
        context: context,
        builder: (_) => _UserFormDialog(title: 'Add Player', color: kPrimary, roleFields: const [], onSave: widget.onAdd),
      ),
      onRefresh: widget.onRefresh,
      onSearch: (q) => setState(() => _query = q.toLowerCase()),
      loading: widget.loading,
      error: widget.error,
      headers: const ['Player', 'Email', 'Phone', 'Bookings', 'Spent', 'Status', 'Actions'],
      rows: filtered.map((p) => _UserRow(
        initials: _initials(p.name), color: kPrimary, name: p.name, email: p.email,
        phone: p.phone, isActive: p.isActive, extra1: '${p.bookings}',
        extra2: '${p.spent.toInt()} DT', extraColor2: kGreen,
        onToggle: () => widget.onToggle(p.id),
        onEdit: () => showDialog(
          context: context,
          builder: (_) => _UserFormDialog(
            title: 'Edit Player', color: kPrimary, roleFields: const [],
            initial: {'username': p.name, 'email': p.email, 'phone': p.phone},
            onSave: (d) => widget.onEdit(p.id, d),
          ),
        ),
        onDelete: () => widget.onDelete(p.id),
      )).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MANAGERS SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _ManagersSection extends StatefulWidget {
  final List<AdminManager> managers;
  final bool loading;
  final String? error;
  final Future<void> Function(Map<String, String>) onAdd;
  final Future<void> Function(String, Map<String, String>) onEdit;
  final Future<void> Function(String) onDelete;
  final Future<void> Function(String) onToggle;
  final Future<void> Function() onRefresh;
  const _ManagersSection({
    required this.managers, required this.loading, this.error,
    required this.onAdd, required this.onEdit, required this.onDelete,
    required this.onToggle, required this.onRefresh,
  });
  @override
  State<_ManagersSection> createState() => _ManagersSectionState();
}

class _ManagersSectionState extends State<_ManagersSection> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final color = const Color(0xFF9333EA);
    final filtered = widget.managers.where((m) {
      return _query.isEmpty || m.name.toLowerCase().contains(_query) || m.email.toLowerCase().contains(_query);
    }).toList();
    return _ListLayout(
      title: 'Managers',
      count: widget.managers.length,
      stats: [
        ('Total', '${widget.managers.length}', color, Icons.manage_accounts_rounded),
        ('Active', '${widget.managers.where((m) => m.isActive).length}', kGreen, Icons.check_circle_rounded),
      ],
      onAdd: () => showDialog(
        context: context,
        builder: (_) => _UserFormDialog(title: 'Add Manager', color: color, roleFields: const [], onSave: widget.onAdd),
      ),
      onRefresh: widget.onRefresh,
      onSearch: (q) => setState(() => _query = q.toLowerCase()),
      loading: widget.loading,
      error: widget.error,
      headers: const ['Manager', 'Email', 'Phone', 'Complexes', 'Revenue', 'Status', 'Actions'],
      rows: filtered.map((m) => _UserRow(
        initials: _initials(m.name), color: color, name: m.name, email: m.email,
        phone: m.phone, isActive: m.isActive, extra1: '${m.complexes.length}',
        extra2: '${(m.revenue / 1000).toStringAsFixed(1)}K DT', extraColor2: kGreen,
        onToggle: () => widget.onToggle(m.id),
        onEdit: () => showDialog(
          context: context,
          builder: (_) => _UserFormDialog(
            title: 'Edit Manager', color: color, roleFields: const [],
            initial: {'username': m.name, 'email': m.email, 'phone': m.phone},
            onSave: (d) => widget.onEdit(m.id, d),
          ),
        ),
        onDelete: () => widget.onDelete(m.id),
      )).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WORKERS SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _WorkersSection extends StatefulWidget {
  final List<AdminWorker> workers;
  final List<AdminManager> managers;
  final bool loading;
  final String? error;
  final Future<void> Function(Map<String, String>) onAdd;
  final Future<void> Function(String, Map<String, String>) onEdit;
  final Future<void> Function(String) onDelete;
  final Future<void> Function(String) onToggle;
  final Future<void> Function() onRefresh;
  const _WorkersSection({
    required this.workers, required this.managers, required this.loading, this.error,
    required this.onAdd, required this.onEdit, required this.onDelete,
    required this.onToggle, required this.onRefresh,
  });
  @override
  State<_WorkersSection> createState() => _WorkersSectionState();
}

class _WorkersSectionState extends State<_WorkersSection> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final filtered = widget.workers.where((w) {
      return _query.isEmpty || w.name.toLowerCase().contains(_query) || w.email.toLowerCase().contains(_query);
    }).toList();
    return _ListLayout(
      title: 'Workers',
      count: widget.workers.length,
      stats: [
        ('Total', '${widget.workers.length}', kAmber, Icons.engineering_rounded),
        ('Active', '${widget.workers.where((w) => w.isActive).length}', kGreen, Icons.check_circle_rounded),
      ],
      onAdd: () => showDialog(
        context: context,
        builder: (_) => _UserFormDialog(
          title: 'Add Worker',
          color: kAmber,
          roleFields: [
            _RoleField('Manager', 'managerId', widget.managers.map((m) => _Option(m.id, m.name)).toList()),
          ],
          onSave: widget.onAdd,
        ),
      ),
      onRefresh: widget.onRefresh,
      onSearch: (q) => setState(() => _query = q.toLowerCase()),
      loading: widget.loading,
      error: widget.error,
      headers: const ['Worker', 'Email', 'Phone', 'Manager', 'Courts', 'Status', 'Actions'],
      rows: filtered.map((w) => _UserRow(
        initials: _initials(w.name), color: kAmber, name: w.name, email: w.email,
        phone: w.phone, isActive: w.isActive, extra1: w.managerName, extra2: '${w.courts.length}',
        onToggle: () => widget.onToggle(w.id),
        onEdit: () => showDialog(
          context: context,
          builder: (_) => _UserFormDialog(
            title: 'Edit Worker', color: kAmber, roleFields: const [],
            initial: {'username': w.name, 'email': w.email, 'phone': w.phone},
            onSave: (d) => widget.onEdit(w.id, d),
          ),
        ),
        onDelete: () => widget.onDelete(w.id),
      )).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPLEXES SECTION
// FIX 4: Consistent flex values between header and data rows via _ComplexRow
// ─────────────────────────────────────────────────────────────────────────────
class _ComplexesSection extends StatelessWidget {
  final List<AdminComplex> complexes;
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;
  const _ComplexesSection({
    required this.complexes, required this.loading, this.error, required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return _ListLayout(
      title: 'Complexes',
      count: complexes.length,
      stats: [
        ('Total', '${complexes.length}', kPrimary, Icons.stadium_rounded),
        ('Active', '${complexes.where((v) => v.isActive).length}', kGreen, Icons.check_circle_rounded),
      ],
      onAdd: null,
      onRefresh: onRefresh,
      onSearch: (_) {},
      loading: loading,
      error: error,
      headers: const ['Complex', 'City', 'Manager', 'Courts', 'Rating', 'Sports', 'Status'],
      rows: complexes.map((v) => _ComplexRow(complex: v)).toList(),
    );
  }
}

/// Dedicated complex row widget with matching flex values to the header.
class _ComplexRow extends StatelessWidget {
  final AdminComplex complex;
  const _ComplexRow({required this.complex});

  @override
  Widget build(BuildContext context) {
    final theme = AdminTheme.lightTheme;
    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.divider))),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      child: Row(
        children: [
          // Complex name — flex 3
          Expanded(
            flex: 3,
            child: Row(
              children: [
                _Avatar(complex.name.isNotEmpty ? complex.name[0].toUpperCase() : 'C', kPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    complex.name,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kTextDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // City — flex 2
          Expanded(
            flex: 2,
            child: Text(complex.city, style: const TextStyle(fontSize: 12, color: kTextMid), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          // Manager — flex 2
          Expanded(
            flex: 2,
            child: Text(complex.manager, style: const TextStyle(fontSize: 12, color: kTextMid), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          // Courts — flex 1
          Expanded(
            flex: 1,
            child: Text('${complex.courts}', style: const TextStyle(fontSize: 12, color: kTextMid)),
          ),
          // Rating — flex 1
          Expanded(
            flex: 1,
            child: Row(
              children: [
                const Icon(Icons.star_rounded, size: 11, color: kAmber),
                const SizedBox(width: 3),
                Text(complex.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12, color: kTextMid)),
              ],
            ),
          ),
          // Sports — flex 3 (wider to fit sport badges comfortably)
          Expanded(
            flex: 3,
            child: complex.sports.isEmpty
                ? Text('—', style: TextStyle(fontSize: 12, color: AdminTheme.lightTheme.light))
                : Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: complex.sports.map((s) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: s.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: s.color.withOpacity(0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(s.icon, size: 9, color: s.color),
                            const SizedBox(width: 3),
                            Text(
                              s.label,
                              style: TextStyle(fontSize: 10, color: s.color, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          // Status — flex 2
          Expanded(
            flex: 2,
            child: _Badge(complex.isActive ? 'Active' : 'Inactive', complex.isActive ? kGreen : kRed),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOOKINGS SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _BookingsSection extends StatelessWidget {
  final List<AdminBooking> bookings;
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;
  const _BookingsSection({
    required this.bookings, required this.loading, this.error, required this.onRefresh,
  });

  Color _statusColor(String s) {
    switch (s) {
      case 'confirmed': return kGreen;
      case 'pending':   return kAmber;
      case 'cancelled': return kRed;
      default:          return kTextLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ListLayout(
      title: 'Bookings',
      count: bookings.length,
      stats: [
        ('Total', '${bookings.length}', kPrimary, Icons.calendar_today_rounded),
        ('Confirmed', '${bookings.where((b) => b.status == 'confirmed').length}', kGreen, Icons.check_circle_rounded),
        ('Pending', '${bookings.where((b) => b.status == 'pending').length}', kAmber, Icons.pending_rounded),
        ('Cancelled', '${bookings.where((b) => b.status == 'cancelled').length}', kRed, Icons.cancel_rounded),
      ],
      onAdd: null,
      onRefresh: onRefresh,
      onSearch: (_) {},
      loading: loading,
      error: error,
      headers: const ['Player', 'Complex', 'Court', 'Sport', 'Date', 'Time', 'Price', 'Status'],
      rows: bookings.map((b) => _TableRow(cells: [
        _TextCell(b.player),
        _TextCell(b.complex),
        _TextCell(b.court),
        _SportCell(b.sport),
        _TextCell(b.date),
        _TextCell(b.time),
        _MoneyCell('${b.price.toInt()} DT'),
        _BadgeCell(b.status.cap, _statusColor(b.status)),
      ])).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SETTINGS SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _SettingsSection extends StatefulWidget {
  final String adminName, adminEmail, token;
  final Future<void> Function(String name, String email, String pw) onSaved;
  const _SettingsSection({
    required this.adminName, required this.adminEmail, required this.token, required this.onSaved,
  });
  @override
  State<_SettingsSection> createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<_SettingsSection> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.adminName);
    _emailController = TextEditingController(text: widget.adminEmail);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_passwordController.text.isNotEmpty && _passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match'), backgroundColor: kRed),
      );
      return;
    }
    setState(() => _saving = true);
    await widget.onSaved(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AdminTheme.lightTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Settings', style: TextStyle(color: theme.text, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: theme.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.divider),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(14)),
                  child: Center(
                    child: Text(
                      _initials(_nameController.text.isEmpty ? 'Admin' : _nameController.text),
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.adminName, style: TextStyle(color: theme.text, fontSize: 18, fontWeight: FontWeight.w800)),
                    Text('Super Admin', style: TextStyle(color: theme.light, fontSize: 13)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),
            Divider(color: theme.divider),
            const SizedBox(height: 24),
            Text('Account Information', style: TextStyle(color: theme.mid, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _SettingsField('Display Name', _nameController, Icons.person_outline_rounded)),
                const SizedBox(width: 16),
                Expanded(child: _SettingsField('Email', _emailController, Icons.email_outlined, type: TextInputType.emailAddress)),
              ],
            ),
            const SizedBox(height: 24),
            Divider(color: theme.divider),
            const SizedBox(height: 24),
            Text('Change Password', style: TextStyle(color: theme.mid, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            const SizedBox(height: 6),
            Text('Leave blank to keep your current password', style: TextStyle(color: theme.light, fontSize: 12)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _SettingsField('New Password', _passwordController, Icons.lock_outline_rounded, obscure: true)),
                const SizedBox(width: 16),
                Expanded(child: _SettingsField('Confirm Password', _confirmPasswordController, Icons.lock_outline_rounded, obscure: true)),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 200,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded, size: 16),
                label: Text(_saving ? 'Saving…' : 'Save Changes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GENERIC LIST LAYOUT
// ─────────────────────────────────────────────────────────────────────────────
class _ListLayout extends StatelessWidget {
  final String title;
  final int count;
  final List<(String, String, Color, IconData)> stats;
  final VoidCallback? onAdd;
  final Future<void> Function() onRefresh;
  final ValueChanged<String> onSearch;
  final bool loading;
  final String? error;
  final List<String> headers;
  final List<Widget> rows;

  const _ListLayout({
    required this.title, required this.count, required this.stats,
    this.onAdd, required this.onRefresh, required this.onSearch,
    required this.loading, this.error, required this.headers, required this.rows,
  });

  int _flex(String header) {
    switch (header) {
      case 'Player':
      case 'Manager':
      case 'Worker':
      case 'Complex':
        return 3;
      case 'Email':
        return 3;
      case 'Sports':
        return 3;
      case 'Courts':
      case 'Rating':
        return 1;
      case 'Status':
      case 'Actions':
        return 2;
      default:
        return 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AdminTheme.lightTheme;
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: kPrimary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              ...stats.map((s) {
                return Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: _MiniStat(label: s.$1, value: s.$2, color: s.$3, icon: s.$4),
                );
              }),
              const Spacer(),
              if (onAdd != null) _AddBtn(onTap: onAdd!),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: theme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.divider),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                  child: Row(
                    children: [
                      Text('All $title', style: TextStyle(color: theme.text, fontSize: 14, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      SizedBox(
                        width: 220,
                        height: 34,
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.bg,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: theme.divider),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 10),
                              const Icon(Icons.search_rounded, size: 14, color: kTextLight),
                              const SizedBox(width: 7),
                              Expanded(
                                child: TextField(
                                  onChanged: onSearch,
                                  style: TextStyle(color: theme.text, fontSize: 12),
                                  decoration: const InputDecoration(
                                    hintText: 'Search…',
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
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                  decoration: BoxDecoration(
                    color: theme.bg,
                    border: Border(top: BorderSide(color: theme.divider), bottom: BorderSide(color: theme.divider)),
                  ),
                  child: Row(
                    children: headers.map((h) {
                      return Expanded(flex: _flex(h), child: Text(
                        h,
                        style: TextStyle(color: theme.light, fontSize: 11, fontWeight: FontWeight.w700),
                      ));
                    }).toList(),
                  ),
                ),
                if (loading)
                  const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: kPrimary)))
                else if (error != null)
                  Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.error_outline, color: kRed, size: 32),
                        const SizedBox(height: 8),
                        Text(error!, style: const TextStyle(color: kTextMid)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: onRefresh,
                          style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                else if (rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.inbox_rounded, size: 40, color: theme.light),
                        const SizedBox(height: 8),
                        Text('No $title found', style: TextStyle(color: theme.light)),
                      ],
                    ),
                  )
                else
                  ...rows,
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// USER ROW
// ─────────────────────────────────────────────────────────────────────────────
class _UserRow extends StatelessWidget {
  final String initials, name, email, phone, extra1, extra2;
  final Color color;
  final Color? extraColor2;
  final bool isActive;
  final VoidCallback onToggle, onEdit, onDelete;
  const _UserRow({
    required this.initials, required this.color, required this.name, required this.email,
    required this.phone, required this.isActive, required this.extra1, required this.extra2,
    this.extraColor2, required this.onToggle, required this.onEdit, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AdminTheme.lightTheme;
    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.divider))),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                _Avatar(initials, color),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(color: theme.text, fontSize: 13, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(phone.isEmpty ? '—' : phone, style: TextStyle(color: theme.light, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(flex: 3, child: Text(email, style: TextStyle(color: theme.mid, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Text(phone.isEmpty ? '—' : phone, style: TextStyle(color: theme.text, fontSize: 12))),
          Expanded(flex: 2, child: Text(extra1, style: TextStyle(color: theme.text, fontSize: 12))),
          Expanded(flex: 2, child: Text(extra2, style: TextStyle(color: extraColor2 ?? theme.text, fontSize: 12, fontWeight: FontWeight.w700))),
          Expanded(flex: 2, child: _Badge(isActive ? 'Active' : 'Blocked', isActive ? kGreen : kRed)),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                _IconButton(Icons.edit_outlined, kPrimary, onEdit),
                const SizedBox(width: 6),
                _IconButton(isActive ? Icons.block_rounded : Icons.check_circle_outline_rounded, isActive ? kAmber : kGreen, onToggle),
                const SizedBox(width: 6),
                _IconButton(Icons.delete_outline_rounded, kRed, onDelete),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GENERIC TABLE ROW + CELLS
// ─────────────────────────────────────────────────────────────────────────────
class _TableRow extends StatelessWidget {
  final List<Widget> cells;
  const _TableRow({required this.cells});
  @override
  Widget build(BuildContext context) {
    final theme = AdminTheme.lightTheme;
    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.divider))),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      child: Row(children: cells.map((c) => Expanded(child: c)).toList()),
    );
  }
}

class _TextCell extends StatelessWidget {
  final String text;
  const _TextCell(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 12, color: kTextMid), maxLines: 1, overflow: TextOverflow.ellipsis);
  }
}

class _MoneyCell extends StatelessWidget {
  final String text;
  const _MoneyCell(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 12, color: kGreen, fontWeight: FontWeight.w700));
  }
}

class _NameCell extends StatelessWidget {
  final String initials, name, sub;
  final Color color;
  const _NameCell({required this.initials, required this.name, required this.sub, required this.color});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Avatar(initials, color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kTextDark), maxLines: 1, overflow: TextOverflow.ellipsis),
              if (sub.isNotEmpty) Text(sub, style: const TextStyle(fontSize: 11, color: kTextLight)),
            ],
          ),
        ),
      ],
    );
  }
}

class _BadgeCell extends StatelessWidget {
  final String label;
  final Color color;
  const _BadgeCell(this.label, this.color);
  @override
  Widget build(BuildContext context) => _Badge(label, color);
}

class _SportCell extends StatelessWidget {
  final SportType sport;
  const _SportCell(this.sport);
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(sport.icon, size: 12, color: sport.color),
        const SizedBox(width: 4),
        Text(sport.label, style: TextStyle(fontSize: 11, color: sport.color, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _SportsCell extends StatelessWidget {
  final List<SportType> sports;
  const _SportsCell(this.sports);
  @override
  Widget build(BuildContext context) {
    if (sports.isEmpty) return Text('—', style: TextStyle(fontSize: 12, color: AdminTheme.lightTheme.light));
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: sports.map((s) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: s.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: s.color.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(s.icon, size: 9, color: s.color),
              const SizedBox(width: 3),
              Text(s.label, style: TextStyle(fontSize: 10, color: s.color, fontWeight: FontWeight.w700)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// USER FORM DIALOG
// ─────────────────────────────────────────────────────────────────────────────
class _Option {
  final String id, label;
  const _Option(this.id, this.label);
}

class _RoleField {
  final String label, key;
  final List<_Option> options;
  const _RoleField(this.label, this.key, this.options);
}

class _UserFormDialog extends StatefulWidget {
  final String title;
  final Color color;
  final List<_RoleField> roleFields;
  final Map<String, String>? initial;
  final Future<void> Function(Map<String, String>) onSave;
  const _UserFormDialog({
    required this.title, required this.color, required this.roleFields,
    this.initial, required this.onSave,
  });
  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  final TextEditingController _passwordController = TextEditingController();
  late TextEditingController _phoneController = TextEditingController();
  final Map<String, String> _roleSelections = {};
  bool _saving = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?['username'] ?? '');
    _emailController = TextEditingController(text: widget.initial?['email'] ?? '');
    _phoneController = TextEditingController(text: widget.initial?['phone'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: kRed, behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final isEdit = widget.initial != null;
    if (!isEdit && _passwordController.text.trim().isEmpty) {
      _showError('Password is required');
      return;
    }
    for (final field in widget.roleFields) {
      if (!_roleSelections.containsKey(field.key) || _roleSelections[field.key]!.isEmpty) {
        _showError('${field.label} is required');
        return;
      }
    }
    setState(() => _saving = true);
    final data = <String, String>{
      'username': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      if (_passwordController.text.trim().isNotEmpty) 'password': _passwordController.text.trim(),
      ..._roleSelections,
    };
    try {
      await widget.onSave(data);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AdminTheme.lightTheme;
    final isEdit = widget.initial != null;
    return Dialog(
      backgroundColor: theme.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: BorderSide(color: theme.divider)),
      child: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: widget.color.withOpacity(0.1), borderRadius: BorderRadius.circular(11)),
                    child: Icon(Icons.person_add_rounded, color: widget.color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(widget.title, style: TextStyle(color: theme.text, fontSize: 16, fontWeight: FontWeight.w800))),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(color: theme.bg, borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.close_rounded, size: 14, color: theme.light),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _FormField('Full Name', _nameController, Icons.person_outline_rounded, required: true),
              const SizedBox(height: 14),
              _FormField('Email', _emailController, Icons.email_outlined, type: TextInputType.emailAddress, required: true),
              const SizedBox(height: 14),
              _FormField(
                isEdit ? 'New Password (leave blank to keep)' : 'Password',
                _passwordController, Icons.lock_outline_rounded,
                obscure: true, required: !isEdit,
              ),
              const SizedBox(height: 14),
              _FormField('Phone', _phoneController, Icons.phone_outlined, type: TextInputType.phone),
              for (final field in widget.roleFields) ...[
                const SizedBox(height: 14),
                Text(field.label, style: TextStyle(color: theme.light, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(color: theme.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: theme.divider)),
                  child: DropdownButtonFormField<String>(
                    value: _roleSelections[field.key],
                    isExpanded: true,
                    hint: Text('Select ${field.label}'),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.manage_accounts_rounded, size: 15),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: field.options.map((o) => DropdownMenuItem(value: o.id, child: Text(o.label))).toList(),
                    onChanged: (value) => setState(() => _roleSelections[field.key] = value ?? ''),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _DialogButton('Cancel', onTap: () => Navigator.pop(context), outlined: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _DialogButton(
                    _saving ? 'Saving…' : (isEdit ? 'Save Changes' : 'Create'),
                    onTap: _saving ? null : _save,
                    color: widget.color,
                  )),
                ],
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SETTINGS FIELD
// ─────────────────────────────────────────────────────────────────────────────
class _SettingsField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool obscure;
  final TextInputType type;
  const _SettingsField(this.label, this.controller, this.icon, {this.obscure = false, this.type = TextInputType.text});
  @override
  State<_SettingsField> createState() => _SettingsFieldState();
}

class _SettingsFieldState extends State<_SettingsField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final theme = AdminTheme.lightTheme;
    final isPassword = widget.obscure;
    final shouldObscure = isPassword && !_visible;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: TextStyle(color: theme.mid, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(color: theme.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: theme.divider)),
          child: TextField(
            controller: widget.controller,
            obscureText: shouldObscure,
            keyboardType: widget.type,
            style: TextStyle(color: theme.text, fontSize: 13),
            decoration: InputDecoration(
              prefixIcon: Icon(widget.icon, size: 15, color: theme.light),
              suffixIcon: isPassword
                  ? GestureDetector(
                      onTap: () => setState(() => _visible = !_visible),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          _visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 16,
                          color: _visible ? kPrimary : theme.light,
                        ),
                      ),
                    )
                  : null,
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONFIRM DIALOG
// ─────────────────────────────────────────────────────────────────────────────
class _ConfirmDialog extends StatelessWidget {
  final String title, body;
  const _ConfirmDialog({required this.title, required this.body});
  @override
  Widget build(BuildContext context) {
    final theme = AdminTheme.lightTheme;
    return Dialog(
      backgroundColor: theme.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: theme.divider)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 340,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: kRed.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.warning_amber_rounded, color: kRed, size: 18),
                ),
                const SizedBox(width: 12),
                Text(title, style: TextStyle(color: theme.text, fontSize: 15, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 14),
            Text(body, style: TextStyle(color: theme.mid, fontSize: 13, height: 1.5)),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(child: _DialogButton('Cancel', onTap: () => Navigator.pop(context, false), outlined: true)),
                const SizedBox(width: 10),
                Expanded(child: _DialogButton('Confirm', onTap: () => Navigator.pop(context, true), color: kRed)),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MICRO WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _Pill extends StatelessWidget {
  final String label;
  final IconData icon;
  const _Pill(this.label, this.icon);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _KPI extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _KPI(this.label, this.value, this.icon, this.color);
  @override
  Widget build(BuildContext context) {
    final theme = AdminTheme.lightTheme;
    return SizedBox(
      width: 180,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: theme.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: theme.divider)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(color: theme.text, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(color: theme.light, fontSize: 12)),
        ]),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final Widget child;
  const _Card({required this.title, required this.child, this.action, this.onAction});
  @override
  Widget build(BuildContext context) {
    final theme = AdminTheme.lightTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: theme.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            Text(title, style: TextStyle(color: theme.text, fontSize: 14, fontWeight: FontWeight.w700)),
            if (action != null) ...[
              const Spacer(),
              GestureDetector(onTap: onAction, child: Text(action!, style: const TextStyle(color: kPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
            ],
          ],
        ),
        const SizedBox(height: 16),
        child,
      ]),
    );
  }
}

class _Bar extends StatelessWidget {
  final String label, suffix;
  final double value, max;
  final Color color;
  const _Bar({required this.label, required this.value, required this.max, required this.color, this.suffix = ''});
  @override
  Widget build(BuildContext context) {
    final theme = AdminTheme.lightTheme;
    final percentage = max == 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: TextStyle(color: theme.text, fontSize: 12, fontWeight: FontWeight.w600))),
              Text('${value.toInt()}$suffix', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage, minHeight: 5,
              backgroundColor: theme.bg,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _SnippetRow extends StatelessWidget {
  final String initials, title, sub, badge;
  final Color color, badgeColor;
  const _SnippetRow({
    required this.initials, required this.color, required this.title,
    required this.sub, required this.badge, required this.badgeColor,
  });
  @override
  Widget build(BuildContext context) {
    final theme = AdminTheme.lightTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          _Avatar(initials, color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: theme.text, fontSize: 12, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(sub, style: TextStyle(color: theme.light, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          _Badge(badge, badgeColor),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _MiniStat({required this.label, required this.value, required this.color, required this.icon});
  @override
  Widget build(BuildContext context) {
    final theme = AdminTheme.lightTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(color: theme.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.divider)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(color: theme.text, fontSize: 16, fontWeight: FontWeight.w800)),
              Text(label, style: TextStyle(color: theme.light, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _AddBtn({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(11)),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 15, color: Colors.white),
            SizedBox(width: 6),
            Text('Add New', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;
  final Color color;
  final double size;
  const _Avatar(this.initials, this.color, {this.size = 36});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Center(
        child: Text(initials, style: TextStyle(color: color, fontSize: size * 0.33, fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconButton(this.icon, this.color, this.onTap);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(7)),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}

class _FormField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool required, obscure;
  final TextInputType type;
  const _FormField(this.label, this.controller, this.icon, {this.required = false, this.obscure = false, this.type = TextInputType.text});
  @override
  State<_FormField> createState() => _FormFieldState();
}

class _FormFieldState extends State<_FormField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final theme = AdminTheme.lightTheme;
    final isPassword = widget.obscure;
    final shouldObscure = isPassword && !_visible;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: TextStyle(color: theme.light, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(color: theme.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: theme.divider)),
          child: TextFormField(
            controller: widget.controller,
            keyboardType: widget.type,
            obscureText: shouldObscure,
            style: TextStyle(color: theme.text, fontSize: 13),
            validator: widget.required ? (value) => (value == null || value.trim().isEmpty) ? 'Required' : null : null,
            decoration: InputDecoration(
              prefixIcon: Icon(widget.icon, size: 15, color: theme.light),
              suffixIcon: isPassword
                  ? GestureDetector(
                      onTap: () => setState(() => _visible = !_visible),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          _visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 16,
                          color: _visible ? kPrimary : theme.light,
                        ),
                      ),
                    )
                  : null,
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ),
      ],
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool outlined;
  final Color? color;
  const _DialogButton(this.label, {this.onTap, this.outlined = false, this.color});
  @override
  Widget build(BuildContext context) {
    final theme = AdminTheme.lightTheme;
    final buttonColor = color ?? kPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: outlined
            ? BoxDecoration(border: Border.all(color: theme.divider), borderRadius: BorderRadius.circular(11))
            : BoxDecoration(
                color: buttonColor, borderRadius: BorderRadius.circular(11),
                boxShadow: [BoxShadow(color: buttonColor.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))],
              ),
        child: Center(
          child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: outlined ? theme.mid : Colors.white)),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String message;
  const _Empty(this.message);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(child: Text(message, style: const TextStyle(color: kTextLight, fontSize: 13))),
    );
  }
}