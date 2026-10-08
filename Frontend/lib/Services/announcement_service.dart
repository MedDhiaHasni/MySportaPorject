// lib/Services/announcement_service.dart
// Changes: AnnouncementData.hostPhone + JoinRequestData.playerPhone
// Both parsed from the linked auth user record (player.player.phone)
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sporta/Core/Constants/api_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────

class AnnouncementData {
  final String id;
  final String description;
  final int    playersNeeded;
  final String status;        // open | full | closed
  final String courtName;
  final String venueName;
  final String sport;
  final String date;
  final String startTime;
  final String endTime;
  final String courtImageUrl;
  final String reservationId;
  final String hostName;
  final String hostInitials;
  final String hostPlayerId;
  final String hostPhone;     // NEW — host's phone number
  final List<JoinRequestData> joinRequests;
  final int    acceptedCount;

  const AnnouncementData({
    required this.id,
    required this.description,
    required this.playersNeeded,
    required this.status,
    required this.courtName,
    required this.venueName,
    required this.sport,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.courtImageUrl,
    required this.reservationId,
    required this.hostName,
    required this.hostInitials,
    required this.hostPlayerId,
    required this.hostPhone,
    required this.joinRequests,
    required this.acceptedCount,
  });

  int  get spotsLeft  => playersNeeded - acceptedCount;
  bool get isFull     => spotsLeft <= 0 || status == 'full';
  bool get isOpen     => status == 'open' && !isFull;

  // Accepted requesters (visible to host)
  List<JoinRequestData> get acceptedPlayers =>
      joinRequests.where((r) => r.status == 'accepted').toList();

  // Pending requests (for host to action)
  List<JoinRequestData> get pendingRequests =>
      joinRequests.where((r) => r.status == 'pending').toList();

