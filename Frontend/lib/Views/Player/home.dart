// lib/Views/Player/home.dart
// e5er 7aja salla7t el cancel flow
import 'package:flutter/material.dart';
import 'package:sporta/Core/Theme/app_tokens.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Views/Player/HomeSettings.dart';
import 'package:sporta/Services/player_manager_auth_service.dart';
import 'package:sporta/Services/booking_store.dart';
import 'package:sporta/Services/reservation_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'Explore.dart';
import 'package:sporta/Services/announcement_service.dart';
import 'package:sporta/Core/Constants/api_constants.dart';
import 'package:sporta/Core/Utils/app_logger.dart';
import 'package:sporta/Widgets/booking_components.dart';
import 'package:sporta/Widgets/Cards/app_card.dart';
import 'package:sporta/Widgets/feedback_components.dart';
import 'package:sporta/Widgets/Inputs/app_text_field.dart';

//
// VENUE MODEL
//
class PlayerVenue {
  final String id, name, location, imageUrl, openUntil;
  final List<String> sports, amenities;
  final double minPrice, maxPrice, rating;
  final int totalRatings;
  final bool isActive;
  final String distance;
  final double? lat, lng;

  PlayerVenue({
    required this.id,
    required this.name,
    required this.location,
    required this.imageUrl,
    required this.openUntil,
    required this.sports,
    required this.amenities,
    required this.minPrice,
    required this.maxPrice,
    required this.isActive,
    this.rating = 0.0,
    this.totalRatings = 0,
    this.distance = '1.5 km',
    this.lat,
    this.lng,
  });

  factory PlayerVenue.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic v) {
      if (v == null) return [];
      if (v is List) return v.map((e) => e.toString()).toList();
      if (v is String) return [v];
      return [];
    }

    final base = ApiConstants.mediaBaseUrl;
    String imageUrl = '';
    if (json['photo'] is Map && json['photo']['url'] != null) {
      final p = json['photo']['url'].toString();
      imageUrl = p.startsWith('http') ? p : '$base$p';
    }

    double minPrice = 0, maxPrice = 0;
    if (json['courts'] is List) {
      final prices = (json['courts'] as List)
          .map((c) {
            if (c is Map && c['pricePerHour'] != null)
              return (c['pricePerHour'] as num).toDouble();
            return 0.0;
          })
          .where((p) => p > 0)
          .toList();
      if (prices.isNotEmpty) {
        minPrice = prices.reduce((a, b) => a < b ? a : b);
        maxPrice = prices.reduce((a, b) => a > b ? a : b);
      }
    }

    return PlayerVenue(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      imageUrl: imageUrl,
      sports: parseList(json['sports']),
      amenities: parseList(json['amenities']),
      minPrice: minPrice,
      maxPrice: maxPrice,
      isActive: json['isActive'] ?? true,
      openUntil: json['closeTime'] ?? '23:00',
      rating: (json['avg_rating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: (json['total_rating'] as num?)?.toInt() ?? 0,
      lat: json['lat'] != null ? double.tryParse(json['lat'].toString()) : null,
      lng: json['lng'] != null ? double.tryParse(json['lng'].toString()) : null,
    );
  }
}

//
// ANNOUNCEMENT MODEL
//
class PlayerAnnouncement {
  final String id;
  final String courtName;
  final String venueName;
  final String date;
  final String startTime;
  final String endTime;
  final String description;
  final int playersNeeded;
  final int acceptedCount;
  final int spotsLeft;
  final String status;
  final String? courtImageUrl;
  final DateTime bookingDate;

  PlayerAnnouncement({
    required this.id,
    required this.courtName,
    required this.venueName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.description,
    required this.playersNeeded,
    required this.acceptedCount,
    required this.spotsLeft,
    required this.status,
    this.courtImageUrl,
    required this.bookingDate,
  });

  bool get isActive {
    final today = DateTime.now();
    final bookingDateObj = DateTime.parse(date);
    return bookingDateObj.isAfter(today.subtract(const Duration(days: 1)));
  }

