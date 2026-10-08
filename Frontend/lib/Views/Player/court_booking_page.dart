// Views/Player/court_booking_page.dart



import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Core/Constants/api_constants.dart';
import 'package:sporta/Models/app_enums.dart';
import 'package:sporta/Models/app_models.dart' as AppModels;
import 'package:sporta/Models/venue_model.dart';
import 'package:sporta/Models/court_model.dart';
import 'package:sporta/Views/Player/court_detail.dart';
import 'package:sporta/Services/rating_service.dart';
import 'package:sporta/Widgets/rating_dialog.dart';
import 'package:sporta/Widgets/star_rating.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PALETTE
// ─────────────────────────────────────────────────────────────────────────────
const _bg        = Color(0xFFF2F4F7);
const _white     = Colors.white;
const _ink       = Color(0xFF0A0E1A);
const _textMid   = Color(0xFF64748B);
const _textLight = Color(0xFFB0B7C3);
const _border    = Color(0xFFE8EDF3);
const _kGreen    = Color(0xFF16A34A);
const _kRed      = Color(0xFFDC2626);
const _cardShadow = Color(0x14000000);

// ─────────────────────────────────────────────────────────────────────────────
// HELPER: Build absolute URL from any Strapi media value
// Handles all 4 shapes the backend can return:
//   1. Already-absolute  "http://..."
//   2. Relative path     "/uploads/..."
//   3. Nested object     { "url": "/uploads/..." }
//   4. pre-built string  court_img_url / photos_urls[0]
// ─────────────────────────────────────────────────────────────────────────────
String _absUrl(dynamic raw) {
  if (raw == null) return '';
  String path = '';

  if (raw is String) {
    path = raw;
  } else if (raw is Map) {
    path = raw['url']?.toString() ?? '';
  }

  if (path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  // Use ApiConstants.mediaBaseUrl to stay consistent with the rest of the app
  return '${ApiConstants.mediaBaseUrl}$path';
}

/// Extract the best single image URL from a raw court Map.
/// Priority: court_img_url → court_img → photos_urls[0] → photos[0]
String _courtImageUrl(Map<String, dynamic> c) {
  // 1. Pre-built string from backend service transform
  final prebuilt = c['court_img_url']?.toString() ?? '';
  if (prebuilt.isNotEmpty) return _absUrl(prebuilt);

  // 2. Nested media object { id, url, ... }
  final courtImg = c['court_img'];
  if (courtImg != null) {
    final url = _absUrl(courtImg);
    if (url.isNotEmpty) return url;
  }

  // 3. Pre-built photos_urls list
  final photosUrls = c['photos_urls'];
  if (photosUrls is List && photosUrls.isNotEmpty) {
    final url = _absUrl(photosUrls.first);
    if (url.isNotEmpty) return url;
  }

  // 4. Nested photos array [{ url, ... }, ...]
  final photos = c['photos'];
  if (photos is List && photos.isNotEmpty) {
    final url = _absUrl(photos.first);
    if (url.isNotEmpty) return url;
  }

  // 5. Legacy field
  return _absUrl(c['imageUrl']);
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────────────────────
class CourtBookingPage extends StatefulWidget {
  final VenueModel venue;
  final String? playerToken;
  const CourtBookingPage({super.key, required this.venue, this.playerToken});

  @override
  State<CourtBookingPage> createState() => _CourtBookingPageState();
}

class _CourtBookingPageState extends State<CourtBookingPage>
    with SingleTickerProviderStateMixin {
  String? _filterSport;
  late final AnimationController _heroCtrl;
  late final Animation<double> _heroFade;

  double? _userRating;
  bool _isLoadingRating  = false;
  bool _isSubmittingRating = false;

  @override
  void initState() {
    super.initState();
    _heroCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _heroFade = CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut);
    _heroCtrl.forward();
    _loadUserRating();
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    super.dispose();
  }

  // ── Rating helpers ──────────────────────────────────────────────────────────

  Future<void> _loadUserRating() async {
    if (widget.playerToken == null) return;
    setState(() => _isLoadingRating = true);
    try {
      final svc    = RatingService(token: widget.playerToken!);
      final result = await svc.getUserRating(widget.venue.id);
      if (result != null && result['rating'] != null) {
        setState(() => _userRating = (result['rating']['rating_value'] as num?)?.toDouble());
      }
    } catch (e) {
      debugPrint('_loadUserRating: $e');
    } finally {
      if (mounted) setState(() => _isLoadingRating = false);
    }
  }

  Future<void> _submitRating(double value) async {
    if (widget.playerToken == null) { _snack('Please login to rate this venue', _kRed); return; }
    setState(() => _isSubmittingRating = true);
    try {
      final svc    = RatingService(token: widget.playerToken!);
      final result = await svc.submitRating(venueId: int.parse(widget.venue.id), ratingValue: value);
      if (result['success'] == true) {
        setState(() => _userRating = value);
        _snack(result['message']?.toString() ?? 'Rating submitted', _kGreen);
      }
    } catch (e) {
      _snack(e.toString().replaceAll('Exception:', ''), _kRed);
    } finally {
      if (mounted) setState(() => _isSubmittingRating = false);
    }
  }

  Future<void> _deleteRating() async {
    if (widget.playerToken == null || _userRating == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Rating'),
        content: const Text('Are you sure you want to delete your rating?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _kRed, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _isSubmittingRating = true);
    try {
      final svc    = RatingService(token: widget.playerToken!);
      final result = await svc.getUserRating(widget.venue.id);
      if (result != null && result['rating'] != null) {
        await svc.deleteRating(result['rating']['id'].toString());
        setState(() => _userRating = null);
        _snack('Rating deleted', _kGreen);
      }
    } catch (e) {
      _snack(e.toString().replaceAll('Exception:', ''), _kRed);
    } finally {
      if (mounted) setState(() => _isSubmittingRating = false);
    }
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (_) => RatingDialog(
        venueName: widget.venue.name,
        existingRating: _userRating,
        isLoading: _isSubmittingRating,
      ),
    ).then((result) {
      if (result != null && result['rating'] != null) _submitRating(result['rating'] as double);
    });
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ── Sport helpers ────────────────────────────────────────────────────────────

  SportType _mapSport(String s) {
    switch (s.toLowerCase()) {
      case 'padel':      return SportType.padel;
      case 'tennis':     return SportType.tennis;
      case 'basketball': return SportType.basketball;
      default:           return SportType.football;
    }
  }

  IconData _sportIcon(String s) {
    switch (s.toLowerCase()) {
      case 'padel':      return Icons.sports_tennis_rounded;
      case 'tennis':     return Icons.sports_tennis;
      case 'basketball': return Icons.sports_basketball_rounded;
      default:           return Icons.sports_soccer_rounded;
    }
  }

  List<String> get _sports {
    final seen = <String>{};
    for (final c in widget.venue.courts) {
      final s = (c['sport'] ?? c['sports'] ?? '').toString();
      if (s.isNotEmpty) seen.add(s);
    }
    return seen.toList();
  }

  List<Map<String, dynamic>> get _filtered {
    final all  = widget.venue.courts;
    final list = _filterSport == null
        ? all
        : all.where((c) {
            final s = (c['sport'] ?? c['sports'] ?? '').toString();
            return s == _filterSport;
          }).toList();
    return [
      ...list.where((c) => c['available'] == true || c['isActive'] == true),
      ...list.where((c) => c['available'] != true && c['isActive'] != true),
    ];
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final navH = kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: Column(children: [
          _VenueHero(venue: widget.venue, fadeAnim: _heroFade),
          Expanded(child: ListView(
            padding: EdgeInsets.fromLTRB(20, 20, 20, navH + 40),
            children: [
              // ── About ───────────────────────────────────────────────────────
              if (widget.venue.description.isNotEmpty) ...[
                const _SectionHeader('About this venue', Icons.info_outline_rounded),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _white, borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
                  ),
                  child: Text(widget.venue.description, style: const TextStyle(fontSize: 14, color: _textMid, height: 1.5)),
                ),
                const SizedBox(height: 24),
              ],

              // ── Rating ──────────────────────────────────────────────────────
              const _SectionHeader('Rating & Reviews', Icons.star_rate_rounded),
              const SizedBox(height: 10),
              _RatingCard(
                avgRating: widget.venue.avgRating,
                totalRatings: widget.venue.totalRatings,
                userRating: _userRating,
                isLoading: _isLoadingRating,
                isSubmitting: _isSubmittingRating,
                onRateTap: _showRatingDialog,
                onDeleteTap: _userRating != null ? _deleteRating : null,
              ),
              const SizedBox(height: 24),

              // ── Manager ─────────────────────────────────────────────────────
              const _SectionHeader('Venue Manager', Icons.person_outline_rounded),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _white, borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: Row(children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(25)),
                    child: Center(child: Text(widget.venue.managerAvatar,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kPrimary))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.venue.managerName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.phone_rounded, size: 14, color: _textMid),
                      const SizedBox(width: 6),
                      Text(widget.venue.managerPhone, style: const TextStyle(fontSize: 13, color: _textMid)),
                    ]),
                  ])),
                ]),
              ),
              const SizedBox(height: 28),

              // ── Courts header ───────────────────────────────────────────────
              _buildCourtsHeader(),
              const SizedBox(height: 14),

              // ── Sport filter ────────────────────────────────────────────────
              if (_sports.length > 1) ...[
                _SportFilterRow(
                  sports: _sports, selected: _filterSport,
                  sportIcon: _sportIcon,
                  onSelect: (s) => setState(() => _filterSport = s),
                ),
                const SizedBox(height: 16),
              ],

              // ── Court cards ─────────────────────────────────────────────────
              ..._buildCourtCards(),
            ],
          )),
        ]),
      ),
    );
  }

  Widget _buildCourtsHeader() => Row(children: [
    Container(width: 4, height: 22, decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 10),
    const Text('Available Courts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.3)),
    const Spacer(),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: kPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
      child: Text(
        '${_filtered.where((c) => c['available'] == true || c['isActive'] == true).length} open',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kPrimary),
      ),
    ),
  ]);

  List<Widget> _buildCourtCards() {
    final courts = _filtered;
    if (courts.isEmpty) return [_EmptyState(sport: _filterSport)];

    return courts.map((c) {
      // ── Sport ────────────────────────────────────────────────────────────────
      final sportStr  = (c['sport'] ?? c['sports'] ?? 'football').toString();
      final sportType = _mapSport(sportStr);
      final sportColor = sportType.color;

      // ── Availability ─────────────────────────────────────────────────────────
      final available = c['available'] == true || c['isActive'] == true;

      // ── Image ────────────────────────────────────────────────────────────────
      // _courtImageUrl() handles every possible shape Strapi returns
      final imageUrl = _courtImageUrl(c);

      // ── Price / capacity ─────────────────────────────────────────────────────
      final price    = (c['pricePerHour'] ?? c['price'] ?? 0 as num).toDouble();
      final capacity = (c['capacity'] ?? 0) as int;

      // ── CourtModel for navigation ────────────────────────────────────────────
      final courtModel = CourtModel(
        id:           int.tryParse(c['id']?.toString() ?? '0') ?? 0,
        name:         (c['name'] ?? c['courtName'] ?? '').toString(),
        sport:        sportStr,
        pricePerHour: price,
        capacity:     capacity,
        isActive:     available,
        venueId:      int.tryParse(widget.venue.id) ?? 0,
        courtImgUrl:  imageUrl.isNotEmpty ? imageUrl : null,
      );

      // ── Old model for CourtDetailPage ─────────────────────────────────────────
      final oldModel = AppModels.CourtModel(
        id:           courtModel.id.toString(),
        name:         courtModel.name,
        sport:        sportType,
        pricePerHour: price,
        color:        sportColor,
        imageUrl:     imageUrl,
        isActive:     available,
      );

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _CourtCard(
          court:       courtModel,
          courtRaw:    c,
          venue:       widget.venue,
          playerToken: widget.playerToken,
          oldModel:    oldModel,
          imageUrl:    imageUrl,
          sportType:   sportType,
          available:   available,
        ),
      );
    }).toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COURT CARD  — displays court_img correctly
