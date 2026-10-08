// venue_page.dart — Views/Manager/venue_page.dart
// Changes from original:
//  1. Fixed header white space on scroll (Scaffold uses Column not CustomScrollView for root)
//  2. Lat/Lng precision warning in VenueFormSheet
//  3. Day Plan + Week Agenda + Time Slot management per court (_ScheduleTab inside VenueDetailPage)
//  4. Court images: support for court_img (single main image) and photos (multiple gallery images)
//  5. Worker assignment - Manager can assign a worker to one or many courts
//  6. Worker assignment now displays assigned worker info with name, phone and inline remove button

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Core/Constants/api_constants.dart';
import 'package:sporta/Models/app_enums.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sporta/Services/court_service.dart';
import 'package:sporta/Services/venue_service.dart';
import 'package:sporta/Services/manager_worker_service.dart';
import 'package:sporta/Services/player_manager_auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ─────────────────────────────────────────────────────────────────────────────
// BASE URL HELPER
// ─────────────────────────────────────────────────────────────────────────────
const String _baseUrl = 'http://10.0.2.2:1337';
String _fullUrl(String path) => path.startsWith('http') ? path : '$_baseUrl$path';

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────
class ManagedVenue {
  final String id;
  String name, location, phone, description, openTime, closeTime;
  List<String> photoUrls;
  List<SportType> sports;
  List<String> amenities;
  List<ManagedCourt> courts;
  double? lat;
  double? lng;
  int? photoId;

  ManagedVenue({
    required this.id, required this.name, required this.location,
    required this.phone, required this.description,
    required this.openTime, required this.closeTime,
    this.photoUrls = const [], required this.sports,
    this.amenities = const [], required this.courts,
    this.lat, this.lng, this.photoId,
  });

  factory ManagedVenue.fromJson(Map<String, dynamic> json) {
    final List<SportType> sportsList = [];
    final rawSports = json['sports'];
    if (rawSports is List) {
      for (final s in rawSports) { final t = _parseSport(s.toString()); if (t != null) sportsList.add(t); }
    } else if (rawSports is String && rawSports.isNotEmpty) {
      final t = _parseSport(rawSports); if (t != null) sportsList.add(t);
    }
    final List<String> amenitiesList = [];
    final rawAmenities = json['amenities'];
    if (rawAmenities is List) amenitiesList.addAll(rawAmenities.map((a) => a.toString()));
    else if (rawAmenities is String && rawAmenities.isNotEmpty) amenitiesList.add(rawAmenities);
    final List<String> photoList = [];
    int? photoId;
    final rawPhoto = json['photo'];
    if (rawPhoto is Map<String, dynamic>) {
      photoId = rawPhoto['id'] as int?;
      final url = rawPhoto['url']?.toString();
      if (url != null && url.isNotEmpty) photoList.add(_fullUrl(url));
    }
    return ManagedVenue(
      id: json['id'].toString(), name: json['name']?.toString() ?? '',
      location: json['location']?.toString() ?? '', phone: '',
      description: json['description']?.toString() ?? '',
      openTime: json['openTime']?.toString() ?? '08:00',
      closeTime: json['closeTime']?.toString() ?? '23:00',
      photoUrls: photoList, sports: sportsList, amenities: amenitiesList,
      courts: [],
      lat: json['lat'] != null ? double.tryParse(json['lat'].toString()) : null,
      lng: json['lng'] != null ? double.tryParse(json['lng'].toString()) : null,
      photoId: photoId,
    );
  }

  static SportType? _parseSport(String s) {
    switch (s.toLowerCase()) {
      case 'football':   return SportType.football;
      case 'tennis':     return SportType.tennis;
      case 'padel':      return SportType.padel;
      case 'basketball': return SportType.basketball;
      default:           return null;
    }
  }
}

class ManagedCourt {
  final String id;
  String name, description, surface;
  SportType sport;
  double pricePerHour;
  int capacity;
  List<String> photoUrls;
  List<String> photosUrls;
  String? courtImgUrl;
  List<String> amenities;
  bool isActive;
  int? courtImgId;
  List<int>? photosIds;
  Map<String, dynamic>? assignedWorker;

  ManagedCourt({
    required this.id, required this.name, required this.description,
    required this.sport, required this.pricePerHour, required this.capacity,
    this.photoUrls = const [], this.photosUrls = const [], this.courtImgUrl,
    this.amenities = const [], this.isActive = true, this.surface = 'Artificial Turf',
    this.courtImgId, this.photosIds, this.assignedWorker,
  });

  factory ManagedCourt.fromJson(Map<String, dynamic> json) {
    SportType sportType = SportType.football;
    final rawSport = json['sport']?.toString().toLowerCase() ?? '';
    switch (rawSport) {
      case 'tennis':     sportType = SportType.tennis;     break;
      case 'padel':      sportType = SportType.padel;      break;
      case 'basketball': sportType = SportType.basketball; break;
      default:           sportType = SportType.football;
    }
    final List<String> amenitiesList = [];
    final rawAmenities = json['amenities'];
    if (rawAmenities is List) amenitiesList.addAll(rawAmenities.map((a) => a.toString()));
    
    String? courtImgUrl;
    int? courtImgId;
    final rawCourtImg = json['court_img'];
    if (rawCourtImg is Map<String, dynamic>) {
      courtImgId = rawCourtImg['id'] as int?;
      final url = rawCourtImg['url']?.toString();
      if (url != null && url.isNotEmpty) courtImgUrl = _fullUrl(url);
    }
    
    List<String> photosUrls = [];
    List<int> photosIds = [];
    final rawPhotos = json['photos'];
    if (rawPhotos is List) {
      for (final p in rawPhotos) {
        if (p is Map<String, dynamic>) {
          final url = p['url']?.toString();
          if (url != null && url.isNotEmpty) photosUrls.add(_fullUrl(url));
          final id = p['id'] as int?;
          if (id != null) photosIds.add(id);
        }
      }
    }
    
    if (json['court_img_url'] != null) courtImgUrl = _fullUrl(json['court_img_url'].toString());
    if (json['photos_urls'] != null && json['photos_urls'] is List) {
      photosUrls = (json['photos_urls'] as List).map((u) => _fullUrl(u.toString())).toList();
    }
    
    // ── Worker parsing — handles every shape Strapi can return ──────────────
    // DEBUG: uncomment the next line to see exact API shape in your logs
    debugPrint('[CourtFromJson] raw worker field for court ${json['id']}: ${json['worker']}');
    Map<String, dynamic>? assignedWorker;
    final rawWorker = json['worker'];
    if (rawWorker != null) {
      if (rawWorker is Map<String, dynamic>) {
        String? wId, wNom, wPhone;

        // Shape A — Strapi v4 REST: { data: { id, attributes: { nom, phone, ... } } }
        final strapiData = rawWorker['data'];
        if (strapiData is Map<String, dynamic>) {
          final attrs = (strapiData['attributes'] as Map<String, dynamic>?) ?? strapiData;
          wId    = (strapiData['id'] ?? attrs['id'])?.toString();
          wNom   = attrs['nom']?.toString() ?? attrs['username']?.toString() ?? attrs['name']?.toString();
          wPhone = attrs['phone']?.toString();
        }
        // Shape B — flat populated: { id, nom, phone, worker: {...}, ... }
        else {
          wId    = rawWorker['id']?.toString();
          wNom   = rawWorker['nom']?.toString()
                ?? rawWorker['username']?.toString()
                ?? rawWorker['name']?.toString();
          wPhone = rawWorker['phone']?.toString();

          // Shape C — worker profile is nested inside 'worker' key of the court's worker relation
          // e.g. court.worker = { id, nom, phone, worker: { id, username } }
          // (already covered by Shape B above)

          // Shape D — court returns worker as a user record: { id, username, email }
          // (covered by 'username' fallback above)
        }

        // Only assign if we got at least an id (don't create a ghost worker object)
        if (wId != null) {
          assignedWorker = {
            'id':    wId,
            'nom':   (wNom != null && wNom.isNotEmpty) ? wNom : null,
            'phone': (wPhone != null && wPhone.isNotEmpty) ? wPhone : null,
          };
          debugPrint('[CourtFromJson] ✅ worker parsed → id=$wId nom=$wNom phone=$wPhone');
        } else {
          debugPrint('[CourtFromJson] ⚠️  worker map found but no id — shape unrecognised: $rawWorker');
        }
      } else if (rawWorker is int || rawWorker is String) {
        // Shape E — bare id only (relation not populated)
        assignedWorker = {'id': rawWorker.toString(), 'nom': null, 'phone': null};
        debugPrint('[CourtFromJson] worker is bare id: $rawWorker');
      }
    }
    
    return ManagedCourt(
      id: json['id'].toString(), name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '', sport: sportType,
      pricePerHour: (json['pricePerHour'] ?? 0).toDouble(),
      capacity: (json['capacity'] ?? 0) as int,
      photoUrls: photosUrls.isNotEmpty ? photosUrls : (json['photoUrls'] as List?)?.cast<String>() ?? [],
      photosUrls: photosUrls,
      courtImgUrl: courtImgUrl,
      amenities: amenitiesList, isActive: json['isActive'] as bool? ?? true,
      courtImgId: courtImgId, photosIds: photosIds,
      surface: json['surface']?.toString() ?? 'Artificial Turf',
      assignedWorker: assignedWorker,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ROOT PAGE
// ─────────────────────────────────────────────────────────────────────────────
class VenuePage extends StatefulWidget {
  final String? managerToken;
  const VenuePage({super.key, this.managerToken});
  @override State<VenuePage> createState() => _VenuePageState();
}

class _VenuePageState extends State<VenuePage> {
  List<ManagedVenue> _venues    = [];
  bool               _isLoading = true;
  String?            _error;
  final _storage                = const FlutterSecureStorage();
  String?            _token;
  Map<String, dynamic>? _currentUser;

  @override void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      _token = widget.managerToken ?? await _storage.read(key: 'jwt_token');
      if (_token == null || _token!.isEmpty) throw Exception('Not authenticated');
      final response = await PlayerManagerAuthService.getMe(_token!);
      setState(() { 
        if (response.containsKey('user')) {
          _currentUser = response['user'] as Map<String, dynamic>;
          _currentUser!['photoUrl'] = response['photoUrl'];
        } else {
          _currentUser = response;
        }
      });
      final venuesData = await VenueService.getVenues(_token!);
      final loaded = <ManagedVenue>[];

      // Fetch all workers once upfront for enrichment
      List<dynamic> allWorkers = [];
      Map<String, Map<String, dynamic>> workerLookup = {};
      try {
        allWorkers = await ManagerWorkerService.getMyWorkers(_token!);
        for (final w in allWorkers) {
          final id = w['id']?.toString();
          if (id != null) workerLookup[id] = w as Map<String, dynamic>;
        }
      } catch (e) { debugPrint('Worker prefetch failed (non-fatal): $e'); }

      for (final raw in venuesData) {
        final venue = ManagedVenue.fromJson(raw as Map<String, dynamic>);
        try {
          final courtsData = await VenueService.getVenueCourts(token: _token!, venueId: venue.id);
          final courts = (courtsData as List).map((c) => ManagedCourt.fromJson(c as Map<String, dynamic>)).toList();
          // Enrich worker names from prefetched worker list
          for (final court in courts) {
            if (court.assignedWorker == null) continue;
            final wId = court.assignedWorker!['id']?.toString();
            if (wId == null) continue;
            final nom = court.assignedWorker!['nom'] as String?;
            if (nom != null && nom.isNotEmpty) continue;
            final fullWorker = workerLookup[wId];
            if (fullWorker != null) {
              court.assignedWorker!['nom']   = fullWorker['nom']?.toString()   ?? fullWorker['username']?.toString();
              court.assignedWorker!['phone'] = fullWorker['phone']?.toString();
            }
          }
          venue.courts = courts;
        } catch (e) { debugPrint('Courts load error for ${venue.id}: $e'); venue.courts = []; }
        loaded.add(venue);
      }
      setState(() { _venues = loaded; _isLoading = false; });
    } catch (e) {
      debugPrint('VenuePage error: $e');
      setState(() { _error = e.toString().replaceAll('Exception:', '').trim(); _isLoading = false; });
    }
  }

  String _initials(String name) {
    if (name.isEmpty) return 'M';
    final p = name.trim().split(' ');
    return p.length >= 2 ? '${p[0][0]}${p[1][0]}'.toUpperCase() : name[0].toUpperCase();
  }

  void _updateVenue(ManagedVenue v) => setState(() { final i = _venues.indexWhere((x) => x.id == v.id); if (i != -1) _venues[i] = v; });
  void _deleteVenue(String id) => setState(() => _venues.removeWhere((v) => v.id == id));

  @override
  Widget build(BuildContext context) {
    final navH        = kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    final managerName = (_currentUser?['username'] ?? 'Manager').toString();
    final photoUrl = _currentUser?['photoUrl'];

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Column(children: [
        _Header(
          venueCount: _venues.length,
          managerName: managerName,
          managerInitials: _initials(managerName),
          photoUrl: photoUrl,
        ),
        Expanded(child: _buildBody(navH)),
      ]),
    );
  }

