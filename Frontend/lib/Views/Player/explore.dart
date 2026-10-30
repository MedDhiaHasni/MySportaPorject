// lib/Views/Player/explore_page.dart
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart' as geo show Position;
import 'package:flutter/services.dart';
import 'package:sporta/Core/Constants/api_constants.dart';
import 'package:sporta/Core/Theme/app_tokens.dart';
import 'package:sporta/Models/venue_model.dart';
import 'package:sporta/Services/location_service.dart';
import 'package:sporta/Views/Player/court_booking_page.dart';
import 'package:sporta/Widgets/star_rating.dart';
import 'package:sporta/Widgets/Buttons/app_buttons.dart';
import 'package:sporta/Widgets/Cards/app_card.dart';
import 'package:sporta/Widgets/feedback_components.dart';
import 'package:sporta/Widgets/booking_components.dart';
import 'package:sporta/Core/Utils/app_logger.dart';

const _kMapboxToken = String.fromEnvironment(
  'MAPBOX_ACCESS_TOKEN',
  defaultValue:
      'pk.eyJ1IjoiaGFzbmk3IiwiYSI6ImNtcHZud2M2ODAwamsycHF1emJiaG53NjcifQ.d4idEEQc51YuabZjcVR0RA',
);
// Style options:
//   Streets:  'mapbox://styles/mapbox/streets-v12'
//   Light:    'mapbox://styles/mapbox/light-v11'
//   Outdoors: 'mapbox://styles/mapbox/outdoors-v12'
const _kMapStyle = 'mapbox://styles/mapbox/streets-v12';
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────
class ExploreVenue {
  final String id, name, location, imageUrl, openUntil;
  final String managerName, managerPhone, managerAvatar, description;
  final List<String> sports, amenities;
  final List<Map<String, dynamic>> courts;
  final double minPrice, maxPrice, lat, lng, avgRating;
  final int totalRatings;
  final bool isActive;

  const ExploreVenue({
    required this.id,
    required this.name,
    required this.location,
    required this.imageUrl,
    required this.openUntil,
    required this.managerName,
    required this.managerPhone,
    required this.managerAvatar,
    required this.description,
    required this.sports,
    required this.amenities,
    required this.courts,
    required this.minPrice,
    required this.maxPrice,
    required this.lat,
    required this.lng,
    required this.isActive,
    this.avgRating = 0.0,
    this.totalRatings = 0,
  });

