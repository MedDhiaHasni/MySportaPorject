// lib/Models/venue_model.dart
// FIX: fromBackendJson now maps courts list and preserves
//      court_img_url / photos_urls so CourtBookingPage can display images.

import 'package:sporta/Core/Constants/api_constants.dart';

class VenueModel {
  final String id;
  final String name;
  final String location;
  final List<String> sports;
  final List<String> amenities;
  final int minPrice;
  final int maxPrice;
  final bool available;
  final String openUntil;
  final String image;
  final double lat;
  final double lng;
  final List<Map<String, dynamic>> courts;
  final String managerName;
  final String managerPhone;
  final String managerAvatar;
  final String description;
  final double avgRating;
  final int totalRatings;

  VenueModel({
    required this.id,
    required this.name,
    required this.location,
    required this.sports,
    required this.amenities,
    required this.minPrice,
    required this.maxPrice,
    required this.available,
    required this.openUntil,
    required this.image,
    required this.lat,
    required this.lng,
    required this.courts,
    this.managerName  = 'Venue Manager',
    this.managerPhone = '+216 XX XXX XXX',
    this.managerAvatar = 'VM',
    this.description  = '',
    this.avgRating    = 0.0,
    this.totalRatings = 0,
  });

  // ── Backend JSON (public venues endpoint) ──────────────────────────────────
  factory VenueModel.fromBackendJson(Map<String, dynamic> json) {

    // ── Sports ─────────────────────────────────────────────────────────────
    List<String> sportsList = [];
    if (json['sports'] is List) {
      sportsList = (json['sports'] as List).map((s) => s.toString()).toList();
    } else if (json['sports'] is String && (json['sports'] as String).isNotEmpty) {
      sportsList = [json['sports'] as String];
    }

    // ── Amenities ──────────────────────────────────────────────────────────
    List<String> amenitiesList = [];
    if (json['amenities'] is List) {
      amenitiesList = (json['amenities'] as List).map((a) => a.toString()).toList();
    } else if (json['amenities'] is String && (json['amenities'] as String).isNotEmpty) {
      amenitiesList = [json['amenities'] as String];
    }

    // ── Venue photo ────────────────────────────────────────────────────────
    String imageUrl = '';
    if (json['photo'] is Map && json['photo']['url'] != null) {
      final raw = json['photo']['url'].toString();
      imageUrl  = raw.startsWith('http') ? raw : '${ApiConstants.mediaBaseUrl}$raw';
    }

    // ── Manager ────────────────────────────────────────────────────────────
    String managerName   = '';
    String managerPhone  = '';
    String managerAvatar = 'VM';

    final mgr = json['manager'];
    if (mgr is Map) {
      managerName  = (mgr['name']     ?? mgr['username'] ?? '').toString();
      managerPhone = (mgr['phone']    ?? '').toString();
      // Avatar: first letter of name
      if (managerName.isNotEmpty) {
        managerAvatar = managerName[0].toUpperCase();
      }
    }

    // ── Courts — preserve court_img_url + photos_urls ─────────────────────
    // The backend now returns courts with flat court_img_url and photos_urls
    // strings so the booking page can display images without extra parsing.
    List<Map<String, dynamic>> courtsList = [];
    if (json['courts'] is List) {
      courtsList = (json['courts'] as List).map((c) {
        if (c is! Map) return <String, dynamic>{};
        final court = Map<String, dynamic>.from(c as Map);

        // Ensure court_img_url is present and absolute
        if (court['court_img_url'] == null || court['court_img_url'].toString().isEmpty) {
          // Try to build from nested court_img object
          final img = court['court_img'];
          if (img is Map && img['url'] != null) {
            final raw = img['url'].toString();
            court['court_img_url'] = raw.startsWith('http')
                ? raw
                : '${ApiConstants.mediaBaseUrl}$raw';
          }
        } else {
          // Make sure it's absolute
          final existing = court['court_img_url'].toString();
          if (!existing.startsWith('http') && existing.isNotEmpty) {
            court['court_img_url'] = '${ApiConstants.mediaBaseUrl}$existing';
          }
        }

        // Ensure photos_urls is present and absolute
        if (court['photos_urls'] == null || (court['photos_urls'] is List && (court['photos_urls'] as List).isEmpty)) {
          final photos = court['photos'];
          if (photos is List && photos.isNotEmpty) {
            court['photos_urls'] = (photos).map((p) {
              final url = (p is Map ? p['url'] : p)?.toString() ?? '';
              if (url.isEmpty) return '';
              return url.startsWith('http') ? url : '${ApiConstants.mediaBaseUrl}$url';
            }).where((u) => u.isNotEmpty).toList();
          }
        }

        // Ensure isActive is mapped (backend uses isActive, old code used available)
        court['available'] = court['isActive'] ?? court['available'] ?? true;

        // Normalise sport field (backend uses 'sports' enum, cards expect 'sport')
        if (court['sport'] == null && court['sports'] != null) {
          court['sport'] = court['sports'];
        }

        // Ensure name field (backend uses 'name', old cards expected 'courtName')
        if (court['courtName'] == null && court['name'] != null) {
          court['courtName'] = court['name'];
        }

        // Normalise price (backend uses 'pricePerHour', old cards expected 'price')
        if (court['price'] == null && court['pricePerHour'] != null) {
          court['price'] = court['pricePerHour'];
        }

        return court;
      }).toList();
    }

    // ── Ratings ────────────────────────────────────────────────────────────
    final avgRating   = (json['avg_rating']   as num?)?.toDouble() ?? 0.0;
    final totalRating = (json['total_rating'] as num?)?.toInt()    ?? 0;

    return VenueModel(
      id:            json['id'].toString(),
      name:          json['name']        ?? '',
      location:      json['location']    ?? '',
      sports:        sportsList,
      amenities:     amenitiesList,
      minPrice:      0,
      maxPrice:      0,
      available:     json['isActive']    ?? true,
      openUntil:     json['closeTime']   ?? '23:00',
      image:         imageUrl,
      lat:           (json['lat']  as num?)?.toDouble() ?? 0.0,
      lng:           (json['lng']  as num?)?.toDouble() ?? 0.0,
      courts:        courtsList,
      managerName:   managerName,
      managerPhone:  managerPhone,
      managerAvatar: managerAvatar,
      description:   json['description']?.toString() ?? '',
      avgRating:     avgRating,
      totalRatings:  totalRating,
    );
  }