// ─────────────────────────────────────────────────────────────────────────────
class _CourtCard extends StatelessWidget {
  final CourtModel court;
  final Map<String, dynamic> courtRaw;
  final VenueModel venue;
  final String? playerToken;
  final AppModels.CourtModel oldModel;
  final String imageUrl;
  final SportType sportType;
  final bool available;

  const _CourtCard({
    required this.court,
    required this.courtRaw,
    required this.venue,
    required this.playerToken,
    required this.oldModel,
    required this.imageUrl,
    required this.sportType,
    required this.available,
  });

  @override
  Widget build(BuildContext context) {
    final sportColor = sportType.color;

    return GestureDetector(
      onTap: available
          ? () => Navigator.push(context, _slideUp(CourtDetailPage(
                court:       oldModel,
                venue:       venue,
                courtRaw:    courtRaw,
                playerToken: playerToken,
              )))
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: _cardShadow, blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Court image ────────────────────────────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: SizedBox(
              width: double.infinity,
              height: 150,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      // Show sport-colored shimmer while loading
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: sportColor.withOpacity(0.06),
                          child: Center(child: SizedBox(
                            width: 26, height: 26,
                            child: CircularProgressIndicator(
                              strokeWidth: 2, color: sportColor,
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                  : null,
                            ),
                          )),
                        );
                      },
                      errorBuilder: (_, __, ___) => _imgFallback(sportType, sportColor),
                    )
                  : _imgFallback(sportType, sportColor),
            ),
          ),

          // ── Card body ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Name + availability badge
              Row(children: [
                Expanded(child: Text(court.name,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ink))),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (available ? _kGreen : _kRed).withOpacity(0.09),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: (available ? _kGreen : _kRed).withOpacity(0.25)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 5, height: 5,
                        decoration: BoxDecoration(color: available ? _kGreen : _kRed, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text(available ? 'Available' : 'Full',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                            color: available ? _kGreen : _kRed)),
                  ]),
                ),
              ]),
              const SizedBox(height: 5),

              // Sport
              Row(children: [
                Icon(sportType.icon, size: 12, color: sportColor),
                const SizedBox(width: 5),
                Text(sportType.label, style: TextStyle(fontSize: 12, color: sportColor, fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                if (court.capacity > 0) ...[
                  const Icon(Icons.people_outline_rounded, size: 12, color: _textMid),
                  const SizedBox(width: 4),
                  Text('${court.capacity} players', style: const TextStyle(fontSize: 11, color: _textMid)),
                ],
              ]),

              // Amenities chips
              if (venue.amenities.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(spacing: 5, runSpacing: 4,
                  children: venue.amenities.take(3).map((a) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFF0F2F5), borderRadius: BorderRadius.circular(6)),
                    child: Text(a, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: _textMid)),
                  )).toList(),
                ),
              ],
              const SizedBox(height: 12),

              // Price + action
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('From', style: TextStyle(fontSize: 10, color: _textMid)),
                  Text('${court.pricePerHour.toInt()} DT/hr',
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: kPrimary)),
                ]),
                available
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                        decoration: BoxDecoration(
                          color: kPrimary, borderRadius: BorderRadius.circular(13),
                          boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.28), blurRadius: 8, offset: const Offset(0, 3))],
                        ),
                        child: const Text('Book Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                        decoration: BoxDecoration(color: const Color(0xFFEEEFF2), borderRadius: BorderRadius.circular(13)),
                        child: const Text('Unavailable', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textMid)),
                      ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _imgFallback(SportType st, Color color) => Container(
    color: color.withOpacity(0.07),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(st.icon, size: 44, color: color.withOpacity(0.45)),
      const SizedBox(height: 6),
      Text(st.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color.withOpacity(0.6))),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Everything below is unchanged from original
