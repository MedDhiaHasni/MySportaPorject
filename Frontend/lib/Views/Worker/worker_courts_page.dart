// lib/Views/Worker/worker_courts_page.dart

import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Core/Constants/api_constants.dart';
import 'package:sporta/Services/worker_service.dart';
import 'package:sporta/Views/Worker/worker_court_detail_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class WorkerCourtsPage extends StatefulWidget {
  final String? workerToken;
  const WorkerCourtsPage({super.key, this.workerToken});

  @override
  State<WorkerCourtsPage> createState() => _WorkerCourtsPageState();
}

class _WorkerCourtsPageState extends State<WorkerCourtsPage> {
  late String _token;
  bool _isLoading = true;
  String? _error;
  List<dynamic> _courts = [];

  @override
  void initState() {
    super.initState();
    _initTokenAndLoadCourts();
  }

  Future<void> _initTokenAndLoadCourts() async {
    try {
      String? token = widget.workerToken;
      if (token == null || token.isEmpty) {
        const storage = FlutterSecureStorage();
        token = await storage.read(key: 'jwt_token');
      }

      if (token == null || token.isEmpty) {
        setState(() {
          _error = 'Not authenticated. Please login again.';
          _isLoading = false;
        });
        return;
      }

      _token = token;
      await _loadCourts();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCourts() async {
    setState(() => _isLoading = true);

    try {
      final courts = await WorkerService.getMyCourts(_token);
      setState(() {
        _courts = courts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getFullImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '${ApiConstants.mediaBaseUrl}$url';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text(
          'My Courts',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: kTextDark,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: kTextDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: kPrimary),
            onPressed: _loadCourts,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCourts,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: kPrimary))
            : _error != null
                ? _buildErrorWidget()
                : _courts.isEmpty
                    ? _buildEmptyWidget()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _courts.length,
                        itemBuilder: (context, index) {
                          final court = _courts[index];
                          return _CourtCard(
                            court: court,
                            token: _token,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => WorkerCourtDetailPage(
                                    workerToken: _token,
                                    court: court,
                                  ),
                                ),
                              );
                            },
                            getFullImageUrl: _getFullImageUrl,
                          );
                        },
                      ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: kRed),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: kTextMid),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadCourts,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_tennis_rounded,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No Courts Assigned',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You haven\'t been assigned to any courts yet.\nContact your manager.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COURT CARD
// ─────────────────────────────────────────────────────────────────────────────
class _CourtCard extends StatelessWidget {
  final Map<String, dynamic> court;
  final String token;
  final VoidCallback onTap;
  final String Function(String?) getFullImageUrl;

  const _CourtCard({
    required this.court,
    required this.token,
    required this.onTap,
    required this.getFullImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final venue = court['venue'] ?? {};
    final courtName = court['name'] ?? 'Unknown Court';
    final venueName = venue['name'] ?? 'Unknown Venue';
    final sport = court['sport'] ?? 'football';
    final pricePerHour = court['pricePerHour'] ?? 0;
    final capacity = court['capacity'] ?? 0;
    final isActive = court['isActive'] ?? true;
    
    // Get image URL with proper base URL
    String courtImgUrl = '';
    if (court['court_img_url'] != null && court['court_img_url'].toString().isNotEmpty) {
      courtImgUrl = getFullImageUrl(court['court_img_url'].toString());
    } else if (court['court_img'] != null && court['court_img']['url'] != null) {
      courtImgUrl = getFullImageUrl(court['court_img']['url'].toString());
    } else if (court['photos_urls'] != null && court['photos_urls'] is List && court['photos_urls'].isNotEmpty) {
      courtImgUrl = getFullImageUrl(court['photos_urls'][0].toString());
    } else if (court['photos'] != null && court['photos'] is List && court['photos'].isNotEmpty) {
      final firstPhoto = court['photos'][0];
      if (firstPhoto is Map && firstPhoto['url'] != null) {
        courtImgUrl = getFullImageUrl(firstPhoto['url'].toString());
      }
    }
    
    final description = court['description'] ?? '';

    String sportIcon = '⚽';
    if (sport == 'tennis') sportIcon = '🎾';
    if (sport == 'padel') sportIcon = '🎾';
    if (sport == 'basketball') sportIcon = '🏀';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Court Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: courtImgUrl.isNotEmpty
                  ? Stack(
                      children: [
                        Image.network(
                          courtImgUrl,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildImagePlaceholder(sportIcon),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 160,
                              color: kPrimary.withOpacity(0.08),
                              child: Center(
                                child: SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: kPrimary,
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        // Status Badge
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isActive ? kGreen : kRed,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: (isActive ? kGreen : kRed).withOpacity(0.4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  isActive ? 'Active' : 'Inactive',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Sport Badge
                        Positioned(
                          bottom: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  sportIcon,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  sport.toString().toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : _buildImagePlaceholder(sportIcon),
            ),
            // Court Info
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Court Name
                  Text(
                    courtName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: kTextDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // Venue Name with icon
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          venueName,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  // Description (if exists)
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  
                  const SizedBox(height: 10),
                  
                  // Price and Capacity Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.attach_money_rounded, size: 14, color: kPrimary),
                              const SizedBox(height: 2),
                              Text(
                                '$pricePerHour DT',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: kPrimary,
                                ),
                              ),
                              const Text(
                                'per hour',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: kTextMid,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.people_rounded, size: 14, color: Colors.blue),
                              const SizedBox(height: 2),
                              Text(
                                '$capacity',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.blue,
                                ),
                              ),
                              const Text(
                                'max players',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: kTextMid,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Action Button
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: kPrimary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.visibility_rounded, size: 16, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'View Details',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(String sportIcon) {
    return Container(
      height: 160,
      width: double.infinity,
      color: kPrimary.withOpacity(0.08),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              sportIcon,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 8),
            Text(
              'No image available',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}