  // ── Sample / local JSON ────────────────────────────────────────────────────
  factory VenueModel.fromJson(Map<String, dynamic> json) {
    return VenueModel(
      id:            json['id']?.toString()          ?? '',
      name:          json['name']                    ?? '',
      location:      json['location']                ?? '',
      sports:        json['sports']    != null ? List<String>.from(json['sports'])    : [],
      amenities:     json['amenities'] != null ? List<String>.from(json['amenities']) : [],
      minPrice:      json['minPrice']  ?? 0,
      maxPrice:      json['maxPrice']  ?? 0,
      available:     json['available'] ?? true,
      openUntil:     json['openUntil'] ?? '23:00',
      image:         json['image']     ?? '',
      lat:           (json['lat']  as num?)?.toDouble() ?? 0.0,
      lng:           (json['lng']  as num?)?.toDouble() ?? 0.0,
      courts:        json['courts'] != null ? List<Map<String, dynamic>>.from(json['courts']) : [],
      managerName:   json['managerName']   ?? 'Venue Manager',
      managerPhone:  json['managerPhone']  ?? '+216 XX XXX XXX',
      managerAvatar: json['managerAvatar'] ?? 'VM',
      description:   json['description']?.toString() ?? '',
      avgRating:     (json['avg_rating']   as num?)?.toDouble() ?? 0.0,
      totalRatings:  (json['total_rating'] as num?)?.toInt()    ?? 0,
    );
  }
}