  Widget _buildBody(double navH) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: kPrimary));
    if (_error != null) return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.error_outline, size: 48, color: kRed),
      const SizedBox(height: 12),
      Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: kTextMid)),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: _loadData, style: ElevatedButton.styleFrom(backgroundColor: kPrimary), child: const Text('Retry')),
    ])));

    return RefreshIndicator(
      color: kPrimary,
      onRefresh: _loadData,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, navH + 24),
        physics: const BouncingScrollPhysics(),
        children: [
          if (_venues.isEmpty)
            _EmptyVenues(onAdd: _openAddVenue)
          else
            ..._venues.map((venue) => _VenueCard(
              venue: venue,
              onTap: () {
                final tok = _token;
                if (tok == null || tok.isEmpty) return;
                Navigator.push(context, MaterialPageRoute(builder: (_) => _VenueDetailPage(
                  venue: venue, token: tok,
                  onSaved: _updateVenue,
                  onDeleted: () => _deleteVenue(venue.id),
                )));
              },
            )),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _openAddVenue,
            child: Container(
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(18),
                border: Border.all(color: kPrimary.withOpacity(0.25), width: 1.5),
                boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(width: 30, height: 30, decoration: BoxDecoration(gradient: const LinearGradient(colors: [kPrimary, Color(0xFF007B7D)]), borderRadius: BorderRadius.circular(9)), child: const Icon(Icons.add_rounded, color: Colors.white, size: 18)),
                const SizedBox(width: 10),
                const Text('Add New Venue', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kPrimary)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _openAddVenue() {
    final tok = _token;
    if (tok == null || tok.isEmpty) return;
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent, useSafeArea: true,
      builder: (_) => _VenueFormSheet(token: tok, onSave: (_) async { Navigator.pop(context); await _loadData(); }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final int venueCount;
  final String managerName, managerInitials;
  final String? photoUrl;
  const _Header({required this.venueCount, required this.managerName, required this.managerInitials, this.photoUrl});

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [Color(0xFF001F20), Color(0xFF003D3E), kPrimary], begin: Alignment.topLeft, end: Alignment.bottomRight),
    ),
    child: SafeArea(bottom: false, child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Color(0xFF007B7D), Color(0xFF00A8AB)]), border: Border.all(color: Colors.white.withOpacity(0.25), width: 2.5)),
            child: photoUrl != null && photoUrl!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      photoUrl!,
                      fit: BoxFit.cover,
                      width: 52,
                      height: 52,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(
                          managerInitials,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      managerInitials,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Welcome back,', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
            Text(managerName, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.4), overflow: TextOverflow.ellipsis),
          ])),
          Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.15))), child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 19)),
        ]),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.09), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.12))),
          child: Row(children: [
            _HS('$venueCount', 'Venues', Icons.location_city_rounded),
            _HDivider(), _HS('0', 'Courts', Icons.sports_tennis_rounded),
            _HDivider(), _HS('0', 'Active', Icons.check_circle_outline_rounded),
            _HDivider(), _HS('0', 'Rating', Icons.star_rounded),
          ]),
        ),
      ]),
    )),
  );
}

class _HS extends StatelessWidget {
  final String value, label; final IconData icon;
  const _HS(this.value, this.label, this.icon);
  @override Widget build(BuildContext context) => Expanded(child: Column(children: [
    Icon(icon, size: 14, color: Colors.white.withOpacity(0.65)), const SizedBox(height: 4),
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
    Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9.5)),
  ]));
}

class _HDivider extends StatelessWidget {
  @override Widget build(BuildContext context) => Container(width: 1, height: 26, color: Colors.white.withOpacity(0.15), margin: const EdgeInsets.symmetric(horizontal: 4));
}

// ─────────────────────────────────────────────────────────────────────────────
// VENUE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _VenueCard extends StatelessWidget {
  final ManagedVenue venue; final VoidCallback onTap;
  const _VenueCard({required this.venue, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 8))]),
      child: Column(children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          child: SizedBox(height: 165, child: Stack(fit: StackFit.expand, children: [
            venue.photoUrls.isNotEmpty
                ? Image.network(venue.photoUrls.first, fit: BoxFit.cover, loadingBuilder: (_, child, progress) => progress == null ? child : Container(color: const Color(0xFF003D3E), child: const Center(child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2))), errorBuilder: (_, __, ___) => const _VenuePh())
                : const _VenuePh(),
            Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.65)], stops: const [0.35, 1.0]))),
            Positioned(bottom: 14, left: 14, right: 14, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(venue.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.4)),
              const SizedBox(height: 3),
              Row(children: [Icon(Icons.location_on_rounded, size: 11, color: Colors.white.withOpacity(0.6)), const SizedBox(width: 4), Flexible(child: Text(venue.location, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11)))]),
            ])),
          ])),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
          child: Row(children: [
            _VChip(Icons.sports_tennis_rounded, '${venue.courts.length} courts', kPrimary),
            const SizedBox(width: 10),
            Flexible(child: _VChip(Icons.location_on_rounded, venue.location, kTextMid)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [kPrimary, Color(0xFF007B7D)]), borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [Text('Manage', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)), SizedBox(width: 5), Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 13)]),
            ),
          ]),
        ),
      ]),
    ),
  );
}

class _VChip extends StatelessWidget {
  final IconData icon; final String label; final Color color;
  const _VChip(this.icon, this.label, this.color);
  @override Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 11, color: color), const SizedBox(width: 4), Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)))]);
}

class _VenuePh extends StatelessWidget {
  const _VenuePh();
  @override Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF001F20), kPrimary], begin: Alignment.topLeft, end: Alignment.bottomRight)),
    child: Center(child: Icon(Icons.stadium_rounded, size: 52, color: Colors.white.withOpacity(0.18))),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY VENUES
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyVenues extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyVenues({required this.onAdd});
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
    child: Column(children: [
      Container(width: 90, height: 90, decoration: BoxDecoration(gradient: LinearGradient(colors: [kPrimary.withOpacity(0.09), kPrimary.withOpacity(0.03)]), shape: BoxShape.circle, border: Border.all(color: kPrimary.withOpacity(0.12), width: 2)), child: Icon(Icons.add_business_rounded, size: 40, color: kPrimary.withOpacity(0.4))),
      const SizedBox(height: 20),
      const Text('No venues yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kTextDark)),
      const SizedBox(height: 8),
      const Text('Add your first venue to start managing courts and bookings.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: kTextMid, height: 1.6)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// VENUE DETAIL PAGE
// ─────────────────────────────────────────────────────────────────────────────
class _VenueDetailPage extends StatefulWidget {
  final ManagedVenue venue;
  final String token;
  final ValueChanged<ManagedVenue> onSaved;
  final VoidCallback onDeleted;
  const _VenueDetailPage({required this.venue, required this.token, required this.onSaved, required this.onDeleted});
  @override State<_VenueDetailPage> createState() => _VenueDetailPageState();
}

class _VenueDetailPageState extends State<_VenueDetailPage> with SingleTickerProviderStateMixin {
  late ManagedVenue _v;
  SportType? _filter;
  bool _isLoading = false;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _v = widget.venue;
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadCourts();
  }

  @override void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _loadCourts() async {
    setState(() => _isLoading = true);
    try {
      final data = await VenueService.getVenueCourts(token: widget.token, venueId: _v.id);
      final courts = (data as List).map((c) => ManagedCourt.fromJson(c as Map<String, dynamic>)).toList();

      // ── Worker enrichment ──────────────────────────────────────────────
      // getVenueCourts may return the worker as a bare id or with no nom.
      // Fetch the full workers list once and use it to fill in missing names.
      final needsEnrichment = courts.any((c) =>
          c.assignedWorker != null &&
          (c.assignedWorker!['nom'] == null || (c.assignedWorker!['nom'] as String?)!.isEmpty));

      if (needsEnrichment) {
        try {
          final workersList = await ManagerWorkerService.getMyWorkers(widget.token);
          // Build a quick lookup map: worker id → worker data
          final workerMap = <String, Map<String, dynamic>>{};
          for (final w in workersList) {
            final id = w['id']?.toString();
            if (id != null) workerMap[id] = w as Map<String, dynamic>;
          }
          // Patch each court whose worker name is missing
          for (final court in courts) {
            if (court.assignedWorker == null) continue;
            final wId = court.assignedWorker!['id']?.toString();
            if (wId == null) continue;
            final nom = court.assignedWorker!['nom'] as String?;
            if (nom != null && nom.isNotEmpty) continue; // already has name
            final fullWorker = workerMap[wId];
            if (fullWorker != null) {
              court.assignedWorker!['nom']   = fullWorker['nom']?.toString()   ?? fullWorker['username']?.toString();
              court.assignedWorker!['phone'] = fullWorker['phone']?.toString();
            }
          }
        } catch (e) {
          debugPrint('Worker enrichment failed (non-fatal): $e');
        }
      }

      setState(() { _v.courts = courts; _isLoading = false; });
    } catch (e) { debugPrint('Load courts: $e'); setState(() => _isLoading = false); }
  }

  List<ManagedCourt> get _filtered => _v.courts.where((c) => _filter == null || c.sport == _filter).toList();

  @override
  Widget build(BuildContext context) {
    final navH   = kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    final active = _v.courts.where((c) => c.isActive).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Column(children: [
        _VenueHero(venue: _v, onBack: () => Navigator.pop(context), onEdit: _openEditVenue, onDelete: _confirmDeleteVenue),
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabCtrl,
            labelColor: kPrimary,
            unselectedLabelColor: kTextMid,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            indicatorColor: kPrimary,
            indicatorWeight: 2.5,
            dividerColor: const Color(0xFFEAECF0),
            tabs: const [Tab(text: 'Courts'), Tab(text: 'Schedule')],
          ),
        ),
        Expanded(child: TabBarView(controller: _tabCtrl, children: [
          _CourtsTab(
            v: _v, filter: _filter, isLoading: _isLoading, filtered: _filtered,
            navH: navH, active: active, token: widget.token,
            onFilterChanged: (s) => setState(() => _filter = s),
            onAddCourt: () => _openCourtForm(null),
            onEditCourt: _openCourtForm,
            onDeleteCourt: _confirmDeleteCourt,
            onToggle: (court) => setState(() { final idx = _v.courts.indexWhere((c) => c.id == court.id); if (idx != -1) _v.courts[idx].isActive = !_v.courts[idx].isActive; }),
            onRefreshCourts: _loadCourts,
          ),
          _ScheduleTab(venue: _v, token: widget.token, courts: _v.courts),
        ])),
      ]),
    );
  }

  void _openEditVenue() => showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent, useSafeArea: true,
    builder: (_) => _VenueFormSheet(existing: _v, token: widget.token, onSave: (u) { Navigator.pop(context); setState(() => _v = u); widget.onSaved(_v); }),
  );

  void _openCourtForm(ManagedCourt? existing) => showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent, useSafeArea: true,
    builder: (_) => _CourtFormSheet(
      existing: existing, token: widget.token, venueId: _v.id, venueSports: _v.sports,
      onSave: (_) async { Navigator.pop(context); await _loadCourts(); widget.onSaved(_v); },
    ),
  );

  void _confirmDeleteVenue() => showDialog(context: context, builder: (_) => _ConfirmDialog(
    icon: Icons.delete_forever_rounded, iconColor: kRed, title: 'Delete Venue',
    message: 'Remove "${_v.name}" and all its courts permanently?',
    confirmLabel: 'Delete', confirmColor: kRed,
    onConfirm: () async { Navigator.pop(context); Navigator.pop(context); try { await VenueService.deleteVenue(token: widget.token, venueId: _v.id); widget.onDeleted(); } catch (e) { if (mounted) _snack('Failed to delete: $e', kRed); } },
  ));

  void _confirmDeleteCourt(ManagedCourt c) => showDialog(context: context, builder: (_) => _ConfirmDialog(
    icon: Icons.delete_outline_rounded, iconColor: kRed, title: 'Delete Court',
    message: 'Remove "${c.name}" permanently?', confirmLabel: 'Delete', confirmColor: kRed,
    onConfirm: () async { Navigator.pop(context); try { await CourtService.deleteCourt(token: widget.token, courtId: c.id); await _loadCourts(); widget.onSaved(_v); } catch (e) { if (mounted) _snack('Failed to delete court: $e', kRed); } },
  ));

  void _snack(String msg, Color color) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating)); }
}

// ─────────────────────────────────────────────────────────────────────────────
// COURTS TAB
// ─────────────────────────────────────────────────────────────────────────────
class _CourtsTab extends StatelessWidget {
  final ManagedVenue v; final SportType? filter; final bool isLoading;
  final List<ManagedCourt> filtered; final double navH; final int active;
  final String token;
  final ValueChanged<SportType?> onFilterChanged;
  final VoidCallback onAddCourt;
  final ValueChanged<ManagedCourt> onEditCourt, onDeleteCourt, onToggle;
  final VoidCallback onRefreshCourts;
  const _CourtsTab({required this.v, required this.filter, required this.isLoading, required this.filtered, required this.navH, required this.active, required this.token, required this.onFilterChanged, required this.onAddCourt, required this.onEditCourt, required this.onDeleteCourt, required this.onToggle, required this.onRefreshCourts});

