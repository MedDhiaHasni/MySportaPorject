import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sporta/Core/Constants/api_constants.dart';

class VenueService {
  // ─────────────────────────────────────────────────────────────────────────
  // GET ALL VENUES - Get all venues for the logged-in manager
  // ─────────────────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getVenues(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.managerVenues),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get venues response status: ${response.statusCode}');
      print('Get venues response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return data;
        } else if (data is Map && data.containsKey('data')) {
          return data['data'] as List;
        } else {
          return [];
        }
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to get venues');
      }
    } catch (e) {
      print('Error in getVenues: $e');
      throw Exception(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GET SINGLE VENUE - Get venue by ID
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getVenue({
    required String token,
    required String venueId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.managerVenue(venueId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get venue response status: ${response.statusCode}');
      print('Get venue response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to get venue');
      }
    } catch (e) {
      print('Error in getVenue: $e');
      throw Exception(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CREATE VENUE - Create a new venue
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> createVenue({
    required String token,
    required String name,
    required String location,
    String? description,
    required String openTime,
    required String closeTime,
    List<String>? photos,
    required List<String> sports,
    List<String>? amenities,
    bool isActive = true,
    double? lat,
    double? lng,
    int? photoId,  // Changed: pass photo ID instead of URL
  }) async {
    try {
      final body = {
        'name': name,
        'location': location,
        'openTime': openTime,
        'closeTime': closeTime,
        'sports': sports,
        'isActive': isActive,
      };
      
      if (description != null && description.isNotEmpty) {
        body['description'] = description;
      }
      // Photo is single media - send the photo ID
      if (photoId != null) {
        body['photo'] = photoId;
      }
      if (amenities != null && amenities.isNotEmpty) {
        body['amenities'] = amenities;
      }
      if (lat != null) {
        body['lat'] = lat;
      }
      if (lng != null) {
        body['lng'] = lng;
      }

      final response = await http.post(
        Uri.parse(ApiConstants.managerVenues),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      print('Create venue response status: ${response.statusCode}');
      print('Create venue response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['venue'] ?? data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to create venue');
      }
    } catch (e) {
      print('Error in createVenue: $e');
      throw Exception(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UPDATE VENUE - Update an existing venue
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> updateVenue({
    required String token,
    required String venueId,
    String? name,
    String? location,
    String? description,
    String? openTime,
    String? closeTime,
    List<String>? photos,
    List<String>? sports,
    List<String>? amenities,
    bool? isActive,
    double? lat,
    double? lng,
    int? photoId,  // Changed: pass photo ID instead of URL
  }) async {
    try {
      final body = <String, dynamic>{};
      
      if (name != null) body['name'] = name;
      if (location != null) body['location'] = location;
      if (description != null) body['description'] = description;
      if (openTime != null) body['openTime'] = openTime;
      if (closeTime != null) body['closeTime'] = closeTime;
      // Photo is single media - send the photo ID
      if (photoId != null) body['photo'] = photoId;
      if (sports != null) body['sports'] = sports;
      if (amenities != null) body['amenities'] = amenities;
      if (isActive != null) body['isActive'] = isActive;
      if (lat != null) body['lat'] = lat;
      if (lng != null) body['lng'] = lng;

      final response = await http.put(
        Uri.parse(ApiConstants.managerVenue(venueId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      print('Update venue response status: ${response.statusCode}');
      print('Update venue response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['venue'] ?? data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to update venue');
      }
    } catch (e) {
      print('Error in updateVenue: $e');
      throw Exception(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DELETE VENUE - Delete a venue
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> deleteVenue({
    required String token,
    required String venueId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConstants.managerVenue(venueId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Delete venue response status: ${response.statusCode}');
      print('Delete venue response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to delete venue');
      }
    } catch (e) {
      print('Error in deleteVenue: $e');
      throw Exception(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GET VENUE COURTS - Get all courts for a specific venue
  // ─────────────────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getVenueCourts({
    required String token,
    required String venueId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.managerVenueCourts(venueId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get venue courts response status: ${response.statusCode}');
      print('Get venue courts response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return data;
        } else if (data is Map && data.containsKey('data')) {
          return data['data'] as List;
        } else {
          return [];
        }
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to get venue courts');
      }
    } catch (e) {
      print('Error in getVenueCourts: $e');
      throw Exception(e.toString());
    }
  }
}