  double distanceTo(double uLat, double uLng) {
    const r = 6371.0;
    final dLat = _rad(lat - uLat), dLng = _rad(lng - uLng);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(uLat)) *
            math.cos(_rad(lat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _rad(double d) => d * math.pi / 180;

  factory ExploreVenue.fromJson(Map<String, dynamic> j) {
    final base = ApiConstants.mediaBaseUrl;
    String abs(dynamic raw) {
      if (raw == null) return '';
      final p = raw is String
          ? raw
          : (raw is Map ? raw['url']?.toString() ?? '' : '');
      return p.isEmpty ? '' : (p.startsWith('http') ? p : '$base$p');
    }

    List<String> lst(dynamic v) {
      if (v == null) return [];
      if (v is List) return v.map((e) => e.toString()).toList();
      if (v is String && v.isNotEmpty) return [v];
      return [];
    }

    double mn = 0, mx = 0;
    final courts = <Map<String, dynamic>>[];
    if (j['courts'] is List) {
      for (final raw in j['courts'] as List) {
        if (raw is! Map) continue;
        final d = Map<String, dynamic>.from(raw);
        final price = ((d['pricePerHour'] ?? d['price'] ?? 0) as num)
            .toDouble();
        String img = '';
        if (d['court_img_url']?.toString().isNotEmpty == true) {
          img = abs(d['court_img_url'].toString());
        } else if (d['court_img'] is Map) {
          img = abs(d['court_img']);
        } else if (d['photos_urls'] is List &&
            (d['photos_urls'] as List).isNotEmpty) {
          img = abs((d['photos_urls'] as List).first);
        } else if (d['photos'] is List && (d['photos'] as List).isNotEmpty) {
          final f = (d['photos'] as List).first;
          img = abs(f is Map ? f : f.toString());
        }
        courts.add({
          ...d,
          'id': d['id']?.toString() ?? '',
          'courtName': d['name']?.toString() ?? '',
          'name': d['name']?.toString() ?? '',
          'sport': d['sport']?.toString() ?? 'football',
          'sports': d['sports']?.toString() ?? 'football',
          'price': price,
          'pricePerHour': price,
          'available': d['isActive'] ?? true,
          'isActive': d['isActive'] ?? true,
          'court_img_url': img,
          'imageUrl': img,
        });
        if (price > 0) {
          if (mn == 0 || price < mn) mn = price;
          if (price > mx) mx = price;
        }
      }
    }

    double lat = 36.8560, lng = 10.2210;
    if (j['lat'] != null) lat = double.tryParse(j['lat'].toString()) ?? lat;
    if (j['lng'] != null) lng = double.tryParse(j['lng'].toString()) ?? lng;

    String mName = 'Venue Manager', mPhone = '+216 XX XXX XXX', mAvatar = 'VM';
    if (j['manager'] is Map) {
      final m = j['manager'] as Map;
      mName = (m['name'] ?? m['username'] ?? mName).toString();
      mPhone = (m['phone'] ?? mPhone).toString();
      if (mName != 'Venue Manager' && mName.isNotEmpty) {
        final p = mName.trim().split(' ');
        mAvatar = p.length >= 2
            ? '${p[0][0]}${p[1][0]}'.toUpperCase()
            : p[0][0].toUpperCase();
      }
    }

    return ExploreVenue(
      id: j['id'].toString(),
      name: j['name']?.toString() ?? '',
      location: j['location']?.toString() ?? '',
      imageUrl: abs(j['photo']),
      openUntil: j['closeTime']?.toString() ?? '23:00',
      managerName: mName,
      managerPhone: mPhone,
      managerAvatar: mAvatar,
      description: j['description']?.toString() ?? '',
      sports: lst(j['sports']),
      amenities: lst(j['amenities']),
      courts: courts,
      minPrice: mn,
      maxPrice: mx,
      lat: lat,
      lng: lng,
      isActive: j['isActive'] ?? true,
      avgRating: (j['avg_rating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: (j['total_rating'] as num?)?.toInt() ?? 0,
    );
  }

  VenueModel toVenueModel() => VenueModel(
    id: id,
    name: name,
    location: location,
    managerName: managerName,
    managerPhone: managerPhone,
    managerAvatar: managerAvatar,
    sports: sports,
    amenities: amenities,
    minPrice: minPrice.toInt(),
    maxPrice: maxPrice.toInt(),
    available: isActive,
    openUntil: openUntil,
    image: imageUrl,
    lat: lat,
    lng: lng,
    courts: courts,
    description: description,
    avgRating: avgRating,
    totalRatings: totalRatings,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────────────────────
enum _LocIssue { none, serviceOff, denied, permanent }

class Explore extends StatefulWidget {
  final String? playerToken;
  const Explore({super.key, this.playerToken});
  @override
  State<Explore> createState() => _ExploreState();
}

class _ExploreState extends State<Explore> with TickerProviderStateMixin {
  int _sport = 0, _sort = 0, _view = 0;
  final _searchCtrl = TextEditingController();

  // ── Mapbox ─────────────────────────────────────────────────────────────────
  MapboxMap? _mapboxMap;
  bool _mapboxReady = false;
  PointAnnotationManager? _annotationManager;
  // Maps annotation id → venue index in _filtered
  final Map<String, int> _annotationIdToIndex = {};
  int? _selMarker;

  List<ExploreVenue> _venues = [];
  bool _loading = true;
  String? _error;

  geo.Position? _pos;
  bool _locLoading = false;
  bool _locDismissed = false;
  _LocIssue _locIssue = _LocIssue.none;

  static const _sports = [
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
    _configureMapbox();
    _loadVenues();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLoc());
  }

  Future<void> _configureMapbox() async {
    try {
      if (_kMapboxToken.isNotEmpty) {
        MapboxOptions.setAccessToken(_kMapboxToken);
      }
      final token = await MapboxOptions.getAccessToken();
      if (!mounted) return;
      setState(() => _mapboxReady = token.trim().isNotEmpty);
    } catch (_) {
      AppLogger.error(
        '[Explore] Mapbox access token is unavailable. Check the native '
        'platform configuration or MAPBOX_ACCESS_TOKEN.',
      );
      if (!mounted) return;
      setState(() => _mapboxReady = false);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Location ──────────────────────────────────────────────────────────────

  Future<void> _initLoc() async {
    if (_locLoading) return;
    setState(() {
      _locLoading = true;
      _locIssue = _LocIssue.none;
    });

    final result = await LocationService.instance.requestAndGet();
    if (!mounted) return;

    switch (result.status) {
      case LocationStatus.granted:
        setState(() {
          _pos = result.position;
          _locLoading = false;
          if (_sort == 0) _sort = 1;
        });
        _moveMapTo(_pos!.latitude, _pos!.longitude, zoom: 13.5);
        _refreshUserDot();
        break;

      case LocationStatus.serviceDisabled:
        setState(() {
          _locLoading = false;
          _locIssue = _LocIssue.serviceOff;
        });
        if (!_locDismissed) await _showLocSheet();
        break;

      case LocationStatus.denied:
        setState(() {
          _locLoading = false;
          _locIssue = _LocIssue.denied;
        });
        if (!_locDismissed) await _showLocSheet();
        break;

      case LocationStatus.deniedForever:
        setState(() {
          _locLoading = false;
          _locIssue = _LocIssue.permanent;
        });
        if (!_locDismissed) await _showLocSheet();
        break;

      case LocationStatus.pluginMissing:
        setState(() {
          _locLoading = false;
        });
        break;

      case LocationStatus.unavailable:
        AppLogger.error('[GPS] Unavailable: ${result.errorMessage}');
        setState(() {
          _locLoading = false;
        });
        break;
    }
  }

  Future<void> _showLocSheet() async {
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surface.withValues(alpha: 0),
      builder: (_) => _LocSheet(
        issue: _locIssue,
        onAllow: () async {
          Navigator.pop(context);
          if (_locIssue == _LocIssue.serviceOff) {
            await LocationService.instance.openLocationSettings();
            await Future.delayed(const Duration(milliseconds: 800));
          } else if (_locIssue == _LocIssue.permanent) {
            await LocationService.instance.openAppSettings();
            await Future.delayed(const Duration(milliseconds: 800));
          }
          await _initLoc();
        },
        onDismiss: () {
          Navigator.pop(context);
          setState(() => _locDismissed = true);
        },
      ),
    );
  }

  // ── Mapbox helpers ────────────────────────────────────────────────────────

  void _moveMapTo(double lat, double lng, {double zoom = 14.0}) {
    _mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(lng, lat)),
        zoom: zoom,
      ),
      MapAnimationOptions(duration: 800),
    );
  }

  /// Called once the MapboxMap is ready.
  void _onMapCreated(MapboxMap map) async {
    _mapboxMap = map;

    // Disable the default Mapbox logo & attribution if you have a paid plan
    // (keep them for free tier to comply with Mapbox ToS)
    map.logo.updateSettings(LogoSettings(marginBottom: 4, marginLeft: 4));
    map.attribution.updateSettings(AttributionSettings(marginBottom: 4));

    // Create annotation manager for venue pins
    _annotationManager = await map.annotations.createPointAnnotationManager();
    _annotationManager!.addOnPointAnnotationClickListener(
      _AnnotationClickListener(
        onTap: (annotation) {
          final idx = _annotationIdToIndex[annotation.id];
          if (idx == null) return;
          final wasSelected = _selMarker == idx;
          HapticFeedback.selectionClick();
          setState(() {
            _selMarker = wasSelected ? null : idx;
          });
          // Re-render pins to distinguish the selected venue.
          _refreshMarkers();
          if (!wasSelected) {
            final v = _filtered[idx];
            _moveMapTo(v.lat, v.lng, zoom: 14);
          }
        },
      ),
    );

    // Draw initial markers
    _refreshMarkers();

    // Move to user location if already available
    if (_pos != null) {
      _moveMapTo(_pos!.latitude, _pos!.longitude, zoom: 13.5);
    }
  }

  Future<void> _refreshMarkers() async {
    if (_annotationManager == null) return;

    final scheme = Theme.of(context).colorScheme;
    await _annotationManager!.deleteAll();
    _annotationIdToIndex.clear();

    final visible = _filtered;
    for (int i = 0; i < visible.length; i++) {
      final v = visible[i];
      final selected = _selMarker == i;
      final bytes = await _renderPinToBytes(
        '${v.minPrice.toInt()} DT',
        selected,
        scheme,
      );
      final annotation = await _annotationManager!.create(
        PointAnnotationOptions(
          geometry: Point(coordinates: Position(v.lng, v.lat)),
          image: bytes,
          iconSize: 1.0,
          iconAnchor: IconAnchor.BOTTOM,
        ),
      );
      _annotationIdToIndex[annotation.id] = i;
    }

    // Draw user location dot on top
    _refreshUserDot();
  }

  // Renders a price-tag pin as a PNG bitmap
  Future<Uint8List> _renderPinToBytes(
    String label,
    bool selected,
    ColorScheme scheme,
  ) async {
    const w = 140.0, h = 66.0, r = 16.0, tailH = 10.0;
    final bgColor = selected
        ? NightMatchColors.actionLime
        : scheme.surface;
    final txtColor = selected
        ? NightMatchColors.onAction
        : scheme.onSurface;
    final borderColor = scheme.secondary;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w, h));

    // Shadow
    final shadowPaint = Paint()
      ..color = NightMatchColors.shadow.withValues(
        alpha: selected ? 0.25 : 0.12,
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final shadowPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(2, 2, w - 4, h - tailH - 2),
          const Radius.circular(r),
        ),
      );
    canvas.drawPath(shadowPath, shadowPaint);

    // Bubble background
    final bgPaint = Paint()..color = bgColor;
    final bubbleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h - tailH),
      Radius.circular(r),
    );
    canvas.drawRRect(bubbleRect, bgPaint);

    // Border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 0 : 1.5;
    canvas.drawRRect(bubbleRect, borderPaint);

    // Tail triangle
    final tailPaint = Paint()..color = bgColor;
    final tailPath = Path()
      ..moveTo(w / 2 - 7, h - tailH)
      ..lineTo(w / 2 + 7, h - tailH)
      ..lineTo(w / 2, h)
      ..close();
    canvas.drawPath(tailPath, tailPaint);
    if (!selected) {
      final tailBorder = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawPath(tailPath, tailBorder);
    }

    // Label text
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: txtColor,
          fontSize: AppTypeScale.titleLarge,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: w);
    tp.paint(canvas, Offset((w - tp.width) / 2, (h - tailH - tp.height) / 2));

    final picture = recorder.endRecording();
    final image = await picture.toImage(w.toInt(), h.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  // Draws an animated-style user location dot using a separate annotation manager
  PointAnnotationManager? _userDotManager;

  Future<void> _refreshUserDot() async {
    if (_mapboxMap == null || _pos == null) return;

    _userDotManager ??= await _mapboxMap!.annotations
        .createPointAnnotationManager();
    await _userDotManager!.deleteAll();

    final bytes = await _renderUserDot();
    await _userDotManager!.create(
      PointAnnotationOptions(
        geometry: Point(coordinates: Position(_pos!.longitude, _pos!.latitude)),
        image: bytes,
        iconSize: 1.0,
        iconAnchor: IconAnchor.CENTER,
      ),
    );
  }

  Future<Uint8List> _renderUserDot() async {
    const size = 72.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));
    const cx = size / 2, cy = size / 2;

    // Outer pulse ring
    canvas.drawCircle(
      Offset(cx, cy),
      33,
      Paint()..color = NightMatchColors.locationDot.withValues(alpha: 0.18),
    );

    // Mid ring
    canvas.drawCircle(
      Offset(cx, cy),
      22,
      Paint()..color = NightMatchColors.locationDot.withValues(alpha: 0.25),
    );

    // White border
    canvas.drawCircle(
      Offset(cx, cy),
      14,
      Paint()..color = NightMatchColors.lightSurface,
    );

    // Blue dot
    canvas.drawCircle(
      Offset(cx, cy),
      11,
      Paint()..color = NightMatchColors.locationDot,
    );

    // Gloss highlight
    canvas.drawCircle(
      Offset(cx - 3, cy - 3),
      4,
      Paint()..color = NightMatchColors.lightSurface.withValues(alpha: 0.5),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  // ── Venues ────────────────────────────────────────────────────────────────

  Future<void> _loadVenues() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final url =
          '${ApiConstants.baseUrl}/public/venues'
          '?populate[photo]=*&populate[manager]=*'
          '&populate[courts][populate][court_img]=*'
          '&populate[courts][populate][photos]=*';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200)
        throw Exception('Server error ${res.statusCode}');
      final body = json.decode(res.body);
      final raw = body is List ? body : (body['data'] as List? ?? []);
      final list = raw
          .whereType<Map<String, dynamic>>()
          .map(ExploreVenue.fromJson)
          .toList();
      setState(() {
        _venues = list;
        _loading = false;
      });
      // Refresh markers after venues load
      _refreshMarkers();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _dist(ExploreVenue v) {
    if (_pos == null) return '';
    final km = v.distanceTo(_pos!.latitude, _pos!.longitude);
    return km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';
  }

  List<ExploreVenue> get _filtered {
    var r = _sport == 0
        ? List<ExploreVenue>.from(_venues)
        : _venues.where((v) {
            final lbl = (_sports[_sport]['label'] as String).toLowerCase();
            return v.sports.any((s) => s.toLowerCase() == lbl);
          }).toList();
    final q = _searchCtrl.text.toLowerCase();
    if (q.isNotEmpty) {
      r = r
          .where(
            (v) =>
                v.name.toLowerCase().contains(q) ||
                v.location.toLowerCase().contains(q),
          )
          .toList();
    }
    switch (_sort) {
      case 1:
        if (_pos != null)
          r.sort(
            (a, b) => a
                .distanceTo(_pos!.latitude, _pos!.longitude)
                .compareTo(b.distanceTo(_pos!.latitude, _pos!.longitude)),
          );
        break;
      case 2:
        r.sort((a, b) => a.minPrice.compareTo(b.minPrice));
        break;
      case 3:
        r.sort((a, b) => b.minPrice.compareTo(a.minPrice));
        break;
      case 4:
        r.sort((a, b) => b.avgRating.compareTo(a.avgRating));
        break;
    }
    return r;
  }

  String get _sortLabel {
    switch (_sort) {
      case 1:
        return 'Nearest';
      case 2:
        return 'Price ↑';
      case 3:
        return 'Price ↓';
      case 4:
        return 'Rating';
      default:
        return 'Recommended';
    }
  }

  void _goBook(ExploreVenue v) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      _slideRoute(
        context,
        CourtBookingPage(
          venue: v.toVenueModel(),
          playerToken: widget.playerToken,
        ),
      ),
    );
  }

  Widget _img(
    BuildContext context,
    String url, {
    double height = 130,
    double? width,
  }) {
    final w = width ?? double.infinity;
    final scheme = Theme.of(context).colorScheme;
    if (url.isEmpty) {
      return Container(
        height: height,
        width: w,
        color: scheme.surfaceContainerHighest,
        child: Icon(
          Icons.stadium_rounded,
          size: 40,
          color: scheme.onSurfaceVariant,
        ),
      );
    }
    return Image.network(
      url,
      height: height,
      width: w,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, p) {
        if (p == null) return child;
        return Container(
          height: height,
          width: w,
          color: scheme.surfaceContainerHighest,
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: scheme.secondary,
                value: p.expectedTotalBytes != null
                    ? p.cumulativeBytesLoaded / p.expectedTotalBytes!
                    : null,
              ),
            ),
          ),
        );
      },
      errorBuilder: (_, _, _) => Container(
        height: height,
        width: w,
        color: scheme.surfaceContainerHighest,
        child: Icon(
          Icons.broken_image,
          size: 40,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    body: _view == 1 ? _buildMap() : _buildList(),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // MAP  (Mapbox)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildMap() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final visible = _filtered;
    final initLat = _pos?.latitude ?? 36.8560;
    final initLng = _pos?.longitude ?? 10.2210;
    final initZoom = _pos != null ? 13.5 : 12.5;

    return Stack(
      children: [
        // ── Mapbox map ────────────────────────────────────────────────────────
        if (!_mapboxReady)
          Positioned.fill(
            child: ColoredBox(
              color: theme.scaffoldBackgroundColor,
              child: Center(
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.map_outlined,
                        size: AppSpacing.xxl,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Map unavailable',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Configure MAPBOX_ACCESS_TOKEN to use map view.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => setState(() {
                          _view = 0;
                          _selMarker = null;
                        }),
                        icon: const Icon(Icons.list_rounded),
                        label: const Text('Switch to list'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          MapWidget(
            key: const ValueKey('mapbox_explore'),
            styleUri: theme.brightness == Brightness.dark
                ? 'mapbox://styles/mapbox/dark-v11'
                : _kMapStyle,
            cameraOptions: CameraOptions(
              center: Point(coordinates: Position(initLng, initLat)),
              zoom: initZoom,
            ),
            onMapCreated: _onMapCreated,
            onTapListener: (ctx) {
              setState(() => _selMarker = null);
              _refreshMarkers();
            },
          ),

        // ── Top bar ───────────────────────────────────────────────────────────
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
                  _circBtn(
                    Icons.arrow_back_rounded,
                    () => setState(() {
                      _view = 0;
                      _selMarker = null;
                    }),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (_) {
                        setState(() {});
                        _refreshMarkers();
                      },
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        hintText: 'Search venues',
                        prefixIcon: Icon(Icons.search_rounded),
                        contentPadding: EdgeInsetsDirectional.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Venue count ───────────────────────────────────────────────────────
        PositionedDirectional(
          top: 130,
          start: AppSpacing.md,
          child: Material(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${visible.length} venues${_pos != null ? ' nearby' : ''}',
                    style: theme.textTheme.labelLarge,
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── My location button ────────────────────────────────────────────────
        PositionedDirectional(
          top: 130,
          end: AppSpacing.md,
          child: IconButton(
            tooltip: 'Use my location',
            onPressed: () {
              if (_pos != null) {
                _moveMapTo(_pos!.latitude, _pos!.longitude, zoom: 13.5);
              } else {
                _initLoc();
              }
            },
            icon: _locLoading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded),
            style: IconButton.styleFrom(
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
        ),

        // ── Zoom buttons ──────────────────────────────────────────────────────
        if (_kMapboxToken.isNotEmpty)
          PositionedDirectional(
            end: AppSpacing.md,
            bottom: _selMarker != null ? 230 : 100,
            child: Column(
              children: [
                _ZoomBtn(Icons.add_rounded, () async {
                  final cam = await _mapboxMap?.getCameraState();
                  if (cam != null) {
                    _mapboxMap?.flyTo(
                      CameraOptions(zoom: (cam.zoom + 1).clamp(1, 22)),
                      MapAnimationOptions(duration: 300),
                    );
                  }
                }, top: true),
                Container(width: 48, height: 1, color: scheme.outlineVariant),
                _ZoomBtn(Icons.remove_rounded, () async {
                  final cam = await _mapboxMap?.getCameraState();
                  if (cam != null) {
                    _mapboxMap?.flyTo(
                      CameraOptions(zoom: (cam.zoom - 1).clamp(1, 22)),
                      MapAnimationOptions(duration: 300),
                    );
                  }
                }, top: false),
              ],
            ),
          ),

        // ── Venue preview card ────────────────────────────────────────────────
        if (_selMarker != null && _selMarker! < visible.length)
          PositionedDirectional(
            bottom: 110,
            start: AppSpacing.md,
            end: AppSpacing.md,
            child: _MapCard(
              venue: visible[_selMarker!],
              distLabel: _dist(visible[_selMarker!]),
              onTap: () => _goBook(visible[_selMarker!]),
              buildImg: _img,
            ),
          ),
        if (!_loading && _error != null)
          Positioned.fill(
            child: ColoredBox(
              color: scheme.surface.withValues(alpha: 0.94),
              child: ErrorState(
                title: 'Venues could not be loaded',
                message: _error!,
                onRetry: () => _loadVenues(),
              ),
            ),
          )
        else if (!_loading && visible.isEmpty)
          PositionedDirectional(
            bottom: AppSpacing.xxxl,
            start: AppSpacing.md,
            end: AppSpacing.md,
            child: const AppCard(
              child: EmptyState(
                title: 'No venues in this view',
                message: 'Try a different sport or search term.',
                icon: Icons.search_off_rounded,
              ),
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LIST
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildList() => RefreshIndicator(
    onRefresh: _loadVenues,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        _buildHeader(),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xxxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearch(),
              const SizedBox(height: AppSpacing.md),
              _buildSports(),
              const SizedBox(height: AppSpacing.md),
              _buildResultsRow(),
              const SizedBox(height: AppSpacing.sm),
              if (_loading)
                _venueLoadingSkeleton()
              else if (_error != null)
                ErrorState(
                  title: 'Venues could not be loaded',
                  message: _error!,
                  onRetry: () => _loadVenues(),
                )
              else
                _buildCards(),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _venueLoadingSkeleton() => Column(
    children: [
      for (var index = 0; index < 3; index++) ...[
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LoadingSkeleton(height: 144),
              const SizedBox(height: AppSpacing.md),
              const LoadingSkeleton(width: 190, height: 22),
              const SizedBox(height: AppSpacing.xs),
              const LoadingSkeleton(width: 240, height: 16),
              const SizedBox(height: AppSpacing.md),
              const LoadingSkeleton(width: 128, height: 18),
            ],
          ),
        ),
        if (index < 2) const SizedBox(height: AppSpacing.md),
      ],
    ],
  );

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Explore venues',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    if (_pos != null)
                      Text(
                        'Showing venues near you',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      )
                    else if (_locLoading)
                      Text(
                        'Getting your location...',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      )
                    else if (!_locDismissed)
                      TextButton.icon(
                        onPressed: _initLoc,
                        icon: const Icon(Icons.location_searching_rounded),
                        label: const Text('Enable location'),
                      ),
                  ],
                ),
              ),
              if (_pos == null && !_locLoading)
                IconButton(
                  tooltip: 'Use my location',
                  onPressed: _initLoc,
                  icon: const Icon(Icons.my_location_rounded),
                ),
              IconButton(
                tooltip: _view == 1 ? 'Show list view' : 'Show map view',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _view = _view == 1 ? 0 : 1;
                    _selMarker = null;
                  });
                },
                icon: Icon(_view == 1 ? Icons.list_rounded : Icons.map_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearch() => Semantics(
    label: 'Search venues and locations',
    child: TextField(
      controller: _searchCtrl,
      onChanged: (_) => setState(() {}),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search venues or locations',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchCtrl.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.close_rounded),
              ),
      ),
    ),
  );

  Widget _buildSports() => SizedBox(
    height: 56,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: _sports.length,
      separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
      itemBuilder: (_, index) => SportChip(
        label: _sports[index]['label'] as String,
        icon: _sports[index]['icon'] as IconData,
        selected: _sport == index,
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _sport = index);
        },
      ),
    ),
  );

  Widget _buildResultsRow() {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            '${_filtered.length} venues found',
            style: theme.textTheme.titleSmall,
          ),
        ),
        AppTextButton(
          label: _sortLabel,
          icon: Icons.tune_rounded,
          onPressed: _showSortSheet,
        ),
      ],
    );
  }

  Widget _buildCards() {
    final venues = _filtered;
    if (venues.isEmpty) {
      return const EmptyState(
        title: 'No venues found',
        message: 'Try changing your search or sport filters.',
        icon: Icons.search_off_rounded,
      );
    }
    return Column(
      children: [
        for (final venue in venues) ...[
          _VenueCard(
            venue: venue,
            distLabel: _dist(venue),
            onBook: () => _goBook(venue),
            buildImg: _img,
          ),
          if (venue != venues.last) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  void _showSortSheet() => AppBottomSheet.show<void>(
    context: context,
    title: 'Sort venues',
    child: Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_pos != null)
            _SortOpt(1, 'Nearest First', Icons.near_me_rounded, _sort, (v) {
              setState(() => _sort = v);
              Navigator.pop(context);
            }),
          _SortOpt(0, 'Recommended', Icons.star_rounded, _sort, (v) {
            setState(() => _sort = v);
            Navigator.pop(context);
          }),
          _SortOpt(2, 'Price: Low → High', Icons.trending_up_rounded, _sort, (
            v,
          ) {
            setState(() => _sort = v);
            Navigator.pop(context);
          }),
          _SortOpt(3, 'Price: High → Low', Icons.trending_down_rounded, _sort, (
            v,
          ) {
            setState(() => _sort = v);
            Navigator.pop(context);
          }),
          _SortOpt(4, 'Rating', Icons.star_rate_rounded, _sort, (v) {
            setState(() => _sort = v);
            Navigator.pop(context);
          }),
          const SizedBox(height: AppSpacing.xs),
        ],
      ),
    ),
  );

  Widget _circBtn(IconData icon, VoidCallback onTap) =>
      IconButton(tooltip: 'Back to list', onPressed: onTap, icon: Icon(icon));
}

