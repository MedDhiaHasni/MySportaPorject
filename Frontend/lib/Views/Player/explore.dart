// lib/Views/Player/explore_page.dart
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart' hide Position;
import 'package:geolocator/geolocator.dart' as geo show Position;
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Core/Constants/api_constants.dart';
import 'package:sporta/Models/venue_model.dart';
import 'package:sporta/Services/location_service.dart';
import 'package:sporta/Views/Player/court_booking_page.dart';
import 'package:sporta/Widgets/star_rating.dart';

// ── Put your Mapbox public token here ────────────────────────────────────────
const _kMapboxToken =
    'pk.eyJ1IjoiWU9VUl9VU0VSTkFNRSIsImEiOiJZT1VSX1RPS0VOIn0.XXXXXXXXXX';
// Style options:
//   Streets:  'mapbox://styles/mapbox/streets-v12'
//   Light:    'mapbox://styles/mapbox/light-v11'
//   Outdoors: 'mapbox://styles/mapbox/outdoors-v12'
const _kMapStyle = 'mapbox://styles/mapbox/streets-v12';
// ─────────────────────────────────────────────────────────────────────────────

const _bg       = Color(0xFFF2F4F7);
const _white    = Colors.white;
const _textDark = Color(0xFF0D0D0D);
const _textMid  = Color(0xFF6B7280);
const _textLight= Color(0xFFB0B7C3);
const _kGreen   = Color(0xFF16A34A);
const _kRed     = Color(0xFFDC2626);

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
    required this.id, required this.name, required this.location,
    required this.imageUrl, required this.openUntil, required this.managerName,
    required this.managerPhone, required this.managerAvatar, required this.description,
    required this.sports, required this.amenities, required this.courts,
    required this.minPrice, required this.maxPrice, required this.lat,
    required this.lng, required this.isActive,
    this.avgRating = 0.0, this.totalRatings = 0,
  });

  double distanceTo(double uLat, double uLng) {
    const r = 6371.0;
    final dLat = _rad(lat - uLat), dLng = _rad(lng - uLng);
    final a = math.sin(dLat/2)*math.sin(dLat/2) +
        math.cos(_rad(uLat))*math.cos(_rad(lat))*math.sin(dLng/2)*math.sin(dLng/2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
  static double _rad(double d) => d * math.pi / 180;

  factory ExploreVenue.fromJson(Map<String, dynamic> j) {
    final base = ApiConstants.mediaBaseUrl;
    String abs(dynamic raw) {
      if (raw == null) return '';
      final p = raw is String ? raw : (raw is Map ? raw['url']?.toString() ?? '' : '');
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
        final d = Map<String, dynamic>.from(raw as Map);
        final price = ((d['pricePerHour'] ?? d['price'] ?? 0) as num).toDouble();
        String img = '';
        if (d['court_img_url']?.toString().isNotEmpty == true) {
          img = abs(d['court_img_url'].toString());
        } else if (d['court_img'] is Map) {
          img = abs(d['court_img']);
        } else if (d['photos_urls'] is List && (d['photos_urls'] as List).isNotEmpty) {
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
          'price': price, 'pricePerHour': price,
          'available': d['isActive'] ?? true,
          'isActive': d['isActive'] ?? true,
          'court_img_url': img, 'imageUrl': img,
        });
        if (price > 0) { if (mn == 0 || price < mn) mn = price; if (price > mx) mx = price; }
      }
    }

    double lat = 36.8560, lng = 10.2210;
    if (j['lat'] != null) lat = double.tryParse(j['lat'].toString()) ?? lat;
    if (j['lng'] != null) lng = double.tryParse(j['lng'].toString()) ?? lng;

    String mName = 'Venue Manager', mPhone = '+216 XX XXX XXX', mAvatar = 'VM';
    if (j['manager'] is Map) {
      final m = j['manager'] as Map;
      mName  = (m['name'] ?? m['username'] ?? mName).toString();
      mPhone = (m['phone'] ?? mPhone).toString();
      if (mName != 'Venue Manager' && mName.isNotEmpty) {
        final p = mName.trim().split(' ');
        mAvatar = p.length >= 2 ? '${p[0][0]}${p[1][0]}'.toUpperCase() : p[0][0].toUpperCase();
      }
    }

    return ExploreVenue(
      id: j['id'].toString(), name: j['name']?.toString() ?? '',
      location: j['location']?.toString() ?? '', imageUrl: abs(j['photo']),
      openUntil: j['closeTime']?.toString() ?? '23:00',
      managerName: mName, managerPhone: mPhone, managerAvatar: mAvatar,
      description: j['description']?.toString() ?? '',
      sports: lst(j['sports']), amenities: lst(j['amenities']),
      courts: courts, minPrice: mn, maxPrice: mx,
      lat: lat, lng: lng, isActive: j['isActive'] ?? true,
      avgRating: (j['avg_rating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: (j['total_rating'] as num?)?.toInt() ?? 0,
    );
  }

  VenueModel toVenueModel() => VenueModel(
    id: id, name: name, location: location, managerName: managerName,
    managerPhone: managerPhone, managerAvatar: managerAvatar,
    sports: sports, amenities: amenities,
    minPrice: minPrice.toInt(), maxPrice: maxPrice.toInt(),
    available: isActive, openUntil: openUntil, image: imageUrl,
    lat: lat, lng: lng, courts: courts, description: description,
    avgRating: avgRating, totalRatings: totalRatings,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────────────────────
enum _LocIssue { none, serviceOff, denied, permanent }

class Explore extends StatefulWidget {
  final String? playerToken;
  const Explore({super.key, this.playerToken});
  @override State<Explore> createState() => _ExploreState();
}

class _ExploreState extends State<Explore> with TickerProviderStateMixin {
  int _sport = 0, _sort = 0, _view = 0;
  final _searchCtrl = TextEditingController();

  // ── Mapbox ─────────────────────────────────────────────────────────────────
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _annotationManager;
  // Maps annotation id → venue index in _filtered
  final Map<String, int> _annotationIdToIndex = {};
  int? _selMarker;

  List<ExploreVenue> _venues = [];
  bool _loading = true;
  String? _error;

  geo.Position? _pos;
  bool _locLoading   = false;
  bool _locDismissed = false;
  _LocIssue _locIssue = _LocIssue.none;

  static const _sports = [
    {'label': 'All',        'icon': Icons.sports_rounded},
    {'label': 'Football',   'icon': Icons.sports_soccer_rounded},
    {'label': 'Padel',      'icon': Icons.sports_tennis_rounded},
    {'label': 'Basketball', 'icon': Icons.sports_basketball_rounded},
    {'label': 'Tennis',     'icon': Icons.sports_tennis},
    {'label': 'Volleyball', 'icon': Icons.sports_volleyball},
  ];

  @override void initState() {
    super.initState();
    // Set the Mapbox access token before any map widget is created
    MapboxOptions.setAccessToken(_kMapboxToken);
    _loadVenues();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLoc());
  }

  @override void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Location ──────────────────────────────────────────────────────────────

  Future<void> _initLoc() async {
    if (_locLoading) return;
    setState(() { _locLoading = true; _locIssue = _LocIssue.none; });

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
        setState(() { _locLoading = false; _locIssue = _LocIssue.serviceOff; });
        if (!_locDismissed) await _showLocSheet();
        break;

      case LocationStatus.denied:
        setState(() { _locLoading = false; _locIssue = _LocIssue.denied; });
        if (!_locDismissed) await _showLocSheet();
        break;

      case LocationStatus.deniedForever:
        setState(() { _locLoading = false; _locIssue = _LocIssue.permanent; });
        if (!_locDismissed) await _showLocSheet();
        break;

      case LocationStatus.pluginMissing:
        debugPrint('[GPS] Plugin missing. Run: flutter clean && flutter pub get && flutter run');
        setState(() { _locLoading = false; });
        break;

      case LocationStatus.unavailable:
        debugPrint('[GPS] Unavailable: ${result.errorMessage}');
        setState(() { _locLoading = false; });
        break;
    }
  }

  Future<void> _showLocSheet() async {
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
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
    _annotationManager!.addOnPointAnnotationClickListener(_AnnotationClickListener(
      onTap: (annotation) {
        final idx = _annotationIdToIndex[annotation.id];
        if (idx == null) return;
        final wasSelected = _selMarker == idx;
        setState(() {
          _selMarker = wasSelected ? null : idx;
        });
        // Re-render pins so selected one turns green
        _refreshMarkers();
        if (!wasSelected) {
          final v = _filtered[idx];
          _moveMapTo(v.lat, v.lng, zoom: 14);
        }
      },
    ));

    // Draw initial markers
    _refreshMarkers();

    // Move to user location if already available
    if (_pos != null) {
      _moveMapTo(_pos!.latitude, _pos!.longitude, zoom: 13.5);
    }
  }

  Future<void> _refreshMarkers() async {
    if (_annotationManager == null) return;

    await _annotationManager!.deleteAll();
    _annotationIdToIndex.clear();

    final visible = _filtered;
    for (int i = 0; i < visible.length; i++) {
      final v = visible[i];
      final selected = _selMarker == i;
      final bytes = await _renderPinToBytes('${v.minPrice.toInt()} DT', selected);
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
  Future<Uint8List> _renderPinToBytes(String label, bool selected) async {
    const w = 140.0, h = 66.0, r = 16.0, tailH = 10.0;
    final bgColor  = selected ? kPrimary : Colors.white;
    final txtColor = selected ? Colors.white : kPrimary;
    final borderColor = kPrimary;

    final recorder = ui.PictureRecorder();
    final canvas   = Canvas(recorder, Rect.fromLTWH(0, 0, w, h));

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(selected ? 0.25 : 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final shadowPath = Path()
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(2, 2, w - 4, h - tailH - 2), const Radius.circular(r)));
    canvas.drawPath(shadowPath, shadowPaint);

    // Bubble background
    final bgPaint = Paint()..color = bgColor;
    final bubbleRect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h - tailH), Radius.circular(r));
    canvas.drawRRect(bubbleRect, bgPaint);

    // Border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 0 : 1.5;
    canvas.drawRRect(bubbleRect, borderPaint);

    // Tail triangle
    final tailPaint = Paint()..color = bgColor;
    final tailPath  = Path()
      ..moveTo(w / 2 - 7, h - tailH)
      ..lineTo(w / 2 + 7, h - tailH)
      ..lineTo(w / 2,     h)
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
      text: TextSpan(text: label, style: TextStyle(
        color: txtColor, fontSize: 20, fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      )),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: w);
    tp.paint(canvas, Offset((w - tp.width) / 2, (h - tailH - tp.height) / 2));

    final picture = recorder.endRecording();
    final image   = await picture.toImage(w.toInt(), h.toInt());
    final bytes   = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  // Draws an animated-style user location dot using a separate annotation manager
  PointAnnotationManager? _userDotManager;

  Future<void> _refreshUserDot() async {
    if (_mapboxMap == null || _pos == null) return;

    _userDotManager ??= await _mapboxMap!.annotations.createPointAnnotationManager();
    await _userDotManager!.deleteAll();

    final bytes = await _renderUserDot();
    await _userDotManager!.create(PointAnnotationOptions(
      geometry: Point(coordinates: Position(_pos!.longitude, _pos!.latitude)),
      image: bytes,
      iconSize: 1.0,
      iconAnchor: IconAnchor.CENTER,
    ));
  }

  Future<Uint8List> _renderUserDot() async {
    const size = 72.0;
    final recorder = ui.PictureRecorder();
    final canvas   = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));
    const cx = size / 2, cy = size / 2;

    // Outer pulse ring
    canvas.drawCircle(Offset(cx, cy), 33, Paint()
      ..color = const Color(0xFF1A73E8).withOpacity(0.18));

    // Mid ring
    canvas.drawCircle(Offset(cx, cy), 22, Paint()
      ..color = const Color(0xFF1A73E8).withOpacity(0.25));

    // White border
    canvas.drawCircle(Offset(cx, cy), 14, Paint()..color = Colors.white);

    // Blue dot
    canvas.drawCircle(Offset(cx, cy), 11, Paint()
      ..color = const Color(0xFF1A73E8));

    // Gloss highlight
    canvas.drawCircle(Offset(cx - 3, cy - 3), 4, Paint()
      ..color = Colors.white.withOpacity(0.5));

    final picture = recorder.endRecording();
    final image   = await picture.toImage(size.toInt(), size.toInt());
    final bytes   = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  // ── Venues ────────────────────────────────────────────────────────────────

  Future<void> _loadVenues() async {
    setState(() { _loading = true; _error = null; });
    try {
      final url = '${ApiConstants.baseUrl}/public/venues'
          '?populate[photo]=*&populate[manager]=*'
          '&populate[courts][populate][court_img]=*'
          '&populate[courts][populate][photos]=*';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) throw Exception('Server error ${res.statusCode}');
      final body  = json.decode(res.body);
      final raw   = body is List ? body : (body['data'] as List? ?? []);
      final list  = raw.whereType<Map<String, dynamic>>().map(ExploreVenue.fromJson).toList();
      setState(() { _venues = list; _loading = false; });
      // Refresh markers after venues load
      _refreshMarkers();
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _loading = false; });
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
      r = r.where((v) => v.name.toLowerCase().contains(q) || v.location.toLowerCase().contains(q)).toList();
    }
    switch (_sort) {
      case 1: if (_pos != null) r.sort((a, b) => a.distanceTo(_pos!.latitude, _pos!.longitude).compareTo(b.distanceTo(_pos!.latitude, _pos!.longitude))); break;
      case 2: r.sort((a, b) => a.minPrice.compareTo(b.minPrice)); break;
      case 3: r.sort((a, b) => b.minPrice.compareTo(a.minPrice)); break;
      case 4: r.sort((a, b) => b.avgRating.compareTo(a.avgRating)); break;
    }
    return r;
  }

  String get _sortLabel {
    switch (_sort) {
      case 1: return 'Nearest';
      case 2: return 'Price ↑';
      case 3: return 'Price ↓';
      case 4: return 'Rating';
      default: return 'Recommended';
    }
  }

  void _goBook(ExploreVenue v) => Navigator.push(context,
      _slideRoute(CourtBookingPage(venue: v.toVenueModel(), playerToken: widget.playerToken)));

  Widget _img(String url, {double height = 130, double? width}) {
    final w = width ?? double.infinity;
    if (url.isEmpty) return Container(height: height, width: w, color: kPrimary.withOpacity(0.1),
        child: Icon(Icons.stadium_rounded, size: 40, color: kPrimary.withOpacity(0.3)));
    return Image.network(url, height: height, width: w, fit: BoxFit.cover,
      loadingBuilder: (_, child, p) {
        if (p == null) return child;
        return Container(height: height, width: w, color: kPrimary.withOpacity(0.1),
          child: Center(child: SizedBox(width: 24, height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary,
              value: p.expectedTotalBytes != null ? p.cumulativeBytesLoaded / p.expectedTotalBytes! : null))));
      },
      errorBuilder: (_, __, ___) => Container(height: height, width: w, color: kPrimary.withOpacity(0.1),
          child: Icon(Icons.broken_image, size: 40, color: kPrimary.withOpacity(0.3))),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: _bg,
    body: _view == 1 ? _buildMap() : _buildList(),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // MAP  (Mapbox)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildMap() {
    final visible  = _filtered;
    final initLat  = _pos?.latitude  ?? 36.8560;
    final initLng  = _pos?.longitude ?? 10.2210;
    final initZoom = _pos != null ? 13.5 : 12.5;

    return Stack(children: [

      // ── Mapbox map ────────────────────────────────────────────────────────
      MapWidget(
        key: const ValueKey('mapbox_explore'),
        styleUri: _kMapStyle,
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
      Positioned(top: 0, left: 0, right: 0,
        child: SafeArea(bottom: false,
          child: Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              _circBtn(Icons.arrow_back_rounded, () => setState(() { _view = 0; _selMarker = null; })),
              const SizedBox(width: 12),
              Expanded(child: Container(height: 44,
                decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(22),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 12, offset: const Offset(0, 3))]),
                child: Row(children: [
                  const SizedBox(width: 14),
                  const Icon(Icons.search_rounded, color: _textLight, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) { setState(() {}); _refreshMarkers(); },
                    style: const TextStyle(fontSize: 14, color: _textDark),
                    decoration: const InputDecoration(
                      hintText: 'Search venues...',
                      hintStyle: TextStyle(color: _textLight, fontSize: 14),
                      border: InputBorder.none, isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10)))),
                ]))),
            ])))),

      // ── Venue count ───────────────────────────────────────────────────────
      Positioned(top: 130, left: 16,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 10)]),
          child: Row(children: [
            Icon(Icons.location_on_rounded, size: 13, color: kPrimary),
            const SizedBox(width: 5),
            Text('${visible.length} venues${_pos != null ? ' nearby' : ''}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textDark)),
          ]))),

      // ── My location button ────────────────────────────────────────────────
      Positioned(top: 130, right: 16,
        child: GestureDetector(
          onTap: () {
            if (_pos != null) {
              _moveMapTo(_pos!.latitude, _pos!.longitude, zoom: 13.5);
            } else {
              _initLoc();
            }
          },
          child: Container(width: 40, height: 40,
            decoration: BoxDecoration(
              color: _pos != null ? kPrimary : _white, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 2))]),
            child: _locLoading
                ? Padding(padding: const EdgeInsets.all(10),
                    child: CircularProgressIndicator(strokeWidth: 2, color: _pos != null ? Colors.white : kPrimary))
                : Icon(Icons.my_location_rounded, size: 18, color: _pos != null ? Colors.white : kPrimary)))),

      // ── Zoom buttons ──────────────────────────────────────────────────────
      Positioned(right: 16, bottom: _selMarker != null ? 230 : 100,
        child: Column(children: [
          _ZoomBtn(Icons.add_rounded, () async {
            final cam = await _mapboxMap?.getCameraState();
            if (cam != null) {
              _mapboxMap?.flyTo(CameraOptions(zoom: (cam.zoom + 1).clamp(1, 22)),
                  MapAnimationOptions(duration: 300));
            }
          }, top: true),
          Container(width: 40, height: 1, color: Colors.grey.shade200),
          _ZoomBtn(Icons.remove_rounded, () async {
            final cam = await _mapboxMap?.getCameraState();
            if (cam != null) {
              _mapboxMap?.flyTo(CameraOptions(zoom: (cam.zoom - 1).clamp(1, 22)),
                  MapAnimationOptions(duration: 300));
            }
          }, top: false),
        ])),

      // ── Venue preview card ────────────────────────────────────────────────
      if (_selMarker != null && _selMarker! < visible.length)
        Positioned(bottom: 110, left: 16, right: 16,
          child: _MapCard(
            venue: visible[_selMarker!],
            distLabel: _dist(visible[_selMarker!]),
            onTap: () => _goBook(visible[_selMarker!]),
            buildImg: _img)),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LIST
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildList() => Column(children: [
    _buildHeader(),
    Expanded(child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildSearch(),
        const SizedBox(height: 14),
        _buildSports(),
        const SizedBox(height: 16),
        _buildResultsRow(),
        const SizedBox(height: 12),
        if (_loading)
          const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: kPrimary)))
        else if (_error != null)
          Center(child: Column(children: [
            const SizedBox(height: 40),
            Icon(Icons.error_outline, size: 48, color: _kRed),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: _textMid)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadVenues, style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
                child: const Text('Retry', style: TextStyle(color: Colors.white))),
          ]))
        else
          _buildCards(),
        const SizedBox(height: 100),
      ]),
    )),
  ]);

  Widget _buildHeader() => Container(color: _white, child: SafeArea(bottom: false,
    child: Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 16), child: Row(children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Explore Venues', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _textDark, letterSpacing: -0.3)),
        if (_pos != null)
          Row(children: [Icon(Icons.location_on_rounded, size: 11, color: kPrimary), const SizedBox(width: 3),
            Text('Showing venues near you', style: TextStyle(fontSize: 11, color: kPrimary, fontWeight: FontWeight.w600))])
        else if (_locLoading)
          Row(children: [SizedBox(width: 11, height: 11, child: CircularProgressIndicator(strokeWidth: 1.5, color: _textLight)),
            const SizedBox(width: 5), Text('Getting your location...', style: TextStyle(fontSize: 11, color: _textLight))])
        else if (!_locDismissed)
          GestureDetector(onTap: _initLoc, child: Row(children: [
            Icon(Icons.location_searching_rounded, size: 11, color: _textLight), const SizedBox(width: 3),
            Text('Tap to enable location', style: TextStyle(fontSize: 11, color: kPrimary, fontWeight: FontWeight.w600, decoration: TextDecoration.underline)),
          ])),
      ]),
      const Spacer(),
      if (_pos == null && !_locLoading)
        GestureDetector(onTap: _initLoc, child: Container(width: 40, height: 40,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.location_searching_rounded, color: kPrimary, size: 20))),
      GestureDetector(
        onTap: () {
          setState(() { _view = _view == 1 ? 0 : 1; _selMarker = null; });
          // Markers are refreshed inside _onMapCreated / when map rebuilds
        },
        child: Container(width: 44, height: 44,
          decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(_view == 1 ? Icons.list_rounded : Icons.map, color: kPrimary, size: 22))),
    ]))));

  Widget _buildSearch() => Container(height: 50,
    decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))]),
    child: Row(children: [
      const SizedBox(width: 14), Icon(Icons.search_rounded, color: Colors.grey[400], size: 22), const SizedBox(width: 10),
      Expanded(child: TextField(controller: _searchCtrl, onChanged: (_) => setState(() {}),
        decoration: InputDecoration(hintText: 'Search venues, locations...', hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14), border: InputBorder.none, isDense: true))),
      if (_searchCtrl.text.isNotEmpty)
        GestureDetector(onTap: () { _searchCtrl.clear(); setState(() {}); },
          child: Padding(padding: const EdgeInsets.only(right: 10), child: Icon(Icons.close_rounded, color: Colors.grey[400], size: 18)))
      else const SizedBox(width: 14),
    ]));

  Widget _buildSports() => SizedBox(height: 36,
    child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: _sports.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, i) {
        final sel = _sport == i;
        return GestureDetector(onTap: () => setState(() => _sport = i),
          child: AnimatedContainer(duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(color: sel ? kPrimary : _white, borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))]),
            child: Row(children: [
              Icon(_sports[i]['icon'] as IconData, size: 14, color: sel ? Colors.white : Colors.grey[500]),
              const SizedBox(width: 5),
              Text(_sports[i]['label'] as String, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : Colors.grey[600])),
            ])));
      }));

  Widget _buildResultsRow() => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text('${_filtered.length} venue${_filtered.length == 1 ? '' : 's'} found',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[600])),
    GestureDetector(onTap: _showSortSheet, child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))]),
      child: Row(children: [
        const Icon(Icons.sort_rounded, size: 14, color: kPrimary), const SizedBox(width: 5),
        Text(_sortLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kPrimary)),
        const SizedBox(width: 3), const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: kPrimary),
      ]))),
  ]);

  Widget _buildCards() {
    final venues = _filtered;
    if (venues.isEmpty) return Padding(padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(children: [
        Icon(Icons.search_off_rounded, size: 56, color: Colors.grey[300]), const SizedBox(height: 12),
        const Text('No venues found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textDark)),
        const SizedBox(height: 4), Text('Try adjusting your filters', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
      ]));
    return ListView.separated(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      itemCount: venues.length, separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, i) => _VenueCard(venue: venues[i], distLabel: _dist(venues[i]), onBook: () => _goBook(venues[i]), buildImg: _img));
  }

  void _showSortSheet() => showModalBottomSheet(context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
      const SizedBox(height: 16),
      const Text('Sort By', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 16),
      if (_pos != null) _SortOpt(1, 'Nearest First', Icons.near_me_rounded, _sort, (v) { setState(() => _sort = v); Navigator.pop(context); }),
      _SortOpt(0, 'Recommended', Icons.star_rounded, _sort, (v) { setState(() => _sort = v); Navigator.pop(context); }),
      _SortOpt(2, 'Price: Low → High', Icons.trending_up_rounded, _sort, (v) { setState(() => _sort = v); Navigator.pop(context); }),
      _SortOpt(3, 'Price: High → Low', Icons.trending_down_rounded, _sort, (v) { setState(() => _sort = v); Navigator.pop(context); }),
      _SortOpt(4, 'Rating', Icons.star_rate_rounded, _sort, (v) { setState(() => _sort = v); Navigator.pop(context); }),
      const SizedBox(height: 8),
    ])));

  Widget _circBtn(IconData icon, VoidCallback onTap) => GestureDetector(onTap: onTap,
    child: Container(width: 44, height: 44,
      decoration: BoxDecoration(color: _white, shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 3))]),
      child: Icon(icon, size: 20, color: _textDark)));
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
  final _LocIssue issue;
  final VoidCallback onAllow, onDismiss;
  const _LocSheet({required this.issue, required this.onAllow, required this.onDismiss});

  @override Widget build(BuildContext context) {
    final svcOff  = issue == _LocIssue.serviceOff;
    final perm    = issue == _LocIssue.permanent;
    final title   = svcOff ? 'Turn On Location' : perm ? 'Location Access Required' : 'Allow Location Access';
    final body    = svcOff
        ? "Turn on your device's location service to see nearby venues and get distance info."
        : perm
            ? "Location permission was denied. Open app settings to allow access so we can show nearby venues."
            : "Sporta uses your location to show nearby courts, calculate distances, and sort venues closest to you.";
    final btnTxt  = svcOff ? 'Open Location Settings' : perm ? 'Open App Settings' : 'Allow Location';
    final btnIcon = svcOff ? Icons.settings_rounded : Icons.my_location_rounded;

    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 28),
        Container(width: 88, height: 88,
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: LinearGradient(colors: [kPrimary.withOpacity(0.15), kPrimary.withOpacity(0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
          child: Stack(alignment: Alignment.center, children: [
            Container(width: 88, height: 88, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: kPrimary.withOpacity(0.2), width: 1.5))),
            Container(width: 64, height: 64, decoration: BoxDecoration(shape: BoxShape.circle, color: kPrimary.withOpacity(0.1), border: Border.all(color: kPrimary.withOpacity(0.3), width: 1.5))),
            Icon(svcOff ? Icons.location_off_rounded : Icons.location_on_rounded, size: 32, color: kPrimary),
          ])),
        const SizedBox(height: 24),
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _textDark), textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Text(body, style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _Pill(Icons.near_me_rounded, 'Nearby Courts'),
          const SizedBox(width: 8),
          _Pill(Icons.straighten_rounded, 'Distances'),
          const SizedBox(width: 8),
          _Pill(Icons.sort_rounded, 'Smart Sort'),
        ]),
        const SizedBox(height: 28),
        SizedBox(width: double.infinity, height: 54, child: ElevatedButton(
          onPressed: onAllow,
          style: ElevatedButton.styleFrom(backgroundColor: kPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(btnIcon, size: 18, color: Colors.white), const SizedBox(width: 8),
            Text(btnTxt, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          ]))),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, height: 48, child: TextButton(
          onPressed: onDismiss,
          style: TextButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          child: Text('Not Now', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[500])))),
      ]),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon; final String label;
  const _Pill(this.icon, this.label);
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: kPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: kPrimary), const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kPrimary)),
    ]));
}