  @override Widget build(BuildContext context) => CustomScrollView(
    physics: const BouncingScrollPhysics(),
    slivers: [
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 0), child: _VenueInfoStrip(venue: v))),
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 0), child: _VenueStats(courts: v.courts.length, active: active, sports: v.sports.length))),
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 28, 20, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Courts', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kTextDark, letterSpacing: -0.5)),
            Text('${v.courts.length} courts · $active active', style: const TextStyle(fontSize: 12, color: kTextMid)),
          ])),
          _GradBtn(icon: Icons.add_rounded, label: 'Add Court', onTap: onAddCourt),
        ]),
        if (v.sports.length > 1) ...[
          const SizedBox(height: 14),
          _SportFilter(sports: v.sports, selected: filter, onChanged: onFilterChanged),
        ],
      ]))),
      if (isLoading)
        const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator(color: kPrimary))))
      else if (filtered.isEmpty)
        SliverToBoxAdapter(child: _EmptyCourts(onAdd: onAddCourt))
      else
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 14, 16, navH + 32),
          sliver: SliverList(delegate: SliverChildBuilderDelegate(
            (_, i) => _CourtCard(
              court: filtered[i], token: token,
              onEdit: () => onEditCourt(filtered[i]),
              onDelete: () => onDeleteCourt(filtered[i]),
              onToggle: () => onToggle(filtered[i]),
              onRefreshCourts: onRefreshCourts,
            ),
            childCount: filtered.length,
          )),
        ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SCHEDULE TAB
// ─────────────────────────────────────────────────────────────────────────────
class _ScheduleTab extends StatefulWidget {
  final ManagedVenue venue; final String token; final List<ManagedCourt> courts;
  const _ScheduleTab({required this.venue, required this.token, required this.courts});
  @override State<_ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<_ScheduleTab> {
  int _selectedCourt = 0;
  List<Map<String, dynamic>> _dayPlans = [];
  bool _loading = false;
  String? _error;

  @override void initState() { super.initState(); if (widget.courts.isNotEmpty) _loadDayPlans(); }

  String? get _currentCourtId => widget.courts.isEmpty || _selectedCourt >= widget.courts.length ? null : widget.courts[_selectedCourt].id;
  String  get _currentCourtName => widget.courts.isEmpty || _selectedCourt >= widget.courts.length ? '' : widget.courts[_selectedCourt].name;

  Future<void> _loadDayPlans() async {
    if (_currentCourtId == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/week-agendas/court/$_currentCourtId'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        final raw = body['dayPlans'] as List? ?? [];
        setState(() { _dayPlans = raw.cast<Map<String, dynamic>>().toList(); _loading = false; });
      } else {
        setState(() { _error = 'Error ${res.statusCode}'; _loading = false; });
      }
    } catch (e) {
      debugPrint('_loadDayPlans: $e');
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override Widget build(BuildContext context) {
    if (widget.courts.isEmpty) return _emptyCourtsMsg();

    return Column(children: [
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('SELECT COURT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kTextMid, letterSpacing: 0.8)),
          const SizedBox(height: 8),
          SizedBox(height: 34, child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.courts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final sel = _selectedCourt == i;
              final sc  = widget.courts[i].sport.color;
              return GestureDetector(
                onTap: () { setState(() { _selectedCourt = i; _dayPlans = []; _error = null; }); _loadDayPlans(); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: sel ? kPrimary : const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: sel ? [BoxShadow(color: kPrimary.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 2))] : [],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(widget.courts[i].sport.icon, size: 12, color: sel ? Colors.white : sc),
                    const SizedBox(width: 5),
                    Text(widget.courts[i].name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : kTextMid)),
                  ]),
                ),
              );
            },
          )),
        ]),
      ),
      const Divider(height: 1, color: Color(0xFFEAECF0)),
      Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : _error != null
              ? _errorView()
              : _buildDayPlanList()),
    ]);
  }

  Widget _emptyCourtsMsg() => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.calendar_today_rounded, size: 48, color: kTextLight.withOpacity(0.4)),
    const SizedBox(height: 12),
    const Text('No courts added yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kTextDark)),
    const SizedBox(height: 4),
    const Text('Add courts first, then configure their schedules.', style: TextStyle(fontSize: 13, color: kTextMid), textAlign: TextAlign.center),
  ])));

  Widget _errorView() => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.error_outline, size: 40, color: kRed),
    const SizedBox(height: 10),
    Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: kTextMid)),
    const SizedBox(height: 14),
    ElevatedButton(onPressed: _loadDayPlans, style: ElevatedButton.styleFrom(backgroundColor: kPrimary), child: const Text('Retry')),
  ])));

  Widget _buildDayPlanList() {
    final navH = kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 14, 16, navH + 20),
      physics: const BouncingScrollPhysics(),
      children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Day Plans', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kTextDark, letterSpacing: -0.3)),
            Text(_currentCourtName, style: const TextStyle(fontSize: 12, color: kTextMid)),
          ])),
          _GradBtn(icon: Icons.add_rounded, label: 'Add Day', onTap: _showCreateDayPlan),
        ]),
        const SizedBox(height: 16),
        if (_dayPlans.isEmpty)
          _emptySchedule()
        else
          ..._dayPlans.map((plan) => _DayPlanCard(plan: plan, token: widget.token, onRefresh: _loadDayPlans)),
      ],
    );
  }

  Widget _emptySchedule() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
    child: Column(children: [
      Container(width: 64, height: 64, decoration: BoxDecoration(color: kPrimary.withOpacity(0.07), shape: BoxShape.circle),
        child: Icon(Icons.calendar_today_rounded, size: 28, color: kPrimary.withOpacity(0.45))),
      const SizedBox(height: 14),
      const Text('No day plans yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kTextDark)),
      const SizedBox(height: 5),
      const Text('Tap "Add Day" to configure this court\'s schedule.', style: TextStyle(fontSize: 12, color: kTextMid, height: 1.5), textAlign: TextAlign.center),
    ]),
  );

  void _showCreateDayPlan() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent, useSafeArea: true,
      builder: (_) => _DayPlanFormSheet(token: widget.token, courtId: _currentCourtId ?? '', onSaved: () { Navigator.pop(context); _loadDayPlans(); }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DAY PLAN CARD
// ─────────────────────────────────────────────────────────────────────────────
class _DayPlanCard extends StatefulWidget {
  final Map<String, dynamic> plan;
  final String token;
  final VoidCallback onRefresh;
  const _DayPlanCard({required this.plan, required this.token, required this.onRefresh});
  @override State<_DayPlanCard> createState() => _DayPlanCardState();
}

class _DayPlanCardState extends State<_DayPlanCard> {
  bool _expanded = false;
  bool _loadingSlots = false;
  List<Map<String, dynamic>> _slots = [];
  bool _slotsFetched = false;

  String get _id        => widget.plan['id']?.toString()        ?? '';
  String get _dayOfWeek => widget.plan['dayOfWeek']?.toString() ?? '—';
  String get _dayType   => widget.plan['dayType']?.toString()   ?? 'normal';
  String get _date      => widget.plan['date']?.toString()      ?? '';

  bool   get _isDayOff  => _dayType == 'day_off';

  Color  get _typeColor {
    switch (_dayType) {
      case 'normal':      return kGreen;
      case 'day_off':     return kTextLight;
      case 'urgent_only': return kAmber;
      default:            return kPrimary;
    }
  }
  String get _typeLabel {
    switch (_dayType) {
      case 'normal':      return 'Open';
      case 'day_off':     return 'Day Off';
      case 'urgent_only': return 'Urgent Only';
      default:            return _dayType.replaceAll('_', ' ');
    }
  }

  Future<void> _fetchSlots() async {
    if (_slotsFetched) return;
    setState(() => _loadingSlots = true);
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/day-plans/$_id/availability'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        final raw = body['slots'] as List? ?? [];
        setState(() {
          _slots        = raw.cast<Map<String, dynamic>>();
          _slotsFetched = true;
          _loadingSlots = false;
        });
      } else {
        setState(() => _loadingSlots = false);
      }
    } catch (e) {
      debugPrint('_fetchSlots: $e');
      setState(() => _loadingSlots = false);
    }
  }

  void _toggleExpand() {
    setState(() => _expanded = !_expanded);
    if (_expanded && !_isDayOff) _fetchSlots();
  }

  void _showAddSlot() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent, useSafeArea: true,
      builder: (_) => _TimeSlotFormSheet(dayPlanId: _id, token: widget.token, onSaved: () { Navigator.pop(context); setState(() { _slotsFetched = false; _slots = []; }); _fetchSlots(); }),
    );
  }

  void _deleteSlot(String slotId) async {
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/api/time-slots/$slotId'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (res.statusCode == 200 || res.statusCode == 204) {
        setState(() { _slots.removeWhere((s) => s['id']?.toString() == slotId); });
      } else {
        final b = json.decode(res.body);
        if (mounted) _snack(b['error']?.toString() ?? 'Delete failed');
      }
    } catch (e) { if (mounted) _snack('Error: $e'); }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: kRed, behavior: SnackBarBehavior.floating));

  @override Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))]),
    child: Column(children: [
      GestureDetector(
        onTap: _toggleExpand,
        child: Padding(padding: const EdgeInsets.fromLTRB(14, 12, 12, 12), child: Row(children: [
          Container(width: 44, height: 44,
            decoration: BoxDecoration(color: (!_isDayOff ? kPrimary : kTextLight).withOpacity(0.09), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(
              _dayOfWeek.length >= 3 ? _dayOfWeek.substring(0, 3).toUpperCase() : _dayOfWeek.toUpperCase(),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                  color: !_isDayOff ? kPrimary : kTextLight, letterSpacing: 0.5)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_dayOfWeek, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kTextDark)),
            const SizedBox(height: 2),
            Row(children: [
              if (_date.isNotEmpty) ...[
                Text(_date, style: const TextStyle(fontSize: 11, color: kTextMid)),
                const SizedBox(width: 8),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: _typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(_typeLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _typeColor)),
              ),
            ]),
          ])),
          if (!_isDayOff) ...[
            GestureDetector(
              onTap: _showAddSlot,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(color: kPrimary.withOpacity(0.07), borderRadius: BorderRadius.circular(9)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.more_time_rounded, size: 13, color: kPrimary),
                  SizedBox(width: 4),
                  Text('+ Slot', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kPrimary)),
                ]),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, size: 18, color: kTextMid),
        ])),
      ),
      if (_expanded && !_isDayOff) ...[
        const Divider(height: 1, indent: 14, endIndent: 14, color: Color(0xFFEAECF0)),
        _loadingSlots
            ? const Padding(padding: EdgeInsets.all(16), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary))))
            : _slots.isEmpty
                ? Padding(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14), child: Row(children: [
                    Icon(Icons.info_outline_rounded, size: 14, color: kTextLight),
                    const SizedBox(width: 8),
                    const Text('No time slots yet. Tap "+ Slot" to add one.', style: TextStyle(fontSize: 12, color: kTextMid)),
                  ]))
                : Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                    child: Wrap(spacing: 6, runSpacing: 6, children: _slots.map((s) {
                      final slotId   = s['id']?.toString()       ?? '';
                      final start    = s['startTime']?.toString() ?? '';
                      final end      = s['endTime']?.toString()   ?? '';
                      final active   = s['isActive']  as bool?    ?? true;
                      final booked   = s['isBooked']  as bool?    ?? false;
                      Color chipColor = booked ? kRed : (active ? kGreen : kTextLight);
                      return GestureDetector(
                        onLongPress: booked ? null : () => _deleteSlot(slotId),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: chipColor.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: chipColor.withOpacity(0.25)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(width: 6, height: 6, decoration: BoxDecoration(color: chipColor, shape: BoxShape.circle)),
                            const SizedBox(width: 5),
                            Text('$start – $end', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                color: booked ? kRed : (active ? kTextDark : kTextLight))),
                            if (booked) ...[
                              const SizedBox(width: 4),
                              const Text('booked', style: TextStyle(fontSize: 9, color: kRed, fontWeight: FontWeight.w600)),
                            ],
                          ]),
                        ),
                      );
                    }).toList()),
                  ),
      ],
      if (_expanded && _isDayOff)
        const Padding(padding: EdgeInsets.all(14), child: Row(children: [
          Icon(Icons.beach_access_rounded, size: 14, color: kTextLight),
          SizedBox(width: 8),
          Text('Day off — no bookings available.', style: TextStyle(fontSize: 12, color: kTextMid)),
        ])),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DAY PLAN FORM SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _DayPlanFormSheet extends StatefulWidget {
  final String token;
  final String courtId;
  final VoidCallback onSaved;
  const _DayPlanFormSheet({required this.token, required this.courtId, required this.onSaved});
  @override State<_DayPlanFormSheet> createState() => _DayPlanFormSheetState();
}

class _DayPlanFormSheetState extends State<_DayPlanFormSheet> {
  DateTime? _selectedDate;
  String    _type    = 'normal';
  bool      _saving  = false;
  String?   _errorMsg;
  final List<Map<String, String>> _slots = [];

  static const _types = [
    {'value': 'normal',      'label': 'Normal Day',   'icon': Icons.wb_sunny_rounded},
    {'value': 'day_off',     'label': 'Day Off',       'icon': Icons.beach_access_rounded},
    {'value': 'urgent_only', 'label': 'Urgent Only',   'icon': Icons.warning_amber_rounded},
    {'value': 'special',     'label': 'Special Day',   'icon': Icons.stars_rounded},
  ];

  bool get _isDayOff => _type == 'day_off';

  String get _dayOfWeek {
    if (_selectedDate == null) return 'monday';
    const names = ['monday','tuesday','wednesday','thursday','friday','saturday','sunday'];
    return names[_selectedDate!.weekday - 1];
  }