// ─────────────────────────────────────────────────────────────────────────────
// Annotation click listener
// ─────────────────────────────────────────────────────────────────────────────
class _AnnotationClickListener extends OnPointAnnotationClickListener {
  final void Function(PointAnnotation annotation) onTap;
  _AnnotationClickListener({required this.onTap});
  @override
  void onPointAnnotationClick(PointAnnotation annotation) => onTap(annotation);
}

// ─────────────────────────────────────────────────────────────────────────────
// LOCATION SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _LocSheet extends StatelessWidget {
  const _LocSheet({
    required this.issue,
    required this.onAllow,
    required this.onDismiss,
  });

  final _LocIssue issue;
  final VoidCallback onAllow;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final serviceOff = issue == _LocIssue.serviceOff;
    final permanent = issue == _LocIssue.permanent;
    final title = serviceOff
        ? 'Turn on location'
        : permanent
        ? 'Location access required'
        : 'Allow location access';
    final message = serviceOff
        ? 'Turn on your device location to see nearby venues and distances.'
        : permanent
        ? 'Open app settings to allow location access and sort venues by distance.'
        : 'Sporta uses your location to show nearby venues and calculate distances.';
    final actionLabel = serviceOff
        ? 'Open location settings'
        : permanent
        ? 'Open app settings'
        : 'Allow location';
    final actionIcon = serviceOff
        ? Icons.settings_rounded
        : Icons.my_location_rounded;
    final theme = Theme.of(context);

    return AppBottomSheet(
      title: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.location_on_rounded,
            size: AppSpacing.xxl,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppPrimaryButton(
            label: actionLabel,
            icon: actionIcon,
            onPressed: onAllow,
          ),
          const SizedBox(height: AppSpacing.xs),
          AppTextButton(label: 'Not now', onPressed: onDismiss),
        ],
      ),
    );
  }
}