// ─────────────────────────────────────────────────────────────────────────────

class _RatingCard extends StatelessWidget {
  final double avgRating;
  final int totalRatings;
  final double? userRating;
  final bool isLoading;
  final bool isSubmitting;
  final VoidCallback onRateTap;
  final VoidCallback? onDeleteTap;

  const _RatingCard({
    required this.avgRating, required this.totalRatings, required this.userRating,
    required this.isLoading, required this.isSubmitting,
    required this.onRateTap, this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _white, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
    ),
    child: isLoading
        ? const Center(child: SizedBox(height: 40, width: 40, child: CircularProgressIndicator(strokeWidth: 2)))
        : Column(children: [
            Row(children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(30)),
                child: Center(child: Text(avgRating.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimary))),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                StarRating(rating: avgRating, size: 16),
                const SizedBox(height: 4),
                Text('$totalRatings ${totalRatings == 1 ? 'rating' : 'ratings'}',
                    style: const TextStyle(fontSize: 12, color: _textMid)),
              ])),
            ]),
            const SizedBox(height: 16),
            Divider(color: _border),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(userRating != null ? 'Your rating' : 'Rate this venue',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ink)),
              Row(children: [
                if (userRating != null) ...[
                  StarRating(rating: userRating!, size: 18, interactive: false),
                  const SizedBox(width: 8),
                  Text(userRating!.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kPrimary)),
                  if (onDeleteTap != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: isSubmitting ? null : onDeleteTap,
                      child: Icon(Icons.delete_outline_rounded, size: 18,
                          color: isSubmitting ? _textLight : _kRed),
                    ),
                  ],
                ],
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isSubmitting ? null : onRateTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: userRating != null ? Colors.amber.shade600 : kPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(userRating != null ? 'Edit' : 'Rate',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ]),
            ]),
            if (isSubmitting)
              const Padding(padding: EdgeInsets.only(top: 12),
                  child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))),
          ]),
  );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader(this.title, this.icon);

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 32, height: 32,
      decoration: BoxDecoration(color: kPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(9)),
      child: Icon(icon, size: 14, color: kPrimary),
    ),
    const SizedBox(width: 10),
    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.2)),
  ]);
}

class _VenueHero extends StatelessWidget {
  final VenueModel venue;
  final Animation<double> fadeAnim;
  const _VenueHero({required this.venue, required this.fadeAnim});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 260, width: double.infinity,
    child: Stack(fit: StackFit.expand, children: [
      FadeTransition(
        opacity: fadeAnim,
        child: venue.image.isNotEmpty
            ? Image.network(venue.image, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback())
            : _fallback(),
      ),
      Container(decoration: const BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0x22000000), Color(0xEE0A0E1A)], stops: [0.3, 1.0],
      ))),
      Positioned(top: 0, left: 0, right: 0,
        child: SafeArea(bottom: false, child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35), shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 15),
              ),
            ),
          ]),
        )),
      ),
      Positioned(bottom: 18, left: 20, right: 20,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          if (venue.sports.isNotEmpty)
            Wrap(spacing: 6, children: venue.sports.take(3).map((s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: kPrimary.withOpacity(0.85), borderRadius: BorderRadius.circular(20)),
              child: Text(s, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
            )).toList()),
          const SizedBox(height: 8),
          Text(venue.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5, height: 1.1)),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.location_on_rounded, size: 12, color: Colors.white70),
            const SizedBox(width: 4),
            Expanded(child: Text(venue.location, style: const TextStyle(fontSize: 12, color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            const Icon(Icons.schedule_rounded, size: 12, color: Colors.white70),
            const SizedBox(width: 4),
            Text('Until ${venue.openUntil}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ]),
        ])),
      Positioned(top: 80, right: 16, child: _VenueStatusBadge(venue.available)),
    ]),
  );

  Widget _fallback() => Container(
    decoration: BoxDecoration(gradient: LinearGradient(
      colors: [kPrimary.withOpacity(0.6), kPrimary],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
    )),
    child: const Icon(Icons.stadium_rounded, size: 56, color: Colors.white24),
  );
}

