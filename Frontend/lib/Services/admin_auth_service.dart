// lib/Core/Services/admin_auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sporta/Core/Constants/api_constants.dart';

class AdminAuthService {
  static Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  static Map<String, dynamic>? _decodeError(http.Response r) {
    try { return json.decode(r.body) as Map<String, dynamic>; } catch (_) { return null; }
  }

  static String _msg(http.Response r, String fallback) {
    final e = _decodeError(r);
    return e?['error']?['message']?.toString()
        ?? e?['message']?.toString()
        ?? fallback;
  }

  // ── AUTH ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final r = await http.post(Uri.parse(ApiConstants.login),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}));
    if (r.statusCode == 200) {
      final d = json.decode(r.body) as Map<String, dynamic>;
      return {'success': true, 'token': d['token'], 'user': d['user']};
    }
    throw Exception(_msg(r, 'Login failed'));
  }

  // ── FORGOT PASSWORD ───────────────────────────────────────────────────────

  /// Request a password reset email
  /// Sends a reset link to the provided email address
  static Future<void> forgotPassword({required String email}) async {
    final r = await http.post(
      Uri.parse(ApiConstants.forgot),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );
    if (r.statusCode != 200) {
      throw Exception(_msg(r, 'Failed to send reset link'));
    }
  }

  // ── RESET PASSWORD ────────────────────────────────────────────────────────

  /// Reset password using the token received by email
  static Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final r = await http.post(
      Uri.parse(ApiConstants.reset),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'token': token, 'password': newPassword}),
    );
    if (r.statusCode != 200) {
      throw Exception(_msg(r, 'Failed to reset password'));
    }
  }

  // ── CHANGE PASSWORD (while logged in) ─────────────────────────────────────

  /// Change password for authenticated user
  static Future<void> changePassword({
    required String token,
    required String oldPassword,
    required String newPassword,
  }) async {
    final r = await http.post(
      Uri.parse(ApiConstants.change),
      headers: _headers(token),
      body: json.encode({'oldPassword': oldPassword, 'newPassword': newPassword}),
    );
    if (r.statusCode != 200) {
      throw Exception(_msg(r, 'Failed to change password'));
    }
  }

  static Future<bool> validateToken(String token) async {
    try { await getMe(token); return true; } catch (_) { return false; }
  }

  static Future<Map<String, dynamic>> getMe(String token) async {
    final r = await http.get(Uri.parse(ApiConstants.me), headers: _headers(token));
    if (r.statusCode == 200) return json.decode(r.body) as Map<String, dynamic>;
    throw Exception(_msg(r, 'Failed to get user info'));
  }

  // ── ADMIN PROFILE ─────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getAdminProfile(String token) async {
    final r = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/profile'),
      headers: _headers(token));
    if (r.statusCode == 200) return json.decode(r.body) as Map<String, dynamic>;
    throw Exception(_msg(r, 'Failed to get admin profile'));
  }

  static Future<Map<String, dynamic>> updateAdminProfile({
    required String token,
    String? username,
    String? email,
    String? password,
  }) async {
    final body = <String, dynamic>{};
    if (username != null && username.trim().isNotEmpty) body['username'] = username.trim();
    if (email    != null && email.trim().isNotEmpty)    body['email']    = email.trim();
    if (password != null && password.trim().isNotEmpty) body['password'] = password.trim();

    final r = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/admin/profile'),
      headers: _headers(token),
      body: json.encode(body));
    if (r.statusCode == 200) return json.decode(r.body) as Map<String, dynamic>;
    throw Exception(_msg(r, 'Failed to update profile'));
  }

  // ── PLATFORM STATS ────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getPlatformStats(String token) async {
    final r = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/stats'),
      headers: _headers(token));
    if (r.statusCode == 200) return json.decode(r.body) as Map<String, dynamic>;
    throw Exception(_msg(r, 'Failed to get stats'));
  }

  // ── TOGGLE USER STATUS (block / unblock) ──────────────────────────────────

  static Future<Map<String, dynamic>> toggleUserStatus({
    required String token,
    required String userId,
  }) async {
    final r = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/admin/users/$userId/toggle-status'),
      headers: _headers(token));
    if (r.statusCode == 200) return json.decode(r.body) as Map<String, dynamic>;
    throw Exception(_msg(r, 'Failed to toggle status'));
  }

  // ── MANAGERS ─────────────────────────────────────────────────────────────

  static Future<List<dynamic>> getManagers(String token) async {
    final r = await http.get(Uri.parse(ApiConstants.adminManagers), headers: _headers(token));
    if (r.statusCode == 200) {
      final d = json.decode(r.body);
      if (d is List) return d;
      if (d is Map) return (d['data'] ?? d['users'] ?? []) as List;
      return [];
    }
    throw Exception(_msg(r, 'Failed to get managers'));
  }

  static Future<Map<String, dynamic>> createManager({
    required String adminToken,
    required String username,
    required String email,
    required String password,
    required String phone,
  }) async {
    final r = await http.post(
      Uri.parse(ApiConstants.adminManagers),
      headers: _headers(adminToken),
      body: json.encode({'username': username, 'email': email, 'password': password, 'phone': phone}));
    if (r.statusCode == 200) {
      final d = json.decode(r.body) as Map<String, dynamic>;
      return d['user'] ?? d;
    }
    throw Exception(_msg(r, 'Failed to create manager'));
  }

  static Future<Map<String, dynamic>> updateManager({
    required String adminToken,
    required String managerId,
    required Map<String, dynamic> data,
  }) async {
    final r = await http.put(
      Uri.parse('${ApiConstants.adminManagers}/$managerId'),
      headers: _headers(adminToken),
      body: json.encode(data));
    if (r.statusCode == 200) {
      final d = json.decode(r.body) as Map<String, dynamic>;
      return d['result'] ?? d;
    }
    throw Exception(_msg(r, 'Failed to update manager'));
  }

  static Future<void> deleteManager({
    required String adminToken,
    required String managerId,
  }) async {
    final r = await http.delete(
      Uri.parse('${ApiConstants.adminManagers}/$managerId'),
      headers: _headers(adminToken));
    if (r.statusCode != 200) throw Exception(_msg(r, 'Failed to delete manager'));
  }

  // ── PLAYERS ───────────────────────────────────────────────────────────────

  static Future<List<dynamic>> getPlayers(String token) async {
    final r = await http.get(Uri.parse(ApiConstants.adminPlayers), headers: _headers(token));
    if (r.statusCode == 200) {
      final d = json.decode(r.body);
      if (d is List) return d;
      if (d is Map) return (d['data'] ?? d['users'] ?? []) as List;
      return [];
    }
    throw Exception(_msg(r, 'Failed to get players'));
  }

  static Future<Map<String, dynamic>> createPlayer({
    required String adminToken,
    required String username,
    required String email,
    required String password,
    required String phone,
  }) async {
    final r = await http.post(
      Uri.parse(ApiConstants.adminPlayers),
      headers: _headers(adminToken),
      body: json.encode({'username': username, 'email': email, 'password': password, 'phone': phone}));
    if (r.statusCode == 200) {
      final d = json.decode(r.body) as Map<String, dynamic>;
      return d['result'] ?? d['user'] ?? d;
    }
    throw Exception(_msg(r, 'Failed to create player'));
  }

  static Future<Map<String, dynamic>> updatePlayer({
    required String adminToken,
    required String playerId,
    required Map<String, dynamic> data,
  }) async {
    final r = await http.put(
      Uri.parse('${ApiConstants.adminPlayers}/$playerId'),
      headers: _headers(adminToken),
      body: json.encode(data));
    if (r.statusCode == 200) {
      final d = json.decode(r.body) as Map<String, dynamic>;
      return d['result'] ?? d;
    }
    throw Exception(_msg(r, 'Failed to update player'));
  }

  static Future<void> deletePlayer({
    required String adminToken,
    required String playerId,
  }) async {
    final r = await http.delete(
      Uri.parse('${ApiConstants.adminPlayers}/$playerId'),
      headers: _headers(adminToken));
    if (r.statusCode != 200) throw Exception(_msg(r, 'Failed to delete player'));
  }

  // ── WORKERS ───────────────────────────────────────────────────────────────

  static Future<List<dynamic>> getWorkers(String token) async {
    final r = await http.get(Uri.parse(ApiConstants.adminWorkers), headers: _headers(token));
    if (r.statusCode == 200) {
      final d = json.decode(r.body);
      if (d is List) return d;
      if (d is Map) return (d['data'] ?? d['users'] ?? []) as List;
      return [];
    }
    throw Exception(_msg(r, 'Failed to get workers'));
  }

  static Future<Map<String, dynamic>> createWorker({
    required String adminToken,
    required String username,
    required String email,
    required String password,
    required String phone,
    required String nom,
    required String managerId,
  }) async {
    final r = await http.post(
      Uri.parse(ApiConstants.adminWorkers),
      headers: _headers(adminToken),
      body: json.encode({
        'username': username, 'email': email, 'password': password,
        'phone': phone, 'nom': nom, 'managerId': managerId,
      }));
    if (r.statusCode == 200) {
      final d = json.decode(r.body) as Map<String, dynamic>;
      return d['result'] ?? d;
    }
    throw Exception(_msg(r, 'Failed to create worker'));
  }

  static Future<Map<String, dynamic>> updateWorker({
    required String adminToken,
    required String workerId,
    required Map<String, dynamic> data,
  }) async {
    final r = await http.put(
      Uri.parse('${ApiConstants.adminWorkers}/$workerId'),
      headers: _headers(adminToken),
      body: json.encode(data));
    if (r.statusCode == 200) {
      final d = json.decode(r.body) as Map<String, dynamic>;
      return d['result'] ?? d;
    }
    throw Exception(_msg(r, 'Failed to update worker'));
  }

  static Future<void> deleteWorker({
    required String adminToken,
    required String workerId,
  }) async {
    final r = await http.delete(
      Uri.parse('${ApiConstants.adminWorkers}/$workerId'),
      headers: _headers(adminToken));
    if (r.statusCode != 200) throw Exception(_msg(r, 'Failed to delete worker'));
  }
}



