  factory PlayerAnnouncement.fromJson(Map<String, dynamic> json) {
    final court = json['court'] ?? {};
    final venue = court['venue'] ?? {};

    String? courtImageUrl;
    if (court['court_img_url'] != null) {
      courtImageUrl = _getFullImageUrlStatic(court['court_img_url'].toString());
    } else if (court['court_img'] != null &&
        court['court_img']['url'] != null) {
      courtImageUrl = _getFullImageUrlStatic(
        court['court_img']['url'].toString(),
      );
    } else if (court['photos_urls'] != null &&
        court['photos_urls'] is List &&
        court['photos_urls'].isNotEmpty) {
      courtImageUrl = _getFullImageUrlStatic(
        court['photos_urls'][0].toString(),
      );
    }

    final playersNeeded = json['players_needed'] ?? 0;
    final acceptedCount =
        json['join_requests']
            ?.where((jr) => jr['status'] == 'accepted')
            .length ??
        0;
    final spotsLeft = playersNeeded - acceptedCount;

    DateTime bookingDate = DateTime.now();
    final bookingDateStr = json['booking_date_play']?.toString().split('T')[0];
    if (bookingDateStr != null) {
      try {
        bookingDate = DateTime.parse(bookingDateStr);
      } catch (e) {}
    }

    return PlayerAnnouncement(
      id: json['id'].toString(),
      courtName: court['name'] ?? 'Unknown Court',
      venueName: venue['name'] ?? 'Unknown Venue',
      date: bookingDateStr ?? '',
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      description: json['description'] ?? '',
      playersNeeded: playersNeeded,
      acceptedCount: acceptedCount,
      spotsLeft: spotsLeft,
      status: json['status'] ?? 'open',
      courtImageUrl: courtImageUrl,
      bookingDate: bookingDate,
    );
  }

  static String _getFullImageUrlStatic(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '${ApiConstants.mediaBaseUrl}$url';
  }
}

//
// HOME
//
class Home extends StatefulWidget {
  final String? playerToken;
  const Home({super.key, this.playerToken});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedSport = 0;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  Map<String, dynamic>? _currentUser;
  bool _isLoadingUser = true;
  String? _playerPhotoUrl;

  List<PlayerVenue> _venues = [];
  bool _isLoadingVenues = true;
  String? _venuesError;

  List<PlayerAnnouncement> _myAnnouncements = [];
  bool _isLoadingAnnouncements = false;

  final _sports = const [
    {'label': 'All', 'icon': Icons.sports_rounded},
    {'label': 'Football', 'icon': Icons.sports_soccer_rounded},
    {'label': 'Padel', 'icon': Icons.sports_tennis_rounded},
    {'label': 'Basketball', 'icon': Icons.sports_basketball_rounded},
    {'label': 'Tennis', 'icon': Icons.sports_tennis},
    {'label': 'Volleyball', 'icon': Icons.sports_volleyball},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadVenues();
    _initBookingStore();
    _loadMyAnnouncements();
    BookingStore.instance.addListener(_onStoreUpdate);
  }

  @override
  void dispose() {
    BookingStore.instance.removeListener(_onStoreUpdate);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _initBookingStore() async {
    final token = await _getToken();
    if (token != null) {
      await BookingStore.instance.initialize(token);
      if (mounted) setState(() {});
    }
  }

  void _onStoreUpdate() {
    if (mounted) setState(() {});
  }

  Future<String?> _getToken() async {
    if (widget.playerToken?.isNotEmpty == true) return widget.playerToken;
    return const FlutterSecureStorage().read(key: 'jwt_token');
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoadingUser = true);
    try {
      final token = await _getToken();
      if (token == null) {
        setState(() => _isLoadingUser = false);
        return;
      }
      final response = await PlayerManagerAuthService.getMe(token);
      setState(() {
        if (response.containsKey('user')) {
          _currentUser = response['user'] as Map<String, dynamic>;
          if (response['photoUrl'] != null &&
              response['photoUrl'].toString().isNotEmpty) {
            _playerPhotoUrl = response['photoUrl'];
          } else if (response['profile'] is Map) {
            final profile = response['profile'] as Map<String, dynamic>;
            if (profile['photo'] is Map && profile['photo']['url'] != null) {
              _playerPhotoUrl = ApiConstants.getFullImageUrl(
                profile['photo']['url'].toString(),
              );
            }
          }
        } else {
          _currentUser = response;
          if (response['photoUrl'] != null)
            _playerPhotoUrl = response['photoUrl'];
        }
        _isLoadingUser = false;
      });
    } catch (_) {
      setState(() => _isLoadingUser = false);
    }
  }