  String get _dateLabel {
    if (_selectedDate == null) return 'Tap to pick a date';
    final d = _selectedDate!;
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const days   = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  Future<void> _pickDate() async {
    final now  = DateTime.now();
    final picked = await showDatePicker(
      context:      context,
      initialDate:  _selectedDate ?? now,
      firstDate:    now.subtract(const Duration(days: 30)),
      lastDate:     now.add(const Duration(days: 365)),
      builder:      (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: kPrimary, onPrimary: Colors.white, surface: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _addSlot() {
    String start = '09:00', end = '10:00';
    if (_slots.isNotEmpty) {
      final lastEnd = _slots.last['endTime'] ?? '09:00';
      final parts   = lastEnd.split(':');
      if (parts.length == 2) {
        int h = (int.tryParse(parts[0]) ?? 9);
        start = '${h.toString().padLeft(2,'0')}:00';
        end   = '${(h + 1).toString().padLeft(2,'0')}:00';
      }
    }
    setState(() => _slots.add({'startTime': start, 'endTime': end}));
  }

  void _removeSlot(int i) => setState(() => _slots.removeAt(i));

  Future<void> _pickTime(int slotIdx, bool isStart) async {
    final cur    = _slots[slotIdx][isStart ? 'startTime' : 'endTime'] ?? '09:00';
    final parts  = cur.split(':');
    final initial = TimeOfDay(hour: int.tryParse(parts[0]) ?? 9, minute: int.tryParse(parts[1]) ?? 0);
    final picked  = await showTimePicker(context: context, initialTime: initial,
      builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: ColorScheme.light(primary: kPrimary)), child: child!));
    if (picked != null) {
      setState(() {
        _slots[slotIdx][isStart ? 'startTime' : 'endTime'] =
            '${picked.hour.toString().padLeft(2,'0')}:${picked.minute.toString().padLeft(2,'0')}';
      });
    }
  }

  Future<void> _save() async {
    if (_selectedDate == null) {
      setState(() => _errorMsg = 'Please pick a date first');
      return;
    }
    setState(() { _saving = true; _errorMsg = null; });
    try {
      final agendaId = await _getOrCreateWeekAgenda();
      final d    = _selectedDate!;
      final date = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
      final dpRes = await http.post(
        Uri.parse('$_baseUrl/api/day-plans'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'},
        body: json.encode({'data': {
          'week_agend': agendaId,
          'dayOfWeek':  _dayOfWeek,
          'dayType':    _type,
          'date':       date,
        }}),
      );
      if (dpRes.statusCode != 200 && dpRes.statusCode != 201) {
        final body = _tryDecodeJson(dpRes.body);
        throw Exception(body?['error']?['message'] ?? 'Day plan error ${dpRes.statusCode}');
      }
      final dpBody   = json.decode(dpRes.body) as Map<String, dynamic>;
      final dpData   = (dpBody['data'] ?? dpBody) as Map<String, dynamic>;
      final dayPlanId = dpData['id']?.toString() ?? '';
      for (final slot in _slots) {
        await http.post(
          Uri.parse('$_baseUrl/api/time-slots'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'},
          body: json.encode({'data': {
            'day_plan':  dayPlanId,
            'startTime': slot['startTime'],
            'endTime':   slot['endTime'],
            'isActive':  true,
          }}),
        );
      }
      if (mounted) widget.onSaved();
    } catch (e) {
      if (mounted) setState(() { _errorMsg = e.toString().replaceAll('Exception: ',''); _saving = false; });
    }
  }

  Future<String> _getOrCreateWeekAgenda() async {
    final listRes = await http.get(
      Uri.parse('$_baseUrl/api/week-agendas?courtId=${widget.courtId}'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (listRes.statusCode == 200) {
      final body = json.decode(listRes.body);
      final list = (body['data'] ?? body) as List?;
      if (list != null && list.isNotEmpty) {
        final first = list.first as Map<String, dynamic>;
        return (first['id'] ?? (first['attributes'] ?? first)['id'])?.toString() ?? '';
      }
    }
    final createRes = await http.post(
      Uri.parse('$_baseUrl/api/week-agendas'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'},
      body: json.encode({'data': {'court': widget.courtId, 'statu': 'Published'}}),
    );
    if (createRes.statusCode == 200 || createRes.statusCode == 201) {
      final body = json.decode(createRes.body);
      final data = (body['data'] ?? body) as Map<String, dynamic>;
      return data['id']?.toString() ?? '';
    }
    throw Exception('Failed to create week agenda: ${createRes.statusCode}');
  }

  Color _typeColor(String t) {
    switch (t) {
      case 'normal':      return kGreen;
      case 'day_off':     return kTextLight;
      case 'urgent_only': return kAmber;
      default:            return kPrimary;
    }
  }

  @override Widget build(BuildContext context) {
    final bot = MediaQuery.of(context).padding.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(color: Color(0xFFF0F2F5), borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(children: [
        Container(decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 18), child: Column(children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E5EA), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 18),
          Row(children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(gradient: const LinearGradient(colors: [kPrimary, Color(0xFF007B7D)]), borderRadius: BorderRadius.circular(13)),
              child: const Icon(Icons.event_rounded, color: Colors.white, size: 20)),
            const SizedBox(width: 12),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Add Day Plan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kTextDark, letterSpacing: -0.3)),
              Text('Pick a date, type & time slots', style: TextStyle(fontSize: 12, color: kTextMid)),
            ])),
            GestureDetector(onTap: () => Navigator.pop(context),
              child: Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFFF0F2F5), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.close_rounded, size: 16, color: kTextMid))),
          ]),
        ])),
        Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(16, 14, 16, 20), children: [
          if (_errorMsg != null) Container(
            padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: kRed.withOpacity(0.07), borderRadius: BorderRadius.circular(12), border: Border.all(color: kRed.withOpacity(0.25))),
            child: Row(children: [
              Icon(Icons.error_outline_rounded, size: 16, color: kRed),
              const SizedBox(width: 8),
              Expanded(child: Text(_errorMsg!, style: const TextStyle(fontSize: 12, color: kRed))),
            ]),
          ),
          _Sec('Date', Icons.calendar_month_rounded, child: GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _selectedDate != null ? kPrimary.withOpacity(0.04) : const Color(0xFFF7F8FB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _selectedDate != null ? kPrimary.withOpacity(0.3) : const Color(0xFFE8EAF0), width: 1.5),
              ),
              child: Row(children: [
                Container(width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: _selectedDate != null ? kPrimary : const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.calendar_today_rounded, size: 18, color: _selectedDate != null ? Colors.white : kTextLight),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_dateLabel, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                      color: _selectedDate != null ? kTextDark : kTextLight)),
                  if (_selectedDate != null) ...[
                    const SizedBox(height: 2),
                    Text('Day: ${_dayOfWeek[0].toUpperCase()}${_dayOfWeek.substring(1)}',
                        style: const TextStyle(fontSize: 11, color: kTextMid)),
                  ],
                ])),
                Icon(Icons.chevron_right_rounded, size: 18, color: _selectedDate != null ? kPrimary : kTextLight),
              ]),
            ),
          )),
          const SizedBox(height: 14),
          _Sec('Day Type', Icons.tune_rounded, child: Column(children: _types.map((t) {
            final val = t['value'] as String;
            final sel = _type == val;
            final col = _typeColor(val);
            return GestureDetector(
              onTap: () => setState(() => _type = val),
              child: AnimatedContainer(duration: const Duration(milliseconds: 160),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(color: sel ? col.withOpacity(0.07) : Colors.white, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: sel ? col.withOpacity(0.35) : const Color(0xFFE8EAF0))),
                child: Row(children: [
                  Container(width: 34, height: 34, decoration: BoxDecoration(color: col.withOpacity(sel ? 0.12 : 0.06), borderRadius: BorderRadius.circular(9)),
                    child: Icon(t['icon'] as IconData, color: col, size: 17)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(t['label'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: sel ? col : kTextDark))),
                  AnimatedContainer(duration: const Duration(milliseconds: 160), width: 21, height: 21,
                    decoration: BoxDecoration(color: sel ? col : Colors.transparent, shape: BoxShape.circle,
                      border: Border.all(color: sel ? col : const Color(0xFFD0D3DB), width: 1.5)),
                    child: sel ? const Icon(Icons.check_rounded, size: 12, color: Colors.white) : null),
                ]),
              ),
            );
          }).toList())),
          const SizedBox(height: 14),
          if (!_isDayOff) _Sec('Time Slots', Icons.access_time_rounded, child: Column(children: [
            ..._slots.asMap().entries.map((e) {
              final i     = e.key;
              final slot  = e.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: kPrimary.withOpacity(0.04), borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kPrimary.withOpacity(0.15))),
                child: Row(children: [
                  Container(width: 28, height: 28, decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Center(child: Text('${i+1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: kPrimary)))),
                  const SizedBox(width: 10),
                  Expanded(child: GestureDetector(
                    onTap: () => _pickTime(i, true),
                    child: _TimeChip(label: 'Start', value: slot['startTime'] ?? ''),
                  )),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('→', style: TextStyle(color: kTextMid, fontSize: 14))),
                  Expanded(child: GestureDetector(
                    onTap: () => _pickTime(i, false),
                    child: _TimeChip(label: 'End', value: slot['endTime'] ?? ''),
                  )),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _removeSlot(i),
                    child: Container(width: 28, height: 28, decoration: BoxDecoration(color: kRed.withOpacity(0.07), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.close_rounded, size: 14, color: kRed)),
                  ),
                ]),
              );
            }),
            GestureDetector(
              onTap: _addSlot,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kPrimary.withOpacity(0.2), width: 1.5)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(width: 22, height: 22, decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.add_rounded, size: 14, color: kPrimary)),
                  const SizedBox(width: 8),
                  const Text('Add Time Slot', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kPrimary)),
                ]),
              ),
            ),
          ])),
          const SizedBox(height: 20),
        ])),
        Container(decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x10000000), blurRadius: 16, offset: Offset(0, -4))]),
          padding: EdgeInsets.fromLTRB(20, 14, 20, bot + 16),
          child: _ActBtn(Icons.check_rounded, _saving ? 'Saving…' : (_slots.isEmpty && !_isDayOff ? 'Save (no slots)' : 'Save Day Plan'), kPrimary, filled: true, onTap: _saving ? null : _save),
        ),
      ]),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String label, value;
  const _TimeChip({required this.label, required this.value});
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9), border: Border.all(color: const Color(0xFFE8EAF0))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 9, color: kTextMid, fontWeight: FontWeight.w600)),
      const SizedBox(height: 1),
      Text(value.isEmpty ? '--:--' : value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kTextDark, letterSpacing: -0.3)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TIME SLOT FORM SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _TimeSlotFormSheet extends StatefulWidget {
  final String dayPlanId, token; final VoidCallback onSaved;
  const _TimeSlotFormSheet({required this.dayPlanId, required this.token, required this.onSaved});
  @override State<_TimeSlotFormSheet> createState() => _TimeSlotFormSheetState();
}

class _TimeSlotFormSheetState extends State<_TimeSlotFormSheet> {
  final _startCtrl = TextEditingController(text: '09:00');
  final _endCtrl   = TextEditingController(text: '10:00');
  bool _active = true, _saving = false;
  String? _errorMsg;

  @override void dispose() { _startCtrl.dispose(); _endCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_startCtrl.text.trim().isEmpty || _endCtrl.text.trim().isEmpty) {
      setState(() => _errorMsg = 'Start and end times are required');
      return;
    }
    setState(() { _saving = true; _errorMsg = null; });
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/time-slots'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'},
        body: json.encode({'data': {
          'day_plan':  widget.dayPlanId,
          'startTime': _startCtrl.text.trim(),
          'endTime':   _endCtrl.text.trim(),
          'isActive':  _active,
        }}),
      );
      if ((res.statusCode == 200 || res.statusCode == 201) && mounted) {
        widget.onSaved();
      } else {
        final body = _tryDecodeJson(res.body);
        final msg  = body?['error']?['message'] ?? body?['error']?.toString() ?? 'Error ${res.statusCode}';
        setState(() { _errorMsg = msg; _saving = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _errorMsg = e.toString(); _saving = false; });
    }
  }

  @override Widget build(BuildContext context) {
    final bot = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(color: Color(0xFFF0F2F5), borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 18), child: Column(children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E5EA), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 18),
          Row(children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(gradient: const LinearGradient(colors: [kPrimary, Color(0xFF007B7D)]), borderRadius: BorderRadius.circular(13)),
              child: const Icon(Icons.more_time_rounded, color: Colors.white, size: 19)),
            const SizedBox(width: 12),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Add Time Slot', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kTextDark, letterSpacing: -0.3)),
              Text('Set start and end time', style: TextStyle(fontSize: 12, color: kTextMid)),
            ])),
            GestureDetector(onTap: () => Navigator.pop(context),
              child: Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFFF0F2F5), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.close_rounded, size: 16, color: kTextMid))),
          ]),
        ])),
        Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 14), child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (_errorMsg != null) ...[
            Container(
              padding: const EdgeInsets.all(10), margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(color: kRed.withOpacity(0.07), borderRadius: BorderRadius.circular(10), border: Border.all(color: kRed.withOpacity(0.25))),
              child: Text(_errorMsg!, style: const TextStyle(fontSize: 11, color: kRed)),
            ),
          ],
          _Sec('Time Range', Icons.access_time_rounded, child: Row(children: [
            Expanded(child: _TP(label: 'Start Time', value: _startCtrl.text, onChanged: (v) => setState(() => _startCtrl.text = v))),
            const SizedBox(width: 12),
            Expanded(child: _TP(label: 'End Time',   value: _endCtrl.text,   onChanged: (v) => setState(() => _endCtrl.text   = v))),
          ])),
          const SizedBox(height: 14),
          _Sec('Availability', Icons.toggle_on_rounded, child: GestureDetector(
            onTap: () => setState(() => _active = !_active),
            child: AnimatedContainer(duration: const Duration(milliseconds: 180), padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: _active ? kGreen.withOpacity(0.05) : const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _active ? kGreen.withOpacity(0.3) : const Color(0xFFE0E0E0))),
              child: Row(children: [
                Container(width: 36, height: 36, decoration: BoxDecoration(color: (_active ? kGreen : kTextLight).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(_active ? Icons.check_circle_rounded : Icons.cancel_rounded, color: _active ? kGreen : kTextLight, size: 19)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Available for booking', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kTextDark)),
                  Text(_active ? 'Players can book this slot' : 'Slot is blocked', style: const TextStyle(fontSize: 11, color: kTextMid)),
                ])),
                Switch(value: _active, onChanged: (v) => setState(() => _active = v), activeColor: kGreen),
              ]),
            ),
          )),
        ])),
        Container(decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x10000000), blurRadius: 16, offset: Offset(0, -4))]),
          padding: EdgeInsets.fromLTRB(20, 14, 20, bot + 16),
          child: _ActBtn(Icons.check_rounded, _saving ? 'Saving…' : 'Add Time Slot', kPrimary, filled: true, onTap: _saving ? null : _save)),
      ]),
    );
  }
}