// ─────────────────────────────────────────────────────────────────────────────
// VENUE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _VenueCard extends StatelessWidget {
  final ExploreVenue venue; final String distLabel;
  final VoidCallback onBook;
  final Widget Function(String, {double height, double? width}) buildImg;
  const _VenueCard({required this.venue, required this.distLabel, required this.onBook, required this.buildImg});

  @override Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Stack(children: [
          buildImg(venue.imageUrl, height: 150),
          Positioned(top: 10, right: 10, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: venue.isActive ? _kGreen : _kRed, borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: (venue.isActive ? _kGreen : _kRed).withOpacity(0.4), blurRadius: 8)]),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 5, height: 5, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(venue.isActive ? 'Open Now' : 'Closed', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
            ]))),
          if (distLabel.isNotEmpty)
            Positioned(top: 10, left: 10, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.near_me_rounded, size: 10, color: Colors.white), const SizedBox(width: 4),
                Text(distLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
              ]))),
          if (venue.sports.isNotEmpty)
            Positioned(bottom: 10, left: 10, child: Wrap(spacing: 4,
              children: venue.sports.take(2).map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: kPrimary.withOpacity(0.85), borderRadius: BorderRadius.circular(20)),
                child: Text(s, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.3)),
              )).toList())),
        ])),
      Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(venue.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _textDark)),
        const SizedBox(height: 4),
        Row(children: [Icon(Icons.location_on_rounded, size: 12, color: Colors.grey[400]), const SizedBox(width: 3),
          Expanded(child: Text(venue.location, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Colors.grey[500])))]),
        const SizedBox(height: 6),
        if (venue.totalRatings > 0) ...[
          Row(children: [StarRating(rating: venue.avgRating, size: 12, interactive: false), const SizedBox(width: 5),
            Text(venue.avgRating.toStringAsFixed(1), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kPrimary)),
            const SizedBox(width: 4), Text('(${venue.totalRatings})', style: TextStyle(fontSize: 10, color: Colors.grey[500]))]),
          const SizedBox(height: 8),
        ],
        Wrap(spacing: 6, runSpacing: 4, children: [
          ...venue.amenities.take(3).map((a) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: kPrimary.withOpacity(0.07), borderRadius: BorderRadius.circular(8)),
            child: Text(a, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: kPrimary)))),
          if (venue.amenities.length > 3)
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
              child: Text('+${venue.amenities.length - 3} more', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.grey[500]))),
        ]),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('From', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
            Text('${venue.minPrice.toInt()} DT/hr', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kPrimary)),
          ]),
          GestureDetector(onTap: onBook, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
            decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]),
            child: const Text('Book Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)))),
        ]),
      ])),
    ]));
}

