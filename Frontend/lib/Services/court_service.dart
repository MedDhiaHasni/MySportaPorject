import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:sporta/Core/Constants/api_constants.dart';

class CourtService {
  // ─────────────────────────────────────────────────────────────────────────
  // GET ALL COURTS - Get all courts for the logged-in manager's venues
  // ─────────────────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getCourts(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.managerCourts),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get courts response status: ${response.statusCode}');
      print('Get courts response body: ${response.body}');

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
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to get courts');
      }
    } catch (e) {
      print('Error in getCourts: $e');
      throw Exception(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GET SINGLE COURT - Get court by ID
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getCourt({
    required String token,
    required String courtId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.managerCourt(courtId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get court response status: ${response.statusCode}');
      print('Get court response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to get court');
      }
    } catch (e) {
      print('Error in getCourt: $e');
      throw Exception(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CREATE COURT - Create a new court for a venue
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> createCourt({
    required String token,
    required String name,
    String? description,
    required String sport,
    required double pricePerHour,
    required int capacity,
    File? courtImg,
    List<File>? photos,
    List<String>? amenities,
    bool isActive = true,
    required int venueId,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstants.managerCourts),
      );
      
      request.headers['Authorization'] = 'Bearer $token';
      
      // Add text fields
      request.fields['name'] = name;
      request.fields['sport'] = sport;
      request.fields['pricePerHour'] = pricePerHour.toString();
      request.fields['capacity'] = capacity.toString();
      request.fields['isActive'] = isActive.toString();
      request.fields['venue'] = venueId.toString();
      
      if (description != null && description.isNotEmpty) {
        request.fields['description'] = description;
      }
      
      if (amenities != null && amenities.isNotEmpty) {
        request.fields['amenities'] = json.encode(amenities);
      }
      
      // Add main court image
      if (courtImg != null) {
        final stream = http.ByteStream(courtImg.openRead());
        final length = await courtImg.length();
        final multipartFile = http.MultipartFile(
          'court_img',
          stream,
          length,
          filename: courtImg.path.split('/').last,
          contentType: MediaType('image', _getFileExtension(courtImg.path)),
        );
        request.files.add(multipartFile);
      }
      
      // Add gallery images
      if (photos != null && photos.isNotEmpty) {
        for (int i = 0; i < photos.length; i++) {
          final photo = photos[i];
          final stream = http.ByteStream(photo.openRead());
          final length = await photo.length();
          final multipartFile = http.MultipartFile(
            'photos',
            stream,
            length,
            filename: photo.path.split('/').last,
            contentType: MediaType('image', _getFileExtension(photo.path)),
          );
          request.files.add(multipartFile);
        }
      }
      
      final response = await request.send();
      final responseBody = await http.Response.fromStream(response);
      
      print('Create court response status: ${response.statusCode}');
      print('Create court response body: ${responseBody.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(responseBody.body);
        return data['court'] ?? data;
      } else {
        final error = json.decode(responseBody.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to create court');
      }
    } catch (e) {
      print('Error in createCourt: $e');
      throw Exception(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UPDATE COURT - Update an existing court
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> updateCourt({
    required String token,
    required String courtId,
    String? name,
    String? description,
    String? sport,
    double? pricePerHour,
    int? capacity,
    File? courtImg,
    List<File>? photos,
    List<String>? amenities,
    bool? isActive, int? courtImgId, required List<int> photosIds,
  }) async {
    try {
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse(ApiConstants.managerCourt(courtId)),
      );
      
      request.headers['Authorization'] = 'Bearer $token';
      
      // Add text fields
      if (name != null) request.fields['name'] = name;
      if (description != null) request.fields['description'] = description;
      if (sport != null) request.fields['sport'] = sport;
      if (pricePerHour != null) request.fields['pricePerHour'] = pricePerHour.toString();
      if (capacity != null) request.fields['capacity'] = capacity.toString();
      if (isActive != null) request.fields['isActive'] = isActive.toString();
      
      if (amenities != null && amenities.isNotEmpty) {
        request.fields['amenities'] = json.encode(amenities);
      }
      
      // Add main court image
      if (courtImg != null) {
        final stream = http.ByteStream(courtImg.openRead());
        final length = await courtImg.length();
        final multipartFile = http.MultipartFile(
          'court_img',
          stream,
          length,
          filename: courtImg.path.split('/').last,
          contentType: MediaType('image', _getFileExtension(courtImg.path)),
        );
        request.files.add(multipartFile);
      }
      
      // Add gallery images
      if (photos != null && photos.isNotEmpty) {
        for (int i = 0; i < photos.length; i++) {
          final photo = photos[i];
          final stream = http.ByteStream(photo.openRead());
          final length = await photo.length();
          final multipartFile = http.MultipartFile(
            'photos',
            stream,
            length,
            filename: photo.path.split('/').last,
            contentType: MediaType('image', _getFileExtension(photo.path)),
          );
          request.files.add(multipartFile);
        }
      }
      
      final response = await request.send();
      final responseBody = await http.Response.fromStream(response);
      
      print('Update court response status: ${response.statusCode}');
      print('Update court response body: ${responseBody.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(responseBody.body);
        return data['court'] ?? data;
      } else {
        final error = json.decode(responseBody.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to update court');
      }
    } catch (e) {
      print('Error in updateCourt: $e');
      throw Exception(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DELETE COURT - Delete a court
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> deleteCourt({
    required String token,
    required String courtId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConstants.managerCourt(courtId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Delete court response status: ${response.statusCode}');
      print('Delete court response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to delete court');
      }
    } catch (e) {
      print('Error in deleteCourt: $e');
      throw Exception(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPER: Get file extension
  // ─────────────────────────────────────────────────────────────────────────
  static String _getFileExtension(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'jpeg';
      case 'png':
        return 'png';
      case 'gif':
        return 'gif';
      case 'webp':
        return 'webp';
      default:
        return 'jpeg';
    }
  }
}











/*port 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sporta/Core/Constants/api_constants.dart';

class CourtService {
  // ─────────────────────────────────────────────────────────────────────────
  // GET ALL COURTS - Get all courts for the logged-in manager's venues
  // ─────────────────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getCourts(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.managerCourts),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get courts response status: ${response.statusCode}');
      print('Get courts response body: ${response.body}');

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
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to get courts');
      }
    } catch (e) {
      print('Error in getCourts: $e');
      throw Exception(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GET SINGLE COURT - Get court by ID
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getCourt({
    required String token,
    required String courtId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.managerCourt(courtId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get court response status: ${response.statusCode}');
      print('Get court response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to get court');
      }
    } catch (e) {
      print('Error in getCourt: $e');
      throw Exception(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CREATE COURT - Create a new court for a venue
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> createCourt({
    required String token,
    required String name,
    String? description,
    required String sport,
    required double pricePerHour,
    required int capacity,
    List<String>? photos,
    List<String>? amenities,
    bool isActive = true,
    required int venueId,
  }) async {
    try {
      final body = {
        'name': name,
        'sport': sport,
        'pricePerHour': pricePerHour,
        'capacity': capacity,
        'isActive': isActive,
        'venue': venueId,
      };
      
      if (description != null && description.isNotEmpty) {
        body['description'] = description;
      }
      if (photos != null && photos.isNotEmpty) {
        body['photos'] = photos;
      }
      if (amenities != null && amenities.isNotEmpty) {
        body['amenities'] = amenities;
      }

      final response = await http.post(
        Uri.parse(ApiConstants.managerCourts),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      print('Create court response status: ${response.statusCode}');
      print('Create court response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['court'] ?? data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to create court');
      }
    } catch (e) {
      print('Error in createCourt: $e');
      throw Exception(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UPDATE COURT - Update an existing court
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> updateCourt({
    required String token,
    required String courtId,
    String? name,
    String? description,
    String? sport,
    double? pricePerHour,
    int? capacity,
    List<String>? photos,
    List<String>? amenities,
    bool? isActive,
  }) async {
    try {
      final body = <String, dynamic>{};
      
      if (name != null) body['name'] = name;
      if (description != null) body['description'] = description;
      if (sport != null) body['sport'] = sport;
      if (pricePerHour != null) body['pricePerHour'] = pricePerHour;
      if (capacity != null) body['capacity'] = capacity;
      if (photos != null) body['photos'] = photos;
      if (amenities != null) body['amenities'] = amenities;
      if (isActive != null) body['isActive'] = isActive;

      final response = await http.put(
        Uri.parse(ApiConstants.managerCourt(courtId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      print('Update court response status: ${response.statusCode}');
      print('Update court response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['court'] ?? data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to update court');
      }
    } catch (e) {
      print('Error in updateCourt: $e');
      throw Exception(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DELETE COURT - Delete a court
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> deleteCourt({
    required String token,
    required String courtId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConstants.managerCourt(courtId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Delete court response status: ${response.statusCode}');
      print('Delete court response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to delete court');
      }
    } catch (e) {
      print('Error in deleteCourt: $e');
      throw Exception(e.toString());
    }
  }
}*/