Map<String, dynamic>? _tryDecodeJson(String s) {
  try { return json.decode(s) as Map<String, dynamic>?; } catch (_) { return null; }
}

// ─────────────────────────────────────────────────────────────────────────────
// VENUE HERO
// ─────────────────────────────────────────────────────────────────────────────
class _VenueHero extends StatefulWidget {
  final ManagedVenue venue;
  final VoidCallback onBack, onEdit, onDelete;
  const _VenueHero({required this.venue, required this.onBack, required this.onEdit, required this.onDelete});
  @override State<_VenueHero> createState() => _VenueHeroState();
}
class _VenueHeroState extends State<_VenueHero> {
  int _idx = 0;
  @override Widget build(BuildContext context) {
    final photos = widget.venue.photoUrls;
    return SizedBox(height: 260, child: Stack(fit: StackFit.expand, children: [
      photos.isEmpty ? const _VenuePh() : PageView.builder(itemCount: photos.length, onPageChanged: (i) => setState(() => _idx = i), itemBuilder: (_, i) => Image.network(photos[i], fit: BoxFit.cover, errorBuilder: (_, __, ___) => const _VenuePh())),
      Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.12), Colors.black.withOpacity(0.78)], stops: const [0.25, 1.0]))),
      Positioned(top: 0, left: 0, right: 0, child: SafeArea(bottom: false, child: Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 0), child: Row(children: [
        _HeroBtn(Icons.arrow_back_ios_rounded, widget.onBack), const Spacer(),
        _HeroPill(Icons.edit_rounded, 'Edit', widget.onEdit), const SizedBox(width: 8),
        _HeroBtn(Icons.delete_outline_rounded, widget.onDelete, color: kRed.withOpacity(0.85)),
      ])))),
      Positioned(bottom: 0, left: 0, right: 0, child: Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (widget.venue.sports.isNotEmpty) Wrap(spacing: 6, runSpacing: 4, children: widget.venue.sports.take(4).map((s) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4), decoration: BoxDecoration(color: s.color, borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(s.icon, size: 10, color: Colors.white), const SizedBox(width: 4), Text(s.label, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700))]))).toList()),
        const SizedBox(height: 6),
        Text(widget.venue.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.6)),
        if (photos.length > 1) ...[const SizedBox(height: 6), Row(children: List.generate(photos.length, (i) => AnimatedContainer(duration: const Duration(milliseconds: 200), margin: const EdgeInsets.only(right: 5), width: _idx == i ? 18 : 5, height: 5, decoration: BoxDecoration(color: _idx == i ? Colors.white : Colors.white.withOpacity(0.35), borderRadius: BorderRadius.circular(3))))),
      ]])),
   )]));
  }
}

class _HeroBtn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap; final Color? color;
  const _HeroBtn(this.icon, this.onTap, {this.color});
  @override Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(width: 40, height: 40, decoration: BoxDecoration(color: color ?? Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: Colors.white, size: 16)));
}
class _HeroPill extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _HeroPill(this.icon, this.label, this.onTap);
  @override Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.25))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.white, size: 13), const SizedBox(width: 5), Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))])));
}

// ─────────────────────────────────────────────────────────────────────────────
// VENUE INFO STRIP
// ─────────────────────────────────────────────────────────────────────────────
class _VenueInfoStrip extends StatelessWidget {
  final ManagedVenue venue;
  const _VenueInfoStrip({required this.venue});
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.location_on_rounded, size: 13, color: kPrimary), const SizedBox(width: 5),
        Expanded(child: Text(venue.location, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kPrimary))),
        const SizedBox(width: 12),
        Icon(Icons.access_time_rounded, size: 13, color: kGreen), const SizedBox(width: 5),
        Text('${venue.openTime}–${venue.closeTime}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kGreen)),
      ]),
      if (venue.lat != null && venue.lng != null) ...[
        const SizedBox(height: 8),
        Row(children: [Icon(Icons.gps_fixed_rounded, size: 13, color: kPurple), const SizedBox(width: 5), Text('${venue.lat!.toStringAsFixed(5)}, ${venue.lng!.toStringAsFixed(5)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kPurple))]),
      ],
      if (venue.description.isNotEmpty) ...[const SizedBox(height: 12), Divider(height: 1, color: Colors.grey.shade100), const SizedBox(height: 12), Text(venue.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: kTextMid, height: 1.5))],
      if (venue.amenities.isNotEmpty) ...[
        const SizedBox(height: 14), Divider(height: 1, color: Colors.grey.shade100), const SizedBox(height: 12),
        Row(children: [Icon(Icons.workspace_premium_rounded, size: 13, color: kPrimary), const SizedBox(width: 6), const Text('Amenities', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kTextDark))]),
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 6, children: venue.amenities.map((a) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: kPrimary.withOpacity(0.06), borderRadius: BorderRadius.circular(8), border: Border.all(color: kPrimary.withOpacity(0.15))), child: Text(a, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kPrimary)))).toList()),
      ],
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// VENUE STATS
// ─────────────────────────────────────────────────────────────────────────────
class _VenueStats extends StatelessWidget {
  final int courts, active, sports;
  const _VenueStats({required this.courts, required this.active, required this.sports});
  @override Widget build(BuildContext context) {
    final items = [_VSI('$courts', 'Courts', Icons.grid_view_rounded, kPrimary), _VSI('$active', 'Active', Icons.check_circle_outline_rounded, kGreen), _VSI('$sports', 'Sports', Icons.sports_rounded, kPurple)];
    return Row(children: items.asMap().entries.map((e) { final last = e.key == items.length - 1; final s = e.value; return Expanded(child: Padding(padding: EdgeInsets.only(right: last ? 0 : 10), child: Container(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: s.color.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 5))]), child: Column(children: [Container(width: 32, height: 32, decoration: BoxDecoration(color: s.color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(s.icon, size: 15, color: s.color)), const SizedBox(height: 6), Text(s.value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: s.color, letterSpacing: -0.5)), Text(s.label, style: const TextStyle(fontSize: 9.5, color: kTextMid, fontWeight: FontWeight.w500))])))); }).toList());
  }
}
class _VSI { final String value, label; final IconData icon; final Color color; const _VSI(this.value, this.label, this.icon, this.color); }

// ─────────────────────────────────────────────────────────────────────────────
// SPORT FILTER
// ─────────────────────────────────────────────────────────────────────────────
class _SportFilter extends StatelessWidget {
  final List<SportType> sports; final SportType? selected; final ValueChanged<SportType?> onChanged;
  const _SportFilter({required this.sports, required this.selected, required this.onChanged});
  @override Widget build(BuildContext context) => SizedBox(height: 36, child: ListView(scrollDirection: Axis.horizontal, children: [
    _Pill('All', Icons.apps_rounded, selected == null, kPrimary, () => onChanged(null)),
    ...sports.map((s) => _Pill(s.label, s.icon, selected == s, s.color, () => onChanged(selected == s ? null : s))),
  ]));
}
class _Pill extends StatelessWidget {
  final String label; final IconData icon; final bool on; final Color color; final VoidCallback onTap;
  const _Pill(this.label, this.icon, this.on, this.color, this.onTap);
  @override Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: AnimatedContainer(duration: const Duration(milliseconds: 200), margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7), decoration: BoxDecoration(color: on ? color : Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: on ? color.withOpacity(0.25) : Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 12, color: on ? Colors.white : kTextMid), const SizedBox(width: 5), Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: on ? Colors.white : kTextMid))])));
}
class _GradBtn extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _GradBtn({required this.icon, required this.label, required this.onTap});
  @override Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(gradient: const LinearGradient(colors: [kPrimary, Color(0xFF007B7D)]), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.white, size: 15), const SizedBox(width: 6), Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700))])));
}

// ─────────────────────────────────────────────────────────────────────────────
// COURT CARD — worker section updated: shows assigned worker card + remove btn
// ─────────────────────────────────────────────────────────────────────────────
class _CourtCard extends StatelessWidget {
  final ManagedCourt court; final String token;
  final VoidCallback onEdit, onDelete, onToggle, onRefreshCourts;
  const _CourtCard({required this.court, required this.token, required this.onEdit, required this.onDelete, required this.onToggle, required this.onRefreshCourts});
  
  List<String> get _allImages {
    final List<String> images = [];
    if (court.courtImgUrl != null && court.courtImgUrl!.isNotEmpty) {
      images.add(court.courtImgUrl!);
    }
    images.addAll(court.photosUrls);
    if (images.isEmpty) {
      images.addAll(court.photoUrls);
    }
    return images;
  }