// ─────────────────────────────────────────────────────────────────────────────
// MAP CARD (venue preview on map tap)
// ─────────────────────────────────────────────────────────────────────────────
class _MapCard extends StatelessWidget {
  final ExploreVenue venue; final String distLabel; final VoidCallback onTap;
  final Widget Function(String, {double height, double? width}) buildImg;
  const _MapCard({required this.venue, required this.distLabel, required this.onTap, required this.buildImg});
  @override Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: Container(padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 6))]),
      child: Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(width: 64, height: 64, child: buildImg(venue.imageUrl, height: 64, width: 64))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(venue.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _textDark)),
          const SizedBox(height: 2),
          Text(venue.location, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          const SizedBox(height: 5),
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: venue.isActive ? _kGreen.withOpacity(0.12) : _kRed.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(venue.isActive ? 'Open' : 'Closed', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: venue.isActive ? _kGreen : _kRed))),
            const SizedBox(width: 6), Text('${venue.courts.length} courts', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
            if (distLabel.isNotEmpty) ...[const SizedBox(width: 6),
              Icon(Icons.near_me_rounded, size: 9, color: kPrimary), const SizedBox(width: 2),
              Text(distLabel, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: kPrimary))],
          ]),
        ])),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${venue.minPrice.toInt()} DT', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kPrimary)),
          if (venue.minPrice != venue.maxPrice) Text('– ${venue.maxPrice.toInt()} DT', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          const SizedBox(height: 6),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(10)),
            child: const Text('Book Now', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white))),
        ]),
      ])));
}