class _SportFilterRow extends StatelessWidget {
  final List<String> sports;
  final String? selected;
  final IconData Function(String) sportIcon;
  final ValueChanged<String?> onSelect;
  const _SportFilterRow({required this.sports, required this.selected, required this.sportIcon, required this.onSelect});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 36,
    child: ListView(scrollDirection: Axis.horizontal, children: [
      _SportChip(label: 'All', icon: Icons.grid_view_rounded, selected: selected == null, onTap: () => onSelect(null)),
      const SizedBox(width: 7),
      ...sports.map((s) => Padding(
        padding: const EdgeInsets.only(right: 7),
        child: _SportChip(label: s, icon: sportIcon(s), selected: selected == s, onTap: () => onSelect(s)),
      )),
    ]),
  );
}

class _SportChip extends StatelessWidget {
  final String label; final IconData icon; final bool selected; final VoidCallback onTap;
  const _SportChip({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? kPrimary : _white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? kPrimary : _border),
        boxShadow: selected
            ? [BoxShadow(color: kPrimary.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 2))]
            : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: selected ? Colors.white : _textMid),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: selected ? Colors.white : _textMid)),
      ]),
    ),
  );
}

class _VenueStatusBadge extends StatelessWidget {
  final bool isOpen;
  const _VenueStatusBadge(this.isOpen);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: isOpen ? _kGreen : _kRed,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: (isOpen ? _kGreen : _kRed).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 3))],
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(isOpen ? 'Open Now' : 'Closed', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
    ]),
  );
}

class _EmptyState extends StatelessWidget {
  final String? sport;
  const _EmptyState({this.sport});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 48),
    child: Column(children: [
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(color: _textLight.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: Icon(Icons.sports_rounded, size: 28, color: _textLight.withOpacity(0.5)),
      ),
      const SizedBox(height: 14),
      Text(sport != null ? 'No $sport courts available' : 'No courts listed',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _ink)),
      const SizedBox(height: 4),
      const Text('Try a different sport filter', style: TextStyle(fontSize: 12, color: _textMid)),
    ]),
  );
}

Route _slideUp(Widget page) => PageRouteBuilder(
  pageBuilder: (_, __, ___) => page,
  transitionsBuilder: (_, a, __, child) => SlideTransition(
    position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
    child: child,
  ),
  transitionDuration: const Duration(milliseconds: 340),
);









