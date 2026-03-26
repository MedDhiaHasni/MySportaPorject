// venue_model.dart — Models/venue_model.dart
// VenueModel used by Explore, CourtBookingPage, and CourtDetailPage

class VenueModel {
  final String name;
  final String location;
  final List<String> sports;
  final List<String> amenities;
  final int minPrice;
  final int maxPrice;
  final bool available;
  final String openUntil;
  final String image;
  final double lat, lng;
  final List<Map<String, dynamic>> courts;
  final String managerName;
  final String managerPhone;
  final String managerAvatar; // initials e.g. "AT"

  const VenueModel({
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
  });
}
