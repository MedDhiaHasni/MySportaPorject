// Views/Player/court_booking_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sporta/Core/Constants/api_constants.dart';
import 'package:sporta/Core/Theme/app_tokens.dart';
import 'package:sporta/Models/app_enums.dart';
import 'package:sporta/Models/app_models.dart' as AppModels;
import 'package:sporta/Models/venue_model.dart';
import 'package:sporta/Models/court_model.dart';
import 'package:sporta/Views/Player/court_detail.dart';
import 'package:sporta/Services/rating_service.dart';
import 'package:sporta/Widgets/rating_dialog.dart';
import 'package:sporta/Widgets/star_rating.dart';
import 'package:sporta/Core/Utils/app_logger.dart';
import 'package:sporta/Widgets/feedback_components.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PALETTE
// ─────────────────────────────────────────────────────────────────────────────
const _kGreen = NightMatchColors.success;
const _kRed = NightMatchColors.lightError;

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

String _titleCaseDisplayName(String value) => value
    .trim()
    .split(RegExp(r'\s+'))
    .where((word) => word.isNotEmpty)
    .map(
      (word) => word.length == 1
          ? word.toUpperCase()
          : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
    )
    .join(' ');

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
  bool _isLoadingRating = false;
  bool _isSubmittingRating = false;

  @override
  void initState() {
    super.initState();
    _heroCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _heroFade = CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut);
    _heroCtrl.forward();
    _loadUserRating();
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) && _heroCtrl.value != 1) {
      _heroCtrl.value = 1;
    }
  }

  // ── Rating helpers ──────────────────────────────────────────────────────────

  Future<void> _loadUserRating() async {
    if (widget.playerToken == null) return;
    setState(() => _isLoadingRating = true);
    try {
      final svc = RatingService(token: widget.playerToken!);
      final result = await svc.getUserRating(widget.venue.id);
      if (result != null && result['rating'] != null) {
        setState(
          () => _userRating = (result['rating']['rating_value'] as num?)
              ?.toDouble(),
        );
      }
    } catch (e) {
      AppLogger.error('_loadUserRating: $e');
    } finally {
      if (mounted) setState(() => _isLoadingRating = false);
    }
  }

  Future<void> _submitRating(double value) async {
    if (widget.playerToken == null) {
      _snack('Please login to rate this venue', _kRed);
      return;
    }
    setState(() => _isSubmittingRating = true);
    try {
      final svc = RatingService(token: widget.playerToken!);
      final result = await svc.submitRating(
        venueId: int.parse(widget.venue.id),
        ratingValue: value,
      );
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
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kRed,
              foregroundColor: NightMatchColors.lightSurface,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _isSubmittingRating = true);
    try {
      final svc = RatingService(token: widget.playerToken!);
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
      if (result != null && result['rating'] != null)
        _submitRating(result['rating'] as double);
    });
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Sport helpers ────────────────────────────────────────────────────────────

  SportType _mapSport(String s) {
    switch (s.toLowerCase()) {
      case 'padel':
        return SportType.padel;
      case 'tennis':
        return SportType.tennis;
      case 'basketball':
        return SportType.basketball;
      default:
        return SportType.football;
    }
  }

  IconData _sportIcon(String s) {
    switch (s.toLowerCase()) {
      case 'padel':
        return Icons.sports_tennis_rounded;
      case 'tennis':
        return Icons.sports_tennis;
      case 'basketball':
        return Icons.sports_basketball_rounded;
      default:
        return Icons.sports_soccer_rounded;
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
    final all = widget.venue.courts;
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final navH =
        kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: theme.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Column(
          children: [
            _VenueHero(venue: widget.venue, fadeAnim: _heroFade),
            Expanded(
              child: ListView(
                padding: EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  navH + AppSpacing.xl,
                ),
                children: [
                  // ── About ───────────────────────────────────────────────────────
                  if (widget.venue.description.isNotEmpty) ...[
                    const _SectionHeader(
                      'About this venue',
                      Icons.info_outline_rounded,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: scheme.outlineVariant),
                        boxShadow: theme.brightness == Brightness.dark
                            ? AppElevation.nightGlow
                            : const [],
                      ),
                      child: Text(
                        widget.venue.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // ── Rating ──────────────────────────────────────────────────────
                  const _SectionHeader(
                    'Rating & Reviews',
                    Icons.star_rate_rounded,
                  ),
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
                  const _SectionHeader(
                    'Venue Manager',
                    Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: scheme.outlineVariant),
                      boxShadow: theme.brightness == Brightness.dark
                          ? AppElevation.nightGlow
                          : const [],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: scheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Center(
                            child: Text(
                              widget.venue.managerAvatar,
                              style: TextStyle(
                                fontSize: AppTypeScale.titleMedium,
                                fontWeight: FontWeight.w800,
                                color: scheme.onSecondaryContainer,
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
                                _titleCaseDisplayName(widget.venue.managerName),
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone_rounded,
                                    size: 18,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.venue.managerPhone,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: scheme.onSurfaceVariant,
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
                  const SizedBox(height: 28),

                  // ── Courts header ───────────────────────────────────────────────
                  _buildCourtsHeader(context),
                  const SizedBox(height: 14),

                  // ── Sport filter ────────────────────────────────────────────────
                  if (_sports.length > 1) ...[
                    _SportFilterRow(
                      sports: _sports,
                      selected: _filterSport,
                      sportIcon: _sportIcon,
                      onSelect: (s) => setState(() => _filterSport = s),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Court cards ─────────────────────────────────────────────────
                  ..._buildCourtCards(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourtsHeader(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: scheme.secondary,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text('Available Courts', style: theme.textTheme.titleLarge),
        const Spacer(),
        Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: scheme.secondaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Center(
            child: Text(
              '${_filtered.where((c) => c['available'] == true || c['isActive'] == true).length} open',
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSecondaryContainer,
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCourtCards(BuildContext context) {
    final courts = _filtered;
    if (courts.isEmpty) return [_EmptyState(sport: _filterSport)];
    final sportColor = Theme.of(context).colorScheme.secondary;

    return courts.map((c) {
      // ── Sport ────────────────────────────────────────────────────────────────
      final sportStr = (c['sport'] ?? c['sports'] ?? 'football').toString();
      final sportType = _mapSport(sportStr);

      // ── Availability ─────────────────────────────────────────────────────────
      final available = c['available'] == true || c['isActive'] == true;

      // ── Image ────────────────────────────────────────────────────────────────
      // _courtImageUrl() handles every possible shape Strapi returns
      final imageUrl = _courtImageUrl(c);

      // ── Price / capacity ─────────────────────────────────────────────────────
      final price = (c['pricePerHour'] ?? c['price'] ?? 0 as num).toDouble();
      final capacity = (c['capacity'] ?? 0) as int;

      // ── CourtModel for navigation ────────────────────────────────────────────
      final courtModel = CourtModel(
        id: int.tryParse(c['id']?.toString() ?? '0') ?? 0,
        name: (c['name'] ?? c['courtName'] ?? '').toString(),
        sport: sportStr,
        pricePerHour: price,
        capacity: capacity,
        isActive: available,
        venueId: int.tryParse(widget.venue.id) ?? 0,
        courtImgUrl: imageUrl.isNotEmpty ? imageUrl : null,
      );

      // ── Old model for CourtDetailPage ─────────────────────────────────────────
      final oldModel = AppModels.CourtModel(
        id: courtModel.id.toString(),
        name: courtModel.name,
        sport: sportType,
        pricePerHour: price,
        color: sportColor,
        imageUrl: imageUrl,
        isActive: available,
      );

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _CourtCard(
          court: courtModel,
          courtRaw: c,
          venue: widget.venue,
          playerToken: widget.playerToken,
          oldModel: oldModel,
          imageUrl: imageUrl,
          sportType: sportType,
          available: available,
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sportColor = scheme.secondary;
    final statusBackground = available
        ? scheme.secondaryContainer
        : scheme.errorContainer;
    final statusForeground = available
        ? scheme.onSecondaryContainer
        : scheme.onErrorContainer;

    return GestureDetector(
      onTap: available
          ? () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                _slideUp(
                  CourtDetailPage(
                    court: oldModel,
                    venue: venue,
                    courtRaw: courtRaw,
                    playerToken: playerToken,
                  ),
                ),
              );
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: scheme.outlineVariant),
          boxShadow: theme.brightness == Brightness.dark
              ? AppElevation.nightGlow
              : const [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Court image ────────────────────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadiusDirectional.vertical(
                top: Radius.circular(16),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 150,
                child: Hero(
                  tag: 'court-image-${oldModel.id}',
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: sportColor.withValues(alpha: 0.06),
                              child: Center(
                                child: SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: sportColor,
                                    value: progress.expectedTotalBytes != null
                                        ? progress.cumulativeBytesLoaded /
                                              progress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, _, _) =>
                              _imgFallback(context, sportType),
                        )
                      : _imgFallback(context, sportType),
                ),
              ),
            ),

            // ── Card body ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + availability badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _titleCaseDisplayName(court.name),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        constraints: const BoxConstraints(minHeight: 36),
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: statusBackground,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: statusForeground,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              available ? 'Available' : 'Full',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: statusForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Sport
                  Row(
                    children: [
                      Icon(sportType.icon, size: 12, color: sportColor),
                      const SizedBox(width: 5),
                      Text(
                        sportType.label,
                        style: TextStyle(
                          fontSize: AppTypeScale.labelMedium,
                          color: sportColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (court.capacity > 0) ...[
                        Icon(
                          Icons.people_outline_rounded,
                          size: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${court.capacity} players',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Amenities chips
                  if (venue.amenities.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: venue.amenities
                          .take(3)
                          .map(
                            (a) => Container(
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.xs,
                                ),
                              ),
                              child: Text(
                                a,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Price + action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'From',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '${court.pricePerHour.toInt()} DT/hr',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: scheme.secondary,
                            ),
                          ),
                        ],
                      ),
                      available
                          ? Container(
                              constraints: const BoxConstraints(minHeight: 48),
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: NightMatchColors.actionLime,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.input,
                                ),
                              ),
                              child: const Text(
                                'Book Now',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: NightMatchColors.onAction,
                                ),
                              ),
                            )
                          : Container(
                              constraints: const BoxConstraints(minHeight: 48),
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.input,
                                ),
                              ),
                              child: Text(
                                'Unavailable',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurfaceVariant,
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

  Widget _imgFallback(BuildContext context, SportType sport) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(sport.icon, size: 44, color: scheme.onSurfaceVariant),
      ),
    );
  }
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: theme.brightness == Brightness.dark
            ? AppElevation.nightGlow
            : const [],
      ),
      child: isLoading
          ? const Column(
              children: [
                LoadingSkeleton(width: 220, height: 22),
                SizedBox(height: AppSpacing.md),
                LoadingSkeleton(width: 140, height: 18),
              ],
            )
          : Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Center(
                        child: Text(
                          avgRating.toStringAsFixed(1),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: scheme.onSecondaryContainer,
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
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: scheme.outlineVariant),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userRating != null ? 'Your rating' : 'Rate this venue',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        if (userRating != null)
                          Expanded(
                            child: Row(
                              children: [
                                StarRating(
                                  rating: userRating!,
                                  size: 18,
                                  interactive: false,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  userRating!.toStringAsFixed(1),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: scheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          const Spacer(),
                        if (userRating != null && onDeleteTap != null)
                          IconButton(
                            tooltip: 'Delete your rating',
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                            padding: EdgeInsets.zero,
                            onPressed: isSubmitting ? null : onDeleteTap,
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        if (userRating != null && onDeleteTap != null)
                          const SizedBox(width: AppSpacing.xxs),
                        FilledButton(
                          onPressed: isSubmitting ? null : onRateTap,
                          style: FilledButton.styleFrom(
                            backgroundColor: NightMatchColors.actionLime,
                            foregroundColor: NightMatchColors.onAction,
                            minimumSize: const Size(48, 48),
                          ),
                          child: Text(
                            userRating != null ? 'Edit' : 'Rate',
                            style: const TextStyle(
                              fontSize: AppTypeScale.labelMedium,
                              fontWeight: FontWeight.w600,
                            ),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, this.icon);

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: scheme.secondaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.input),
          ),
          child: Icon(icon, color: scheme.onSecondaryContainer),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
      ],
    );
  }
}

class _VenueHero extends StatelessWidget {
  const _VenueHero({required this.venue, required this.fadeAnim});

  final VenueModel venue;
  final Animation<double> fadeAnim;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final venueName = _titleCaseDisplayName(venue.name);
    return SizedBox(
      height: AppLayout.heroHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FadeTransition(
            opacity: fadeAnim,
            child: venue.image.isNotEmpty
                ? Image.network(
                    venue.image,
                    fit: BoxFit.cover,
                    semanticLabel: 'Venue photo: $venueName',
                    errorBuilder: (_, _, _) => _fallback(context),
                  )
                : _fallback(context),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: AlignmentDirectional.topCenter,
                end: AlignmentDirectional.bottomCenter,
                colors: [
                  NightMatchColors.heroScrimTop,
                  NightMatchColors.heroScrimBottom,
                ],
                stops: [0.3, 1],
              ),
            ),
          ),
          PositionedDirectional(
            top: 0,
            start: 0,
            end: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Back to venue list',
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: scheme.inverseSurface.withValues(
                          alpha: 0.8,
                        ),
                      ),
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: scheme.onInverseSurface,
                      ),
                    ),
                    const Spacer(),
                    _VenueStatusBadge(venue.available),
                  ],
                ),
              ),
            ),
          ),
          PositionedDirectional(
            bottom: AppSpacing.md,
            start: AppSpacing.md,
            end: AppSpacing.md,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (venue.sports.isNotEmpty)
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: venue.sports
                        .take(3)
                        .map(
                          (sport) => Container(
                            constraints: const BoxConstraints(minHeight: 36),
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xxs,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.inverseSurface.withValues(
                                alpha: 0.88,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            child: Text(
                              _titleCaseDisplayName(sport),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: scheme.onInverseSurface,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  venueName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: NightMatchColors.text,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _HeroMeta(
                      icon: Icons.location_on_rounded,
                      label: venue.location,
                    ),
                    _HeroMeta(
                      icon: Icons.schedule_rounded,
                      label: 'Until ${venue.openUntil}',
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

  Widget _fallback(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.stadium_rounded,
          size: AppSpacing.xxl,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _HeroMeta extends StatelessWidget {
  const _HeroMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = NightMatchColors.text.withValues(alpha: 0.82);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: foreground),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: foreground),
        ),
      ],
    );
  }
}

class _SportFilterRow extends StatelessWidget {
  final List<String> sports;
  final String? selected;
  final IconData Function(String) sportIcon;
  final ValueChanged<String?> onSelect;
  const _SportFilterRow({
    required this.sports,
    required this.selected,
    required this.sportIcon,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 56,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: [
        _SportChip(
          label: 'All',
          icon: Icons.grid_view_rounded,
          selected: selected == null,
          onTap: () => onSelect(null),
        ),
        const SizedBox(width: AppSpacing.xs),
        ...sports.map(
          (s) => Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
            child: _SportChip(
              label: s,
              icon: sportIcon(s),
              selected: selected == s,
              onTap: () => onSelect(s),
            ),
          ),
        ),
      ],
    ),
  );
}

class _SportChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _SportChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = selected
        ? NightMatchColors.onAction
        : theme.colorScheme.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 220),
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: selected
                ? NightMatchColors.actionLime
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected
                  ? NightMatchColors.actionLime
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VenueStatusBadge extends StatelessWidget {
  final bool isOpen;
  const _VenueStatusBadge(this.isOpen);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = isOpen
        ? theme.colorScheme.secondaryContainer
        : theme.colorScheme.errorContainer;
    final foreground = isOpen
        ? theme.colorScheme.onSecondaryContainer
        : theme.colorScheme.onErrorContainer;
    return Semantics(
      label: isOpen ? 'Open now' : 'Closed',
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          isOpen ? 'Open now' : 'Closed',
          style: theme.textTheme.labelLarge?.copyWith(color: foreground),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String? sport;
  const _EmptyState({this.sport});

  @override
  Widget build(BuildContext context) => EmptyState(
    title: sport != null ? 'No $sport courts available' : 'No courts listed',
    message: 'Try a different sport filter.',
    icon: Icons.sports_rounded,
  );
}

Route _slideUp(Widget page) => PageRouteBuilder(
  pageBuilder: (_, _, _) => page,
  transitionsBuilder: (_, a, _, child) => SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
    child: child,
  ),
  transitionDuration: const Duration(milliseconds: 340),
);