/*// Views/Player/court_booking_page.dart
// Redesigned: Added venue description, simplified manager section,
// Court cards redesigned to match screenshot (vertical layout)
// NEW: Added rating functionality

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Models/app_enums.dart';
import 'package:sporta/Models/app_models.dart';
import 'package:sporta/Models/venue_model.dart';
import 'package:sporta/Views/Player/court_detail.dart';
import 'package:sporta/Services/rating_service.dart';
import 'package:sporta/Widgets/rating_dialog.dart';
import 'package:sporta/Widgets/star_rating.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PALETTE
// ─────────────────────────────────────────────────────────────────────────────
const _bg        = Color(0xFFF2F4F7);
const _white     = Colors.white;
const _ink       = Color(0xFF0A0E1A);
const _textMid   = Color(0xFF64748B);
const _textLight = Color(0xFFB0B7C3);
const _border    = Color(0xFFE8EDF3);
const _kGreen    = Color(0xFF16A34A);
const _kRed      = Color(0xFFDC2626);
const _cardShadow = Color(0x14000000);

// ─────────────────────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────────────────────
class CourtBookingPage extends StatefulWidget {
  final VenueModel venue;
  final String? playerToken;
  const CourtBookingPage({super.key, required this.venue, this.playerToken});

  @override
  State<CourtBookingPage> createState() => _CourtBookingPageState();
}

class _CourtBookingPageState extends State<CourtBookingPage>
    with SingleTickerProviderStateMixin {
  String? _filterSport;
  late final AnimationController _heroCtrl;
  late final Animation<double> _heroFade;
  
  // Rating state
  double? _userRating;
  bool _isLoadingRating = false;
  bool _isSubmittingRating = false;

  @override
  void initState() {
    super.initState();
    _heroCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _heroFade = CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut);
    _heroCtrl.forward();
    _loadUserRating();
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserRating() async {
    if (widget.playerToken == null) return;
    
    setState(() {
      _isLoadingRating = true;
    });
    
    try {
      final ratingService = RatingService(token: widget.playerToken!);
      final result = await ratingService.getUserRating(widget.venue.id);
      
      if (result != null && result['rating'] != null) {
        setState(() {
          _userRating = (result['rating']['rating_value'] as num?)?.toDouble();
        });
      }
    } catch (e) {
      print('Error loading rating: $e');
    } finally {
      setState(() {
        _isLoadingRating = false;
      });
    }
  }

  Future<void> _submitRating(double ratingValue) async {
    if (widget.playerToken == null) {
      _showSnackBar('Please login to rate this venue', _kRed);
      return;
    }
    
    setState(() {
      _isSubmittingRating = true;
    });
    
    try {
      final ratingService = RatingService(token: widget.playerToken!);
      final result = await ratingService.submitRating(
        venueId: int.parse(widget.venue.id),
        ratingValue: ratingValue,
      );
      
      if (result['success']) {
        setState(() {
          _userRating = ratingValue;
          // Also update the venue object's average rating
          // This will be refreshed when the page is rebuilt
        });
        _showSnackBar(result['message'], _kGreen);
        
        // Refresh the page to show updated average
        // You can also emit an event to update parent widgets
      }
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception:', ''), _kRed);
    } finally {
      setState(() {
        _isSubmittingRating = false;
      });
    }
  }

  Future<void> _deleteRating() async {
    if (widget.playerToken == null || _userRating == null) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Rating'),
        content: const Text('Are you sure you want to delete your rating?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    setState(() {
      _isSubmittingRating = true;
    });
    
    try {
      // First get the rating ID
      final ratingService = RatingService(token: widget.playerToken!);
      final result = await ratingService.getUserRating(widget.venue.id);
      
      if (result != null && result['rating'] != null) {
        final ratingId = result['rating']['id'].toString();
        await ratingService.deleteRating(ratingId);
        
        setState(() {
          _userRating = null;
        });
        _showSnackBar('Rating deleted successfully', _kGreen);
      }
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception:', ''), _kRed);
    } finally {
      setState(() {
        _isSubmittingRating = false;
      });
    }
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (context) => RatingDialog(
        venueName: widget.venue.name,
        existingRating: _userRating,
        isLoading: _isSubmittingRating,
      ),
    ).then((result) {
      if (result != null && result['rating'] != null) {
        _submitRating(result['rating']);
      }
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  SportType _mapSport(String s) {
    switch (s.toLowerCase()) {
      case 'padel':      return SportType.padel;
      case 'tennis':     return SportType.tennis;
      case 'basketball': return SportType.basketball;
      default:           return SportType.football;
    }
  }

  IconData _sportIcon(String s) {
    switch (s.toLowerCase()) {
      case 'padel':      return Icons.sports_tennis_rounded;
      case 'tennis':     return Icons.sports_tennis;
      case 'basketball': return Icons.sports_basketball_rounded;
      case 'volleyball': return Icons.sports_volleyball_rounded;
      default:           return Icons.sports_soccer_rounded;
    }
  }

  List<String> get _sports {
    final seen = <String>{};
    for (final c in widget.venue.courts) {
      final s = c['sport']?.toString() ?? '';
      if (s.isNotEmpty) seen.add(s);
    }
    return seen.toList();
  }

  List<Map<String, dynamic>> get _filtered {
    final all = widget.venue.courts;
    final list = _filterSport == null
        ? all
        : all.where((c) => c['sport']?.toString() == _filterSport).toList();
    return [
      ...list.where((c) => c['available'] == true),
      ...list.where((c) => c['available'] != true),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final navH = kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: Column(
          children: [
            // Fixed-height hero
            _VenueHero(venue: widget.venue, fadeAnim: _heroFade),
            // Scrollable body
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(20, 20, 20, navH + 40),
                children: [
                  // ── Venue Description ──────────────────────────────────────
                  if (widget.venue.description.isNotEmpty) ...[
                    _SectionHeader('About this venue', Icons.info_outline_rounded),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
                      ),
                      child: Text(
                        widget.venue.description,
                        style: const TextStyle(fontSize: 14, color: _textMid, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Rating Section (NEW) ───────────────────────────────────
                  _SectionHeader('Rating & Reviews', Icons.star_rate_rounded),
                  const SizedBox(height: 10),
                  _RatingCard(
                    avgRating: widget.venue.avgRating,
                    totalRatings: widget.venue.totalRatings,
                    userRating: _userRating,
                    isLoading: _isLoadingRating,
                    isSubmitting: _isSubmittingRating,
                    onRateTap: _showRatingDialog,
                    onDeleteTap: _userRating != null ? _deleteRating : null,
                  ),
                  const SizedBox(height: 24),

                  // ── Venue Manager (simplified - only name and phone) ───────
                  _SectionHeader('Venue Manager', Icons.person_outline_rounded),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _border),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Center(
                            child: Text(
                              widget.venue.managerAvatar,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kPrimary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.venue.managerName,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ink),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.phone_rounded, size: 14, color: _textMid),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.venue.managerPhone,
                                    style: const TextStyle(fontSize: 13, color: _textMid),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Available Courts Header ────────────────────────────────
                  _buildCourtsHeader(),
                  const SizedBox(height: 14),
                  
                  // ── Sport Filter ───────────────────────────────────────────
                  if (_sports.length > 1) ...[
                    _SportFilterRow(
                      sports: _sports,
                      selected: _filterSport,
                      sportIcon: _sportIcon,
                      onSelect: (s) => setState(() => _filterSport = s),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // ── Court Cards (Redesigned - vertical layout) ──────────────
                  ..._buildCourtCards(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourtsHeader() => Row(children: [
    Container(
      width: 4, height: 22,
      decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(2)),
    ),
    const SizedBox(width: 10),
    const Text('Available Courts',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.3)),
    const Spacer(),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: kPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
      child: Text(
        '${_filtered.where((c) => c['available'] == true).length} open',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kPrimary),
      ),
    ),
  ]);

  List<Widget> _buildCourtCards() {
    final courts = _filtered;
    if (courts.isEmpty) return [_EmptyState(sport: _filterSport)];
    
    final List<Widget> cards = [];
    for (final c in courts) {
      final st = _mapSport(c['sport']?.toString() ?? '');
      final model = CourtModel(
        id: c['id']?.toString() ?? '${widget.venue.id}_${c['courtName']}',
        name: c['courtName']?.toString() ?? '',
        sport: st,
        pricePerHour: (c['price'] as num?)?.toDouble() ?? 0,
        color: st.color,
        imageUrl: c['imageUrl']?.toString(),
        isActive: c['available'] ?? true,
      );
      cards.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _CourtCard(
            court: model,
            courtRaw: c,
            venue: widget.venue,
            playerToken: widget.playerToken,
          ),
        ),
      );
    }
    return cards;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RATING CARD (NEW)
// ─────────────────────────────────────────────────────────────────────────────
class _RatingCard extends StatelessWidget {
  final double avgRating;
  final int totalRatings;
  final double? userRating;
  final bool isLoading;
  final bool isSubmitting;
  final VoidCallback onRateTap;
  final VoidCallback? onDeleteTap;

  const _RatingCard({
    required this.avgRating,
    required this.totalRatings,
    required this.userRating,
    required this.isLoading,
    required this.isSubmitting,
    required this.onRateTap,
    this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: isLoading
          ? const Center(
              child: SizedBox(
                height: 40,
                width: 40,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Column(
              children: [
                // Average rating display
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: kPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: Text(
                          avgRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: kPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StarRating(rating: avgRating, size: 16),
                          const SizedBox(height: 4),
                          Text(
                            '$totalRatings ${totalRatings == 1 ? 'rating' : 'ratings'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _textMid,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: _border),
                const SizedBox(height: 12),
                
                // User rating section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      userRating != null ? 'Your rating' : 'Rate this venue',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                      ),
                    ),
                    Row(
                      children: [
                        if (userRating != null) ...[
                          StarRating(
                            rating: userRating!,
                            size: 18,
                            interactive: false,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            userRating!.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: kPrimary,
                            ),
                          ),
                          if (onDeleteTap != null) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: isSubmitting ? null : onDeleteTap,
                              child: Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: isSubmitting ? _textLight : _kRed,
                              ),
                            ),
                          ],
                        ],
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: isSubmitting ? null : onRateTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: userRating != null ? Colors.amber.shade600 : kPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            userRating != null ? 'Edit' : 'Rate',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (isSubmitting)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader(this.title, this.icon);
  
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 32, height: 32,
      decoration: BoxDecoration(color: kPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(9)),
      child: Icon(icon, size: 14, color: kPrimary),
    ),
    const SizedBox(width: 10),
    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.2)),
  ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// VENUE HERO
// ─────────────────────────────────────────────────────────────────────────────
class _VenueHero extends StatelessWidget {
  final VenueModel venue;
  final Animation<double> fadeAnim;
  const _VenueHero({required this.venue, required this.fadeAnim});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      width: double.infinity,
      child: Stack(fit: StackFit.expand, children: [
        FadeTransition(
          opacity: fadeAnim,
          child: venue.image.isNotEmpty
              ? Image.network(venue.image, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallback())
              : _fallback(),
        ),
        Container(decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x22000000), Color(0xEE0A0E1A)],
            stops: [0.3, 1.0],
          ),
        )),
        Positioned(
          top: 0, left: 0, right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 15),
                  ),
                ),
              ]),
            ),
          ),
        ),
        Positioned(
          bottom: 18, left: 20, right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (venue.sports.isNotEmpty)
                Wrap(
                  spacing: 6,
                  children: venue.sports.take(3).map((s) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(s, style: const TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w800,
                        color: Colors.white, letterSpacing: 0.5)),
                  )).toList(),
                ),
              const SizedBox(height: 8),
              Text(venue.name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900,
                      color: Colors.white, letterSpacing: -0.5, height: 1.1)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.location_on_rounded, size: 12, color: Colors.white70),
                const SizedBox(width: 4),
                Expanded(child: Text(venue.location,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                const Icon(Icons.schedule_rounded, size: 12, color: Colors.white70),
                const SizedBox(width: 4),
                Text('Until ${venue.openUntil}',
                    style: const TextStyle(fontSize: 12, color: Colors.white70)),
              ]),
            ],
          ),
        ),
        Positioned(
          top: 80, right: 16,
          child: _VenueStatusBadge(venue.available),
        ),
      ]),
    );
  }

  Widget _fallback() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [kPrimary.withOpacity(0.6), kPrimary],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
    ),
    child: const Icon(Icons.stadium_rounded, size: 56, color: Colors.white24),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SPORT FILTER
// ─────────────────────────────────────────────────────────────────────────────
class _SportFilterRow extends StatelessWidget {
  final List<String> sports;
  final String? selected;
  final IconData Function(String) sportIcon;
  final ValueChanged<String?> onSelect;
  const _SportFilterRow({required this.sports, required this.selected, required this.sportIcon, required this.onSelect});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 36,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: [
        _SportChip(label: 'All', icon: Icons.grid_view_rounded, selected: selected == null, onTap: () => onSelect(null)),
        const SizedBox(width: 7),
        ...sports.map((s) => Padding(
          padding: const EdgeInsets.only(right: 7),
          child: _SportChip(label: s, icon: sportIcon(s), selected: selected == s, onTap: () => onSelect(s)),
        )),
      ],
    ),
  );
}

class _SportChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _SportChip({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? kPrimary : _white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? kPrimary : _border),
        boxShadow: selected
            ? [BoxShadow(color: kPrimary.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 2))]
            : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: selected ? Colors.white : _textMid),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
            color: selected ? Colors.white : _textMid)),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// REDESIGNED COURT CARD - Vertical layout like your screenshot
// ─────────────────────────────────────────────────────────────────────────────
class _CourtCard extends StatelessWidget {
  final CourtModel court;
  final Map<String, dynamic> courtRaw;
  final VenueModel venue;
  final String? playerToken;
  const _CourtCard({required this.court, required this.courtRaw, required this.venue, required this.playerToken});

  @override
  Widget build(BuildContext context) {
    final available = courtRaw['available'] == true;

    return GestureDetector(
      onTap: available
          ? () => Navigator.push(context, _slideUp(CourtDetailPage(
              court: court, venue: venue, courtRaw: courtRaw, playerToken: playerToken)))
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _cardShadow,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image - top
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                width: double.infinity,
                height: 140,
                child: court.imageUrl != null && court.imageUrl!.isNotEmpty
                    ? Image.network(
                        court.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: court.color.withOpacity(0.1),
                          child: Icon(court.sport.icon, size: 40, color: court.color),
                        ),
                      )
                    : Container(
                        color: court.color.withOpacity(0.1),
                        child: Icon(court.sport.icon, size: 40, color: court.color),
                      ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Court name
                  Text(
                    court.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Sport type with icon
                  Row(
                    children: [
                      Icon(court.sport.icon, size: 12, color: _textMid),
                      const SizedBox(width: 4),
                      Text(
                        court.sport.label,
                        style: const TextStyle(fontSize: 12, color: _textMid),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Amenities (Parking, etc.)
                  if (venue.amenities.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: venue.amenities.take(3).map((a) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          a,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                        ),
                      )).toList(),
                    ),
                  const SizedBox(height: 12),
                  
                  // Price and Book button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'From',
                            style: TextStyle(fontSize: 10, color: _textMid),
                          ),
                          Text(
                            '${court.pricePerHour.toInt()} DT/hr',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: kPrimary,
                            ),
                          ),
                        ],
                      ),
                      if (available)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: kPrimary,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: kPrimary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Book Now',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Full',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _textMid,
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VENUE STATUS BADGE
// ─────────────────────────────────────────────────────────────────────────────
class _VenueStatusBadge extends StatelessWidget {
  final bool isOpen;
  const _VenueStatusBadge(this.isOpen);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: isOpen ? _kGreen : _kRed,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(color: (isOpen ? _kGreen : _kRed).withOpacity(0.4),
            blurRadius: 12, offset: const Offset(0, 3))
      ],
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 6, height: 6,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(isOpen ? 'Open Now' : 'Closed',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String? sport;
  const _EmptyState({this.sport});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 48),
    child: Column(children: [
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
            color: _textLight.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: Icon(Icons.sports_rounded, size: 28, color: _textLight.withOpacity(0.5)),
      ),
      const SizedBox(height: 14),
      Text(sport != null ? 'No $sport courts available' : 'No courts listed',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _ink)),
      const SizedBox(height: 4),
      const Text('Try a different sport filter',
          style: TextStyle(fontSize: 12, color: _textMid)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// RATING DIALOG (Re-exported from widgets - make sure to import)
// ─────────────────────────────────────────────────────────────────────────────
// Note: RatingDialog is defined in lib/Widgets/rating_dialog.dart
// Make sure that file exists

// ─────────────────────────────────────────────────────────────────────────────
// ROUTE TRANSITION
// ─────────────────────────────────────────────────────────────────────────────
Route _slideUp(Widget page) => PageRouteBuilder(
  pageBuilder: (_, __, ___) => page,
  transitionsBuilder: (_, a, __, child) => SlideTransition(
    position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
    child: child,
  ),
  transitionDuration: const Duration(milliseconds: 340),
);






// Views/Player/court_booking_page.dart
// Redesigned: Added venue description, simplified manager section,
// Court cards redesigned to match screenshot (vertical layout)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Models/app_enums.dart';
import 'package:sporta/Models/app_models.dart';
import 'package:sporta/Models/venue_model.dart';
import 'package:sporta/Views/Player/court_detail.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PALETTE
// ─────────────────────────────────────────────────────────────────────────────
const _bg        = Color(0xFFF2F4F7);
const _white     = Colors.white;
const _ink       = Color(0xFF0A0E1A);
const _textMid   = Color(0xFF64748B);
const _textLight = Color(0xFFB0B7C3);
const _border    = Color(0xFFE8EDF3);
const _kGreen    = Color(0xFF16A34A);
const _kRed      = Color(0xFFDC2626);
const _cardShadow = Color(0x14000000);

// ─────────────────────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────────────────────
class CourtBookingPage extends StatefulWidget {
  final VenueModel venue;
  final String? playerToken;
  const CourtBookingPage({super.key, required this.venue, this.playerToken});

  @override
  State<CourtBookingPage> createState() => _CourtBookingPageState();
}

class _CourtBookingPageState extends State<CourtBookingPage>
    with SingleTickerProviderStateMixin {
  String? _filterSport;
  late final AnimationController _heroCtrl;
  late final Animation<double> _heroFade;

  @override
  void initState() {
    super.initState();
    _heroCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _heroFade = CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut);
    _heroCtrl.forward();
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    super.dispose();
  }

  SportType _mapSport(String s) {
    switch (s.toLowerCase()) {
      case 'padel':      return SportType.padel;
      case 'tennis':     return SportType.tennis;
      case 'basketball': return SportType.basketball;
      default:           return SportType.football;
    }
  }

  IconData _sportIcon(String s) {
    switch (s.toLowerCase()) {
      case 'padel':      return Icons.sports_tennis_rounded;
      case 'tennis':     return Icons.sports_tennis;
      case 'basketball': return Icons.sports_basketball_rounded;
      case 'volleyball': return Icons.sports_volleyball_rounded;
      default:           return Icons.sports_soccer_rounded;
    }
  }

  List<String> get _sports {
    final seen = <String>{};
    for (final c in widget.venue.courts) {
      final s = c['sport']?.toString() ?? '';
      if (s.isNotEmpty) seen.add(s);
    }
    return seen.toList();
  }

  List<Map<String, dynamic>> get _filtered {
    final all = widget.venue.courts;
    final list = _filterSport == null
        ? all
        : all.where((c) => c['sport']?.toString() == _filterSport).toList();
    return [
      ...list.where((c) => c['available'] == true),
      ...list.where((c) => c['available'] != true),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final navH = kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: Column(
          children: [
            // Fixed-height hero
            _VenueHero(venue: widget.venue, fadeAnim: _heroFade),
            // Scrollable body
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(20, 20, 20, navH + 40),
                children: [
                  // ── Venue Description ──────────────────────────────────────
                  if (widget.venue.description.isNotEmpty) ...[
                    _SectionHeader('About this venue', Icons.info_outline_rounded),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
                      ),
                      child: Text(
                        widget.venue.description,
                        style: const TextStyle(fontSize: 14, color: _textMid, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Venue Manager (simplified - only name and phone) ───────
                  _SectionHeader('Venue Manager', Icons.person_outline_rounded),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _border),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Center(
                            child: Text(
                              widget.venue.managerAvatar,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kPrimary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.venue.managerName,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ink),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.phone_rounded, size: 14, color: _textMid),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.venue.managerPhone,
                                    style: const TextStyle(fontSize: 13, color: _textMid),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Available Courts Header ────────────────────────────────
                  _buildCourtsHeader(),
                  const SizedBox(height: 14),
                  
                  // ── Sport Filter ───────────────────────────────────────────
                  if (_sports.length > 1) ...[
                    _SportFilterRow(
                      sports: _sports,
                      selected: _filterSport,
                      sportIcon: _sportIcon,
                      onSelect: (s) => setState(() => _filterSport = s),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // ── Court Cards (Redesigned - vertical layout) ──────────────
                  ..._buildCourtCards(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourtsHeader() => Row(children: [
    Container(
      width: 4, height: 22,
      decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(2)),
    ),
    const SizedBox(width: 10),
    const Text('Available Courts',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.3)),
    const Spacer(),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: kPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
      child: Text(
        '${_filtered.where((c) => c['available'] == true).length} open',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kPrimary),
      ),
    ),
  ]);

  List<Widget> _buildCourtCards() {
    final courts = _filtered;
    if (courts.isEmpty) return [_EmptyState(sport: _filterSport)];
    
    final List<Widget> cards = [];
    for (final c in courts) {
      final st = _mapSport(c['sport']?.toString() ?? '');
      final model = CourtModel(
        id: c['id']?.toString() ?? '${widget.venue.id}_${c['courtName']}',
        name: c['courtName']?.toString() ?? '',
        sport: st,
        pricePerHour: (c['price'] as num?)?.toDouble() ?? 0,
        color: st.color,
        imageUrl: c['imageUrl']?.toString(),
        isActive: c['available'] ?? true,
      );
      cards.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _CourtCard(
            court: model,
            courtRaw: c,
            venue: widget.venue,
            playerToken: widget.playerToken,
          ),
        ),
      );
    }
    return cards;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader(this.title, this.icon);
  
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 32, height: 32,
      decoration: BoxDecoration(color: kPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(9)),
      child: Icon(icon, size: 14, color: kPrimary),
    ),
    const SizedBox(width: 10),
    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.2)),
  ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// VENUE HERO
// ─────────────────────────────────────────────────────────────────────────────
class _VenueHero extends StatelessWidget {
  final VenueModel venue;
  final Animation<double> fadeAnim;
  const _VenueHero({required this.venue, required this.fadeAnim});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      width: double.infinity,
      child: Stack(fit: StackFit.expand, children: [
        FadeTransition(
          opacity: fadeAnim,
          child: venue.image.isNotEmpty
              ? Image.network(venue.image, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallback())
              : _fallback(),
        ),
        Container(decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x22000000), Color(0xEE0A0E1A)],
            stops: [0.3, 1.0],
          ),
        )),
        Positioned(
          top: 0, left: 0, right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 15),
                  ),
                ),
              ]),
            ),
          ),
        ),
        Positioned(
          bottom: 18, left: 20, right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (venue.sports.isNotEmpty)
                Wrap(
                  spacing: 6,
                  children: venue.sports.take(3).map((s) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(s, style: const TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w800,
                        color: Colors.white, letterSpacing: 0.5)),
                  )).toList(),
                ),
              const SizedBox(height: 8),
              Text(venue.name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900,
                      color: Colors.white, letterSpacing: -0.5, height: 1.1)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.location_on_rounded, size: 12, color: Colors.white70),
                const SizedBox(width: 4),
                Expanded(child: Text(venue.location,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                const Icon(Icons.schedule_rounded, size: 12, color: Colors.white70),
                const SizedBox(width: 4),
                Text('Until ${venue.openUntil}',
                    style: const TextStyle(fontSize: 12, color: Colors.white70)),
              ]),
            ],
          ),
        ),
        Positioned(
          top: 80, right: 16,
          child: _VenueStatusBadge(venue.available),
        ),
      ]),
    );
  }

  Widget _fallback() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [kPrimary.withOpacity(0.6), kPrimary],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
    ),
    child: const Icon(Icons.stadium_rounded, size: 56, color: Colors.white24),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SPORT FILTER
// ─────────────────────────────────────────────────────────────────────────────
class _SportFilterRow extends StatelessWidget {
  final List<String> sports;
  final String? selected;
  final IconData Function(String) sportIcon;
  final ValueChanged<String?> onSelect;
  const _SportFilterRow({required this.sports, required this.selected, required this.sportIcon, required this.onSelect});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 36,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: [
        _SportChip(label: 'All', icon: Icons.grid_view_rounded, selected: selected == null, onTap: () => onSelect(null)),
        const SizedBox(width: 7),
        ...sports.map((s) => Padding(
          padding: const EdgeInsets.only(right: 7),
          child: _SportChip(label: s, icon: sportIcon(s), selected: selected == s, onTap: () => onSelect(s)),
        )),
      ],
    ),
  );
}

class _SportChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _SportChip({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? kPrimary : _white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? kPrimary : _border),
        boxShadow: selected
            ? [BoxShadow(color: kPrimary.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 2))]
            : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: selected ? Colors.white : _textMid),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
            color: selected ? Colors.white : _textMid)),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// REDESIGNED COURT CARD - Vertical layout like your screenshot
// ─────────────────────────────────────────────────────────────────────────────
class _CourtCard extends StatelessWidget {
  final CourtModel court;
  final Map<String, dynamic> courtRaw;
  final VenueModel venue;
  final String? playerToken;
  const _CourtCard({required this.court, required this.courtRaw, required this.venue, required this.playerToken});

  @override
  Widget build(BuildContext context) {
    final available = courtRaw['available'] == true;

    return GestureDetector(
      onTap: available
          ? () => Navigator.push(context, _slideUp(CourtDetailPage(
              court: court, venue: venue, courtRaw: courtRaw, playerToken: playerToken)))
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _cardShadow,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image - top
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                width: double.infinity,
                height: 140,
                child: court.imageUrl != null && court.imageUrl!.isNotEmpty
                    ? Image.network(
                        court.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: court.color.withOpacity(0.1),
                          child: Icon(court.sport.icon, size: 40, color: court.color),
                        ),
                      )
                    : Container(
                        color: court.color.withOpacity(0.1),
                        child: Icon(court.sport.icon, size: 40, color: court.color),
                      ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Court name
                  Text(
                    court.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Sport type with icon
                  Row(
                    children: [
                      Icon(court.sport.icon, size: 12, color: _textMid),
                      const SizedBox(width: 4),
                      Text(
                        court.sport.label,
                        style: const TextStyle(fontSize: 12, color: _textMid),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Amenities (Parking, etc.)
                  if (venue.amenities.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: venue.amenities.take(3).map((a) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          a,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                        ),
                      )).toList(),
                    ),
                  const SizedBox(height: 12),
                  
                  // Price and Book button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'From',
                            style: TextStyle(fontSize: 10, color: _textMid),
                          ),
                          Text(
                            '${court.pricePerHour.toInt()} DT/hr',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: kPrimary,
                            ),
                          ),
                        ],
                      ),
                      if (available)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: kPrimary,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: kPrimary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Book Now',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Full',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _textMid,
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VENUE STATUS BADGE
// ─────────────────────────────────────────────────────────────────────────────
class _VenueStatusBadge extends StatelessWidget {
  final bool isOpen;
  const _VenueStatusBadge(this.isOpen);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: isOpen ? _kGreen : _kRed,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(color: (isOpen ? _kGreen : _kRed).withOpacity(0.4),
            blurRadius: 12, offset: const Offset(0, 3))
      ],
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 6, height: 6,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(isOpen ? 'Open Now' : 'Closed',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String? sport;
  const _EmptyState({this.sport});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 48),
    child: Column(children: [
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
            color: _textLight.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: Icon(Icons.sports_rounded, size: 28, color: _textLight.withOpacity(0.5)),
      ),
      const SizedBox(height: 14),
      Text(sport != null ? 'No $sport courts available' : 'No courts listed',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _ink)),
      const SizedBox(height: 4),
      const Text('Try a different sport filter',
          style: TextStyle(fontSize: 12, color: _textMid)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ROUTE TRANSITION
// ─────────────────────────────────────────────────────────────────────────────
Route _slideUp(Widget page) => PageRouteBuilder(
  pageBuilder: (_, __, ___) => page,
  transitionsBuilder: (_, a, __, child) => SlideTransition(
    position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
    child: child,
  ),
  transitionDuration: const Duration(milliseconds: 340),
);*/