// VENUE CARD
// ─────────────────────────────────────────────────────────────────────────────
String _titleCase(String value) => value
    .trim()
    .split(RegExp(r'\s+'))
    .where((word) => word.isNotEmpty)
    .map(
      (word) => word.length == 1
          ? word.toUpperCase()
          : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
    )
    .join(' ');

class _VenueCard extends StatelessWidget {
  const _VenueCard({
    required this.venue,
    required this.distLabel,
    required this.onBook,
    required this.buildImg,
  });

  final ExploreVenue venue;
  final String distLabel;
  final VoidCallback onBook;
  final Widget Function(
    BuildContext,
    String, {
    double height,
    double? width,
  }) buildImg;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final statusColor = venue.isActive
        ? scheme.secondaryContainer
        : scheme.errorContainer;
    final statusText = venue.isActive
        ? scheme.onSecondaryContainer
        : scheme.onErrorContainer;

    return Semantics(
      label: '${_titleCase(venue.name)}, ${venue.isActive ? 'open' : 'closed'}',
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadiusDirectional.vertical(
                top: Radius.circular(AppRadius.card),
              ),
              child: Stack(
                children: [
                  buildImg(context, venue.imageUrl, height: 164),
                  PositionedDirectional(
                    top: AppSpacing.sm,
                    end: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        venue.isActive ? 'Open now' : 'Closed',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: statusText,
                        ),
                      ),
                    ),
                  ),
                  if (distLabel.isNotEmpty)
                    PositionedDirectional(
                      top: AppSpacing.sm,
                      start: AppSpacing.sm,
                      child: Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.inverseSurface.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          distLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onInverseSurface,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _titleCase(venue.name),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Expanded(
                        child: Text(
                          venue.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (venue.totalRatings > 0) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        StarRating(
                          rating: venue.avgRating,
                          size: 18,
                          interactive: false,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '${venue.avgRating.toStringAsFixed(1)} (${venue.totalRatings})',
                          style: theme.textTheme.labelLarge,
                        ),
                      ],
                    ),
                  ],
                  if (venue.sports.isNotEmpty ||
                      venue.amenities.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        ...venue.sports
                            .take(2)
                            .map(
                              (sport) => SportChip(label: _titleCase(sport)),
                            ),
                        ...venue.amenities
                            .take(2)
                            .map(
                              (amenity) =>
                                  SportChip(label: _titleCase(amenity)),
                            ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('From', style: theme.textTheme.bodySmall),
                            Text(
                              '${venue.minPrice.toInt()} DT/hr',
                              style: theme.textTheme.titleLarge,
                            ),
                          ],
                        ),
                      ),
                      AppPrimaryButton(
                        label: 'Book now',
                        icon: Icons.calendar_month_rounded,
                        onPressed: onBook,
                        expand: false,
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

// MAP CARD (venue preview on map tap)
// ─────────────────────────────────────────────────────────────────────────────
class _MapCard extends StatelessWidget {
  const _MapCard({
    required this.venue,
    required this.distLabel,
    required this.onTap,
    required this.buildImg,
  });

  final ExploreVenue venue;
  final String distLabel;
  final VoidCallback onTap;
  final Widget Function(
    BuildContext,
    String, {
    double height,
    double? width,
  }) buildImg;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.input),
            child: SizedBox(
              width: 72,
              height: 72,
              child: buildImg(
                context,
                venue.imageUrl,
                height: 72,
                width: 72,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _titleCase(venue.name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  venue.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (distLabel.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(distLabel, style: theme.textTheme.labelMedium),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${venue.minPrice.toInt()} DT',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.end,
          ),
        ],
      ),
    );
  }
}

