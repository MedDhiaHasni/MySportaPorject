// lib/Models/court_model.dart

import 'package:sporta/Core/Constants/api_constants.dart';

class CourtModel {
  final int id;
  final String name;
  final String? description;
  final String sport;
  final double pricePerHour;
  final int capacity;
  final String? courtImgUrl;
  final List<String> photosUrls;
  final List<String> amenities;
  final bool isActive;
  final int venueId;
  final int? managerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CourtModel({
    required this.id,
    required this.name,
    this.description,
    required this.sport,
    required this.pricePerHour,
    required this.capacity,
    this.courtImgUrl,
    this.photosUrls = const [],
    this.amenities = const [],
    required this.isActive,
    required this.venueId,
    this.managerId,
    this.createdAt,
    this.updatedAt,
  });

  factory CourtModel.fromJson(Map<String, dynamic> json) {
    // Get court_img_url from various possible formats
    String? courtImgUrl;
    if (json['court_img_url'] != null) {
      courtImgUrl = ApiConstants.getFullImageUrl(json['court_img_url'].toString());
    } else if (json['court_img'] != null) {
      if (json['court_img'] is Map && json['court_img']['url'] != null) {
        courtImgUrl = ApiConstants.getFullImageUrl(json['court_img']['url'].toString());
      } else if (json['court_img'] is String) {
        courtImgUrl = ApiConstants.getFullImageUrl(json['court_img']);
      }
    }
    
    // Get photos_urls from various possible formats
    List<String> photosUrls = [];
    if (json['photos_urls'] != null && json['photos_urls'] is List) {
      photosUrls = (json['photos_urls'] as List)
          .map((e) => ApiConstants.getFullImageUrl(e.toString()))
          .toList();
    } else if (json['photos'] != null && json['photos'] is List) {
      photosUrls = (json['photos'] as List)
          .map((e) {
            if (e is Map && e['url'] != null) {
              return ApiConstants.getFullImageUrl(e['url'].toString());
            }
            return '';
          })
          .where((url) => url.isNotEmpty)
          .toList();
    }
    
    // Get amenities
    List<String> amenities = [];
    if (json['amenities'] != null) {
      if (json['amenities'] is List) {
        amenities = (json['amenities'] as List).map((e) => e.toString()).toList();
      } else if (json['amenities'] is String) {
        amenities = [json['amenities']];
      }
    }
    
    // Get venueId
    int venueId = 0;
    if (json['venue'] != null) {
      if (json['venue'] is Map) {
        venueId = json['venue']['id'] ?? 0;
      } else if (json['venue'] is int) {
        venueId = json['venue'];
      }
    } else if (json['venueId'] != null) {
      venueId = json['venueId'];
    }
    
    // Get managerId
    int? managerId;
    if (json['manager'] != null && json['manager'] is Map) {
      managerId = json['manager']['id'];
    } else if (json['managerId'] != null) {
      managerId = json['managerId'];
    }
    
    return CourtModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      sport: json['sport'] ?? '',
      pricePerHour: (json['pricePerHour'] as num?)?.toDouble() ?? 0.0,
      capacity: json['capacity'] ?? 0,
      courtImgUrl: courtImgUrl,
      photosUrls: photosUrls,
      amenities: amenities,
      isActive: json['isActive'] ?? true,
      venueId: venueId,
      managerId: managerId,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'sport': sport,
      'pricePerHour': pricePerHour,
      'capacity': capacity,
      'court_img_url': courtImgUrl,
      'photos_urls': photosUrls,
      'amenities': amenities,
      'isActive': isActive,
      'venueId': venueId,
      'managerId': managerId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
  
  // Helper to check if court is bookable
  bool get isBookable => isActive;
  
  // Helper to get main image URL (fallback to first photo if no main image)
  String get displayImageUrl {
    if (courtImgUrl != null && courtImgUrl!.isNotEmpty) {
      return courtImgUrl!;
    }
    if (photosUrls.isNotEmpty) {
      return photosUrls.first;
    }
    return '';
  }
  
  // Helper to get all images for gallery
  List<String> get allImageUrls {
    final List<String> urls = [];
    if (courtImgUrl != null && courtImgUrl!.isNotEmpty) {
      urls.add(courtImgUrl!);
    }
    urls.addAll(photosUrls);
    return urls;
  }
}