  Future<void> _loadVenues() async {
    setState(() {
      _isLoadingVenues = true;
      _venuesError = null;
    });
    try {
      final res = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/public/venues?populate[photo]=*&populate[courts]=*',
        ),
      );
      if (res.statusCode == 200) {
        final list = json.decode(res.body) as List<dynamic>;
        setState(() {
          _venues = list
              .map((j) => PlayerVenue.fromJson(j as Map<String, dynamic>))
              .toList();
          _isLoadingVenues = false;
        });
      } else {
        throw Exception('Failed to load venues');
      }
    } catch (e) {
      setState(() {
        _venuesError = e.toString().replaceAll('Exception:', '').trim();
        _isLoadingVenues = false;
      });
    }
  }

  Future<void> _loadMyAnnouncements() async {
    setState(() => _isLoadingAnnouncements = true);
    try {
      final token = await _getToken();
      if (token == null) {
        setState(() => _isLoadingAnnouncements = false);
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/announcements/mine'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> announcements = data['data'] ?? [];
        final allAnnouncements = announcements
            .map((a) => PlayerAnnouncement.fromJson(a))
            .toList();
        final activeAnnouncements = allAnnouncements
            .where((a) => a.isActive)
            .toList();
        setState(() {
          _myAnnouncements = activeAnnouncements;
          _isLoadingAnnouncements = false;
        });
      } else {
        setState(() => _isLoadingAnnouncements = false);
      }
    } catch (e) {
      AppLogger.error('Error loading announcements: $e');
      setState(() => _isLoadingAnnouncements = false);
    }
  }

  Future<void> _deleteAnnouncement(String announcementId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Announcement'),
        content: const Text(
          'Are you sure you want to delete this announcement? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: kRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/announcements/$announcementId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        await _loadMyAnnouncements();
        _showSnackBar('Announcement deleted successfully', kGreen);
      } else {
        throw Exception('Failed to delete announcement');
      }
    } catch (e) {
      _showSnackBar('Error: $e', kRed);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CANCEL FLOW — shows reason dialog then calls requestCancel
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _requestCancelReservation(LocalBooking booking) async {
    if (booking.status == 'cancel_requested') {
      _showSnackBar(
        'Cancellation already requested. Waiting for worker approval.',
        kAmber,
      );
      return;
    }

    final reason = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _CancelReasonDialog(courtName: booking.courtName),
    );

    if (reason == null) return;

    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final svc = ReservationService(token: token);
      await svc.requestCancel(booking.id, reason: reason);

      await BookingStore.instance.initialize(token);
      if (mounted) {
        _showSnackBar(
          'Cancellation request sent. The worker will review it shortly.',
          kPrimary,
        );
      }
    } catch (e) {
      if (mounted)
        _showSnackBar(
          'Error: ${e.toString().replaceAll('Exception:', '').trim()}',
          kRed,
        );
    }
  }

  Future<void> _postAnnouncementFromBooking(LocalBooking booking) async {
    final token = await _getToken();
    if (token == null) {
      _showSnackBar('Please login to post an announcement', kRed);
      return;
    }

    if (BookingStore.instance.hasAnnouncementForReservation(booking.id)) {
      _showSnackBar(
        'You already have an announcement for this booking',
        kAmber,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _PostAnnouncementSheet(
        booking: booking,
        playerToken: token,
        onPosted: () {
          _loadMyAnnouncements();
          BookingStore.instance.refresh();
        },
      ),
    );
  }

  void _showAnnouncementDetail(PlayerAnnouncement announcement) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AnnouncementDetailSheet(
        announcement: announcement,
        onDelete: () {
          Navigator.pop(ctx);
          _deleteAnnouncement(announcement.id);
        },
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── User helpers ──────────────────────────────────────────────────────────
  String get _userName {
    if (_currentUser == null) return 'Player';
    return _currentUser!['username']?.toString() ??
        _currentUser!['name']?.toString() ??
        'Player';
  }

  String get _userInitials {
    final name = _userName;
    if (name.isEmpty || name == 'Player') return 'P';
    final parts = name.trim().split(' ');
    return parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name[0].toUpperCase();
  }

  String get _userEmail => _currentUser?['email']?.toString() ?? '';
  String get _userPhone => _currentUser?['phone']?.toString() ?? '';
  String _getTimeOfDay() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }

  List<PlayerVenue> get _filteredVenues {
    final lbl = _sports[_selectedSport]['label'] as String;
    return _venues.where((v) {
      final matchSport =
          lbl == 'All' ||
          v.sports.any((s) => s.toLowerCase() == lbl.toLowerCase());
      final q = _searchQuery.toLowerCase();
      final matchSearch =
          q.isEmpty ||
          v.name.toLowerCase().contains(q) ||
          v.location.toLowerCase().contains(q);
      return matchSport && matchSearch && v.isActive;
    }).toList();
  }

  List<LocalBooking> get _upcomingBookings =>
      BookingStore.instance.upcomingBookings;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildTopBar()),
        SliverPadding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            0,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildSearchBar(),
              const SizedBox(height: AppSpacing.lg),
              _buildSectionTitle('Near you'),
              const SizedBox(height: AppSpacing.sm),
              _buildSportFilter(),
              const SizedBox(height: AppSpacing.md),
              _buildVenueCards(),
              const SizedBox(height: AppSpacing.lg),
              if (_upcomingBookings.isNotEmpty) ...[
                _buildSectionTitle('Upcoming booking'),
                const SizedBox(height: AppSpacing.sm),
                _buildUpcomingBookings(),
              ],
              if (_myAnnouncements.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                _buildSectionTitle('My announcements'),
                const SizedBox(height: AppSpacing.sm),
                _buildMyAnnouncements(),
              ],
              const SizedBox(height: 104),
            ]),
          ),
        ),
      ],
    ),
  );

  // ── Top bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    final theme = Theme.of(context);
    return Container(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Semantics(
                button: true,
                label: 'Open profile settings',
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 450),
                      reverseTransitionDuration: const Duration(
                        milliseconds: 320,
                      ),
                      pageBuilder: (_, anim, _) => HomeSettings(
                        username: _userName,
                        email: _userEmail,
                        phone: _userPhone,
                        playerToken: widget.playerToken,
                        currentPhotoUrl: _playerPhotoUrl,
                      ),
                      transitionsBuilder: (_, anim, _, child) {
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
                  ),
                  child: Hero(
                    tag: 'profile_avatar',
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: NightMatchColors.brandTeal,
                        border: Border.all(
                          color: NightMatchColors.actionLime,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: _isLoadingUser
                            ? const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: NightMatchColors.actionLime,
                                ),
                              )
                            : (_playerPhotoUrl != null &&
                                      _playerPhotoUrl!.isNotEmpty
                                  ? Image.network(
                                      _playerPhotoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) =>
                                          _avatarInitial(theme),
                                    )
                                  : _avatarInitial(theme)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good ${_getTimeOfDay()}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      _isLoadingUser ? 'Loading...' : _userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              Semantics(
                label: 'Notifications',
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_outlined,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarInitial(ThemeData theme) => Center(
    child: Text(
      _userInitials,
      style: theme.textTheme.titleMedium?.copyWith(
        color: NightMatchColors.text,
      ),
    ),
  );

  Widget _buildSearchBar() => AppTextField(
    controller: _searchCtrl,
    hint: 'Search venues, locations...',
    prefixIcon: Icons.search_rounded,
    onChanged: (value) => setState(() => _searchQuery = value),
    suffix: _searchQuery.isNotEmpty
        ? IconButton(
            tooltip: 'Clear search',
            onPressed: () => setState(() {
              _searchQuery = '';
              _searchCtrl.clear();
            }),
            icon: const Icon(Icons.close_rounded),
          )
        : IconButton(
            tooltip: 'Open filters',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Explore(playerToken: widget.playerToken),
              ),
            ),
            icon: const Icon(Icons.tune_rounded),
          ),
  );

  Widget _buildSectionTitle(String title) => SectionHeader(
    title: title,
    actionLabel: 'See all',
    onAction: () => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Explore(playerToken: widget.playerToken),
      ),
    ),
  );

  Widget _buildSportFilter() => SizedBox(
    height: 96,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: _sports.length,
      separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
      itemBuilder: (_, i) {
        return SportCategoryCircle(
          label: _sports[i]['label'] as String,
          icon: _sports[i]['icon'] as IconData,
          selected: _selectedSport == i,
          onTap: () => setState(() => _selectedSport = i),
        );
      },
    ),
  );

  Widget _buildVenueCards() {
    if (_isLoadingVenues) {
      return const SizedBox(
        height: 240,
        child: Center(
          child: LoadingSkeleton(width: 300, height: 220, borderRadius: 28),
        ),
      );
    }
    if (_venuesError != null) {
      return ErrorState(
        title: 'Could not load venues',
        message: _venuesError!,
        onRetry: _loadVenues,
      );
    }
    final venues = _filteredVenues;
    if (venues.isEmpty) {
      return EmptyState(
        title: _searchQuery.isNotEmpty ? 'No venues found' : 'No venues yet',
        message: _searchQuery.isNotEmpty
            ? 'Try another venue name or area.'
            : 'There are no available venues nearby right now.',
        icon: Icons.stadium_outlined,
      );
    }

    return SizedBox(
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: venues.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, index) {
          final venue = venues[index];
          final sport = venue.sports.isEmpty ? 'Sports' : venue.sports.first;
          final price = venue.minPrice <= 0
              ? 'Price unavailable'
              : venue.minPrice != venue.maxPrice
              ? '${venue.minPrice.toInt()}–${venue.maxPrice.toInt()} DT'
              : '${venue.minPrice.toInt()} DT';
          return VenueCard(
            name: venue.name,
            sport: sport,
            rating: venue.totalRatings > 0
                ? venue.rating.toStringAsFixed(1)
                : 'New',
            distance: '${venue.distance} · ${venue.location}',
            price: price,
            earliestSlot: '',
            availabilityLabel: 'Open until ${venue.openUntil}',
            photoUrl: venue.imageUrl,
          );
        },
      ),
    );
  }

  // ── My Announcements Section ──────────────────────────────────────────────
  Widget _buildMyAnnouncements() {
    return Column(
      children: _myAnnouncements.map((announcement) {
        final spotsLeft = announcement.spotsLeft;
        final statusColor = spotsLeft > 0 ? kGreen : kRed;
        final statusText = spotsLeft > 0 ? '$spotsLeft spots left' : 'Full';

        return GestureDetector(
          onTap: () => _showAnnouncementDetail(announcement),
          child: Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: SizedBox(
                    height: 120,
                    width: double.infinity,
                    child:
                        announcement.courtImageUrl != null &&
                            announcement.courtImageUrl!.isNotEmpty
                        ? Image.network(
                            announcement.courtImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: kPrimary.withOpacity(0.08),
                              child: const Icon(
                                Icons.stadium_rounded,
                                size: 40,
                                color: kPrimary,
                              ),
                            ),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: kPrimary.withOpacity(0.08),
                                child: const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: kPrimary,
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: kPrimary.withOpacity(0.08),
                            child: const Icon(
                              Icons.stadium_rounded,
                              size: 40,
                              color: kPrimary,
                            ),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              announcement.courtName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: kTextDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 12,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              announcement.venueName,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 11,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${announcement.date} · ${announcement.startTime} - ${announcement.endTime}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: kTextMid,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        announcement.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _AnnouncementStat(
                            icon: Icons.people_rounded,
                            value: '${announcement.playersNeeded}',
                            label: 'Needed',
                            color: kPrimary,
                          ),
                          const SizedBox(width: 8),
                          _AnnouncementStat(
                            icon: Icons.check_circle_outline_rounded,
                            value: '${announcement.acceptedCount}',
                            label: 'Joined',
                            color: kGreen,
                          ),
                          const SizedBox(width: 8),
                          _AnnouncementStat(
                            icon: Icons.hourglass_top_rounded,
                            value: '$spotsLeft',
                            label: 'Left',
                            color: kAmber,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Upcoming Bookings with status-aware cancel button ─────────────────────
  Widget _buildUpcomingBookings() {
    return Column(
      children: _upcomingBookings.map((booking) {
        var imageUrl = booking.courtImageUrl;
        if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
          imageUrl = ApiConstants.getFullImageUrl(imageUrl);
        }
        final status = switch (booking.status) {
          'confirmed' => ReservationStatus.confirmed,
          'rejected' || 'cancelled' => ReservationStatus.cancelled,
          _ => ReservationStatus.pending,
        };
        final statusLabel = switch (booking.status) {
          'cancel_requested' => 'Cancellation requested',
          'rejected' => 'Rejected',
          'confirmed' => 'Confirmed',
          _ => 'Pending',
        };
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
          child: AppCard(
            padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
            onTap: () => _showBookingDetailDialog(booking),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: imageUrl.isEmpty
                        ? ColoredBox(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.stadium_rounded,
                              color: theme.colorScheme.secondary,
                            ),
                          )
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => ColoredBox(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.stadium_rounded,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.courtName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        booking.venueName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        '${booking.date} · ${booking.time}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        '${booking.price} DT · ${booking.reference}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      ReservationStatusBadge(
                        status: status,
                        label: statusLabel,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showBookingDetailDialog(LocalBooking booking) {
    final status = booking.status;
    final isCancelReq = status == 'cancel_requested';
    final canCancel = ['pending', 'confirmed'].contains(status);
    final isConfirmed = status == 'confirmed';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          booking.courtName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(Icons.location_on_rounded, 'Venue', booking.venueName),
            const SizedBox(height: 8),
            _InfoRow(Icons.calendar_today_rounded, 'Date', booking.date),
            const SizedBox(height: 8),
            _InfoRow(Icons.access_time_rounded, 'Time', booking.time),
            const SizedBox(height: 8),
            _InfoRow(
              Icons.attach_money_rounded,
              'Price',
              '${booking.price} DT',
            ),
            const SizedBox(height: 8),
            _InfoRow(
              Icons.receipt_long_rounded,
              'Reference',
              booking.reference,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              Icons.info_outline_rounded,
              'Status',
              _statusLabel(status),
              valueColor: _statusColor(status),
            ),
            if (isCancelReq) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Cancellation is pending worker/manager approval. You will be notified.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          if (isConfirmed)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _postAnnouncementFromBooking(booking);
              },
              icon: const Icon(Icons.campaign_rounded, size: 16),
              label: const Text('Post Announcement'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          if (canCancel)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _requestCancelReservation(booking);
              },
              icon: const Icon(Icons.cancel_outlined, size: 16),
              label: const Text('Request Cancellation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmed';
      case 'cancel_requested':
        return 'Cancel Requested';
      case 'cancelled':
        return 'Cancelled';
      case 'completed':
        return 'Completed';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return kGreen;
      case 'cancel_requested':
        return Colors.orange;
      case 'cancelled':
        return kRed;
      case 'completed':
        return Colors.blue;
      case 'rejected':
        return kRed;
      default:
        return kAmber;
    }
  }
}

//
// CANCEL REASON DIALOG
//
class _CancelReasonDialog extends StatefulWidget {
  final String courtName;
  const _CancelReasonDialog({required this.courtName});
  @override
  State<_CancelReasonDialog> createState() => _CancelReasonDialogState();
}

class _CancelReasonDialogState extends State<_CancelReasonDialog> {
  final _ctrl = TextEditingController();
  String _selected = '';
  bool _otherMode = false;

  static const _quickReasons = [
    'Change of plans',
    'Bad weather',
    'Injury / health issue',
    'Found another venue',
    'Work / schedule conflict',
    'Other…',
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _pickReason(String r) {
    setState(() {
      if (r == 'Other…') {
        _otherMode = true;
        _selected = '';
      } else {
        _otherMode = false;
        _selected = r;
      }
    });
  }

  bool get _canConfirm =>
      _otherMode ? _ctrl.text.trim().isNotEmpty : _selected.isNotEmpty;

  String get _finalReason => _otherMode ? _ctrl.text.trim() : _selected;

  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
    contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
    actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: kRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.cancel_outlined, color: kRed, size: 18),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Request Cancellation',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          widget.courtName,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
    content: SizedBox(
      width: double.maxFinite,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            const Text(
              'Why do you want to cancel?',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0D0D0D),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickReasons.map((r) {
                final isOtherSel = r == 'Other…' && _otherMode;
                final isSel = _selected == r || isOtherSel;
                return GestureDetector(
                  onTap: () => _pickReason(r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isSel ? kRed : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSel ? kRed : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      r,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSel ? Colors.white : Colors.grey[700],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_otherMode) ...[
              const SizedBox(height: 12),
              StatefulBuilder(
                builder: (_, setInner) => TextField(
                  controller: _ctrl,
                  maxLines: 3,
                  minLines: 2,
                  onChanged: (_) {
                    setInner(() {});
                    setState(() {});
                  },
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Describe your reason…',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kRed, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 4),
          ],
        ),
      ),
    ),
    actions: [
      Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => Navigator.pop(context, null),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              child: const Text(
                'Back',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: _canConfirm
                  ? () => Navigator.pop(context, _finalReason)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: kRed,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade200,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Send Request',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

//
// POST ANNOUNCEMENT SHEET
//
class _PostAnnouncementSheet extends StatefulWidget {
  final LocalBooking booking;
  final String playerToken;
  final VoidCallback onPosted;

  const _PostAnnouncementSheet({
    required this.booking,
    required this.playerToken,
    required this.onPosted,
  });

  @override
  State<_PostAnnouncementSheet> createState() => _PostAnnouncementSheetState();
}

class _PostAnnouncementSheetState extends State<_PostAnnouncementSheet> {
  int _playersNeeded = 2;
  final TextEditingController _descCtrl = TextEditingController();
  bool _posting = false;
  late AnnouncementService _announcementService;

  @override
  void initState() {
    super.initState();
    _announcementService = AnnouncementService(token: widget.playerToken);
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    if (_descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a description'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _posting = true);

    try {
      final announcement = await _announcementService.create(
        reservationId: widget.booking.id,
        description: _descCtrl.text.trim(),
        playersNeeded: _playersNeeded,
      );

      if (!mounted) return;

      widget.onPosted();
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.campaign_rounded, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text(
                'Announcement posted!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: kPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      AppLogger.error('Error posting announcement: $e');
      setState(() => _posting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to post announcement: $e'),
          backgroundColor: kRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bot = MediaQuery.of(context).padding.bottom;
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.5,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFC5C9D4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.campaign_rounded,
                      color: kPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Make an Announcement',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: kTextDark,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Find teammates for your session',
                          style: TextStyle(fontSize: 12, color: kTextMid),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              color: const Color(0xFFE8EDF3),
            ),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: EdgeInsets.fromLTRB(20, 18, 20, bot + 20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kPrimary.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.sports_soccer_rounded,
                          size: 16,
                          color: kPrimary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${widget.booking.courtName}  ·  ${widget.booking.date}  ·  ${widget.booking.time}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: kTextDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Players needed',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: kTextDark,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'How many more players to join?',
                              style: TextStyle(fontSize: 11, color: kTextMid),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F4F7),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE8EDF3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (_playersNeeded > 1)
                                  setState(() => _playersNeeded--);
                              },
                              child: SizedBox(
                                width: 40,
                                height: 40,
                                child: Icon(
                                  Icons.remove_rounded,
                                  size: 16,
                                  color: _playersNeeded > 1
                                      ? kPrimary
                                      : kTextLight,
                                ),
                              ),
                            ),
                            Text(
                              '$_playersNeeded',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: kTextDark,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                if (_playersNeeded < 20)
                                  setState(() => _playersNeeded++);
                              },
                              child: SizedBox(
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.add_rounded,
                                  size: 16,
                                  color: kPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: kTextDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE8EDF3)),
                    ),
                    child: TextField(
                      controller: _descCtrl,
                      maxLines: 4,
                      minLines: 4,
                      style: const TextStyle(
                        fontSize: 14,
                        color: kTextDark,
                        height: 1.5,
                      ),
                      decoration: const InputDecoration(
                        hintText:
                            'e.g. Friendly match, intermediate level. All welcome!',
                        hintStyle: TextStyle(color: kTextLight, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  GestureDetector(
                    onTap: _posting ? null : _post,
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: kPrimary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: kPrimary.withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _posting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.campaign_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Post Announcement',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
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
  }
}

//
// ANNOUNCEMENT DETAIL SHEET
//
class _AnnouncementDetailSheet extends StatelessWidget {
  final PlayerAnnouncement announcement;
  final VoidCallback onDelete;

  const _AnnouncementDetailSheet({
    required this.announcement,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final spotsLeft = announcement.spotsLeft;
    final statusColor = spotsLeft > 0
        ? (theme.brightness == Brightness.dark
              ? NightMatchColors.success
              : NightMatchColors.lightSuccess)
        : scheme.error;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Padding(
              padding: EdgeInsets.only(top: 12),
              child: SizedBox(
                width: 40,
                height: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.outline,
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                  ),
                ),
              ),
            ),
          ),
          if (announcement.courtImageUrl != null &&
              announcement.courtImageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: Image.network(
                announcement.courtImageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 180,
                  color: scheme.surfaceContainerHighest,
                  child: const Icon(
                    Icons.stadium_rounded,
                    size: 60,
                    color: NightMatchColors.actionLime,
                  ),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 180,
                    color: scheme.surfaceContainerHighest,
                    child: Center(
                      child: CircularProgressIndicator(color: scheme.secondary),
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        announcement.courtName,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        spotsLeft > 0 ? '$spotsLeft spots left' : 'Full',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      announcement.venueName,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(announcement.date, style: theme.textTheme.bodyMedium),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${announcement.startTime} - ${announcement.endTime}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: scheme.outlineVariant),
                const SizedBox(height: 16),
                Text('Description', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Text(
                  announcement.description,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _DetailStat(
                        icon: Icons.people_rounded,
                        value: '${announcement.playersNeeded}',
                        label: 'Players Needed',
                        color: scheme.secondary,
                      ),
                    ),
                    Expanded(
                      child: _DetailStat(
                        icon: Icons.check_circle_outline_rounded,
                        value: '${announcement.acceptedCount}',
                        label: 'Joined',
                        color: theme.brightness == Brightness.dark
                            ? NightMatchColors.success
                            : NightMatchColors.lightSuccess,
                      ),
                    ),
                    Expanded(
                      child: _DetailStat(
                        icon: Icons.hourglass_top_rounded,
                        value: '$spotsLeft',
                        label: 'Spots Left',
                        color: NightMatchColors.actionLime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: scheme.errorContainer,
                      borderRadius: BorderRadius.circular(AppRadius.input),
                      border: Border.all(color: scheme.error),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_outline_rounded, color: scheme.error),
                        SizedBox(width: 8),
                        Text(
                          'Delete Announcement',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: scheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//
// ANNOUNCEMENT STAT
//
class _AnnouncementStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _AnnouncementStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(width: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: kTextMid)),
        ],
      ),
    );
  }
}

//
// DETAIL STAT
//
class _DetailStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _DetailStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.input),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

//
// INFO ROW
//
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color? valueColor;
  const _InfoRow(this.icon, this.label, this.value, {this.valueColor});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16, color: Colors.grey[500]),
      const SizedBox(width: 8),
      SizedBox(
        width: 70,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: kTextMid,
          ),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: valueColor ?? kTextDark,
          ),
        ),
      ),
    ],
  );
}