  Future<void> _assignWorker(BuildContext context) async {
    try {
      final workers = await ManagerWorkerService.getMyWorkers(token);
      if (workers.isEmpty) {
        _showSnackBar(context, 'No workers available. Create workers first.', kRed);
        return;
      }
      final selectedWorker = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (ctx) => _WorkerSelectionDialog(
          workers: workers,
          currentWorker: court.assignedWorker,
        ),
      );
      if (selectedWorker != null) {
        await ManagerWorkerService.assignWorkerToSingleCourt(
          token: token,
          courtId: court.id,
          workerId: selectedWorker['id'].toString(),
        );
        onRefreshCourts();
        _showSnackBar(context, 'Worker assigned successfully', kGreen);
      }
    } catch (e) {
      _showSnackBar(context, 'Error: $e', kRed);
    }
  }

  Future<void> _unassignWorker(BuildContext context) async {
    if (court.assignedWorker == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Worker'),
        content: Text('Remove ${court.assignedWorker!['nom']} from this court?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: kRed),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ManagerWorkerService.removeWorkerFromSingleCourt(
          token: token,
          courtId: court.id,
        );
        onRefreshCourts();
        _showSnackBar(context, 'Worker removed from court', kGreen);
      } catch (e) {
        _showSnackBar(context, 'Error: $e', kRed);
      }
    }
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  String _workerInitials(String name) {
    if (name.isEmpty) return 'W';
    final parts = name.trim().split(' ');
    return parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final c = court;
    final sc = c.sport.color;
    final images = _allImages;
    final hasWorker = c.assignedWorker != null && (c.assignedWorker!['id'] != null || (c.assignedWorker!['nom'] != null && (c.assignedWorker!['nom'] as String?)!.isNotEmpty));
    final workerName = (c.assignedWorker?['nom'] as String? ?? '').isNotEmpty
        ? c.assignedWorker!['nom'] as String
        : (c.assignedWorker?['id'] != null ? 'Worker #${c.assignedWorker!['id']}' : '');
    final workerPhone = c.assignedWorker?['phone']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: sc.withOpacity(0.07), blurRadius: 18, offset: const Offset(0, 7))],
      ),
      child: Column(children: [
        // ── Image gallery ──────────────────────────────────────────────────
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          child: SizedBox(
            height: 180,
            width: double.infinity,
            child: images.isEmpty
                ? _CourtPh(sc)
                : _CourtGallery(photos: images, sc: sc, isActive: c.isActive),
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Court name + active toggle ─────────────────────────────────
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _CTag(c.sport.label, c.sport.icon, sc),
                const SizedBox(height: 7),
                Text(c.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: kTextDark, letterSpacing: -0.4)),
              ])),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    color: c.isActive ? kGreen.withOpacity(0.09) : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.isActive ? kGreen.withOpacity(0.3) : const Color(0xFFE0E0E0)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: c.isActive ? kGreen : kTextLight, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text(c.isActive ? 'Active' : 'Inactive', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.isActive ? kGreen : kTextLight)),
                  ]),
                ),
              ),
            ]),

            if (c.description.isNotEmpty) ...[
              const SizedBox(height: 7),
              Text(c.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: kTextMid, height: 1.5)),
            ],

            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF0F2F5)),
            const SizedBox(height: 14),

            // ── Worker section header ──────────────────────────────────────
            Row(children: [
              const Icon(Icons.badge_rounded, size: 14, color: kPrimary),
              const SizedBox(width: 6),
              const Text('Assigned Worker', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kTextDark)),
              const Spacer(),
              GestureDetector(
                onTap: () => _assignWorker(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [kPrimary, Color(0xFF007B7D)]),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(hasWorker ? Icons.swap_horiz_rounded : Icons.person_add_alt_1_rounded, size: 13, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(hasWorker ? 'Change' : 'Assign', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                  ]),
                ),
              ),
            ]),

            const SizedBox(height: 10),

            // ── Worker display card ────────────────────────────────────────
            if (hasWorker)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: kGreen.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kGreen.withOpacity(0.2)),
                ),
                child: Row(children: [
                  // Avatar
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF00C4C6), kPrimary]),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _workerInitials(workerName),
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name + phone
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      workerName.isNotEmpty ? workerName : 'Unknown Worker',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kTextDark),
                    ),
                    if (workerPhone.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(children: [
                        Icon(Icons.phone_rounded, size: 11, color: kTextMid),
                        const SizedBox(width: 4),
                        Text(workerPhone, style: const TextStyle(fontSize: 11, color: kTextMid, fontWeight: FontWeight.w500)),
                      ]),
                    ],
                  ])),
                  // Remove button
                  GestureDetector(
                    onTap: () => _unassignWorker(context),
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: kRed.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kRed.withOpacity(0.18)),
                      ),
                      child: const Icon(Icons.person_remove_alt_1_rounded, color: kRed, size: 16),
                    ),
                  ),
                ]),
              )
            else
              // ── No worker placeholder ──────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE8EAF0)),
                ),
                child: Row(children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: kTextLight.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.person_outline_rounded, color: kTextLight.withOpacity(0.5), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('No worker assigned yet', style: TextStyle(fontSize: 13, color: kTextMid, fontWeight: FontWeight.w500)),
                ]),
              ),

            const SizedBox(height: 14),

            // ── Edit + Delete row ──────────────────────────────────────────
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kPrimary.withOpacity(0.2)),
                    ),
                    child: Center(
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.edit_rounded, size: 15, color: kPrimary),
                        const SizedBox(width: 6),
                        Text('Edit Court', style: TextStyle(color: kPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: kRed.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kRed.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: kRed, size: 18),
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WORKER SELECTION DIALOG
// ─────────────────────────────────────────────────────────────────────────────
class _WorkerSelectionDialog extends StatefulWidget {
  final List<dynamic> workers;
  final Map<String, dynamic>? currentWorker;
  const _WorkerSelectionDialog({required this.workers, this.currentWorker});

  @override
  State<_WorkerSelectionDialog> createState() => _WorkerSelectionDialogState();
}

class _WorkerSelectionDialogState extends State<_WorkerSelectionDialog> {
  String? _selectedWorkerId;
  
  @override
  void initState() {
    super.initState();
    _selectedWorkerId = widget.currentWorker?['id']?.toString();
  }

  String _initials(String name) {
    if (name.isEmpty) return 'W';
    final p = name.trim().split(' ');
    return p.length >= 2 ? '${p[0][0]}${p[1][0]}'.toUpperCase() : name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [kPrimary, Color(0xFF007B7D)]), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.people_rounded, color: Colors.white, size: 19),
        ),
        const SizedBox(width: 12),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Assign Worker', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          Text('Select a worker for this court', style: TextStyle(fontSize: 11, color: kTextMid, fontWeight: FontWeight.w400)),
        ]),
      ]),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: widget.workers.isEmpty
            ? Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.person_off_rounded, size: 40, color: kTextLight.withOpacity(0.4)),
                  const SizedBox(height: 10),
                  const Text('No workers available.\nCreate workers first.', textAlign: TextAlign.center, style: TextStyle(color: kTextMid, fontSize: 13)),
                ]),
              )
            : ListView.separated(
                itemCount: widget.workers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (ctx, i) {
                  final worker = widget.workers[i];
                  final wId = worker['id'].toString();
                  final wName = (worker['nom'] ?? worker['username'] ?? 'Unknown').toString();
                  final wPhone = (worker['phone'] ?? '').toString();
                  final isSelected = _selectedWorkerId == wId;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedWorkerId = wId),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? kPrimary.withOpacity(0.06) : const Color(0xFFF7F8FB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isSelected ? kPrimary.withOpacity(0.3) : const Color(0xFFE8EAF0), width: 1.5),
                      ),
                      child: Row(children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(colors: [kPrimary, Color(0xFF007B7D)])
                                : LinearGradient(colors: [kTextLight.withOpacity(0.15), kTextLight.withOpacity(0.08)]),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _initials(wName),
                              style: TextStyle(
                                color: isSelected ? Colors.white : kTextMid,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(wName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isSelected ? kPrimary : kTextDark)),
                          if (wPhone.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Row(children: [
                              Icon(Icons.phone_rounded, size: 10, color: kTextMid),
                              const SizedBox(width: 3),
                              Text(wPhone, style: const TextStyle(fontSize: 11, color: kTextMid)),
                            ]),
                          ],
                        ])),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                            color: isSelected ? kPrimary : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(color: isSelected ? kPrimary : const Color(0xFFD0D3DB), width: 1.5),
                          ),
                          child: isSelected ? const Icon(Icons.check_rounded, size: 13, color: Colors.white) : null,
                        ),
                      ]),
                    ),
                  );
                },
              ),
      ),
      actions: [
        Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: 44,
                decoration: BoxDecoration(color: const Color(0xFFF0F2F5), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE0E3E8))),
                child: const Center(child: Text('Cancel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kTextMid))),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: _selectedWorkerId != null
                  ? () {
                      final selected = widget.workers.firstWhere((w) => w['id'].toString() == _selectedWorkerId);
                      Navigator.pop(context, selected);
                    }
                  : null,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: _selectedWorkerId != null ? 1.0 : 0.4,
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [kPrimary, Color(0xFF007B7D)]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: const Center(child: Text('Assign', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white))),
                ),
              ),
            ),
          ),
        ]),
      ],
    );
  }
}

class _CourtGallery extends StatefulWidget {
  final List<String> photos; final Color sc; final bool isActive;
  const _CourtGallery({required this.photos, required this.sc, required this.isActive});
  @override State<_CourtGallery> createState() => _CourtGalleryState();
}
class _CourtGalleryState extends State<_CourtGallery> {
  int _i = 0;
  @override Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
    PageView.builder(itemCount: widget.photos.length, onPageChanged: (i) => setState(() => _i = i), itemBuilder: (_, i) => Image.network(widget.photos[i], fit: BoxFit.cover, errorBuilder: (_, __, ___) => _CourtPh(widget.sc))),
    Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.22)], stops: const [0.5, 1.0]))),
    Positioned(top: 12, right: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: widget.isActive ? kGreen.withOpacity(0.88) : Colors.black.withOpacity(0.55), borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 5, height: 5, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)), const SizedBox(width: 4), Text(widget.isActive ? 'Active' : 'Inactive', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700))]))),
    if (widget.photos.length > 1) Positioned(bottom: 10, left: 0, right: 0, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(widget.photos.length, (i) => AnimatedContainer(duration: const Duration(milliseconds: 200), margin: const EdgeInsets.symmetric(horizontal: 2.5), width: _i == i ? 14 : 5, height: 5, decoration: BoxDecoration(color: _i == i ? Colors.white : Colors.white.withOpacity(0.45), borderRadius: BorderRadius.circular(3)))))),
  ]);
}

class _CourtPh extends StatelessWidget {
  final Color sc; const _CourtPh(this.sc);
  @override Widget build(BuildContext context) => Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Color.lerp(sc, Colors.black, 0.4)!, sc], begin: Alignment.topLeft, end: Alignment.bottomRight)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate_rounded, size: 40, color: Colors.white.withOpacity(0.28)), const SizedBox(height: 8), Text('No photos', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4)))]));
}
class _CTag extends StatelessWidget {
  final String label; final IconData icon; final Color color; const _CTag(this.label, this.icon, this.color);
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(7)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 11, color: color), const SizedBox(width: 4), Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color))]));
}
class _CStat extends StatelessWidget {
  final IconData icon; final String value, label; const _CStat(this.icon, this.value, this.label);
  @override Widget build(BuildContext context) => Expanded(child: Column(children: [Icon(icon, size: 14, color: kTextMid), const SizedBox(height: 3), Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kTextDark)), Text(label, style: const TextStyle(fontSize: 9, color: kTextMid, fontWeight: FontWeight.w500))]));
}
class _ActBtn extends StatelessWidget {
  final IconData icon; final String label; final Color color; final bool filled; final VoidCallback? onTap;
  const _ActBtn(this.icon, this.label, this.color, {required this.onTap, this.filled = false});
  @override Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: AnimatedOpacity(duration: const Duration(milliseconds: 150), opacity: onTap == null ? 0.5 : 1.0, child: Container(height: 44, decoration: filled ? BoxDecoration(gradient: LinearGradient(colors: color == kPrimary ? [kPrimary, const Color(0xFF007B7D)] : [color, color]), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]) : BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))), child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 15, color: filled ? Colors.white : color), const SizedBox(width: 6), Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: filled ? Colors.white : color))])))));
}
class _DelBtn extends StatelessWidget {
  final VoidCallback onTap; const _DelBtn({required this.onTap});
  @override Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(width: 44, height: 44, decoration: BoxDecoration(color: kRed.withOpacity(0.07), borderRadius: BorderRadius.circular(12), border: Border.all(color: kRed.withOpacity(0.2))), child: const Icon(Icons.delete_outline_rounded, color: kRed, size: 18)));
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY COURTS
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyCourts extends StatelessWidget {
  final VoidCallback onAdd; const _EmptyCourts({required this.onAdd});
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40), child: Column(children: [
    Container(width: 80, height: 80, decoration: BoxDecoration(gradient: LinearGradient(colors: [kPrimary.withOpacity(0.08), kPrimary.withOpacity(0.03)]), shape: BoxShape.circle, border: Border.all(color: kPrimary.withOpacity(0.1), width: 2)), child: Icon(Icons.add_business_rounded, size: 36, color: kPrimary.withOpacity(0.4))),
    const SizedBox(height: 18),
    const Text('No courts yet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kTextDark)),
    const SizedBox(height: 6),
    const Text('Add your first court so players can book it.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: kTextMid, height: 1.6)),
    const SizedBox(height: 22),
    GestureDetector(onTap: onAdd, child: Container(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13), decoration: BoxDecoration(gradient: const LinearGradient(colors: [kPrimary, Color(0xFF007B7D)]), borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 5))]), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add_rounded, color: Colors.white, size: 17), SizedBox(width: 8), Text('Add First Court', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700))]))),
  ]));
}

// ─────────────────────────────────────────────────────────────────────────────
// VENUE FORM SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _VenueFormSheet extends StatefulWidget {
  final ManagedVenue? existing; final String token; final ValueChanged<ManagedVenue> onSave;
  const _VenueFormSheet({this.existing, required this.token, required this.onSave});
  @override State<_VenueFormSheet> createState() => _VenueFormSheetState();
}

