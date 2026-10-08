// lib/Services/player_manager_auth_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // add to pubspec: http_parser: ^4.0.0

class PlayerManagerAuthService {
  static String get _baseUrl {
    if (Platform.isAndroid) return 'http://10.0.2.2:1337/api';
    if (Platform.isIOS)     return 'http://localhost:1337/api';
    return 'http://localhost:1337/api';
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'token': data['token'], 'user': data['user']};
      }
      final error = json.decode(response.body);
      throw Exception(error['error']?['message'] ?? 'Login failed');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'email': email, 'password': password, 'phone': phone}),
      );
      if (response.statusCode == 200) return json.decode(response.body);
      final error = json.decode(response.body);
      throw Exception(error['error']?['message'] ?? 'Registration failed');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<void> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/forgot'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );
      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? 'Failed to send reset link');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<void> resetPassword({required String token, required String newPassword}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/reset'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': token, 'password': newPassword}),
      );
      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? 'Failed to reset password');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<void> changePassword({
    required String token,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/change'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: json.encode({'oldPassword': oldPassword, 'newPassword': newPassword}),
      );
      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? 'Failed to change password');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// GET /auth/me
  /// Response now includes: { user, profile, photoUrl }
  /// photoUrl is a convenience string — absolute URL or null
  static Future<Map<String, dynamic>> getMe(String token) async {
  try {
    final response = await http.get(
      Uri.parse('$_baseUrl/auth/me'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      // Make photoUrl absolute if it exists
      if (data['photoUrl'] != null && data['photoUrl'].toString().isNotEmpty) {
        String url = data['photoUrl'].toString();
        if (!url.startsWith('http')) {
          if (Platform.isAndroid) {
            url = 'http://10.0.2.2:1337$url';
          } else {
            url = 'http://localhost:1337$url';
          }
          data['photoUrl'] = url;
        }
      }
      
      return data;
    }
    final error = json.decode(response.body);
    throw Exception(error['error']?['message'] ?? 'Failed to get user info');
  } catch (e) {
    throw Exception(e.toString());
  }
}

  static Future<Map<String, dynamic>> updateProfile({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/auth/update'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: json.encode(data),
      );
      if (response.statusCode == 200) return json.decode(response.body);
      final error = json.decode(response.body);
      throw Exception(error['error']?['message'] ?? 'Failed to update profile');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<bool> validateToken(String token) async {
    try {
      await getMe(token);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> updateFirebaseUid({
    required String token,
    required String firebaseUid,
    String? fcmToken,
  }) async {
    try {
      final body = <String, dynamic>{'firebaseUid': firebaseUid};
      if (fcmToken != null && fcmToken.isNotEmpty) body['fcmToken'] = fcmToken;

      final response = await http.put(
        Uri.parse('$_baseUrl/auth/update-firebase-uid'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        print('✅ Firebase identity updated: uid=$firebaseUid fcm=${fcmToken ?? 'unchanged'}');
      } else {
        final error = json.decode(response.body);
        print('⚠️ Failed: ${error['error']?['message']}');
      }
    } catch (e) {
      print('❌ updateFirebaseUid error: $e');
    }
  }

  // ── Photo upload ──────────────────────────────────────────────────────────

  /// Upload a profile photo.
  ///
  /// [imageFile] — the File picked from the gallery or camera.
  ///
  /// Sends a multipart/form-data POST to POST /auth/upload-photo.
  /// The backend uploads to Strapi media library, links the file to the
  /// player or manager profile, and returns { photoUrl, photoId }.
  ///
  /// Returns the absolute photo URL string on success.
  // ── Update profile photo ─────────────────────────────────────────────────
static Future<String> uploadProfilePhoto({
  required String token,
  required File imageFile,
}) async {
  try {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/auth/upload-photo'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      await http.MultipartFile.fromPath(
        'photo',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      String url = data['photoUrl']?.toString() ?? '';
      
      // Make URL absolute if it's relative
      if (url.isNotEmpty && !url.startsWith('http')) {
        if (Platform.isAndroid) {
          url = 'http://10.0.2.2:1337$url';
        } else {
          url = 'http://localhost:1337$url';
        }
      }
      
      print('✅ Profile photo uploaded: $url');
      return url;
    }
    
    final error = json.decode(response.body);
    throw Exception(error['error']?['message'] ?? 'Photo upload failed (${response.statusCode})');
  } catch (e) {
    throw Exception('uploadProfilePhoto: $e');
  }
}
  /// Helper — extract photoUrl from getMe response safely.
  /// Usage:  final url = PlayerManagerAuthService.photoUrlFrom(meResponse);
  static String? photoUrlFrom(Map<String, dynamic> meResponse) {
    // Backend returns photoUrl at the top level
    final topLevel = meResponse['photoUrl']?.toString();
    if (topLevel != null && topLevel.isNotEmpty) return topLevel;

    // Fallback: dig into profile.photo.url
    final profile = meResponse['profile'] as Map<String, dynamic>?;
    final photo   = profile?['photo'] as Map<String, dynamic>?;
    final url     = photo?['url']?.toString();
    if (url == null || url.isEmpty) return null;

    // Make absolute if relative
    if (url.startsWith('http')) return url;
    if (Platform.isAndroid) return 'http://10.0.2.2:1337$url';
    return 'http://localhost:1337$url';
  }

  static String _mimeType(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'png':  return 'image/png';
      case 'webp': return 'image/webp';
      case 'gif':  return 'image/gif';
      default:     return 'image/jpeg';
    }
  }
}