/*// venue_model.dart — Models/venue_model.dart

class VenueModel {
  final String id;
  final String name;
  final String location;
  final List<String> sports;
  final List<String> amenities;
  final int minPrice;
  final int maxPrice;
  final bool available;
  final String openUntil;
  final String image;
  final double lat;
  final double lng;
  final List<Map<String, dynamic>> courts;
  final String managerName;
  final String managerPhone;
  final String managerAvatar;
  final String description;  // NEW: Venue description field

  VenueModel({
    required this.id,
    required this.name,
    required this.location,
    required this.sports,
    required this.amenities,
    required this.minPrice,
    required this.maxPrice,
    required this.available,
    required this.openUntil,
    required this.image,
    required this.lat,
    required this.lng,
    required this.courts,
    this.managerName = 'Venue Manager',
    this.managerPhone = '+216 XX XXX XXX',
    this.managerAvatar = 'VM',
    this.description = '',  // NEW: Default empty string
  });

  // NEW: Factory constructor for backend data (used by dashboard)
  factory VenueModel.fromBackendJson(Map<String, dynamic> json) {
    // Parse sports
    List<String> sportsList = [];
    if (json['sports'] != null && json['sports'] is List) {
      sportsList = (json['sports'] as List).map((s) => s.toString()).toList();
    }

    // Parse amenities
    List<String> amenitiesList = [];
    if (json['amenities'] != null && json['amenities'] is List) {
      amenitiesList = (json['amenities'] as List).map((a) => a.toString()).toList();
    }

    // Parse photos - get first photo URL
    String imageUrl = '';
    if (json['photos'] != null) {
      if (json['photos'] is List && json['photos'].isNotEmpty) {
        final firstPhoto = json['photos'][0];
        if (firstPhoto is Map && firstPhoto.containsKey('url')) {
          imageUrl = 'http://localhost:1337${firstPhoto['url']}';
        } else if (firstPhoto is String) {
          imageUrl = firstPhoto;
        }
      }
    }

    // Parse description
    String description = json['description']?.toString() ?? '';

    return VenueModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      sports: sportsList,
      amenities: amenitiesList,
      minPrice: 0,  // Will be calculated from courts
      maxPrice: 0,  // Will be calculated from courts
      available: json['isActive'] ?? true,
      openUntil: json['closeTime'] ?? '23:00',
      image: imageUrl,
      lat: 0.0,  // Not from backend, will be updated later if needed
      lng: 0.0,  // Not from backend, will be updated later if needed
      courts: [],  // Will be loaded separately
      managerName: '',
      managerPhone: '',
      managerAvatar: '',
      description: description,  // NEW: Add description
    );
  }

  // Existing fromJson for player explore page (sample data)
  factory VenueModel.fromJson(Map<String, dynamic> json) {
    return VenueModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      sports: json['sports'] != null ? List<String>.from(json['sports']) : [],
      amenities: json['amenities'] != null ? List<String>.from(json['amenities']) : [],
      minPrice: json['minPrice'] ?? 0,
      maxPrice: json['maxPrice'] ?? 0,
      available: json['available'] ?? true,
      openUntil: json['openUntil'] ?? '23:00',
      image: json['image'] ?? '',
      lat: json['lat']?.toDouble() ?? 0.0,
      lng: json['lng']?.toDouble() ?? 0.0,
      courts: json['courts'] != null ? List<Map<String, dynamic>>.from(json['courts']) : [],
      managerName: json['managerName'] ?? 'Venue Manager',
      managerPhone: json['managerPhone'] ?? '+216 XX XXX XXX',
      managerAvatar: json['managerAvatar'] ?? 'VM',
      description: json['description']?.toString() ?? '',  // NEW: Add description
    );
  }
}*/