/*// lib/Core/Services/admin_auth_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sporta/Core/Constants/api_constants.dart';

class AdminAuthService {
  // ─────────────────────────────────────────────────────────────────────────
  // LOGIN - Authenticate admin user
  // ─────────────────────────────────────────────────────────────────────────
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

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'token': data['token'],
          'user': data['user'],
        };
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? 'Login failed');
      }
    } catch (e) {
      print('Login error: $e');
      throw Exception(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FORGOT PASSWORD - Send reset link to email
  // ─────────────────────────────────────────────────────────────────────────
  static Future<void> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.forgot),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
        }),
      );

      print('Forgot password response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? 'Failed to send reset link');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RESET PASSWORD - Reset password with token
  // ─────────────────────────────────────────────────────────────────────────
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

  // ─────────────────────────────────────────────────────────────────────────
  // CHANGE PASSWORD - Change password while logged in
  // ─────────────────────────────────────────────────────────────────────────
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

  // ─────────────────────────────────────────────────────────────────────────
  // GET CURRENT USER - Get logged-in user info
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getMe(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.me),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? 'Failed to get user info');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UPDATE PROFILE - Update user profile
  // ─────────────────────────────────────────────────────────────────────────
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

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GET ALL PLAYERS - Admin only - List all players
  // ─────────────────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getPlayers(String adminToken) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.adminPlayers),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
      );

      print('Get players response status: ${response.statusCode}');
      print('Get players response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return data;
        } else if (data is Map && data.containsKey('data')) {
          return data['data'] as List;
        } else if (data is Map && data.containsKey('users')) {
          return data['users'] as List;
        } else {
          return [];
        }
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to get players');
      }
    } catch (e) {
      print('Error in getPlayers: $e');
      throw Exception(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CREATE MANAGER - Admin only - Create a new manager account
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> createManager({
    required String adminToken,
    required String username,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.adminRegisterManager),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
          'phone': phone,
        }),
      );

      print('Create manager response status: ${response.statusCode}');
      print('Create manager response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['user'] ?? data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to create manager');
      }
    } catch (e) {
      print('Error in createManager: $e');
      throw Exception(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GET ALL MANAGERS - Admin only - List all managers
  // ─────────────────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getManagers(String adminToken) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.adminManagers),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
      );

      print('Get managers response status: ${response.statusCode}');
      print('Get managers response body: ${response.body}');

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
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to get managers');
      }
    } catch (e) {
      print('Error in getManagers: $e');
      throw Exception(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UPDATE MANAGER - Admin only - Update a manager
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> updateManager({
    required String adminToken,
    required String managerId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConstants.adminManager(managerId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
        body: json.encode(data),
      );

      print('Update manager response status: ${response.statusCode}');
      print('Update manager response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return result['result'] ?? result;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to update manager');
      }
    } catch (e) {
      print('Error in updateManager: $e');
      throw Exception(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DELETE MANAGER - Admin only - Delete a manager
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> deleteManager({
    required String adminToken,
    required String managerId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConstants.adminManager(managerId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
      );

      print('Delete manager response status: ${response.statusCode}');
      print('Delete manager response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to delete manager');
      }
    } catch (e) {
      print('Error in deleteManager: $e');
      throw Exception(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GET SINGLE MANAGER - Admin only - Get manager details
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getManager({
    required String adminToken,
    required String managerId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.adminManager(managerId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
      );

      print('Get manager response status: ${response.statusCode}');
      print('Get manager response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? 'Failed to get manager');
      }
    } catch (e) {
      print('Error in getManager: $e');
      throw Exception(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // VALIDATE TOKEN - Check if token is valid
  // ─────────────────────────────────────────────────────────────────────────
  static Future<bool> validateToken(String token) async {
    try {
      await getMe(token);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WORKER MANAGEMENT (Admin only)
  // ─────────────────────────────────────────────────────────────────────────

  // CREATE WORKER - Admin only - Create a new worker account
  static Future<Map<String, dynamic>> createWorker({
    required String adminToken,
    required String username,
    required String email,
    required String password,
    required String phone,
    required String nom,
    required String managerId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.adminRegisterWorker),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
          'phone': phone,
          'nom': nom,
          'managerId': managerId,
        }),
      );

      print('Create worker response status: ${response.statusCode}');
      print('Create worker response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['result'] ?? data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to create worker');
      }
    } catch (e) {
      print('Error in createWorker: $e');
      throw Exception(e.toString());
    }
  }

  // GET ALL WORKERS - Admin only - List all workers
  static Future<List<dynamic>> getWorkers(String adminToken) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.adminWorkers),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
      );

      print('Get workers response status: ${response.statusCode}');
      print('Get workers response body: ${response.body}');

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
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to get workers');
      }
    } catch (e) {
      print('Error in getWorkers: $e');
      throw Exception(e.toString());
    }
  }

  // DELETE WORKER - Admin only - Delete a worker
  static Future<Map<String, dynamic>> deleteWorker({
    required String adminToken,
    required String workerId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConstants.adminWorker(workerId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
      );

      print('Delete worker response status: ${response.statusCode}');
      print('Delete worker response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to delete worker');
      }
    } catch (e) {
      print('Error in deleteWorker: $e');
      throw Exception(e.toString());
    }
  }
}

*/