  factory AnnouncementData.fromJson(Map<String, dynamic> json) {
    final attrs = (json['attributes'] ?? json) as Map<String, dynamic>;
    final id    = (json['id'] ?? '').toString();

    // ── Reservation / court / venue / time_slot ──────────────────────────
    Map<String, dynamic> courtAttrs    = {};
    Map<String, dynamic> venueAttrs    = {};
    Map<String, dynamic> resAttrs      = {};
    Map<String, dynamic> timeSlotAttrs = {};
    String reservationId = '';
    String startTime     = '';
    String endTime       = '';

    final resRaw = attrs['reservation'];
    if (resRaw != null) {
      final resData = resRaw is Map ? (resRaw['data'] ?? resRaw) as Map<String, dynamic>? : null;
      if (resData != null) {
        reservationId = (resData['id'] ?? '').toString();
        resAttrs      = (resData['attributes'] ?? resData) as Map<String, dynamic>;

        final tsRaw  = resAttrs['time_slot'];
        if (tsRaw != null) {
          final tsData = tsRaw is Map ? (tsRaw['data'] ?? tsRaw) as Map<String, dynamic>? : null;
          if (tsData != null) {
            timeSlotAttrs = (tsData['attributes'] ?? tsData) as Map<String, dynamic>;
            startTime     = timeSlotAttrs['startTime']?.toString() ?? '';
            endTime       = timeSlotAttrs['endTime']?.toString() ?? '';
          }
        }

        final courtRaw = resAttrs['court'];
        if (courtRaw != null) {
          final courtData = courtRaw is Map ? (courtRaw['data'] ?? courtRaw) as Map<String, dynamic>? : null;
          if (courtData != null) {
            courtAttrs    = (courtData['attributes'] ?? courtData) as Map<String, dynamic>;
            final venueRaw = courtAttrs['venue'];
            if (venueRaw != null) {
              final venueData = venueRaw is Map ? (venueRaw['data'] ?? venueRaw) as Map<String, dynamic>? : null;
              if (venueData != null) {
                venueAttrs = (venueData['attributes'] ?? venueData) as Map<String, dynamic>;
              }
            }
          }
        }
      }
    }

    // Court image URL
    String courtImgUrl = '';
    if (courtAttrs['court_img_url']?.toString().isNotEmpty == true) {
      final u = courtAttrs['court_img_url'].toString();
      courtImgUrl = u.startsWith('http') ? u : '${ApiConstants.mediaBaseUrl}$u';
    } else if (courtAttrs['court_img'] is Map) {
      final img = courtAttrs['court_img'] as Map;
      final imgData = img['data'] ?? img;
      final u = imgData['url']?.toString() ?? '';
      if (u.isNotEmpty) courtImgUrl = u.startsWith('http') ? u : '${ApiConstants.mediaBaseUrl}$u';
    } else if (courtAttrs['photos_urls'] is List && (courtAttrs['photos_urls'] as List).isNotEmpty) {
      final u = (courtAttrs['photos_urls'] as List).first.toString();
      courtImgUrl = u.startsWith('http') ? u : '${ApiConstants.mediaBaseUrl}$u';
    } else if (courtAttrs['photos'] is List && (courtAttrs['photos'] as List).isNotEmpty) {
      final f = (courtAttrs['photos'] as List).first;
      if (f is Map && f['url'] != null) {
        final u = f['url'].toString();
        courtImgUrl = u.startsWith('http') ? u : '${ApiConstants.mediaBaseUrl}$u';
      }
    }

    // ── Host (player who created the announcement) ───────────────────────
    final playerRaw   = attrs['player'];
    final playerData  = playerRaw is Map ? (playerRaw['data'] ?? playerRaw) as Map<String, dynamic>? : null;
    final playerAttrs = playerData != null ? (playerData['attributes'] ?? playerData) as Map<String, dynamic> : <String, dynamic>{};
    final authRaw     = playerAttrs['player'];
    final authData    = authRaw is Map ? (authRaw['data'] ?? authRaw) as Map<String, dynamic>? : null;
    final authAttrs   = authData != null ? (authData['attributes'] ?? authData) as Map<String, dynamic> : <String, dynamic>{};

    final hostName     = authAttrs['username']?.toString() ?? playerAttrs['nom']?.toString() ?? 'Player';
    final hostInitials = hostName.isNotEmpty ? hostName[0].toUpperCase() : 'P';
    final hostPlayerId = (playerData?['id'] ?? '').toString();
    // Phone: check auth user first, then player profile
    final hostPhone    = authAttrs['phone']?.toString() ?? playerAttrs['phone']?.toString() ?? '';

    // ── Join requests ────────────────────────────────────────────────────
    final jrRaw  = attrs['join_requests'];
    final jrList = jrRaw is Map
        ? (jrRaw['data'] as List? ?? [])
        : (jrRaw is List ? jrRaw : <dynamic>[]);

    final joinRequests = jrList
        .whereType<Map<String, dynamic>>()
        .map(JoinRequestData.fromJson)
        .toList();

    final acceptedCount = joinRequests.where((j) => j.status == 'accepted').length;

    return AnnouncementData(
      id:            id,
      description:   attrs['description']?.toString() ?? '',
      playersNeeded: (attrs['players_needed'] as num?)?.toInt() ?? 1,
      status:        attrs['status']?.toString() ?? 'open',
      courtName:     courtAttrs['name']?.toString() ?? 'Court',
      venueName:     venueAttrs['name']?.toString() ?? 'Venue',
      sport:         (courtAttrs['sport'] ?? courtAttrs['sports'])?.toString() ?? 'football',
      date:          resAttrs['booking_date_play']?.toString().split('T')[0] ?? '',
      startTime:     startTime,
      endTime:       endTime,
      courtImageUrl: courtImgUrl,
      reservationId: reservationId,
      hostName:      hostName,
      hostInitials:  hostInitials,
      hostPlayerId:  hostPlayerId,
      hostPhone:     hostPhone,
      joinRequests:  joinRequests,
      acceptedCount: acceptedCount,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class JoinRequestData {
  final String  id;
  final String  message;
  final String  status;        // pending | accepted | declined
  final String  playerName;
  final String  playerInitials;
  final String  playerId;
  final String  playerPhone;   // NEW — requester's phone number
  final String? announcementId;
  final String? courtName;

  const JoinRequestData({
    required this.id,
    required this.message,
    required this.status,
    required this.playerName,
    required this.playerInitials,
    required this.playerId,
    required this.playerPhone,
    this.announcementId,
    this.courtName,
  });

  factory JoinRequestData.fromJson(Map<String, dynamic> json) {
    final attrs      = (json['attributes'] ?? json) as Map<String, dynamic>;
    final playerRaw  = attrs['player'];
    final playerData = playerRaw is Map ? (playerRaw['data'] ?? playerRaw) as Map<String, dynamic>? : null;
    final playerAttrs = playerData != null ? (playerData['attributes'] ?? playerData) as Map<String, dynamic> : <String, dynamic>{};
    final authRaw    = playerAttrs['player'];
    final authData   = authRaw is Map ? (authRaw['data'] ?? authRaw) as Map<String, dynamic>? : null;
    final authAttrs  = authData != null ? (authData['attributes'] ?? authData) as Map<String, dynamic> : <String, dynamic>{};

    final name      = authAttrs['username']?.toString() ?? playerAttrs['nom']?.toString() ?? 'Player';
    final initials  = name.isNotEmpty ? name[0].toUpperCase() : 'P';
    // Phone: check auth user, then player profile
    final phone     = authAttrs['phone']?.toString() ?? playerAttrs['phone']?.toString() ?? '';

    // Court name via announcement → reservation → court
    String courtName = '';
    final annRaw  = attrs['announcement'];
    final annData = annRaw is Map ? (annRaw['data'] ?? annRaw) as Map<String, dynamic>? : null;
    if (annData != null) {
      final annAttrs  = (annData['attributes'] ?? annData) as Map<String, dynamic>;
      final resRaw    = annAttrs['reservation'];
      final resData   = resRaw is Map ? (resRaw['data'] ?? resRaw) as Map<String, dynamic>? : null;
      if (resData != null) {
        final resAttrs  = (resData['attributes'] ?? resData) as Map<String, dynamic>;
        final courtRaw  = resAttrs['court'];
        final courtData = courtRaw is Map ? (courtRaw['data'] ?? courtRaw) as Map<String, dynamic>? : null;
        if (courtData != null) {
          final ca = (courtData['attributes'] ?? courtData) as Map<String, dynamic>;
          courtName = ca['name']?.toString() ?? '';
        }
      }
    }

    return JoinRequestData(
      id:             (json['id'] ?? '').toString(),
      message:        attrs['message']?.toString() ?? '',
      status:         attrs['status']?.toString() ?? 'pending',
      playerName:     name,
      playerInitials: initials,
      playerId:       (playerData?['id'] ?? '').toString(),
      playerPhone:    phone,
      announcementId: annData?['id']?.toString(),
      courtName:      courtName,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVICE
// ─────────────────────────────────────────────────────────────────────────────

class AnnouncementService {
  final String token;
  AnnouncementService({required this.token});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  void _check(http.Response r, String method) {
    if (r.statusCode < 200 || r.statusCode >= 300) {
      final body = _tryDecode(r.body);
      throw Exception(body?['error']?['message'] ?? body?['message'] ?? 'Error ${r.statusCode}');
    }
  }

  static Map<String, dynamic>? _tryDecode(String s) {
    try { return json.decode(s) as Map<String, dynamic>?; } catch (_) { return null; }
  }

  Future<List<AnnouncementData>> fetchFeed() async {
    final r = await http.get(Uri.parse(ApiConstants.announcements), headers: _headers);
    _check(r, 'fetchFeed');
    final body = json.decode(r.body) as Map<String, dynamic>;
    return (body['data'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(AnnouncementData.fromJson)
        .toList();
  }

  Future<List<AnnouncementData>> fetchMine() async {
    final r = await http.get(Uri.parse(ApiConstants.myAnnouncements), headers: _headers);
    _check(r, 'fetchMine');
    final body = json.decode(r.body) as Map<String, dynamic>;
    return (body['data'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(AnnouncementData.fromJson)
        .toList();
  }

  Future<List<JoinRequestData>> fetchMyRequests() async {
    final r = await http.get(Uri.parse(ApiConstants.myRequests), headers: _headers);
    _check(r, 'fetchMyRequests');
    final body = json.decode(r.body) as Map<String, dynamic>;
    return (body['data'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(JoinRequestData.fromJson)
        .toList();
  }

  Future<AnnouncementData> create({
    required String reservationId,
    required String description,
    required int    playersNeeded,
  }) async {
    final r = await http.post(
      Uri.parse(ApiConstants.announcements),
      headers: _headers,
      body: json.encode({
        'reservation_id': reservationId,
        'description':    description,
        'players_needed': playersNeeded,
      }),
    );
    _check(r, 'create');
    final body = json.decode(r.body) as Map<String, dynamic>;
    return AnnouncementData.fromJson(body['data'] ?? body);
  }

  Future<void> delete(String id) async {
    final r = await http.delete(Uri.parse(ApiConstants.announcement(id)), headers: _headers);
    _check(r, 'delete');
  }

  Future<AnnouncementData> update(String id, Map<String, dynamic> data) async {
    final r = await http.put(
      Uri.parse(ApiConstants.announcement(id)),
      headers: _headers,
      body: json.encode(data),
    );
    _check(r, 'update');
    final body = json.decode(r.body) as Map<String, dynamic>;
    return AnnouncementData.fromJson(body['data'] ?? body);
  }

  Future<JoinRequestData> requestJoin(String announcementId, {String message = ''}) async {
    final r = await http.post(
      Uri.parse(ApiConstants.announcementRequests(announcementId)),
      headers: _headers,
      body: json.encode({'message': message}),
    );
    _check(r, 'requestJoin');
    final body = json.decode(r.body) as Map<String, dynamic>;
    return JoinRequestData.fromJson(body['data'] ?? body);
  }

  Future<JoinRequestData> respondToRequest(
    String announcementId,
    String requestId,
    String status,
  ) async {
    final r = await http.put(
      Uri.parse(ApiConstants.announcementRequest(announcementId, requestId)),
      headers: _headers,
      body: json.encode({'status': status}),
    );
    _check(r, 'respondToRequest');
    final body = json.decode(r.body) as Map<String, dynamic>;
    return JoinRequestData.fromJson(body['data'] ?? body);
  }
}





















/*// lib/Services/announcement_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sporta/Core/Constants/api_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────

class AnnouncementData {
  final String id;
  final String description;
  final int playersNeeded;
  final String status;
  final String courtName;
  final String venueName;
  final String sport;
  final String date;
  final String startTime;
  final String endTime;
  final String courtImageUrl;
  final String reservationId;
  final String hostName;
  final String hostInitials;
  final String hostPlayerId;
  final List<JoinRequestData> joinRequests;
  final int acceptedCount;

  const AnnouncementData({
    required this.id,
    required this.description,
    required this.playersNeeded,
    required this.status,
    required this.courtName,
    required this.venueName,
    required this.sport,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.courtImageUrl,
    required this.reservationId,
    required this.hostName,
    required this.hostInitials,
    required this.hostPlayerId,
    required this.joinRequests,
    required this.acceptedCount,
  });

  int get spotsLeft => playersNeeded - acceptedCount;
  bool get isFull => spotsLeft <= 0 || status == 'full';
  bool get isOpen => status == 'open' && !isFull;

  factory AnnouncementData.fromJson(Map<String, dynamic> json) {
    // Handle both { data: {...} } and direct object formats
    final attrs = (json['attributes'] ?? json) as Map<String, dynamic>;
    final id = (json['id'] ?? '').toString();

    // ── Reservation / court / venue / time_slot ──────────────────────────
    Map<String, dynamic> courtAttrs = {};
    Map<String, dynamic> venueAttrs = {};
    Map<String, dynamic> resAttrs = {};
    Map<String, dynamic> timeSlotAttrs = {};
    String reservationId = '';
    String startTime = '';
    String endTime = '';
    
    // Try to get reservation data
    final resRaw = attrs['reservation'];
    if (resRaw != null) {
      final resData = resRaw is Map ? (resRaw['data'] ?? resRaw) as Map<String, dynamic> : null;
      if (resData != null) {
        reservationId = (resData['id'] ?? '').toString();
        resAttrs = (resData['attributes'] ?? resData) as Map<String, dynamic>;
        
        // ✅ FIX: Get time_slot data from reservation
        final timeSlotRaw = resAttrs['time_slot'];
        if (timeSlotRaw != null) {
          final timeSlotData = timeSlotRaw is Map ? (timeSlotRaw['data'] ?? timeSlotRaw) as Map<String, dynamic> : null;
          if (timeSlotData != null) {
            timeSlotAttrs = (timeSlotData['attributes'] ?? timeSlotData) as Map<String, dynamic>;
            startTime = timeSlotAttrs['startTime']?.toString() ?? '';
            endTime = timeSlotAttrs['endTime']?.toString() ?? '';
          }
        }
        
        // Get court data
        final courtRaw = resAttrs['court'];
        if (courtRaw != null) {
          final courtData = courtRaw is Map ? (courtRaw['data'] ?? courtRaw) as Map<String, dynamic> : null;
          if (courtData != null) {
            courtAttrs = (courtData['attributes'] ?? courtData) as Map<String, dynamic>;
            
            // Get venue data from court
            final venueRaw = courtAttrs['venue'];
            if (venueRaw != null) {
              final venueData = venueRaw is Map ? (venueRaw['data'] ?? venueRaw) as Map<String, dynamic> : null;
              if (venueData != null) {
                venueAttrs = (venueData['attributes'] ?? venueData) as Map<String, dynamic>;
              }
            }
          }
        }
      }
    }

    // Extract court image URL
    String courtImgUrl = '';
    if (courtAttrs['court_img_url'] != null && courtAttrs['court_img_url'].toString().isNotEmpty) {
      String url = courtAttrs['court_img_url'].toString();
      if (url.startsWith('http')) {
        courtImgUrl = url;
      } else {
        courtImgUrl = ApiConstants.mediaBaseUrl + url;
      }
    } else if (courtAttrs['court_img'] != null) {
      final courtImg = courtAttrs['court_img'];
      if (courtImg is Map) {
        final imgData = courtImg['data'] ?? courtImg;
        final url = imgData['url']?.toString() ?? '';
        if (url.isNotEmpty) {
          courtImgUrl = url.startsWith('http') ? url : ApiConstants.mediaBaseUrl + url;
        }
      }
    } else if (courtAttrs['photos_urls'] != null && courtAttrs['photos_urls'] is List && (courtAttrs['photos_urls'] as List).isNotEmpty) {
      String url = (courtAttrs['photos_urls'] as List).first.toString();
      courtImgUrl = url.startsWith('http') ? url : ApiConstants.mediaBaseUrl + url;
    } else if (courtAttrs['photos'] != null && courtAttrs['photos'] is List && (courtAttrs['photos'] as List).isNotEmpty) {
      final firstPhoto = (courtAttrs['photos'] as List).first;
      if (firstPhoto is Map) {
        final url = firstPhoto['url']?.toString() ?? '';
        if (url.isNotEmpty) {
          courtImgUrl = url.startsWith('http') ? url : ApiConstants.mediaBaseUrl + url;
        }
      }
    }

    // ── Host (player who created the announcement) ───────────────────────────
    final playerRaw = attrs['player'];
    final playerData = playerRaw is Map ? (playerRaw['data'] ?? playerRaw) as Map<String, dynamic> : null;
    final playerAttrs = playerData != null ? (playerData['attributes'] ?? playerData) as Map<String, dynamic> : <String, dynamic>{};
    final authUserRaw = playerAttrs['player'];
    final authUserData = authUserRaw is Map ? (authUserRaw['data'] ?? authUserRaw) as Map<String, dynamic> : null;
    final authUserAttrs = authUserData != null ? (authUserData['attributes'] ?? authUserData) as Map<String, dynamic> : <String, dynamic>{};

    final hostName = authUserAttrs['username']?.toString() ?? playerAttrs['nom']?.toString() ?? 'Player';
    final hostInitials = hostName.isNotEmpty ? hostName[0].toUpperCase() : 'P';
    final hostPlayerId = (playerData?['id'] ?? '').toString();

    // ── Join requests ────────────────────────────────────────────────────────
    final jrRaw = attrs['join_requests'];
    final jrList = jrRaw is Map ? (jrRaw['data'] as List? ?? []) : (jrRaw is List ? jrRaw : <dynamic>[]);
    final joinRequests = jrList
        .whereType<Map<String, dynamic>>()
        .map((j) => JoinRequestData.fromJson(j))
        .toList();
    final acceptedCount = joinRequests.where((j) => j.status == 'accepted').length;

    return AnnouncementData(
      id: id,
      description: attrs['description']?.toString() ?? '',
      playersNeeded: (attrs['players_needed'] as num?)?.toInt() ?? 1,
      status: attrs['status']?.toString() ?? 'open',
      courtName: courtAttrs['name']?.toString() ?? 'Court',
      venueName: venueAttrs['name']?.toString() ?? 'Venue',
      sport: (courtAttrs['sport'] ?? courtAttrs['sports'])?.toString() ?? 'football',
      date: resAttrs['booking_date_play']?.toString().split('T')[0] ?? '',
      startTime: startTime,
      endTime: endTime,
      courtImageUrl: courtImgUrl,
      reservationId: reservationId,
      hostName: hostName,
      hostInitials: hostInitials,
      hostPlayerId: hostPlayerId,
      joinRequests: joinRequests,
      acceptedCount: acceptedCount,
    );
  }
}

class JoinRequestData {
  final String id;
  final String message;
  final String status;
  final String playerName;
  final String playerInitials;
  final String playerId;
  final String? announcementId;
  final String? courtName;

  const JoinRequestData({
    required this.id,
    required this.message,
    required this.status,
    required this.playerName,
    required this.playerInitials,
    required this.playerId,
    this.announcementId,
    this.courtName,
  });

  factory JoinRequestData.fromJson(Map<String, dynamic> json) {
    final attrs = (json['attributes'] ?? json) as Map<String, dynamic>;
    final playerRaw = attrs['player'];
    final playerData = playerRaw is Map ? (playerRaw['data'] ?? playerRaw) as Map<String, dynamic> : null;
    final playerAttrs = playerData != null ? (playerData['attributes'] ?? playerData) as Map<String, dynamic> : <String, dynamic>{};
    final authRaw = playerAttrs['player'];
    final authData = authRaw is Map ? (authRaw['data'] ?? authRaw) as Map<String, dynamic> : null;
    final authAttrs = authData != null ? (authData['attributes'] ?? authData) as Map<String, dynamic> : <String, dynamic>{};

    final name = authAttrs['username']?.toString() ?? playerAttrs['nom']?.toString() ?? 'Player';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'P';

    String courtName = '';
    final announcementRaw = attrs['announcement'];
    final announcementData = announcementRaw is Map ? (announcementRaw['data'] ?? announcementRaw) as Map<String, dynamic>? : null;
    if (announcementData != null) {
      final announcementAttrs = announcementData['attributes'] ?? announcementData;
      final reservationRaw = announcementAttrs['reservation'];
      final reservationData = reservationRaw is Map ? (reservationRaw['data'] ?? reservationRaw) as Map<String, dynamic>? : null;
      if (reservationData != null) {
        final reservationAttrs = reservationData['attributes'] ?? reservationData;
        final courtRaw = reservationAttrs['court'];
        final courtData = courtRaw is Map ? (courtRaw['data'] ?? courtRaw) as Map<String, dynamic>? : null;
        if (courtData != null) {
          final courtAttrs = courtData['attributes'] ?? courtData;
          courtName = courtAttrs['name']?.toString() ?? '';
        }
      }
    }

    return JoinRequestData(
      id: (json['id'] ?? '').toString(),
      message: attrs['message']?.toString() ?? '',
      status: attrs['status']?.toString() ?? 'pending',
      playerName: name,
      playerInitials: initials,
      playerId: (playerData?['id'] ?? '').toString(),
      announcementId: announcementData?['id']?.toString(),
      courtName: courtName,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVICE
// ─────────────────────────────────────────────────────────────────────────────

class AnnouncementService {
  final String token;
  
  AnnouncementService({required this.token});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  void _check(http.Response r, String method) {
    if (r.statusCode < 200 || r.statusCode >= 300) {
      final body = _tryDecode(r.body);
      final msg = body?['error']?['message'] ?? body?['message'] ?? 'Error ${r.statusCode}';
      throw Exception(msg);
    }
  }

  static Map<String, dynamic>? _tryDecode(String s) {
    try {
      return json.decode(s) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  /// GET /announcements — community feed
  Future<List<AnnouncementData>> fetchFeed() async {
    final r = await http.get(Uri.parse(ApiConstants.announcements), headers: _headers);
    _check(r, 'fetchFeed');
    
    final body = json.decode(r.body) as Map<String, dynamic>;
    List<dynamic> list = body['data'] as List? ?? [];
    
    return list.whereType<Map<String, dynamic>>().map(AnnouncementData.fromJson).toList();
  }

  /// GET /announcements/mine — current player's own announcements
  Future<List<AnnouncementData>> fetchMine() async {
    final r = await http.get(Uri.parse(ApiConstants.myAnnouncements), headers: _headers);
    _check(r, 'fetchMine');
    
    final body = json.decode(r.body) as Map<String, dynamic>;
    List<dynamic> list = body['data'] as List? ?? [];
    
    return list.whereType<Map<String, dynamic>>().map(AnnouncementData.fromJson).toList();
  }

  /// GET /announcements/my-requests — current player's own join requests
  Future<List<JoinRequestData>> fetchMyRequests() async {
    final r = await http.get(Uri.parse(ApiConstants.myRequests), headers: _headers);
    _check(r, 'fetchMyRequests');
    
    final body = json.decode(r.body) as Map<String, dynamic>;
    List<dynamic> list = body['data'] as List? ?? [];
    
    return list.whereType<Map<String, dynamic>>().map(JoinRequestData.fromJson).toList();
  }

  /// POST /announcements — create new announcement
  Future<AnnouncementData> create({
    required String reservationId,
    required String description,
    required int playersNeeded,
  }) async {
    final r = await http.post(
      Uri.parse(ApiConstants.announcements),
      headers: _headers,
      body: json.encode({
        'reservation_id': reservationId,
        'description': description,
        'players_needed': playersNeeded,
      }),
    );
    _check(r, 'create');
    
    final body = json.decode(r.body) as Map<String, dynamic>;
    return AnnouncementData.fromJson(body['data'] ?? body);
  }

  /// DELETE /announcements/:id
  Future<void> delete(String id) async {
    final r = await http.delete(Uri.parse(ApiConstants.announcement(id)), headers: _headers);
    _check(r, 'delete');
  }

  /// PUT /announcements/:id — update announcement
  Future<AnnouncementData> update(String id, Map<String, dynamic> data) async {
    final r = await http.put(
      Uri.parse(ApiConstants.announcement(id)),
      headers: _headers,
      body: json.encode(data),
    );
    _check(r, 'update');
    
    final body = json.decode(r.body) as Map<String, dynamic>;
    return AnnouncementData.fromJson(body['data'] ?? body);
  }

  /// POST /announcements/:id/requests — request to join
  Future<JoinRequestData> requestJoin(String announcementId, {String message = ''}) async {
    final r = await http.post(
      Uri.parse(ApiConstants.announcementRequests(announcementId)),
      headers: _headers,
      body: json.encode({'message': message}),
    );
    _check(r, 'requestJoin');
    
    final body = json.decode(r.body) as Map<String, dynamic>;
    return JoinRequestData.fromJson(body['data'] ?? body);
  }

  /// PUT /announcements/:id/requests/:requestId — host responds
  Future<JoinRequestData> respondToRequest(
    String announcementId,
    String requestId,
    String status,
  ) async {
    final r = await http.put(
      Uri.parse(ApiConstants.announcementRequest(announcementId, requestId)),
      headers: _headers,
      body: json.encode({'status': status}),
    );
    _check(r, 'respondToRequest');
    
    final body = json.decode(r.body) as Map<String, dynamic>;
    return JoinRequestData.fromJson(body['data'] ?? body);
  }
}*/