class _VenueFormSheetState extends State<_VenueFormSheet> {
  late final TextEditingController _nameCtrl, _locCtrl, _descCtrl, _latCtrl, _lngCtrl;
  late String _openTime, _closeTime;
  late final Set<SportType> _sports;
  late final Set<String>    _amenities;
  File? _selectedPhoto;
  int?  _existingPhotoId;
  final _key = GlobalKey<FormState>();
  bool  _isSaving = false;
  bool  _lowPrecisionWarning = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name        ?? '');
    _locCtrl  = TextEditingController(text: widget.existing?.location    ?? '');
    _descCtrl = TextEditingController(text: widget.existing?.description ?? '');
    _latCtrl  = TextEditingController(text: widget.existing?.lat?.toString() ?? '');
    _lngCtrl  = TextEditingController(text: widget.existing?.lng?.toString() ?? '');
    _openTime        = widget.existing?.openTime  ?? '08:00';
    _closeTime       = widget.existing?.closeTime ?? '23:00';
    _sports          = Set.from(widget.existing?.sports    ?? []);
    _amenities       = Set.from(widget.existing?.amenities ?? []);
    _existingPhotoId = widget.existing?.photoId;
    _latCtrl.addListener(_checkPrecision);
    _lngCtrl.addListener(_checkPrecision);
  }

  void _checkPrecision() {
    final latText = _latCtrl.text.trim();
    final lngText = _lngCtrl.text.trim();
    if (latText.isEmpty && lngText.isEmpty) { if (_lowPrecisionWarning) setState(() => _lowPrecisionWarning = false); return; }
    bool low = false;
    for (final t in [latText, lngText]) {
      if (t.isEmpty) continue;
      final parts = t.split('.');
      if (parts.length < 2 || parts[1].length < 4) { low = true; break; }
    }
    if (low != _lowPrecisionWarning) setState(() => _lowPrecisionWarning = low);
  }

  @override
  void dispose() { _nameCtrl.dispose(); _locCtrl.dispose(); _descCtrl.dispose(); _latCtrl.dispose(); _lngCtrl.dispose(); super.dispose(); }

  Future<int?> _uploadPhoto(File f) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/api/upload'));
      request.headers['Authorization'] = 'Bearer ${widget.token}';
      request.files.add(await http.MultipartFile.fromPath('files', f.path));
      final response = await request.send();
      final responseBody = await response.stream.toBytes();
      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = json.decode(String.fromCharCodes(responseBody));
        if (result is List && result.isNotEmpty) {
          return result[0]['id'] as int?;
        }
      }
    } catch (e) { debugPrint('Upload error: $e'); }
    return null;
  }

  Future<void> _pickPhoto() async {
    final img = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1000, maxHeight: 1000, imageQuality: 80);
    if (img != null) setState(() => _selectedPhoto = File(img.path));
  }

  Widget _photoChild() {
    if (_selectedPhoto != null) {
      return ClipRRect(borderRadius: BorderRadius.circular(14), child: Stack(fit: StackFit.expand, children: [
        Image.file(_selectedPhoto!, fit: BoxFit.cover),
        Positioned(top: 8, right: 8, child: GestureDetector(onTap: () => setState(() => _selectedPhoto = null), child: Container(width: 28, height: 28, decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle), child: const Icon(Icons.close_rounded, color: Colors.white, size: 16)))),
      ]));
    }
    if (widget.existing?.photoUrls.isNotEmpty == true) {
      return ClipRRect(borderRadius: BorderRadius.circular(14), child: Stack(fit: StackFit.expand, children: [
        Image.network(widget.existing!.photoUrls.first, fit: BoxFit.cover),
        Positioned(bottom: 0, left: 0, right: 0, child: Container(padding: const EdgeInsets.symmetric(vertical: 6), color: Colors.black.withOpacity(0.5), child: const Text('Tap to change', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 11)))),
      ]));
    }
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.add_photo_alternate_rounded, color: kPrimary.withOpacity(0.5), size: 36), const SizedBox(height: 8),
      Text('Tap to add venue photo', style: TextStyle(fontSize: 12, color: kPrimary.withOpacity(0.6))),
    ]);
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final sportsList = _sports.map((s) => s.name).toList();
      final lat = _latCtrl.text.trim().isNotEmpty ? double.tryParse(_latCtrl.text.trim()) : null;
      final lng = _lngCtrl.text.trim().isNotEmpty ? double.tryParse(_lngCtrl.text.trim()) : null;
      final uploadedId = _selectedPhoto != null ? await _uploadPhoto(_selectedPhoto!) : null;
      if (widget.existing != null) {
        await VenueService.updateVenue(token: widget.token, venueId: widget.existing!.id, name: _nameCtrl.text.trim(), location: _locCtrl.text.trim(), description: _descCtrl.text.trim(), openTime: _openTime, closeTime: _closeTime, sports: sportsList, amenities: _amenities.toList(), lat: lat, lng: lng, photoId: uploadedId ?? _existingPhotoId);
      } else {
        await VenueService.createVenue(token: widget.token, name: _nameCtrl.text.trim(), location: _locCtrl.text.trim(), description: _descCtrl.text.trim(), openTime: _openTime, closeTime: _closeTime, sports: sportsList, amenities: _amenities.toList(), lat: lat, lng: lng, photoId: uploadedId);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.existing != null ? 'Venue updated' : 'Venue created'), backgroundColor: kGreen, behavior: SnackBarBehavior.floating));
        widget.onSave(ManagedVenue(id: widget.existing?.id ?? 'temp', name: _nameCtrl.text.trim(), location: _locCtrl.text.trim(), phone: '', description: _descCtrl.text.trim(), openTime: _openTime, closeTime: _closeTime, photoUrls: widget.existing?.photoUrls ?? [], sports: _sports.toList(), amenities: _amenities.toList(), courts: widget.existing?.courts ?? [], lat: lat, lng: lng));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${e.toString().replaceAll('Exception:', '')}'), backgroundColor: kRed, behavior: SnackBarBehavior.floating));
    } finally { if (mounted) setState(() => _isSaving = false); }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return _FormShell(
      title: isEdit ? 'Edit Venue' : 'Add New Venue',
      subtitle: isEdit ? 'Update your venue details' : 'Set up your new venue',
      icon: isEdit ? Icons.edit_rounded : Icons.add_business_rounded,
      bot: MediaQuery.of(context).padding.bottom, onSave: _save, isSaving: _isSaving, formKey: _key,
      child: Column(children: [
        _Sec('Venue Photo', Icons.photo_camera_rounded, child: GestureDetector(onTap: _pickPhoto, child: Container(height: 120, width: double.infinity, decoration: BoxDecoration(color: kPrimary.withOpacity(0.04), borderRadius: BorderRadius.circular(14), border: Border.all(color: kPrimary.withOpacity(0.2), width: 1.5)), child: _photoChild()))),
        const SizedBox(height: 14),
        _Sec('Venue Info', Icons.stadium_rounded, child: Column(children: [
          _TF(ctrl: _nameCtrl, label: 'Venue Name', hint: 'e.g. Arena Sport Center', icon: Icons.label_rounded, required: true),
          const SizedBox(height: 12),
          _TF(ctrl: _locCtrl,  label: 'Location',   hint: 'e.g. Lac 2, Tunis',       icon: Icons.location_on_rounded, required: true),
        ])),
        const SizedBox(height: 14),
        _Sec('Location Coordinates', Icons.gps_fixed_rounded, child: Column(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: kAmber.withOpacity(0.07), borderRadius: BorderRadius.circular(12), border: Border.all(color: kAmber.withOpacity(0.25))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.tips_and_updates_rounded, size: 15, color: kAmber),
                const SizedBox(width: 8),
                const Text('Precision required for accurate maps', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kAmber)),
              ]),
              const SizedBox(height: 6),
              const Text('Use at least 4 decimal places — e.g. 36.8560 not 36.86', style: TextStyle(fontSize: 11, color: kAmber, height: 1.4)),
              const SizedBox(height: 6),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Tunisia reference range:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kTextDark)),
                const SizedBox(height: 2),
                Text('Lat: 30.24 – 37.54  ·  Lng: 7.52 – 11.60', style: const TextStyle(fontSize: 10, color: kTextMid, fontFamily: 'monospace')),
              ])),
              const SizedBox(height: 6),
              Text('💡 Google Maps → long-press your venue → copy the coordinates shown.', style: const TextStyle(fontSize: 10, color: kTextMid, height: 1.4)),
            ]),
          ),
          const SizedBox(height: 10),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: _lowPrecisionWarning ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(color: kRed.withOpacity(0.06), borderRadius: BorderRadius.circular(11), border: Border.all(color: kRed.withOpacity(0.25))),
              child: Row(children: [Icon(Icons.error_outline_rounded, size: 15, color: kRed), const SizedBox(width: 8), const Expanded(child: Text('Coordinates look imprecise — add more decimal places for an accurate pin on the map.', style: TextStyle(fontSize: 11, color: kRed, fontWeight: FontWeight.w600, height: 1.4)))]),
            ),
            secondChild: const SizedBox.shrink(),
          ),
          Row(children: [
            Expanded(child: _TF(ctrl: _latCtrl, label: 'Latitude',  hint: '36.8560', icon: Icons.gps_fixed_rounded, type: TextInputType.numberWithOptions(decimal: true, signed: true))),
            const SizedBox(width: 12),
            Expanded(child: _TF(ctrl: _lngCtrl, label: 'Longitude', hint: '10.2210', icon: Icons.gps_fixed_rounded, type: TextInputType.numberWithOptions(decimal: true, signed: true))),
          ]),
        ])),
        const SizedBox(height: 14),
        _Sec('Opening Hours', Icons.schedule_rounded, child: Row(children: [
          Expanded(child: _TP(label: 'Opens at',  value: _openTime,  onChanged: (v) => setState(() => _openTime  = v))),
          const SizedBox(width: 12),
          Expanded(child: _TP(label: 'Closes at', value: _closeTime, onChanged: (v) => setState(() => _closeTime = v))),
        ])),
        const SizedBox(height: 14),
        _Sec('Sports', Icons.sports_rounded, child: Column(children: SportType.values.map((s) {
          final on = _sports.contains(s);
          return GestureDetector(onTap: () => setState(() => on ? _sports.remove(s) : _sports.add(s)), child: AnimatedContainer(duration: const Duration(milliseconds: 180), margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: BoxDecoration(color: on ? s.color.withOpacity(0.07) : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: on ? s.color.withOpacity(0.3) : const Color(0xFFE8EAF0))),
            child: Row(children: [Container(width: 34, height: 34, decoration: BoxDecoration(color: s.color.withOpacity(on ? 0.12 : 0.06), borderRadius: BorderRadius.circular(9)), child: Icon(s.icon, color: s.color, size: 17)), const SizedBox(width: 12), Expanded(child: Text(s.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: on ? s.color : kTextDark))), AnimatedContainer(duration: const Duration(milliseconds: 180), width: 21, height: 21, decoration: BoxDecoration(color: on ? s.color : Colors.transparent, shape: BoxShape.circle, border: Border.all(color: on ? s.color : const Color(0xFFD0D3DB), width: 1.5)), child: on ? const Icon(Icons.check_rounded, size: 12, color: Colors.white) : null)])));
        }).toList())),
        const SizedBox(height: 14),
        _Sec('Description', Icons.description_rounded, child: _TF(ctrl: _descCtrl, label: 'About the venue', hint: 'Tell players what makes your venue special...', icon: Icons.edit_note_rounded, maxLines: 4)),
        const SizedBox(height: 14),
        _Sec('Amenities', Icons.workspace_premium_rounded, child: Wrap(spacing: 8, runSpacing: 8, children: ['Parking','Showers','Changing Rooms','Cafe','WiFi','First Aid','Seating','Coaching','Equipment Rental','AC','Lockers','Pro Shop'].map((a) {
          final on = _amenities.contains(a);
          return GestureDetector(onTap: () => setState(() => on ? _amenities.remove(a) : _amenities.add(a)), child: AnimatedContainer(duration: const Duration(milliseconds: 160), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), decoration: BoxDecoration(color: on ? kPrimary : Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: on ? kPrimary : const Color(0xFFE0E3E8)), boxShadow: on ? [BoxShadow(color: kPrimary.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2))] : []), child: Row(mainAxisSize: MainAxisSize.min, children: [if (on) ...[const Icon(Icons.check_rounded, size: 11, color: Colors.white), const SizedBox(width: 4)], Text(a, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: on ? Colors.white : kTextMid))])));
        }).toList())),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COURT FORM SHEET - UPDATED with court_img and photos support
// ─────────────────────────────────────────────────────────────────────────────
class _CourtFormSheet extends StatefulWidget {
  final ManagedCourt? existing; final String token; final String venueId;
  final List<SportType> venueSports; final ValueChanged<ManagedCourt> onSave;
  const _CourtFormSheet({this.existing, required this.token, required this.venueId, required this.venueSports, required this.onSave});
  @override State<_CourtFormSheet> createState() => _CourtFormSheetState();
}

class _CourtFormSheetState extends State<_CourtFormSheet> {
  late final TextEditingController _nameCtrl, _descCtrl, _priceCtrl, _capCtrl;
  late SportType _sport;
  File? _selectedMainImage;
  List<File> _selectedGalleryImages = [];
  List<String> _existingMainImageUrl = [];
  List<String> _existingGalleryUrls = [];
  int? _existingMainImageId;
  List<int> _existingGalleryIds = [];
  final _key = GlobalKey<FormState>();
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _descCtrl = TextEditingController(text: widget.existing?.description ?? '');
    _priceCtrl = TextEditingController(text: widget.existing?.pricePerHour.toStringAsFixed(0) ?? '');
    _capCtrl = TextEditingController(text: widget.existing?.capacity.toString() ?? '');
    _sport = widget.existing?.sport ?? (widget.venueSports.isNotEmpty ? widget.venueSports.first : SportType.football);
    
    if (widget.existing?.courtImgUrl != null && widget.existing!.courtImgUrl!.isNotEmpty) {
      _existingMainImageUrl = [widget.existing!.courtImgUrl!];
      _existingMainImageId = widget.existing?.courtImgId;
    }
    if (widget.existing?.photosUrls.isNotEmpty == true) {
      _existingGalleryUrls = List.from(widget.existing!.photosUrls);
      _existingGalleryIds = List.from(widget.existing?.photosIds ?? []);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _capCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickMainImage() async {
    final img = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1000, maxHeight: 1000, imageQuality: 80);
    if (img != null) {
      setState(() {
        _selectedMainImage = File(img.path);
        _existingMainImageUrl.clear();
      });
    }
  }

  Future<void> _addGalleryImages() async {
    final images = await _picker.pickMultiImage(maxWidth: 1000, maxHeight: 1000, imageQuality: 80);
    if (images.isNotEmpty) {
      setState(() {
        _selectedGalleryImages.addAll(images.map((img) => File(img.path)));
      });
    }
  }

  void _removeGalleryImage(int index, {bool isExisting = false, int existingIndex = -1}) {
    setState(() {
      if (isExisting) {
        _existingGalleryUrls.removeAt(existingIndex);
        if (existingIndex < _existingGalleryIds.length) {
          _existingGalleryIds.removeAt(existingIndex);
        }
      } else {
        _selectedGalleryImages.removeAt(index);
      }
    });
  }

  void _removeMainImage() {
    setState(() {
      _selectedMainImage = null;
      _existingMainImageUrl.clear();
      _existingMainImageId = null;
    });
  }

