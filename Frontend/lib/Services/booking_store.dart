// lib/Services/booking_store.dart
// Bookings: loaded from /reservations.
// Announcements: loaded from /announcements/mine (own) — no more special_requests.

import 'package:flutter/foundation.dart';
import 'package:sporta/Core/Constants/api_constants.dart';
import 'package:sporta/Services/announcement_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ─────────────────────────────────────────────────────────────────────────────
// DATA CLASSES
// ─────────────────────────────────────────────────────────────────────────────

class LocalBooking {
  final String id;
  final String courtName;
  final String venueName;
  final String courtImageUrl;
  final String sport;
  final String date;
  final String dateRaw;
  final String time;
  final int    price;
  final String status;
  final String reference;
  final String paymentMethod;

  const LocalBooking({
    required this.id,
    required this.courtName,
    required this.venueName,
    required this.courtImageUrl,
    required this.sport,
    required this.date,
    required this.dateRaw,
    required this.time,
    required this.price,
    required this.status,
    required this.reference,
    required this.paymentMethod,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// STORE
// ─────────────────────────────────────────────────────────────────────────────

class BookingStore extends ChangeNotifier {
  BookingStore._();
  static final BookingStore instance = BookingStore._();

  final List<LocalBooking>      _bookings      = [];
  List<AnnouncementData>        _myAnnouncements = [];
  String?                       _userToken;
  AnnouncementService?          _annSvc;
  bool                          _initialized   = false;

  List<LocalBooking>      get bookings         => List.unmodifiable(_bookings);
  List<AnnouncementData>  get myAnnouncements  => List.unmodifiable(_myAnnouncements);

  // ── Init ────────────────────────────────────────────────────────────────────

  Future<void> initialize(String token) async {
    if (_initialized && _userToken == token) { await refresh(); return; }
    _userToken    = token;
    _annSvc       = AnnouncementService(token: token);
    _initialized  = true;
    await _loadAll();
  }

  Future<void> refresh() async { await _loadAll(); }

  Future<void> _loadAll() async {
    await Future.wait([_loadBookings(), _loadMyAnnouncements()]);
    notifyListeners();
  }

  // ── Bookings ─────────────────────────────────────────────────────────────────

  String _absUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${ApiConstants.mediaBaseUrl}$path';
  }

  Future<void> _loadBookings() async {
    if (_userToken == null) return;
    try {
      final url = '${ApiConstants.reservations}'
          '?populate[court][populate][court_img]=*'
          '&populate[court][populate][photos]=*'
          '&populate[court][populate][venue]=*'
          '&populate[time_slot]=*';
      final res = await http.get(Uri.parse(url), headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $_userToken',
      });
      if (res.statusCode != 200) return;

      final body       = json.decode(res.body) as Map<String, dynamic>;
      final rawList    = body['data'] as List? ?? [];
      _bookings.clear();

      for (final item in rawList) {
        final attrs = (item['attributes'] ?? item) as Map<String, dynamic>;

        // ── Court ────────────────────────────────────────────────────────────
        final courtRaw   = attrs['court'];
        final courtData  = courtRaw is Map ? (courtRaw['data'] ?? courtRaw) as Map<String, dynamic> : null;
        final courtAttrs = courtData != null ? (courtData['attributes'] ?? courtData) as Map<String, dynamic> : <String, dynamic>{};

        final venueRaw   = courtAttrs['venue'];
        final venueData  = venueRaw is Map ? (venueRaw['data'] ?? venueRaw) as Map<String, dynamic> : null;
        final venueAttrs = venueData != null ? (venueData['attributes'] ?? venueData) as Map<String, dynamic> : <String, dynamic>{};

        // Court image — try all possible shapes
        String courtImgUrl = '';
        if (courtAttrs['court_img_url']?.toString().isNotEmpty == true) {
          courtImgUrl = _absUrl(courtAttrs['court_img_url'].toString());
        } else if (courtAttrs['court_img'] is Map) {
          courtImgUrl = _absUrl((courtAttrs['court_img'] as Map)['url']?.toString());
        } else if (courtAttrs['photos_urls'] is List && (courtAttrs['photos_urls'] as List).isNotEmpty) {
          courtImgUrl = _absUrl((courtAttrs['photos_urls'] as List).first.toString());
        } else if (courtAttrs['photos'] is List && (courtAttrs['photos'] as List).isNotEmpty) {
          final first = (courtAttrs['photos'] as List).first;
          if (first is Map) courtImgUrl = _absUrl(first['url']?.toString());
        }

        // ── Time ─────────────────────────────────────────────────────────────
        final slotRaw   = attrs['time_slot'];
        final slotData  = slotRaw is Map ? (slotRaw['data'] ?? slotRaw) as Map<String, dynamic> : null;
        final slotAttrs = slotData != null ? (slotData['attributes'] ?? slotData) as Map<String, dynamic> : <String, dynamic>{};

        final startTime = slotAttrs['startTime']?.toString() ?? attrs['start_time']?.toString() ?? '';
        final endTime   = slotAttrs['endTime']?.toString()   ?? attrs['end_time']?.toString()   ?? '';
        final timeStr   = (startTime.isNotEmpty && endTime.isNotEmpty) ? '$startTime – $endTime' : '';

        // ── Date ─────────────────────────────────────────────────────────────
        final rawDate = attrs['booking_date_play']?.toString() ?? '';
        String formattedDate = rawDate;
        try {
          final d = DateTime.parse(rawDate);
          formattedDate = _fmtDate(d);
        } catch (_) {}

        _bookings.add(LocalBooking(
          id:            item['id']?.toString() ?? '',
          courtName:     courtAttrs['name']?.toString()        ?? '',
          venueName:     venueAttrs['name']?.toString()        ?? '',
          courtImageUrl: courtImgUrl,
          sport:         (courtAttrs['sport'] ?? courtAttrs['sports'])?.toString() ?? '',
          date:          formattedDate,
          dateRaw:       rawDate,
          time:          timeStr,
          price:         (attrs['total_price'] as num?)?.toInt() ?? 0,
          status:        attrs['booking_status']?.toString()  ?? 'pending',
          reference:     attrs['booking_reference']?.toString() ?? '',
          paymentMethod: attrs['payment_method']?.toString()  ?? 'pay_at_venue',
        ));
      }
      _bookings.sort((a, b) => b.dateRaw.compareTo(a.dateRaw));
    } catch (e) {
      debugPrint('BookingStore._loadBookings: $e');
    }
  }

  // ── Announcements ─────────────────────────────────────────────────────────────

  Future<void> _loadMyAnnouncements() async {
    if (_annSvc == null) return;
    try {
      _myAnnouncements = await _annSvc!.fetchMine();
    } catch (e) {
      debugPrint('BookingStore._loadMyAnnouncements: $e');
    }
  }

  /// Create a new announcement for a reservation
  Future<AnnouncementData> createAnnouncement({
    required String reservationId,
    required String description,
    required int    playersNeeded,
  }) async {
    if (_annSvc == null) throw Exception('Not initialized');
    final ann = await _annSvc!.create(
      reservationId:  reservationId,
      description:    description,
      playersNeeded:  playersNeeded,
    );
    _myAnnouncements = [ann, ..._myAnnouncements];
    notifyListeners();
    return ann;
  }

  /// Delete an announcement
  Future<void> deleteAnnouncement(String announcementId) async {
    if (_annSvc == null) return;
    await _annSvc!.delete(announcementId);
    _myAnnouncements.removeWhere((a) => a.id == announcementId);
    notifyListeners();
  }

  /// True if this reservation already has an active announcement
  bool hasAnnouncementForReservation(String reservationId) =>
      _myAnnouncements.any((a) => a.reservationId == reservationId && a.status != 'closed');

  // ── Booking helpers ───────────────────────────────────────────────────────────

  void addBooking(LocalBooking b) { _bookings.insert(0, b); notifyListeners(); }

  List<LocalBooking> get upcomingBookings {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';
    return _bookings.where((b) => b.dateRaw.compareTo(todayStr) >= 0).toList()
      ..sort((a, b) => a.dateRaw.compareTo(b.dateRaw));
  }

  String _fmtDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const w = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${w[d.weekday-1]}, ${d.day} ${m[d.month-1]}';
  }
}



















