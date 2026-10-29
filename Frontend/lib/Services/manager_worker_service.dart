// lib/Core/Services/manager_worker_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sporta/Core/Constants/api_constants.dart';
import 'package:sporta/Core/Utils/app_logger.dart';

class ManagerWorkerService {
  // ─────────────────────────────────────────────────────────────────────────
  // MANAGER WORKER MANAGEMENT (Manager only)
  // ─────────────────────────────────────────────────────────────────────────

  // GET MY WORKERS - Get all workers under this manager
  static Future<List<dynamic>> getMyWorkers(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.managerMyWorkers),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['workers'] ?? [];
      } else {
        final error = json.decode(response.body);
        throw Exception(
          error['error']?['message'] ??
              error['message'] ??
              'Failed to get workers',
        );
      }
    } catch (e) {
      AppLogger.error('Error in getMyWorkers: $e');
      throw Exception(e.toString());
    }
  }

  // GET WORKER BY ID - Get a specific worker's details
  static Future<Map<String, dynamic>> getWorkerById({
    required String token,
    required String workerId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.managerWorker(workerId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['worker'] ?? data;
      } else {
        final error = json.decode(response.body);
        throw Exception(
          error['error']?['message'] ??
              error['message'] ??
              'Failed to get worker details',
        );
      }
    } catch (e) {
      AppLogger.error('Error in getWorkerById: $e');
      throw Exception(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NEW: DIRECT COURT WORKER ASSIGNMENT
  // ─────────────────────────────────────────────────────────────────────────

  // ASSIGN WORKER TO A SINGLE COURT - Uses the new court endpoint
  static Future<Map<String, dynamic>> assignWorkerToSingleCourt({
    required String token,
    required String courtId,
    required String workerId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/courts/$courtId/assign-worker'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'workerId': workerId}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(
          error['error']?['message'] ??
              error['message'] ??
              'Failed to assign worker to court',
        );
      }
    } catch (e) {
      AppLogger.error('Error in assignWorkerToSingleCourt: $e');
      throw Exception(e.toString());
    }
  }

  // REMOVE WORKER FROM A SINGLE COURT - Uses the new court endpoint
  static Future<Map<String, dynamic>> removeWorkerFromSingleCourt({
    required String token,
    required String courtId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/courts/$courtId/remove-worker'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(
          error['error']?['message'] ??
              error['message'] ??
              'Failed to remove worker from court',
        );
      }
    } catch (e) {
      AppLogger.error('Error in removeWorkerFromSingleCourt: $e');
      throw Exception(e.toString());
    }
  }

  // ASSIGN WORKER TO MULTIPLE COURTS - Uses the new court endpoint for each court
  static Future<Map<String, dynamic>> assignWorkerToCourts({
    required String token,
    required String workerId,
    required List<String> courtIds,
  }) async {
    try {
      final results = <String, dynamic>{};
      bool allSuccess = true;

      for (final courtId in courtIds) {
        try {
          final result = await assignWorkerToSingleCourt(
            token: token,
            courtId: courtId,
            workerId: workerId,
          );
          results[courtId] = result;
        } catch (e) {
          allSuccess = false;
          results[courtId] = {'error': e.toString()};
        }
      }

      return {'success': allSuccess, 'results': results};
    } catch (e) {
      AppLogger.error('Error in assignWorkerToCourts: $e');
      throw Exception(e.toString());
    }
  }

  // REMOVE WORKER FROM MULTIPLE COURTS
  static Future<Map<String, dynamic>> removeWorkerFromCourts({
    required String token,
    required List<String> courtIds,
  }) async {
    try {
      final results = <String, dynamic>{};
      bool allSuccess = true;

      for (final courtId in courtIds) {
        try {
          final result = await removeWorkerFromSingleCourt(
            token: token,
            courtId: courtId,
          );
          results[courtId] = result;
        } catch (e) {
          allSuccess = false;
          results[courtId] = {'error': e.toString()};
        }
      }

      return {'success': allSuccess, 'results': results};
    } catch (e) {
      AppLogger.error('Error in removeWorkerFromCourts: $e');
      throw Exception(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LEGACY METHODS (kept for backward compatibility)
  // ─────────────────────────────────────────────────────────────────────────

  // ASSIGN WORKER TO COURTS (Legacy - uses manager endpoint)
  static Future<Map<String, dynamic>> assignWorkerToCourtsLegacy({
    required String token,
    required String workerId,
    required List<String> courtIds,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConstants.assignWorkerCourts(workerId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'courtIds': courtIds}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(
          error['error']?['message'] ??
              error['message'] ??
              'Failed to assign worker to courts',
        );
      }
    } catch (e) {
      AppLogger.error('Error in assignWorkerToCourtsLegacy: $e');
      throw Exception(e.toString());
    }
  }

  // REMOVE WORKER FROM COURT (Legacy - uses manager endpoint)
  static Future<Map<String, dynamic>> removeWorkerFromCourtLegacy({
    required String token,
    required String workerId,
    required String courtId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConstants.removeWorkerFromCourt(workerId, courtId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(
          error['error']?['message'] ??
              error['message'] ??
              'Failed to remove worker from court',
        );
      }
    } catch (e) {
      AppLogger.error('Error in removeWorkerFromCourtLegacy: $e');
      throw Exception(e.toString());
    }
  }

  // GET WORKER'S COURTS - Get all courts assigned to a specific worker
  static Future<List<dynamic>> getWorkerCourts({
    required String token,
    required String workerId,
  }) async {
    try {
      final worker = await getWorkerById(token: token, workerId: workerId);
      return worker['courts'] ?? [];
    } catch (e) {
      AppLogger.error('Error in getWorkerCourts: $e');
      throw Exception(e.toString());
    }
  }

  // GET UNASSIGNED COURTS - Get courts that have no worker assigned (for assignment)
  static Future<List<dynamic>> getUnassignedCourts(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.managerCourts),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> allCourts = data is List
            ? data
            : (data['data'] ?? []);

        // Filter courts with no worker assigned
        final unassignedCourts = allCourts.where((court) {
          return court['worker'] == null;
        }).toList();

        return unassignedCourts;
      } else {
        final error = json.decode(response.body);
        throw Exception(
          error['error']?['message'] ??
              error['message'] ??
              'Failed to get courts',
        );
      }
    } catch (e) {
      AppLogger.error('Error in getUnassignedCourts: $e');
      throw Exception(e.toString());
    }
  }

  // GET ASSIGNED COURTS FOR WORKER - Alternative method
  static Future<List<dynamic>> getAssignedCourtsForWorker({
    required String token,
    required String workerId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.managerCourts),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> allCourts = data is List
            ? data
            : (data['data'] ?? []);

        // Filter courts assigned to this worker
        final assignedCourts = allCourts.where((court) {
          return court['worker'] != null &&
              court['worker']['id'].toString() == workerId;
        }).toList();

        return assignedCourts;
      } else {
        final error = json.decode(response.body);
        throw Exception(
          error['error']?['message'] ??
              error['message'] ??
              'Failed to get assigned courts',
        );
      }
    } catch (e) {
      AppLogger.error('Error in getAssignedCourtsForWorker: $e');
      throw Exception(e.toString());
    }
  }

  // BULK ASSIGN WORKERS TO COURTS - Assign multiple workers to multiple courts
  static Future<Map<String, dynamic>> bulkAssignWorkers({
    required String token,
    required Map<String, List<String>> assignments, // { workerId: [courtIds] }
  }) async {
    try {
      final results = <String, dynamic>{};

      for (final entry in assignments.entries) {
        final workerId = entry.key;
        final courtIds = entry.value;

        final result = await assignWorkerToCourts(
          token: token,
          workerId: workerId,
          courtIds: courtIds,
        );

        results[workerId] = result;
      }

      return {'success': true, 'results': results};
    } catch (e) {
      AppLogger.error('Error in bulkAssignWorkers: $e');
      throw Exception(e.toString());
    }
  }

  // GET WORKER STATISTICS - Get statistics for a worker (reservations count, etc.)
  static Future<Map<String, dynamic>> getWorkerStatistics({
    required String token,
    required String workerId,
  }) async {
    try {
      final worker = await getWorkerById(token: token, workerId: workerId);
      final courts = worker['courts'] ?? [];

      // Get all reservations for worker's courts
      final response = await http.get(
        Uri.parse(ApiConstants.reservations),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> allReservations = data['data'] ?? [];

        final courtIds = courts.map<int>((c) => c['id'] as int).toList();

        // Count reservations for worker's courts
        final pendingReservations = allReservations.where((r) {
          return courtIds.contains(r['court']?['id']) &&
              r['booking_status'] == 'pending';
        }).length;

        final confirmedReservations = allReservations.where((r) {
          return courtIds.contains(r['court']?['id']) &&
              r['booking_status'] == 'confirmed';
        }).length;

        final completedReservations = allReservations.where((r) {
          return courtIds.contains(r['court']?['id']) &&
              r['booking_status'] == 'completed';
        }).length;

        return {
          'totalCourts': courts.length,
          'pendingReservations': pendingReservations,
          'confirmedReservations': confirmedReservations,
          'completedReservations': completedReservations,
          'totalReservations':
              pendingReservations +
              confirmedReservations +
              completedReservations,
        };
      } else {
        return {
          'totalCourts': courts.length,
          'pendingReservations': 0,
          'confirmedReservations': 0,
          'completedReservations': 0,
          'totalReservations': 0,
        };
      }
    } catch (e) {
      AppLogger.error('Error in getWorkerStatistics: $e');
      throw Exception(e.toString());
    }
  }
}