  Future<int?> _uploadImage(File image) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/api/upload'));
      request.headers['Authorization'] = 'Bearer ${widget.token}';
      request.files.add(await http.MultipartFile.fromPath('files', image.path));
      final response = await request.send();
      final responseBody = await response.stream.toBytes();
      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = json.decode(String.fromCharCodes(responseBody));
        if (result is List && result.isNotEmpty) {
          return result[0]['id'] as int?;
        }
      }
    } catch (e) {
      debugPrint('Upload error: $e');
    }
    return null;
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      int? uploadedMainImageId;
      if (_selectedMainImage != null) {
        uploadedMainImageId = await _uploadImage(_selectedMainImage!);
      }
      
      List<int> uploadedGalleryIds = [];
      for (final img in _selectedGalleryImages) {
        final id = await _uploadImage(img);
        if (id != null) uploadedGalleryIds.add(id);
      }
      
      final allGalleryIds = [..._existingGalleryIds, ...uploadedGalleryIds];
      
      if (widget.existing != null) {
        await CourtService.updateCourt(
          token: widget.token,
          courtId: widget.existing!.id,
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          sport: _sport.name,
          pricePerHour: double.tryParse(_priceCtrl.text) ?? 0,
          capacity: int.tryParse(_capCtrl.text) ?? 0,
          courtImgId: uploadedMainImageId ?? _existingMainImageId,
          photosIds: allGalleryIds,
        );
      } else {
        await CourtService.createCourt(
          token: widget.token,
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          sport: _sport.name,
          pricePerHour: double.tryParse(_priceCtrl.text) ?? 0,
          capacity: int.tryParse(_capCtrl.text) ?? 0,
          venueId: int.parse(widget.venueId),
          courtImg: _selectedMainImage,
          photos: _selectedGalleryImages,
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.existing != null ? 'Court updated' : 'Court created'), backgroundColor: kGreen, behavior: SnackBarBehavior.floating)
        );
        widget.onSave(ManagedCourt(
          id: widget.existing?.id ?? 'temp',
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          sport: _sport,
          pricePerHour: double.tryParse(_priceCtrl.text) ?? 0,
          capacity: int.tryParse(_capCtrl.text) ?? 0,
          photoUrls: [],
          photosUrls: [],
          courtImgUrl: null,
          amenities: [],
          isActive: true,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${e.toString().replaceAll('Exception:', '')}'), backgroundColor: kRed, behavior: SnackBarBehavior.floating)
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return _FormShell(
      title: isEdit ? 'Edit Court' : 'Add New Court',
      subtitle: isEdit ? 'Update court details' : 'Fill in the court information',
      icon: isEdit ? Icons.edit_rounded : Icons.add_rounded,
      bot: MediaQuery.of(context).padding.bottom,
      onSave: _save,
      isSaving: _isSaving,
      formKey: _key,
      child: Column(children: [
        _Sec('Main Court Image', Icons.image_rounded, child: GestureDetector(
          onTap: _pickMainImage,
          child: Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kPrimary.withOpacity(0.2), width: 1.5),
            ),
            child: (_selectedMainImage != null)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(fit: StackFit.expand, children: [
                      Image.file(_selectedMainImage!, fit: BoxFit.cover),
                      Positioned(
                        top: 8, right: 8,
                        child: GestureDetector(
                          onTap: _removeMainImage,
                          child: Container(width: 28, height: 28, decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle), child: const Icon(Icons.close_rounded, color: Colors.white, size: 16)),
                        ),
                      ),
                    ]),
                  )
                : (_existingMainImageUrl.isNotEmpty)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(fit: StackFit.expand, children: [
                          Image.network(_existingMainImageUrl.first, fit: BoxFit.cover),
                          Positioned(
                            top: 8, right: 8,
                            child: GestureDetector(
                              onTap: _removeMainImage,
                              child: Container(width: 28, height: 28, decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle), child: const Icon(Icons.close_rounded, color: Colors.white, size: 16)),
                            ),
                          ),
                        ]),
                      )
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.add_photo_alternate_rounded, color: kPrimary.withOpacity(0.5), size: 36),
                        const SizedBox(height: 8),
                        Text('Tap to add main image', style: TextStyle(fontSize: 12, color: kPrimary.withOpacity(0.6))),
                      ]),
          ),
        )),
        const SizedBox(height: 14),
        
        _Sec('Gallery Images', Icons.photo_library_rounded, child: Column(children: [
          if (_existingGalleryUrls.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _existingGalleryUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) => Container(
                  width: 100,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
                  clipBehavior: Clip.hardEdge,
                  child: Stack(fit: StackFit.expand, children: [
                    Image.network(_existingGalleryUrls[i], fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xFFF0F2F5), child: const Icon(Icons.broken_image_rounded, color: kTextLight, size: 22))),
                    Positioned(top: 5, right: 5, child: GestureDetector(
                      onTap: () => _removeGalleryImage(0, isExisting: true, existingIndex: i),
                      child: Container(width: 22, height: 22, decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), shape: BoxShape.circle), child: const Icon(Icons.close_rounded, color: Colors.white, size: 12)),
                    )),
                  ]),
                ),
              ),
            ),
          
          if (_selectedGalleryImages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedGalleryImages.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => Container(
                    width: 100,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
                    clipBehavior: Clip.hardEdge,
                    child: Stack(fit: StackFit.expand, children: [
                      Image.file(_selectedGalleryImages[i], fit: BoxFit.cover),
                      Positioned(top: 5, right: 5, child: GestureDetector(
                        onTap: () => _removeGalleryImage(i, isExisting: false),
                        child: Container(width: 22, height: 22, decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), shape: BoxShape.circle), child: const Icon(Icons.close_rounded, color: Colors.white, size: 12)),
                      )),
                    ]),
                  ),
                ),
              ),
            ),
          
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _addGalleryImages,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kPrimary.withOpacity(0.2), width: 1.5),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(width: 28, height: 28, decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.add_photo_alternate_rounded, size: 16, color: kPrimary)),
                const SizedBox(width: 8),
                const Text('Add Gallery Images', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kPrimary)),
              ]),
            ),
          ),
        ])),
        const SizedBox(height: 14),
        
        _Sec('Basic Info', Icons.info_outline_rounded, child: Column(children: [
          _TF(ctrl: _nameCtrl, label: 'Court Name', hint: 'e.g. Court Alpha', icon: Icons.label_rounded, required: true),
          const SizedBox(height: 12),
          _TF(ctrl: _descCtrl, label: 'Description', hint: 'Surface, lighting...', icon: Icons.description_rounded, maxLines: 3),
        ])),
        const SizedBox(height: 14),
        _Sec('Sport', Icons.sports_rounded, child: Wrap(spacing: 8, runSpacing: 8, children: (widget.venueSports.isEmpty ? SportType.values : widget.venueSports).map((s) {
          final sel = _sport == s;
          return GestureDetector(onTap: () => setState(() => _sport = s), child: AnimatedContainer(duration: const Duration(milliseconds: 180), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: sel ? s.color : const Color(0xFFF0F2F5), borderRadius: BorderRadius.circular(12), boxShadow: sel ? [BoxShadow(color: s.color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))] : []), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(s.icon, size: 13, color: sel ? Colors.white : kTextMid), const SizedBox(width: 5), Text(s.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: sel ? Colors.white : kTextMid))])));
        }).toList())),
        const SizedBox(height: 14),
        _Sec('Pricing & Capacity', Icons.tune_rounded, child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _TF(ctrl: _priceCtrl, label: 'Price (DT)', hint: '0', icon: Icons.payments_rounded, type: TextInputType.number, required: true)),
          const SizedBox(width: 12),
          Expanded(child: _TF(ctrl: _capCtrl, label: 'Max Players', hint: '0', icon: Icons.people_rounded, type: TextInputType.number, required: true)),
        ])),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PHOTO PICKER
// ─────────────────────────────────────────────────────────────────────────────
class _PhotoPicker extends StatelessWidget {
  final List<String> photos; final VoidCallback onAdd; final ValueChanged<int> onRemove;
  const _PhotoPicker({required this.photos, required this.onAdd, required this.onRemove});
  @override Widget build(BuildContext context) => SizedBox(height: 100, child: ListView(scrollDirection: Axis.horizontal, children: [
    GestureDetector(onTap: onAdd, child: Container(width: 100, margin: const EdgeInsets.only(right: 10), decoration: BoxDecoration(color: kPrimary.withOpacity(0.04), borderRadius: BorderRadius.circular(14), border: Border.all(color: kPrimary.withOpacity(0.2), width: 1.5)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate_rounded, color: kPrimary.withOpacity(0.5), size: 26), const SizedBox(height: 5), Text('Add Photo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kPrimary.withOpacity(0.6)))]))),
    ...photos.asMap().entries.map((e) => Container(width: 100, margin: const EdgeInsets.only(right: 10), decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)), clipBehavior: Clip.hardEdge, child: Stack(fit: StackFit.expand, children: [Image.network(e.value, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xFFF0F2F5), child: const Icon(Icons.broken_image_rounded, color: kTextLight, size: 22))), Positioned(top: 5, right: 5, child: GestureDetector(onTap: () => onRemove(e.key), child: Container(width: 20, height: 20, decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), shape: BoxShape.circle), child: const Icon(Icons.close_rounded, color: Colors.white, size: 11))))]))),
  ]));
}

// ─────────────────────────────────────────────────────────────────────────────
// CONFIRM DIALOG
// ─────────────────────────────────────────────────────────────────────────────
class _ConfirmDialog extends StatelessWidget {
  final IconData icon; final Color iconColor; final String title, message, confirmLabel; final Color confirmColor; final VoidCallback onConfirm;
  const _ConfirmDialog({required this.icon, required this.iconColor, required this.title, required this.message, required this.confirmLabel, required this.confirmColor, required this.onConfirm});
  @override Widget build(BuildContext context) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0), actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16), content: Column(mainAxisSize: MainAxisSize.min, children: [Container(width: 56, height: 56, decoration: BoxDecoration(color: iconColor.withOpacity(0.09), shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 28)), const SizedBox(height: 16), Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kTextDark)), const SizedBox(height: 8), Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: kTextMid, height: 1.5))]), actions: [Row(children: [Expanded(child: _ActBtn(Icons.close_rounded, 'Cancel', kTextMid, onTap: () => Navigator.pop(context))), const SizedBox(width: 10), Expanded(child: _ActBtn(Icons.delete_rounded, confirmLabel, confirmColor, filled: true, onTap: onConfirm))])]);
}

// ─────────────────────────────────────────────────────────────────────────────
// FORM SHELL
// ─────────────────────────────────────────────────────────────────────────────
class _FormShell extends StatelessWidget {
  final String title, subtitle; final IconData icon; final double bot;
  final VoidCallback onSave; final bool isSaving; final Widget child; final GlobalKey<FormState>? formKey;
  const _FormShell({required this.title, required this.subtitle, required this.icon, required this.bot, required this.onSave, required this.child, this.formKey, this.isSaving = false});
  @override Widget build(BuildContext context) => Container(
    height: MediaQuery.of(context).size.height * 0.93,
    decoration: const BoxDecoration(color: Color(0xFFF0F2F5), borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    child: Column(children: [
      Container(decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))), padding: const EdgeInsets.fromLTRB(20, 12, 20, 18), child: Column(children: [
        Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E5EA), borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 18),
        Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(gradient: const LinearGradient(colors: [kPrimary, Color(0xFF007B7D)]), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: Colors.white, size: 19)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kTextDark, letterSpacing: -0.3)), Text(subtitle, style: const TextStyle(fontSize: 12, color: kTextMid))])), GestureDetector(onTap: () => Navigator.pop(context), child: Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFFF0F2F5), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.close_rounded, size: 16, color: kTextMid)))]),
      ])),
      Expanded(child: formKey != null ? Form(key: formKey, child: _body()) : _body()),
      Container(decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x10000000), blurRadius: 16, offset: Offset(0, -4))]), padding: EdgeInsets.fromLTRB(20, 14, 20, bot + 16), child: _ActBtn(Icons.check_rounded, isSaving ? 'Saving...' : 'Save', kPrimary, filled: true, onTap: isSaving ? null : onSave)),
    ]),
  );
  Widget _body() => ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), children: [child, const SizedBox(height: 100)]);
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED FORM WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _Sec extends StatelessWidget {
  final String title; final IconData icon; final Widget child;
  const _Sec(this.title, this.icon, {required this.child});
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.025), blurRadius: 8, offset: const Offset(0, 2))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, size: 14, color: kPrimary), const SizedBox(width: 7), Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kTextDark))]), const SizedBox(height: 14), Container(height: 1, color: const Color(0xFFF0F2F5)), const SizedBox(height: 14), child]));
}

class _TF extends StatelessWidget {
  final TextEditingController ctrl; final String label, hint; final IconData icon;
  final TextInputType type; final int maxLines; final bool required;
  const _TF({required this.ctrl, required this.label, required this.hint, required this.icon, this.type = TextInputType.text, this.maxLines = 1, this.required = false});
  @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kTextDark))),
    TextFormField(controller: ctrl, keyboardType: type, maxLines: maxLines, validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kTextDark),
      decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: kTextLight, fontSize: 13), prefixIcon: Icon(icon, color: kPrimary, size: 17), filled: true, fillColor: const Color(0xFFF7F8FB), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8EAF0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kPrimary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kRed)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kRed, width: 1.5)))),
  ]);
}

class _TP extends StatelessWidget {
  final String label, value; final ValueChanged<String> onChanged;
  const _TP({required this.label, required this.value, required this.onChanged});
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: () async {
      final p = value.split(':');
      final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: int.tryParse(p[0]) ?? 8, minute: int.tryParse(p.length > 1 ? p[1] : '0') ?? 0));
      if (t != null) onChanged('${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
    },
    child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFF7F8FB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8EAF0))), child: Row(children: [const Icon(Icons.access_time_rounded, size: 15, color: kPrimary), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 10, color: kTextMid, fontWeight: FontWeight.w600)), const SizedBox(height: 2), Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kTextDark, letterSpacing: -0.3))])), const Icon(Icons.chevron_right_rounded, size: 15, color: kTextLight)])),
  );
}

extension _ListX<T> on List<T> { T? get firstOrNull => isEmpty ? null : first; }