// ZOOM BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _ZoomBtn extends StatelessWidget {
  const _ZoomBtn(this.icon, this.onTap, {required this.top});

  final IconData icon;
  final VoidCallback onTap;
  final bool top;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: icon == Icons.add_rounded ? 'Zoom in' : 'Zoom out',
    onPressed: () {
      HapticFeedback.selectionClick();
      onTap();
    },
    style: IconButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: top ? const Radius.circular(AppRadius.input) : Radius.zero,
          bottom: top ? Radius.zero : const Radius.circular(AppRadius.input),
        ),
      ),
    ),
    icon: Icon(icon),
  );
}

// SORT OPTION
// ─────────────────────────────────────────────────────────────────────────────
class _SortOpt extends StatelessWidget {
  const _SortOpt(this.idx, this.label, this.icon, this.sel, this.onTap);

  final int idx;
  final String label;
  final IconData icon;
  final int sel;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final selected = sel == idx;
    final theme = Theme.of(context);
    final foreground = selected
        ? NightMatchColors.onAction
        : theme.colorScheme.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.input),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap(idx);
        },
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 220),
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: selected
                ? NightMatchColors.actionLime
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.input),
          ),
          child: Row(
            children: [
              Icon(icon, color: foreground),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: foreground,
                    fontWeight: selected ? FontWeight.w700 : null,
                  ),
                ),
              ),
              if (selected) Icon(Icons.check_rounded, color: foreground),
            ],
          ),
        ),
      ),
    );
  }
}

// PAGE TRANSITION
// ─────────────────────────────────────────────────────────────────────────────
Route _slideRoute(BuildContext context, Widget page) {
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  final direction = Directionality.of(context);
  return PageRouteBuilder(
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, _, child) => SlideTransition(
      position: Tween<Offset>(
        begin: Offset(direction == TextDirection.rtl ? -1 : 1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: child,
    ),
    transitionDuration: reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 270),
  );
}