/*// lib/Core/Services/manager_worker_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sporta/Core/Constants/api_constants.dart';

class ManagerWorkerService {
  // ─────────────────────────────────────────────────────────────────────────
  // MANAGER WORKER MANAGEMENT (Manager only)
  // ─────────────────────────────────────────────────────────────────────────

  // GET MY WORKERS - Get all workers under this manager
  static Future<List<dynamic>> getMyWorkers(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.managerMyWorkers),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );


      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['workers'] ?? [];
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to get workers');
      }
    } catch (e) {
      AppLogger.error('Error in getMyWorkers: $e');
      throw Exception(e.toString());
    }
  }

  // GET WORKER BY ID - Get a specific worker's details
  static Future<Map<String, dynamic>> getWorkerById({
    required String token,
    required String workerId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.managerWorker(workerId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );


      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['worker'] ?? data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to get worker details');
      }
    } catch (e) {
      AppLogger.error('Error in getWorkerById: $e');
      throw Exception(e.toString());
    }
  }

  // ASSIGN WORKER TO COURTS - Assign a worker to multiple courts
  static Future<Map<String, dynamic>> assignWorkerToCourts({
    required String token,
    required String workerId,
    required List<String> courtIds,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConstants.assignWorkerCourts(workerId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'courtIds': courtIds,
        }),
      );


      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to assign worker to courts');
      }
    } catch (e) {
      AppLogger.error('Error in assignWorkerToCourts: $e');
      throw Exception(e.toString());
    }
  }

  // REMOVE WORKER FROM COURT - Remove a worker from a specific court
  static Future<Map<String, dynamic>> removeWorkerFromCourt({
    required String token,
    required String workerId,
    required String courtId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConstants.removeWorkerFromCourt(workerId, courtId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );


      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to remove worker from court');
      }
    } catch (e) {
      AppLogger.error('Error in removeWorkerFromCourt: $e');
      throw Exception(e.toString());
    }
  }

  // GET WORKER'S COURTS - Get all courts assigned to a specific worker
  static Future<List<dynamic>> getWorkerCourts({
    required String token,
    required String workerId,
  }) async {
    try {
      final worker = await getWorkerById(token: token, workerId: workerId);
      return worker['courts'] ?? [];
    } catch (e) {
      AppLogger.error('Error in getWorkerCourts: $e');
      throw Exception(e.toString());
    }
  }

  // GET UNASSIGNED COURTS - Get courts that have no worker assigned (for assignment)
  static Future<List<dynamic>> getUnassignedCourts(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.managerCourts),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );


      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> allCourts = data is List ? data : (data['data'] ?? []);
        
        // Filter courts with no worker assigned
        final unassignedCourts = allCourts.where((court) {
          return court['worker'] == null;
        }).toList();
        
        return unassignedCourts;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to get courts');
      }
    } catch (e) {
      AppLogger.error('Error in getUnassignedCourts: $e');
      throw Exception(e.toString());
    }
  }

  // GET ASSIGNED COURTS FOR WORKER - Alternative method
  static Future<List<dynamic>> getAssignedCourtsForWorker({
    required String token,
    required String workerId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.managerCourts),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );


      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> allCourts = data is List ? data : (data['data'] ?? []);
        
        // Filter courts assigned to this worker
        final assignedCourts = allCourts.where((court) {
          return court['worker'] != null && court['worker']['id'].toString() == workerId;
        }).toList();
        
        return assignedCourts;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? error['message'] ?? 'Failed to get assigned courts');
      }
    } catch (e) {
      AppLogger.error('Error in getAssignedCourtsForWorker: $e');
      throw Exception(e.toString());
    }
  }

  // BULK ASSIGN WORKERS TO COURTS - Assign multiple workers to multiple courts
  static Future<Map<String, dynamic>> bulkAssignWorkers({
    required String token,
    required Map<String, List<String>> assignments, // { workerId: [courtIds] }
  }) async {
    try {
      final results = <String, dynamic>{};
      
      for (final entry in assignments.entries) {
        final workerId = entry.key;
        final courtIds = entry.value;
        
        final result = await assignWorkerToCourts(
          token: token,
          workerId: workerId,
          courtIds: courtIds,
        );
        
        results[workerId] = result;
      }
      
      return {
        'success': true,
        'results': results,
      };
    } catch (e) {
      AppLogger.error('Error in bulkAssignWorkers: $e');
      throw Exception(e.toString());
    }
  }

  // GET WORKER STATISTICS - Get statistics for a worker (reservations count, etc.)
  static Future<Map<String, dynamic>> getWorkerStatistics({
    required String token,
    required String workerId,
  }) async {
    try {
      final worker = await getWorkerById(token: token, workerId: workerId);
      final courts = worker['courts'] ?? [];
      
      // Get all reservations for worker's courts
      final response = await http.get(
        Uri.parse(ApiConstants.reservations),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> allReservations = data['data'] ?? [];
        
        final courtIds = courts.map<int>((c) => c['id'] as int).toList();
        
        // Count reservations for worker's courts
        final pendingReservations = allReservations.where((r) {
          return courtIds.contains(r['court']?['id']) && r['booking_status'] == 'pending';
        }).length;
        
        final confirmedReservations = allReservations.where((r) {
          return courtIds.contains(r['court']?['id']) && r['booking_status'] == 'confirmed';
        }).length;
        
        final completedReservations = allReservations.where((r) {
          return courtIds.contains(r['court']?['id']) && r['booking_status'] == 'completed';
        }).length;
        
        return {
          'totalCourts': courts.length,
          'pendingReservations': pendingReservations,
          'confirmedReservations': confirmedReservations,
          'completedReservations': completedReservations,
          'totalReservations': pendingReservations + confirmedReservations + completedReservations,
        };
      } else {
        return {
          'totalCourts': courts.length,
          'pendingReservations': 0,
          'confirmedReservations': 0,
          'completedReservations': 0,
          'totalReservations': 0,
        };
      }
    } catch (e) {
      AppLogger.error('Error in getWorkerStatistics: $e');
      throw Exception(e.toString());
    }
  }
}*/