// ─────────────────────────────────────────────────────────────────────────────
// ZOOM BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _ZoomBtn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap; final bool top;
  const _ZoomBtn(this.icon, this.onTap, {required this.top});
  @override Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: Container(width: 40, height: 40,
      decoration: BoxDecoration(color: _white,
        borderRadius: BorderRadius.vertical(top: top ? const Radius.circular(12) : Radius.zero, bottom: top ? Radius.zero : const Radius.circular(12)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Icon(icon, size: 20, color: kPrimary)));
}

// ─────────────────────────────────────────────────────────────────────────────
// SORT OPTION
// ─────────────────────────────────────────────────────────────────────────────
class _SortOpt extends StatelessWidget {
  final int idx; final String label; final IconData icon; final int sel; final ValueChanged<int> onTap;
  const _SortOpt(this.idx, this.label, this.icon, this.sel, this.onTap);
  @override Widget build(BuildContext context) {
    final s = sel == idx;
    return GestureDetector(onTap: () => onTap(idx), child: Container(margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(color: s ? kPrimary.withOpacity(0.08) : Colors.transparent, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: s ? kPrimary : Colors.grey.shade200)),
      child: Row(children: [
        Icon(icon, size: 18, color: s ? kPrimary : Colors.grey[500]), const SizedBox(width: 12),
        Text(label, style: TextStyle(fontSize: 14, fontWeight: s ? FontWeight.w700 : FontWeight.w500, color: s ? kPrimary : _textDark)),
        const Spacer(),
        if (s) const Icon(Icons.check_circle_rounded, color: kPrimary, size: 18),
      ])));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE TRANSITION
// ─────────────────────────────────────────────────────────────────────────────
Route _slideRoute(Widget p) => PageRouteBuilder(
  pageBuilder: (_, __, ___) => p,
  transitionsBuilder: (_, a, __, child) => SlideTransition(
    position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: a, curve: Curves.easeOut)), child: child),
  transitionDuration: const Duration(milliseconds: 270));