/*// lib/Services/booking_store.dart
// Persistent singleton ChangeNotifier — syncs with backend.
// Home and HomeSettings listen to this for live booking + announcement data.

import 'package:flutter/foundation.dart';
import 'package:sporta/Services/reservation_service.dart';
import 'package:sporta/Core/Constants/api_constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ─────────────────────────────────────────────────────────────────────────────
// DATA CLASSES
// ─────────────────────────────────────────────────────────────────────────────

class LocalBooking {
  final String id;
  final String courtName;
  final String venueName;
  final String courtImageUrl;
  final String sport;
  final String date;         // e.g. "Mon, 14 Apr"
  final String dateRaw;      // yyyy-MM-dd for sorting
  final String time;         // e.g. "09:00 – 10:00"
  final int price;
  final String status;       // confirmed | pending
  final String reference;
  final String paymentMethod; // pay_now | pay_at_venue

  const LocalBooking({
    required this.id,
    required this.courtName,
    required this.venueName,
    required this.courtImageUrl,
    required this.sport,
    required this.date,
    required this.dateRaw,
    required this.time,
    required this.price,
    required this.status,
    required this.reference,
    required this.paymentMethod,
  });
}

class LocalAnnouncement {
  final String id;
  final String bookingId;
  final String courtName;
  final String venueName;
  final String sport;
  final String date;
  final String time;
  final String courtImageUrl;
  final String description;
  final int playersNeeded;
  int joined;
  final String hostName;
  final String hostInitials;

  LocalAnnouncement({
    required this.id,
    required this.bookingId,
    required this.courtName,
    required this.venueName,
    required this.sport,
    required this.date,
    required this.time,
    required this.courtImageUrl,
    required this.description,
    required this.playersNeeded,
    this.joined = 0,
    this.hostName = 'You',
    this.hostInitials = 'Y',
  });

  int get spotsLeft => playersNeeded - joined;
  bool get isFull => spotsLeft <= 0;
}

// ─────────────────────────────────────────────────────────────────────────────
// STORE - Now syncs with backend
// ─────────────────────────────────────────────────────────────────────────────

class BookingStore extends ChangeNotifier {
  BookingStore._();
  static final BookingStore instance = BookingStore._();

  final List<LocalBooking> _bookings = [];
  final List<LocalAnnouncement> _announcements = [];
  String? _userToken;
  ReservationService? _reservationService;
  bool _isInitialized = false;

  List<LocalBooking> get bookings => List.unmodifiable(_bookings);
  List<LocalAnnouncement> get announcements => List.unmodifiable(_announcements);

  /// Initialize the store with user token and load data from backend
  Future<void> initialize(String token) async {
    if (_isInitialized && _userToken == token) {
      // Already initialized with same token, just refresh
      await refresh();
      return;
    }
    
    _userToken = token;
    _reservationService = ReservationService(token: token);
    _isInitialized = true;
    await _loadFromBackend();
  }

  /// Load bookings AND announcements from backend
  Future<void> _loadFromBackend() async {
    if (_userToken == null) return;
    
    try {
      // Load bookings from API
      await _loadBookingsFromBackend();
      
      // Load announcements from reservations' special_requests
      await _loadAnnouncementsFromBackend();
      
      notifyListeners();
    } catch (e) {
      print('Error loading from backend: $e');
    }
  }
  
  /// Helper to get full image URL
  String _getFullImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    const baseUrl = 'http://10.0.2.2:1337';
    return '$baseUrl$url';
  }
  
  /// Load bookings from /reservations endpoint
  Future<void> _loadBookingsFromBackend() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.reservations}?populate[court][populate][venue]=*&populate[court][populate][court_img]=*&populate[court][populate][photos]=*&populate[court][populate][photo]=*'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_userToken',
        },
      );
      
      if (response.statusCode != 200) {
        print('Failed to load bookings: ${response.statusCode}');
        return;
      }
      
      final responseData = json.decode(response.body);
      final List<dynamic> reservations = responseData['data'] ?? [];
      
      _bookings.clear(); 
      
      for (final res in reservations) {
        final attributes = res['attributes'] ?? res;
        
        // Get court and venue info
        final courtData = attributes['court']?['data'] ?? attributes['court'];
        String courtName = '';
        String venueName = '';
        String sport = '';
        String courtImageUrl = '';
        
        if (courtData != null) {
          final courtAttrs = courtData['attributes'] ?? courtData;
          courtName = courtAttrs['name'] ?? '';
          sport = courtAttrs['sport'] ?? '';
          
          // Get venue from court
          final venueData = courtAttrs['venue']?['data'] ?? courtAttrs['venue'];
          if (venueData != null) {
            final venueAttrs = venueData['attributes'] ?? venueData;
            venueName = venueAttrs['name'] ?? '';
          }
          
          // Get court image - try multiple sources
          // 1. court_img_url (transformed field)
          if (courtAttrs['court_img_url'] != null && courtAttrs['court_img_url'].toString().isNotEmpty) {
            courtImageUrl = _getFullImageUrl(courtAttrs['court_img_url'].toString());
            print('Court image from court_img_url: $courtImageUrl');
          }
          // 2. court_img object
          else if (courtAttrs['court_img'] != null && courtAttrs['court_img']['url'] != null) {
            courtImageUrl = _getFullImageUrl(courtAttrs['court_img']['url'].toString());
            print('Court image from court_img.url: $courtImageUrl');
          }
          // 3. photos_urls array
          else if (courtAttrs['photos_urls'] != null && courtAttrs['photos_urls'] is List && (courtAttrs['photos_urls'] as List).isNotEmpty) {
            courtImageUrl = _getFullImageUrl((courtAttrs['photos_urls'] as List).first.toString());
            print('Court image from photos_urls: $courtImageUrl');
          }
          // 4. photos array
          else if (courtAttrs['photos'] != null && courtAttrs['photos'] is List && (courtAttrs['photos'] as List).isNotEmpty) {
            final firstPhoto = (courtAttrs['photos'] as List).first;
            if (firstPhoto is Map && firstPhoto['url'] != null) {
              courtImageUrl = _getFullImageUrl(firstPhoto['url'].toString());
              print('Court image from photos: $courtImageUrl');
            }
          }
          // 5. photo object (legacy)
          else if (courtAttrs['photo'] != null && courtAttrs['photo']['url'] != null) {
            courtImageUrl = _getFullImageUrl(courtAttrs['photo']['url'].toString());
            print('Court image from photo.url: $courtImageUrl');
          }
          
          print('Final court image URL for $courtName: $courtImageUrl');
        }
        
        // Format date
        final bookingDate = attributes['booking_date_play'];
        String formattedDate = '';
        String dateRaw = '';
        if (bookingDate != null) {
          try {
            final dateObj = DateTime.parse(bookingDate);
            formattedDate = _formatDate(dateObj);
            dateRaw = bookingDate;
          } catch (e) {
            formattedDate = bookingDate.toString();
            dateRaw = bookingDate.toString();
          }
        }
        
        // Format time
        final startTime = attributes['start_time'] ?? '';
        final endTime = attributes['end_time'] ?? '';
        String time = '';
        if (startTime.isNotEmpty && endTime.isNotEmpty) {
          time = '$startTime – $endTime';
        }
        
        // Get status
        final bookingStatus = attributes['booking_status'] ?? 'pending';
        
        // Map status: pending -> pending, confirmed -> confirmed
        String localStatus = 'pending';
        if (bookingStatus == 'confirmed') {
          localStatus = 'confirmed';
        }
        
        final paymentMethod = attributes['payment_method'] ?? 'pay_at_venue';
        final totalPrice = (attributes['total_price'] as num?)?.toInt() ?? 0;
        
        _bookings.add(LocalBooking(
          id: res['id'].toString(),
          courtName: courtName,
          venueName: venueName,
          courtImageUrl: courtImageUrl,
          sport: sport,
          date: formattedDate,
          dateRaw: dateRaw,
          time: time,
          price: totalPrice,
          status: localStatus,
          reference: attributes['booking_reference'] ?? '',
          paymentMethod: paymentMethod,
        ));
      }
      
      // Sort bookings by date (newest first)
      _bookings.sort((a, b) => b.dateRaw.compareTo(a.dateRaw));
      
      print('✅ Loaded ${_bookings.length} bookings from backend');
      for (final b in _bookings) {
        print('  Booking: ${b.courtName}, Image: ${b.courtImageUrl}');
      }
    } catch (e) {
      print('❌ Error loading bookings: $e');
    }
  }
  
  /// Load announcements from reservations' special_requests
  Future<void> _loadAnnouncementsFromBackend() async {
    if (_reservationService == null) return;
    
    try {
      final backendAnnouncements = await _reservationService!.getAllAnnouncements();
      
      _announcements.clear();
      for (final ann in backendAnnouncements) {
        _announcements.add(LocalAnnouncement(
          id: ann['id'],
          bookingId: ann['bookingId'],
          courtName: ann['courtName'],
          venueName: ann['venueName'],
          sport: ann['sport'],
          date: ann['date'],
          time: ann['time'],
          courtImageUrl: ann['courtImageUrl'] ?? '',
          description: ann['description'],
          playersNeeded: ann['playersNeeded'],
          joined: ann['joined'] ?? 0,
        ));
      }
      
      print('✅ Loaded ${_announcements.length} announcements from backend');
    } catch (e) {
      print('❌ Error loading announcements: $e');
    }
  }

  /// Upcoming = today or future, sorted by date ascending
  List<LocalBooking> get upcomingBookings {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return _bookings
        .where((b) => b.dateRaw.compareTo(todayStr) >= 0)
        .toList()
      ..sort((a, b) => a.dateRaw.compareTo(b.dateRaw));
  }

  void addBooking(LocalBooking booking) {
    _bookings.insert(0, booking);
    notifyListeners();
  }

  /// Add announcement to backend and local store
  Future<void> addAnnouncement(LocalAnnouncement ann) async {
    if (_reservationService == null) {
      // Fallback: add locally only
      _announcements.insert(0, ann);
      notifyListeners();
      return;
    }
    
    try {
      print('📢 Adding announcement to backend for booking: ${ann.bookingId}');
      await _reservationService!.addAnnouncementToReservation(
        reservationId: ann.bookingId,
        announcementText: ann.description,
        playersNeeded: ann.playersNeeded,
      );
      
      // Reload from backend to get fresh data
      await _loadAnnouncementsFromBackend();
      notifyListeners();
      print('✅ Announcement added successfully');
    } catch (e) {
      print('❌ Error adding announcement to backend: $e');
      // Still add locally even if backend fails
      _announcements.insert(0, ann);
      notifyListeners();
    }
  }

  /// Remove announcement from backend and local store
  Future<void> removeAnnouncement(String id) async {
    final announcement = _announcements.firstWhere((a) => a.id == id);
    
    if (_reservationService != null) {
      try {
        await _reservationService!.deleteAnnouncementFromReservation(
          reservationId: announcement.bookingId,
          announcementId: id,
        );
        
        // Reload from backend
        await _loadAnnouncementsFromBackend();
        notifyListeners();
      } catch (e) {
        print('Error removing announcement from backend: $e');
        // Still remove locally even if backend fails
        _announcements.removeWhere((a) => a.id == id);
        notifyListeners();
      }
    } else {
      _announcements.removeWhere((a) => a.id == id);
      notifyListeners();
    }
  }

  bool hasAnnouncementForBooking(String bookingId) =>
      _announcements.any((a) => a.bookingId == bookingId);
  
  /// Refresh all data from backend
  Future<void> refresh() async {
    print('🔄 Refreshing BookingStore...');
    await _loadFromBackend();
  }
  
  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }
}*/