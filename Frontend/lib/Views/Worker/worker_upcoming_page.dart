// lib/Views/Worker/worker_upcoming_page.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Core/Constants/api_constants.dart';
import 'package:sporta/Services/worker_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class WorkerUpcomingPage extends StatefulWidget {
  final String? workerToken;
  const WorkerUpcomingPage({super.key, this.workerToken});

  @override
  State<WorkerUpcomingPage> createState() => _WorkerUpcomingPageState();
}

class _WorkerUpcomingPageState extends State<WorkerUpcomingPage> {
  late String _token;
  bool _isLoading = true;
  String? _error;
  List<dynamic> _reservations = [];
  List<dynamic> _filteredReservations = [];
  
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  late Map<DateTime, List<dynamic>> _reservationsByDay;

  String _getFullImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '${ApiConstants.mediaBaseUrl}$url';
  }

  @override
  void initState() {
    super.initState();
    _reservationsByDay = {};
    _selectedDay = DateTime.now();
    _initTokenAndLoadReservations();
  }

  Future<void> _initTokenAndLoadReservations() async {
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
      await _loadReservations();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

 Future<void> _loadReservations() async {
  setState(() => _isLoading = true);

  try {
    final reservations =
        await WorkerService.getUpcomingReservations(_token);

    setState(() {
      _reservations = reservations;
      _filterReservationsByDay();
      _filterReservationsBySelectedDay();
      _isLoading = false;
    });
  } catch (e) {
    setState(() {
      _error = e.toString();
      _isLoading = false;
    });
  }
}

  void _filterReservationsByDay() {
    _reservationsByDay = {};
    
    for (final reservation in _reservations) {
      final dateStr = reservation['booking_date_play']?.toString().split(' ')[0];
      if (dateStr != null) {
        try {
          final date = DateTime.parse(dateStr);
          final normalizedDate = DateTime(date.year, date.month, date.day);
          
          if (!_reservationsByDay.containsKey(normalizedDate)) {
            _reservationsByDay[normalizedDate] = [];
          }
          _reservationsByDay[normalizedDate]!.add(reservation);
        } catch (e) {
          print('Error parsing date: $dateStr');
        }
      }
    }
  }

  void _filterReservationsBySelectedDay() {
    if (_selectedDay == null) return;
    final normalizedDate = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    setState(() {
      _filteredReservations = _reservationsByDay[normalizedDate] ?? [];
    });
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _filterReservationsBySelectedDay();
    });
  }

  String _getCourtImageUrl(Map<String, dynamic> reservation) {
    final court = reservation['court'] ?? {};
    
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

  String _getTimeString(Map<String, dynamic> reservation) {
    // Get time from time_slot relation
    final timeSlot = reservation['time_slot'] ?? {};
    final startTime = timeSlot['startTime']?.toString() ?? '--:--';
    final endTime = timeSlot['endTime']?.toString() ?? '--:--';
    
    if (startTime != '--:--' && endTime != '--:--') {
      // Format time to remove seconds if present
      String formattedStart = startTime;
      String formattedEnd = endTime;
      if (startTime.length > 5) {
        formattedStart = startTime.substring(0, 5);
      }
      if (endTime.length > 5) {
        formattedEnd = endTime.substring(0, 5);
      }
      return '$formattedStart - $formattedEnd';
    }
    return '--:-- - --:--';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text(
          'Upcoming Schedule',
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
            onPressed: _loadReservations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : _error != null
              ? _buildErrorWidget()
              : Column(
                  children: [
                    // Calendar
                    Container(
                      color: Colors.white,
                      child: TableCalendar(
                        firstDay: DateTime.now(),
                        lastDay: DateTime.now().add(const Duration(days: 30)),
                        focusedDay: _focusedDay,
                        calendarFormat: _calendarFormat,
                        onFormatChanged: (format) {
                          setState(() => _calendarFormat = format);
                        },
                        onDaySelected: _onDaySelected,
                        selectedDayPredicate: (day) {
                          return _selectedDay != null &&
                              day.year == _selectedDay!.year &&
                              day.month == _selectedDay!.month &&
                              day.day == _selectedDay!.day;
                        },
                        eventLoader: (day) {
                          final normalizedDay = DateTime(day.year, day.month, day.day);
                          return _reservationsByDay[normalizedDay] ?? [];
                        },
                        calendarStyle: const CalendarStyle(
                          selectedDecoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          todayDecoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          markerDecoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: true,
                          titleCentered: true,
                          formatButtonDecoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          formatButtonTextStyle: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    
                    // Selected Day Header
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDay != null
                                ? DateFormat('EEEE, MMM d', 'en_US').format(_selectedDay!)
                                : 'Select a day',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: kTextDark,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: kPrimary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_filteredReservations.length} bookings',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: kPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Reservations List
                    Expanded(
                      child: _filteredReservations.isEmpty
                          ? _buildEmptyDayWidget()
                          : RefreshIndicator(
                              onRefresh: _loadReservations,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filteredReservations.length,
                                itemBuilder: (context, index) {
                                  final reservation = _filteredReservations[index];
                                  return _UpcomingReservationCard(
                                    reservation: reservation,
                                    token: _token,
                                    getCourtImageUrl: _getCourtImageUrl,
                                    getFullImageUrl: _getFullImageUrl,
                                    getTimeString: _getTimeString,
                                    onStatusChanged: () {
                                      _loadReservations();
                                    },
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
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
              onPressed: _loadReservations,
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

  Widget _buildEmptyDayWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy_rounded,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No reservations on this day',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select another day to view reservations',
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
// UPCOMING RESERVATION CARD
// ─────────────────────────────────────────────────────────────────────────────
class _UpcomingReservationCard extends StatefulWidget {
  final Map<String, dynamic> reservation;
  final String token;
  final String Function(Map<String, dynamic>) getCourtImageUrl;
  final String Function(String?) getFullImageUrl;
  final String Function(Map<String, dynamic>) getTimeString;
  final VoidCallback onStatusChanged;

  const _UpcomingReservationCard({
    required this.reservation,
    required this.token,
    required this.getCourtImageUrl,
    required this.getFullImageUrl,
    required this.getTimeString,
    required this.onStatusChanged,
  });

  @override
  State<_UpcomingReservationCard> createState() => _UpcomingReservationCardState();
}

class _UpcomingReservationCardState extends State<_UpcomingReservationCard> {
  bool _isProcessing = false;

  Future<void> _confirmReservation() async {
    setState(() => _isProcessing = true);
    
    try {
      await WorkerService.confirmReservation(
        token: widget.token,
        reservationId: widget.reservation['id'].toString(),
      );
      
      widget.onStatusChanged();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reservation confirmed!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _cancelReservation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Reservation'),
        content: const Text('Are you sure you want to cancel this reservation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    setState(() => _isProcessing = true);
    
    try {
      await WorkerService.cancelReservation(
        token: widget.token,
        reservationId: widget.reservation['id'].toString(),
      );
      
      widget.onStatusChanged();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reservation cancelled!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reservation = widget.reservation;
    final court = reservation['court'] ?? {};
    final player = reservation['player'] ?? {};
    final playerUser = player['player'] ?? {};
    final playerName = playerUser['username'] ?? player['nom'] ?? 'Player';
    final timeString = widget.getTimeString(reservation);
    final totalPrice = reservation['total_price'] ?? 0;
    final reference = reservation['booking_reference'] ?? '';
    final status = reservation['booking_status'];
    final paymentMethod = reservation['payment_method'] ?? 'pay_at_venue';
    final courtImageUrl = widget.getCourtImageUrl(reservation);

    Color statusColor;
    String statusText;
    
    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Pending';
        break;
      case 'confirmed':
        statusColor = Colors.green;
        statusText = 'Confirmed';
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusText = 'Completed';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusText = 'Cancelled';
        break;
      default:
        statusColor = Colors.grey;
        statusText = status ?? 'Unknown';
    }

    // Determine if it's today
    final bookingDate = reservation['booking_date_play']?.toString().split(' ')[0];
    final isToday = bookingDate == DateTime.now().toString().split(' ')[0];
    final primaryColor = const Color(0xFF005D5E);

    return Container(
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
          // Court Image with Time Badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: courtImageUrl.isNotEmpty
                    ? Image.network(
                        courtImageUrl,
                        height: 130,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 130,
                            color: primaryColor.withOpacity(0.08),
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: kPrimary,
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : _buildImagePlaceholder(),
              ),
              Positioned(
                top: 12,
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
                      const Icon(Icons.schedule_rounded, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        timeString,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Status Badge on Image
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              if (isToday)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'TODAY',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Court Name
                Text(
                  court['name'] ?? 'Court',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D0D0D),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                
                // Player Info
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.person_outline, size: 16, color: Color(0xFF005D5E)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            playerName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0D0D0D),
                            ),
                          ),
                          Text(
                            'Booking reference: $reference',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 10),
                
                // Price and Payment
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$totalPrice DT',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        paymentMethod == 'pay_now' ? 'Paid Online' : 'Pay at Venue',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                
                if (paymentMethod == 'pay_at_venue' && status == 'pending') ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  
                  // Action Buttons for Pending Reservations
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing ? null : _confirmReservation,
                          icon: _isProcessing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_rounded, size: 16),
                          label: const Text('Confirm'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isProcessing ? null : _cancelReservation,
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('Cancel'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    final primaryColor = const Color(0xFF005D5E);
    return Container(
      height: 130,
      width: double.infinity,
      color: primaryColor.withOpacity(0.08),
      child: const Center(
        child: Icon(
          Icons.stadium_rounded,
          size: 40,
          color: Color(0xFF005D5E),
        ),
      ),
    );
  }
}