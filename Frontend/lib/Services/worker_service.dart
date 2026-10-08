// lib/Core/Services/worker_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sporta/Core/Constants/api_constants.dart';

class WorkerService {
  static String _getFullImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '${ApiConstants.mediaBaseUrl}$url';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // AUTHENTICATION
  // ─────────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.login),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final user = data['user'] as Map<String, dynamic>;
        if (user['user_role'] != 'worker') {
          throw Exception('This account is not a worker account');
        }
        return {'success': true, 'token': data['token'], 'user': user};
      } else {
        final error = json.decode(response.body) as Map<String, dynamic>;
        throw Exception(error['error']?['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<void> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse(ApiConstants.forgot),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );
    if (response.statusCode != 200) {
      final error = json.decode(response.body) as Map<String, dynamic>;
      throw Exception(error['error']?['message'] ?? 'Failed to send reset link');
    }
  }

  static Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConstants.reset),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'token': token, 'password': newPassword}),
    );
    if (response.statusCode != 200) {
      final error = json.decode(response.body) as Map<String, dynamic>;
      throw Exception(error['error']?['message'] ?? 'Failed to reset password');
    }
  }

  static Future<void> changePassword({
    required String token,
    required String oldPassword,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConstants.change),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'oldPassword': oldPassword, 'newPassword': newPassword}),
    );
    if (response.statusCode != 200) {
      final error = json.decode(response.body) as Map<String, dynamic>;
      throw Exception(error['error']?['message'] ?? 'Failed to change password');
    }
  }

  static Future<bool> validateToken(String token) async {
    try {
      final user = await getMe(token);
      return user['user_role'] == 'worker';
    } catch (e) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WORKER PROFILE
  // ─────────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getMe(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.workerMe),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final worker = Map<String, dynamic>.from(
          data['worker'] != null ? data['worker'] as Map : data,
        );
        worker['user_role'] = 'worker';
        return worker;
      } else {
        final error = json.decode(response.body) as Map<String, dynamic>;
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to get worker profile');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Update worker profile — sends nom, phone (and optionally username) to
  /// PATCH /workers/me/profile which writes directly to the worker content-type.
  static Future<Map<String, dynamic>> updateProfile({
    required String token,
    required String nom,
    required String phone,
    String? username,
  }) async {
    try {
      final body = <String, dynamic>{
        'nom': nom.trim(),
        'phone': phone.trim(),
        if (username != null && username.trim().isNotEmpty) 'username': username.trim(),
      };

      final response = await http.patch(
        Uri.parse(ApiConstants.workerUpdateProfile),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        final error = json.decode(response.body) as Map<String, dynamic>;
        throw Exception(
          error['error']?['message'] ?? error['message'] ?? 'Failed to update profile',
        );
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<String> uploadPhoto({
    required String token,
    required String filePath,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstants.uploadPhoto),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('photo', filePath));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody) as Map<String, dynamic>;
        return data['photoUrl'] ?? '';
      } else {
        final error = json.decode(responseBody) as Map<String, dynamic>;
        throw Exception(error['error']?['message'] ?? 'Failed to upload photo');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<Map<String, dynamic>> updateFirebase({
    required String token,
    required String firebaseUid,
    String? fcmToken,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse(ApiConstants.workerUpdateFirebase),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'firebaseUid': firebaseUid,
          if (fcmToken != null) 'fcmToken': fcmToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['data'] ?? data;
      } else {
        final error = json.decode(response.body) as Map<String, dynamic>;
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to update Firebase');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WORKER COURTS
  // ─────────────────────────────────────────────────────────────────────────

  static Future<List<dynamic>> getMyCourts(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.workerMyCourts),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final courts = data['courts'] as List<dynamic>? ?? [];

        return courts.map((courtItem) {
          final court = Map<String, dynamic>.from(courtItem as Map);

          String imageUrl = '';
          if (court['court_img_url'] != null && court['court_img_url'].toString().isNotEmpty) {
            imageUrl = _getFullImageUrl(court['court_img_url'].toString());
          } else if (court['court_img'] != null && court['court_img']['url'] != null) {
            imageUrl = _getFullImageUrl(court['court_img']['url'].toString());
          } else if (court['photos_urls'] is List && (court['photos_urls'] as List).isNotEmpty) {
            imageUrl = _getFullImageUrl((court['photos_urls'] as List)[0].toString());
          } else if (court['photos'] is List && (court['photos'] as List).isNotEmpty) {
            final first = (court['photos'] as List)[0];
            if (first is Map && first['url'] != null) {
              imageUrl = _getFullImageUrl(first['url'].toString());
            }
          }

          List<String> photosUrls = [];
          if (court['photos_urls'] is List) {
            photosUrls = (court['photos_urls'] as List).map((u) => _getFullImageUrl(u.toString())).toList();
          } else if (court['photos'] is List) {
            photosUrls = (court['photos'] as List)
                .where((p) => p is Map && p['url'] != null)
                .map((p) => _getFullImageUrl(p['url'].toString()))
                .toList();
          }

          return {...court, 'court_img_url': imageUrl, 'photos_urls': photosUrls};
        }).toList();
      } else {
        final error = json.decode(response.body) as Map<String, dynamic>;
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to get assigned courts');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

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

      if (response.statusCode == 200) {
        final court = Map<String, dynamic>.from(json.decode(response.body) as Map);

        String imageUrl = '';
        if (court['court_img_url'] != null && court['court_img_url'].toString().isNotEmpty) {
          imageUrl = _getFullImageUrl(court['court_img_url'].toString());
        } else if (court['court_img'] != null && court['court_img']['url'] != null) {
          imageUrl = _getFullImageUrl(court['court_img']['url'].toString());
        }

        List<String> photosUrls = [];
        if (court['photos_urls'] is List) {
          photosUrls = (court['photos_urls'] as List).map((u) => _getFullImageUrl(u.toString())).toList();
        } else if (court['photos'] is List) {
          photosUrls = (court['photos'] as List)
              .where((p) => p is Map && p['url'] != null)
              .map((p) => _getFullImageUrl(p['url'].toString()))
              .toList();
        }

        return {...court, 'court_img_url': imageUrl, 'photos_urls': photosUrls};
      } else {
        final error = json.decode(response.body) as Map<String, dynamic>;
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to get court details');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WORKER RESERVATIONS
  // ─────────────────────────────────────────────────────────────────────────

  static Future<List<dynamic>> getMyReservations(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.workerMyReservations),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return _transformReservations(data['reservations'] as List<dynamic>? ?? []);
      } else {
        final error = json.decode(response.body) as Map<String, dynamic>;
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to get reservations');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<List<dynamic>> getUpcomingReservations(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.workerUpcomingReservations),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return _transformReservations(data['reservations'] as List<dynamic>? ?? []);
      } else {
        final error = json.decode(response.body) as Map<String, dynamic>;
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to get upcoming reservations');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static List<dynamic> _transformReservations(List<dynamic> reservations) {
    return reservations.map((resItem) {
      final res = Map<String, dynamic>.from(resItem as Map);
      final court = Map<String, dynamic>.from(res['court'] as Map? ?? {});

      String courtImageUrl = '';
      if (court['court_img_url'] != null && court['court_img_url'].toString().isNotEmpty) {
        courtImageUrl = _getFullImageUrl(court['court_img_url'].toString());
      } else if (court['court_img'] != null && court['court_img']['url'] != null) {
        courtImageUrl = _getFullImageUrl(court['court_img']['url'].toString());
      } else if (court['photos_urls'] is List && (court['photos_urls'] as List).isNotEmpty) {
        courtImageUrl = _getFullImageUrl((court['photos_urls'] as List)[0].toString());
      } else if (court['photos'] is List && (court['photos'] as List).isNotEmpty) {
        final first = (court['photos'] as List)[0];
        if (first is Map && first['url'] != null) {
          courtImageUrl = _getFullImageUrl(first['url'].toString());
        }
      }

      return {...res, 'court': {...court, 'court_img_url': courtImageUrl}};
    }).toList();
  }

  static Future<Map<String, dynamic>> getReservation({
    required String token,
    required String reservationId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.reservation(reservationId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final reservation = Map<String, dynamic>.from(json.decode(response.body) as Map);
        final court = Map<String, dynamic>.from(reservation['court'] as Map? ?? {});

        String courtImageUrl = '';
        if (court['court_img_url'] != null && court['court_img_url'].toString().isNotEmpty) {
          courtImageUrl = _getFullImageUrl(court['court_img_url'].toString());
        } else if (court['court_img'] != null && court['court_img']['url'] != null) {
          courtImageUrl = _getFullImageUrl(court['court_img']['url'].toString());
        }

        return {...reservation, 'court': {...court, 'court_img_url': courtImageUrl}};
      } else {
        final error = json.decode(response.body) as Map<String, dynamic>;
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to get reservation');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<Map<String, dynamic>> confirmReservation({
    required String token,
    required String reservationId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConstants.workerConfirmReservation(reservationId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['reservation'] ?? data;
      } else {
        final error = json.decode(response.body) as Map<String, dynamic>;
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to confirm reservation');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<Map<String, dynamic>> cancelReservation({
    required String token,
    required String reservationId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConstants.workerCancelReservation(reservationId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['reservation'] ?? data;
      } else {
        final error = json.decode(response.body) as Map<String, dynamic>;
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to cancel reservation');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WORKER TIME SLOTS
  // ─────────────────────────────────────────────────────────────────────────

  static Future<List<dynamic>> getMyTimeSlots({
    required String token,
    String? date,
    String? dayPlanId,
  }) async {
    try {
      final queryParams = <String, String>{
        if (date != null && date.isNotEmpty) 'date': date,
        if (dayPlanId != null && dayPlanId.isNotEmpty) 'dayPlanId': dayPlanId,
      };

      final uri = Uri.parse(ApiConstants.workerMyTimeSlots).replace(
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['timeSlots'] as List<dynamic>? ?? [];
      } else {
        final error = json.decode(response.body) as Map<String, dynamic>;
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to get time slots');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<Map<String, dynamic>> updateTimeSlot({
    required String token,
    required String timeSlotId,
    required bool isActive,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConstants.workerTimeSlot(timeSlotId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'isActive': isActive}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['timeSlot'] ?? data;
      } else {
        final error = json.decode(response.body) as Map<String, dynamic>;
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to update time slot');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}














/*// lib/Core/Services/worker_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sporta/Core/Constants/api_constants.dart';

class WorkerService {
  // ─────────────────────────────────────────────────────────────────────────
  // HELPER - Get full image URL
  // ─────────────────────────────────────────────────────────────────────────
  static String _getFullImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '${ApiConstants.mediaBaseUrl}$url';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // AUTHENTICATION (Worker only)
  // ─────────────────────────────────────────────────────────────────────────

  // LOGIN - Authenticate worker user
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.login),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      print('Worker login response status: ${response.statusCode}');
      print('Worker login response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        // Verify the user is a worker
        final Map<String, dynamic> user = data['user'];
        if (user['user_role'] != 'worker') {
          throw Exception('This account is not a worker account');
        }
        
        return {
          'success': true,
          'token': data['token'],
          'user': user,
        };
      } else {
        final Map<String, dynamic> error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? 'Login failed');
      }
    } catch (e) {
      print('Worker login error: $e');
      throw Exception(e.toString());
    }
  }

  // FORGOT PASSWORD - Send reset link to email
  static Future<void> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.forgot),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
        }),
      );

      print('Worker forgot password response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        final Map<String, dynamic> error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? 'Failed to send reset link');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // RESET PASSWORD - Reset password with token
  static Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.reset),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': token,
          'password': newPassword,
        }),
      );

      if (response.statusCode != 200) {
        final Map<String, dynamic> error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? 'Failed to reset password');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // CHANGE PASSWORD - Change password while logged in
  static Future<void> changePassword({
    required String token,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.change),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode != 200) {
        final Map<String, dynamic> error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? 'Failed to change password');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // VALIDATE TOKEN - Check if token is valid and user is worker
  static Future<bool> validateToken(String token) async {
    try {
      final user = await getMe(token);
      return user['user_role'] == 'worker';
    } catch (e) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WORKER PROFILE
  // ─────────────────────────────────────────────────────────────────────────

  // GET WORKER PROFILE - Get authenticated worker's profile
  static Future<Map<String, dynamic>> getMe(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.workerMe),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get worker me response status: ${response.statusCode}');
      print('Get worker me response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final Map<String, dynamic> worker = data['worker'] != null 
            ? Map<String, dynamic>.from(data['worker'] as Map)
            : Map<String, dynamic>.from(data);
        
        // Add user_role to the response for validation
        worker['user_role'] = 'worker';
        
        return worker;
      } else {
        final Map<String, dynamic> error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to get worker profile');
      }
    } catch (e) {
      print('Error in getMe: $e');
      throw Exception(e.toString());
    }
  }

  // UPDATE WORKER PROFILE - Update worker's own profile
  static Future<Map<String, dynamic>> updateProfile({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConstants.update),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      print('Update worker profile response status: ${response.statusCode}');
      print('Update worker profile response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final Map<String, dynamic> error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      print('Error in updateProfile: $e');
      throw Exception(e.toString());
    }
  }

  // UPLOAD PHOTO - Upload worker profile photo
  static Future<String> uploadPhoto({
    required String token,
    required String filePath,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstants.uploadPhoto),
      );
      
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('photo', filePath));
      
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      print('Upload photo response status: ${response.statusCode}');
      print('Upload photo response body: $responseBody');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(responseBody);
        return data['photoUrl'] ?? '';
      } else {
        final Map<String, dynamic> error = json.decode(responseBody);
        throw Exception(error['error']?['message'] ?? 'Failed to upload photo');
      }
    } catch (e) {
      print('Error in uploadPhoto: $e');
      throw Exception(e.toString());
    }
  }

  // UPDATE FIREBASE - Update Firebase UID and FCM token for worker
  static Future<Map<String, dynamic>> updateFirebase({
    required String token,
    required String firebaseUid,
    String? fcmToken,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse(ApiConstants.workerUpdateFirebase),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'firebaseUid': firebaseUid,
          if (fcmToken != null) 'fcmToken': fcmToken,
        }),
      );

      print('Update worker firebase response status: ${response.statusCode}');
      print('Update worker firebase response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['data'] ?? data;
      } else {
        final Map<String, dynamic> error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to update Firebase');
      }
    } catch (e) {
      print('Error in updateFirebase: $e');
      throw Exception(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WORKER COURTS
  // ─────────────────────────────────────────────────────────────────────────

  // GET MY COURTS - Get all courts assigned to this worker (with image URLs)
  static Future<List<dynamic>> getMyCourts(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.workerMyCourts),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get my courts response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> courts = data['courts'] ?? [];
        
        // Transform each court to add full image URLs
        final transformedCourts = courts.map((courtItem) {
          final Map<String, dynamic> court = Map<String, dynamic>.from(courtItem as Map);
          
          // Get image URL from various possible sources
          String imageUrl = '';
          
          if (court['court_img_url'] != null && court['court_img_url'].toString().isNotEmpty) {
            imageUrl = _getFullImageUrl(court['court_img_url'].toString());
          } else if (court['court_img'] != null && court['court_img']['url'] != null) {
            imageUrl = _getFullImageUrl(court['court_img']['url'].toString());
          } else if (court['photos_urls'] != null && court['photos_urls'] is List && court['photos_urls'].isNotEmpty) {
            imageUrl = _getFullImageUrl(court['photos_urls'][0].toString());
          } else if (court['photos'] != null && court['photos'] is List && court['photos'].isNotEmpty) {
            final firstPhoto = court['photos'][0];
            if (firstPhoto is Map && firstPhoto['url'] != null) {
              imageUrl = _getFullImageUrl(firstPhoto['url'].toString());
            }
          }
          
          // Transform photos_urls
          List<String> photosUrls = [];
          if (court['photos_urls'] != null && court['photos_urls'] is List) {
            photosUrls = (court['photos_urls'] as List)
                .map((url) => _getFullImageUrl(url.toString()))
                .toList();
          } else if (court['photos'] != null && court['photos'] is List) {
            photosUrls = (court['photos'] as List)
                .where((p) => p is Map && p['url'] != null)
                .map((p) => _getFullImageUrl(p['url'].toString()))
                .toList();
          }
          
          final Map<String, dynamic> result = Map<String, dynamic>.from(court);
          result['court_img_url'] = imageUrl;
          result['photos_urls'] = photosUrls;
          
          return result;
        }).toList();
        
        return transformedCourts;
      } else {
        final Map<String, dynamic> error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to get assigned courts');
      }
    } catch (e) {
      print('Error in getMyCourts: $e');
      throw Exception(e.toString());
    }
  }

  // GET SINGLE COURT - Get details of a specific court (must be assigned)
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

      if (response.statusCode == 200) {
        final Map<String, dynamic> court = json.decode(response.body);
        
        // Transform image URLs
        String imageUrl = '';
        if (court['court_img_url'] != null && court['court_img_url'].toString().isNotEmpty) {
          imageUrl = _getFullImageUrl(court['court_img_url'].toString());
        } else if (court['court_img'] != null && court['court_img']['url'] != null) {
          imageUrl = _getFullImageUrl(court['court_img']['url'].toString());
        }
        
        List<String> photosUrls = [];
        if (court['photos_urls'] != null && court['photos_urls'] is List) {
          photosUrls = (court['photos_urls'] as List)
              .map((url) => _getFullImageUrl(url.toString()))
              .toList();
        } else if (court['photos'] != null && court['photos'] is List) {
          photosUrls = (court['photos'] as List)
              .where((p) => p is Map && p['url'] != null)
              .map((p) => _getFullImageUrl(p['url'].toString()))
              .toList();
        }
        
        final Map<String, dynamic> result = Map<String, dynamic>.from(court);
        result['court_img_url'] = imageUrl;
        result['photos_urls'] = photosUrls;
        
        return result;
      } else {
        final Map<String, dynamic> error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to get court details');
      }
    } catch (e) {
      print('Error in getCourt: $e');
      throw Exception(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WORKER RESERVATIONS
  // ─────────────────────────────────────────────────────────────────────────

  // GET MY RESERVATIONS - Get all reservations for worker's assigned courts
  static Future<List<dynamic>> getMyReservations(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.workerMyReservations),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get my reservations response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> reservations = data['reservations'] ?? [];
        
        // Transform each reservation to add court image URLs
        final transformedReservations = reservations.map((resItem) {
          final Map<String, dynamic> res = Map<String, dynamic>.from(resItem as Map);
          final Map<String, dynamic> court = res.containsKey('court') 
              ? Map<String, dynamic>.from(res['court'] as Map)
              : {};
          
          // Get court image URL
          String courtImageUrl = '';
          if (court['court_img_url'] != null && court['court_img_url'].toString().isNotEmpty) {
            courtImageUrl = _getFullImageUrl(court['court_img_url'].toString());
          } else if (court['court_img'] != null && court['court_img']['url'] != null) {
            courtImageUrl = _getFullImageUrl(court['court_img']['url'].toString());
          } else if (court['photos_urls'] != null && court['photos_urls'] is List && court['photos_urls'].isNotEmpty) {
            courtImageUrl = _getFullImageUrl(court['photos_urls'][0].toString());
          } else if (court['photos'] != null && court['photos'] is List && court['photos'].isNotEmpty) {
            final firstPhoto = court['photos'][0];
            if (firstPhoto is Map && firstPhoto['url'] != null) {
              courtImageUrl = _getFullImageUrl(firstPhoto['url'].toString());
            }
          }
          
          final Map<String, dynamic> result = Map<String, dynamic>.from(res);
          final Map<String, dynamic> transformedCourt = Map<String, dynamic>.from(court);
          transformedCourt['court_img_url'] = courtImageUrl;
          result['court'] = transformedCourt;
          
          return result;
        }).toList();
        
        return transformedReservations;
      } else {
        final Map<String, dynamic> error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to get reservations');
      }
    } catch (e) {
      print('Error in getMyReservations: $e');
      throw Exception(e.toString());
    }
  }

  // GET UPCOMING RESERVATIONS - Get upcoming reservations (today and future)
  static Future<List<dynamic>> getUpcomingReservations(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.workerUpcomingReservations),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get upcoming reservations response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> reservations = data['reservations'] ?? [];
        
        // Transform each reservation to add court image URLs
        final transformedReservations = reservations.map((resItem) {
          final Map<String, dynamic> res = Map<String, dynamic>.from(resItem as Map);
          final Map<String, dynamic> court = res.containsKey('court') 
              ? Map<String, dynamic>.from(res['court'] as Map)
              : {};
          
          // Get court image URL
          String courtImageUrl = '';
          if (court['court_img_url'] != null && court['court_img_url'].toString().isNotEmpty) {
            courtImageUrl = _getFullImageUrl(court['court_img_url'].toString());
          } else if (court['court_img'] != null && court['court_img']['url'] != null) {
            courtImageUrl = _getFullImageUrl(court['court_img']['url'].toString());
          } else if (court['photos_urls'] != null && court['photos_urls'] is List && court['photos_urls'].isNotEmpty) {
            courtImageUrl = _getFullImageUrl(court['photos_urls'][0].toString());
          } else if (court['photos'] != null && court['photos'] is List && court['photos'].isNotEmpty) {
            final firstPhoto = court['photos'][0];
            if (firstPhoto is Map && firstPhoto['url'] != null) {
              courtImageUrl = _getFullImageUrl(firstPhoto['url'].toString());
            }
          }
          
          final Map<String, dynamic> result = Map<String, dynamic>.from(res);
          final Map<String, dynamic> transformedCourt = Map<String, dynamic>.from(court);
          transformedCourt['court_img_url'] = courtImageUrl;
          result['court'] = transformedCourt;
          
          return result;
        }).toList();
        
        return transformedReservations;
      } else {
        final Map<String, dynamic> error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to get upcoming reservations');
      }
    } catch (e) {
      print('Error in getUpcomingReservations: $e');
      throw Exception(e.toString());
    }
  }

  // GET RESERVATION BY ID - Get a specific reservation
  static Future<Map<String, dynamic>> getReservation({
    required String token,
    required String reservationId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.reservation(reservationId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get reservation response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> reservation = json.decode(response.body);
        final Map<String, dynamic> court = reservation.containsKey('court') 
            ? Map<String, dynamic>.from(reservation['court'] as Map)
            : {};
        
        // Transform court image URL
        String courtImageUrl = '';
        if (court['court_img_url'] != null && court['court_img_url'].toString().isNotEmpty) {
          courtImageUrl = _getFullImageUrl(court['court_img_url'].toString());
        } else if (court['court_img'] != null && court['court_img']['url'] != null) {
          courtImageUrl = _getFullImageUrl(court['court_img']['url'].toString());
        }
        
        final Map<String, dynamic> result = Map<String, dynamic>.from(reservation);
        final Map<String, dynamic> transformedCourt = Map<String, dynamic>.from(court);
        transformedCourt['court_img_url'] = courtImageUrl;
        result['court'] = transformedCourt;
        
        return result;
      } else {
        final Map<String, dynamic> error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to get reservation');
      }
    } catch (e) {
      print('Error in getReservation: $e');
      throw Exception(e.toString());
    }
  }

  // CONFIRM RESERVATION - Worker confirms a reservation
  static Future<Map<String, dynamic>> confirmReservation({
    required String token,
    required String reservationId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConstants.workerConfirmReservation(reservationId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Confirm reservation response status: ${response.statusCode}');
      print('Confirm reservation response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['reservation'] ?? data;
      } else {
        final Map<String, dynamic> error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to confirm reservation');
      }
    } catch (e) {
      print('Error in confirmReservation: $e');
      throw Exception(e.toString());
    }
  }

  // CANCEL RESERVATION - Worker cancels a reservation
  static Future<Map<String, dynamic>> cancelReservation({
    required String token,
    required String reservationId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConstants.workerCancelReservation(reservationId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Cancel reservation response status: ${response.statusCode}');
      print('Cancel reservation response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['reservation'] ?? data;
      } else {
        final Map<String, dynamic> error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to cancel reservation');
      }
    } catch (e) {
      print('Error in cancelReservation: $e');
      throw Exception(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WORKER TIME SLOTS
  // ─────────────────────────────────────────────────────────────────────────

  // GET MY TIME SLOTS - Get time slots for worker's assigned courts
  static Future<List<dynamic>> getMyTimeSlots({
    required String token,
    String? date,
    String? dayPlanId,
  }) async {
    try {
      String url = ApiConstants.workerMyTimeSlots;
      final queryParams = <String, String>{};
      
      if (date != null && date.isNotEmpty) {
        queryParams['date'] = date;
      }
      if (dayPlanId != null && dayPlanId.isNotEmpty) {
        queryParams['dayPlanId'] = dayPlanId;
      }
      
      if (queryParams.isNotEmpty) {
        final uri = Uri.parse(url).replace(queryParameters: queryParams);
        url = uri.toString();
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get my time slots response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['timeSlots'] ?? [];
      } else {
        final Map<String, dynamic> error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to get time slots');
      }
    } catch (e) {
      print('Error in getMyTimeSlots: $e');
      throw Exception(e.toString());
    }
  }

  // UPDATE TIME SLOT - Worker updates a time slot (toggle isActive)
  static Future<Map<String, dynamic>> updateTimeSlot({
    required String token,
    required String timeSlotId,
    required bool isActive,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConstants.workerTimeSlot(timeSlotId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'isActive': isActive,
        }),
      );

      print('Update time slot response status: ${response.statusCode}');
      print('Update time slot response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['timeSlot'] ?? data;
      } else {
        final Map<String, dynamic> error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to update time slot');
      }
    } catch (e) {
      print('Error in updateTimeSlot: $e');
      throw Exception(e.toString());
    }
  }
}
*/



//******************************************** */







/*// lib/Core/Services/worker_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sporta/Core/Constants/api_constants.dart';

class WorkerService {
  // ─────────────────────────────────────────────────────────────────────────
  // AUTHENTICATION (Worker only)
  // ─────────────────────────────────────────────────────────────────────────

  // LOGIN - Authenticate worker user
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.login),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      print('Worker login response status: ${response.statusCode}');
      print('Worker login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Verify the user is a worker
        final user = data['user'];
        if (user['user_role'] != 'worker') {
          throw Exception('This account is not a worker account');
        }
        
        return {
          'success': true,
          'token': data['token'],
          'user': user,
        };
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? 'Login failed');
      }
    } catch (e) {
      print('Worker login error: $e');
      throw Exception(e.toString());
    }
  }

  // FORGOT PASSWORD - Send reset link to email
  static Future<void> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.forgot),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
        }),
      );

      print('Worker forgot password response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? 'Failed to send reset link');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // RESET PASSWORD - Reset password with token
  static Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.reset),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': token,
          'password': newPassword,
        }),
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? 'Failed to reset password');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // CHANGE PASSWORD - Change password while logged in
  static Future<void> changePassword({
    required String token,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.change),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? 'Failed to change password');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // VALIDATE TOKEN - Check if token is valid and user is worker
  static Future<bool> validateToken(String token) async {
    try {
      final user = await getMe(token);
      return user['user_role'] == 'worker';
    } catch (e) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WORKER PROFILE
  // ─────────────────────────────────────────────────────────────────────────

  // GET WORKER PROFILE - Get authenticated worker's profile
  static Future<Map<String, dynamic>> getMe(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.workerMe),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get worker me response status: ${response.statusCode}');
      print('Get worker me response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final worker = data['worker'] ?? data;
        
        // Add user_role to the response for validation
        worker['user_role'] = 'worker';
        
        return worker;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to get worker profile');
      }
    } catch (e) {
      print('Error in getMe: $e');
      throw Exception(e.toString());
    }
  }

  // UPDATE WORKER PROFILE - Update worker's own profile
  static Future<Map<String, dynamic>> updateProfile({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConstants.update),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      print('Update worker profile response status: ${response.statusCode}');
      print('Update worker profile response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      print('Error in updateProfile: $e');
      throw Exception(e.toString());
    }
  }

  // UPLOAD PHOTO - Upload worker profile photo
  static Future<String> uploadPhoto({
    required String token,
    required String filePath,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstants.uploadPhoto),
      );
      
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('photo', filePath));
      
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      print('Upload photo response status: ${response.statusCode}');
      print('Upload photo response body: $responseBody');
      
      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        return data['photoUrl'] ?? '';
      } else {
        final error = json.decode(responseBody);
        throw Exception(error['error']?['message'] ?? 'Failed to upload photo');
      }
    } catch (e) {
      print('Error in uploadPhoto: $e');
      throw Exception(e.toString());
    }
  }

  // UPDATE FIREBASE - Update Firebase UID and FCM token for worker
  static Future<Map<String, dynamic>> updateFirebase({
    required String token,
    required String firebaseUid,
    String? fcmToken,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse(ApiConstants.workerUpdateFirebase),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'firebaseUid': firebaseUid,
          if (fcmToken != null) 'fcmToken': fcmToken,
        }),
      );

      print('Update worker firebase response status: ${response.statusCode}');
      print('Update worker firebase response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to update Firebase');
      }
    } catch (e) {
      print('Error in updateFirebase: $e');
      throw Exception(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WORKER COURTS
  // ─────────────────────────────────────────────────────────────────────────

  // GET MY COURTS - Get all courts assigned to this worker
  static Future<List<dynamic>> getMyCourts(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.workerMyCourts),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get my courts response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['courts'] ?? [];
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to get assigned courts');
      }
    } catch (e) {
      print('Error in getMyCourts: $e');
      throw Exception(e.toString());
    }
  }

  // GET SINGLE COURT - Get details of a specific court (must be assigned)
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

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to get court details');
      }
    } catch (e) {
      print('Error in getCourt: $e');
      throw Exception(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WORKER RESERVATIONS
  // ─────────────────────────────────────────────────────────────────────────

  // GET MY RESERVATIONS - Get all reservations for worker's assigned courts
  static Future<List<dynamic>> getMyReservations(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.workerMyReservations),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get my reservations response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['reservations'] ?? [];
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to get reservations');
      }
    } catch (e) {
      print('Error in getMyReservations: $e');
      throw Exception(e.toString());
    }
  }

  // GET UPCOMING RESERVATIONS - Get upcoming reservations (today and future)
  static Future<List<dynamic>> getUpcomingReservations(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.workerUpcomingReservations),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get upcoming reservations response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['reservations'] ?? [];
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to get upcoming reservations');
      }
    } catch (e) {
      print('Error in getUpcomingReservations: $e');
      throw Exception(e.toString());
    }
  }

  // GET RESERVATION BY ID - Get a specific reservation
  static Future<Map<String, dynamic>> getReservation({
    required String token,
    required String reservationId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.reservation(reservationId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get reservation response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to get reservation');
      }
    } catch (e) {
      print('Error in getReservation: $e');
      throw Exception(e.toString());
    }
  }

  // CONFIRM RESERVATION - Worker confirms a reservation
  static Future<Map<String, dynamic>> confirmReservation({
    required String token,
    required String reservationId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConstants.workerConfirmReservation(reservationId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Confirm reservation response status: ${response.statusCode}');
      print('Confirm reservation response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['reservation'] ?? data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to confirm reservation');
      }
    } catch (e) {
      print('Error in confirmReservation: $e');
      throw Exception(e.toString());
    }
  }

  // CANCEL RESERVATION - Worker cancels a reservation
  static Future<Map<String, dynamic>> cancelReservation({
    required String token,
    required String reservationId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConstants.workerCancelReservation(reservationId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Cancel reservation response status: ${response.statusCode}');
      print('Cancel reservation response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['reservation'] ?? data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to cancel reservation');
      }
    } catch (e) {
      print('Error in cancelReservation: $e');
      throw Exception(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WORKER TIME SLOTS
  // ─────────────────────────────────────────────────────────────────────────

  // GET MY TIME SLOTS - Get time slots for worker's assigned courts
  static Future<List<dynamic>> getMyTimeSlots({
    required String token,
    String? date,
    String? dayPlanId,
  }) async {
    try {
      String url = ApiConstants.workerMyTimeSlots;
      final queryParams = <String, String>{};
      
      if (date != null && date.isNotEmpty) {
        queryParams['date'] = date;
      }
      if (dayPlanId != null && dayPlanId.isNotEmpty) {
        queryParams['dayPlanId'] = dayPlanId;
      }
      
      if (queryParams.isNotEmpty) {
        final uri = Uri.parse(url).replace(queryParameters: queryParams);
        url = uri.toString();
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get my time slots response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['timeSlots'] ?? [];
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to get time slots');
      }
    } catch (e) {
      print('Error in getMyTimeSlots: $e');
      throw Exception(e.toString());
    }
  }

  // UPDATE TIME SLOT - Worker updates a time slot (toggle isActive)
  static Future<Map<String, dynamic>> updateTimeSlot({
    required String token,
    required String timeSlotId,
    required bool isActive,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConstants.workerTimeSlot(timeSlotId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'isActive': isActive,
        }),
      );

      print('Update time slot response status: ${response.statusCode}');
      print('Update time slot response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['timeSlot'] ?? data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to update time slot');
      }
    } catch (e) {
      print('Error in updateTimeSlot: $e');
      throw Exception(e.toString());
    }
  }

}*/