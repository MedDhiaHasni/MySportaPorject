// lib/Views/Worker/worker_court_detail_page.dart

import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Core/Constants/api_constants.dart';
import 'package:sporta/Services/worker_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class WorkerCourtDetailPage extends StatefulWidget {
  final String? workerToken;
  final Map<String, dynamic> court;
  
  const WorkerCourtDetailPage({
    super.key,
    this.workerToken,
    required this.court,
  });

  @override
  State<WorkerCourtDetailPage> createState() => _WorkerCourtDetailPageState();
}

class _WorkerCourtDetailPageState extends State<WorkerCourtDetailPage>
    with SingleTickerProviderStateMixin {
  late String _token;
  late Map<String, dynamic> _court;
  bool _isLoading = true;
  bool _isLoadingSlots = false;
  String? _error;
  List<dynamic> _timeSlots = [];
  String _selectedDate = '';
  
  late TabController _tabController;

  String _getFullImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '${ApiConstants.mediaBaseUrl}$url';
  }

  String _getCourtImageUrl() {
    final court = _court;
    
    // Priority order for image URL
    if (court['court_img_url'] != null && court['court_img_url'].toString().isNotEmpty) {
      return _getFullImageUrl(court['court_img_url'].toString());
    }
    if (court['court_img'] != null && court['court_img']['url'] != null) {
      return _getFullImageUrl(court['court_img']['url'].toString());
    }
    if (court['photos_urls'] != null && court['photos_urls'] is List && court['photos_urls'].isNotEmpty) {
      return _getFullImageUrl(court['photos_urls'][0].toString());
    }
    if (court['photos'] != null && court['photos'] is List && court['photos'].isNotEmpty) {
      final firstPhoto = court['photos'][0];
      if (firstPhoto is Map && firstPhoto['url'] != null) {
        return _getFullImageUrl(firstPhoto['url'].toString());
      }
    }
    return '';
  }

  List<String> _getAllGalleryImages() {
    final List<String> images = [];
    final court = _court;
    
    // Main image
    final mainImage = _getCourtImageUrl();
    if (mainImage.isNotEmpty) {
      images.add(mainImage);
    }
    
    // Gallery images from photos_urls
    if (court['photos_urls'] != null && court['photos_urls'] is List) {
      for (final url in court['photos_urls']) {
        final fullUrl = _getFullImageUrl(url.toString());
        if (fullUrl.isNotEmpty && !images.contains(fullUrl)) {
          images.add(fullUrl);
        }
      }
    }
    
    // Gallery images from photos nested
    if (court['photos'] != null && court['photos'] is List) {
      for (final photo in court['photos']) {
        if (photo is Map && photo['url'] != null) {
          final fullUrl = _getFullImageUrl(photo['url'].toString());
          if (fullUrl.isNotEmpty && !images.contains(fullUrl)) {
            images.add(fullUrl);
          }
        }
      }
    }
    
    return images;
  }

  @override
  void initState() {
    super.initState();
    _court = widget.court;
    _tabController = TabController(length: 2, vsync: this);
    _initTokenAndLoadData();
  }

  Future<void> _initTokenAndLoadData() async {
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
      
      // Set today as selected date
      _selectedDate = DateTime.now().toString().split(' ')[0];
      
      await _loadTimeSlots();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTimeSlots() async {
    setState(() => _isLoadingSlots = true);

    try {
      final slots = await WorkerService.getMyTimeSlots(
        token: _token,
        date: _selectedDate,
      );
      setState(() {
        _timeSlots = slots;
        _isLoading = false;
        _isLoadingSlots = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isLoadingSlots = false;
      });
    }
  }

  Future<void> _toggleTimeSlot(String slotId, bool isActive, bool hasReservation) async {
    if (hasReservation && !isActive) {
      _showSnackBar('Cannot deactivate a time slot with a reservation', Colors.red);
      return;
    }

    setState(() => _isLoadingSlots = true);

    try {
      await WorkerService.updateTimeSlot(
        token: _token,
        timeSlotId: slotId,
        isActive: !isActive,
      );
      
      await _loadTimeSlots();
      
      _showSnackBar(
        'Time slot ${!isActive ? 'activated' : 'deactivated'} successfully',
        kGreen,
      );
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
      setState(() => _isLoadingSlots = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: Text(
          _court['name'] ?? 'Court Details',
          style: const TextStyle(
            fontSize: 18,
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: kPrimary,
          unselectedLabelColor: kTextMid,
          indicatorColor: kPrimary,
          tabs: const [
            Tab(text: 'Details', icon: Icon(Icons.info_outline)),
            Tab(text: 'Time Slots', icon: Icon(Icons.schedule_rounded)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : _error != null
              ? _buildErrorWidget()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDetailsTab(),
                    _buildTimeSlotsTab(),
                  ],
                ),
    );
  }

  Widget _buildDetailsTab() {
    final venue = _court['venue'] ?? {};
    final sport = _court['sport'] ?? 'football';
    final pricePerHour = _court['pricePerHour'] ?? 0;
    final capacity = _court['capacity'] ?? 0;
    final description = _court['description'] ?? 'No description available';
    final amenities = _court['amenities'] ?? [];
    final isActive = _court['isActive'] ?? true;
    
    final courtImages = _getAllGalleryImages();
    final primaryImage = courtImages.isNotEmpty ? courtImages.first : '';

    String sportIcon = '⚽';
    if (sport == 'tennis') sportIcon = '🎾';
    if (sport == 'padel') sportIcon = '🎾';
    if (sport == 'basketball') sportIcon = '🏀';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Court Image Gallery (if multiple images, show carousel)
          courtImages.isEmpty
              ? _buildImagePlaceholder(sportIcon)
              : courtImages.length == 1
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        courtImages.first,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildImagePlaceholder(sportIcon),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 220,
                            color: kPrimary.withOpacity(0.08),
                            child: const Center(
                              child: CircularProgressIndicator(color: kPrimary),
                            ),
                          );
                        },
                      ),
                    )
                  : _buildImageCarousel(courtImages, sportIcon),
          
          const SizedBox(height: 16),

          // Court Name & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _court['name'] ?? 'Court',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: kTextDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? kGreen.withOpacity(0.1) : kRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isActive ? kGreen : kRed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Venue & Location
          Row(
            children: [
              Icon(Icons.location_on_rounded, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  venue['name'] ?? 'Unknown Venue',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stats Row
          Row(
            children: [
              Expanded(
                child: _InfoCard(
                  icon: Icons.sports_soccer_rounded,
                  label: 'Sport',
                  value: sport.toString().toUpperCase(),
                  color: kPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoCard(
                  icon: Icons.attach_money_rounded,
                  label: 'Price',
                  value: '$pricePerHour DT/hr',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoCard(
                  icon: Icons.people_rounded,
                  label: 'Capacity',
                  value: '$capacity players',
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Description
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: kTextDark,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Amenities
          if (amenities.isNotEmpty) ...[
            const Text(
              'Amenities',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: kTextDark,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: amenities.map<Widget>((amenity) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    amenity.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kPrimary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageCarousel(List<String> images, String sportIcon) {
    return SizedBox(
      height: 220,
      child: PageView.builder(
        itemCount: images.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(
              images[index],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildImagePlaceholder(sportIcon),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: kPrimary.withOpacity(0.08),
                  child: const Center(
                    child: CircularProgressIndicator(color: kPrimary),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeSlotsTab() {
    return Column(
      children: [
        // Date Picker
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectDate(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: kBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 18, color: kPrimary),
                        const SizedBox(width: 12),
                        Text(
                          _formatDate(_selectedDate),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_drop_down_rounded, color: kTextMid),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _loadTimeSlots,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kPrimary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),

        // Time Slots Grid
        Expanded(
          child: _isLoadingSlots
              ? const Center(child: CircularProgressIndicator(color: kPrimary))
              : _timeSlots.isEmpty
                  ? _buildEmptyTimeSlots()
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.8,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _timeSlots.length,
                      itemBuilder: (context, index) {
                        final slot = _timeSlots[index];
                        final startTime = slot['startTime'] ?? '--:--';
                        final endTime = slot['endTime'] ?? '--:--';
                        final isActive = slot['isActive'] ?? false;
                        final hasReservation = slot['reservation'] != null;
                        
                        return _TimeSlotCard(
                          startTime: startTime,
                          endTime: endTime,
                          isActive: isActive,
                          isBooked: hasReservation,
                          onToggle: () => _toggleTimeSlot(
                            slot['id'].toString(),
                            isActive,
                            hasReservation,
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_selectedDate),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: kPrimary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked.toString().split(' ')[0];
      });
      await _loadTimeSlots();
    }
  }

  String _formatDate(String date) {
    if (date.isEmpty) return 'Select Date';
    final parts = date.split('-');
    if (parts.length != 3) return date;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  Widget _buildImagePlaceholder(String sportIcon) {
    return Container(
      height: 220,
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
              onPressed: _initTokenAndLoadData,
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

  Widget _buildEmptyTimeSlots() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No Time Slots',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No time slots available for ${_formatDate(_selectedDate)}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INFO CARD
// ─────────────────────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TIME SLOT CARD
// ─────────────────────────────────────────────────────────────────────────────
class _TimeSlotCard extends StatelessWidget {
  final String startTime;
  final String endTime;
  final bool isActive;
  final bool isBooked;
  final VoidCallback onToggle;

  const _TimeSlotCard({
    required this.startTime,
    required this.endTime,
    required this.isActive,
    required this.isBooked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    Color slotColor;
    String statusText;
    
    if (isBooked) {
      slotColor = Colors.red;
      statusText = 'Booked';
    } else if (isActive) {
      slotColor = kGreen;
      statusText = 'Available';
    } else {
      slotColor = Colors.grey;
      statusText = 'Inactive';
    }

    return GestureDetector(
      onTap: !isBooked ? onToggle : null,
      child: Container(
        decoration: BoxDecoration(
          color: slotColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: slotColor.withOpacity(isActive ? 0.3 : 0.15),
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$startTime - $endTime',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: slotColor,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: slotColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: slotColor,
                    ),
                  ),
                ),
              ],
            ),
            if (!isBooked)
              Positioned(
                top: 6,
                right: 6,
                child: Icon(
                  isActive ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                  size: 20,
                  color: slotColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}