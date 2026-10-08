// lib/Services/rating_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sporta/Core/Constants/api_constants.dart';

class RatingService {
  final String _token;

  RatingService({required String token}) : _token = token;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_token',
  };

  // ─────────────────────────────────────────────────────────────────────────
  // Submit or update rating
  // ─────────────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> submitRating({
    required int venueId,
    required double ratingValue,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.submitRating),
        headers: _headers,
        body: json.encode({
          'rating_value': ratingValue,
          'venue_id': venueId,
        }),
      );

      print('Submit rating response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Rating submitted successfully',
          'rating': data['rating'],
        };
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? 'Failed to submit rating');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Delete rating
  // ─────────────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> deleteRating(String ratingId) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConstants.ratingById(ratingId)),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Rating deleted successfully',
        };
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? 'Failed to delete rating');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Get user's rating for a specific venue
  // ─────────────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getUserRating(String venueId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.getUserRating(venueId)),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      }
      return null;
    } catch (e) {
      print('Error getting user rating: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Get all ratings for a venue (public)
  // ─────────────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getVenueRatings(String venueId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.getVenueRatings(venueId)),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get ratings');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}