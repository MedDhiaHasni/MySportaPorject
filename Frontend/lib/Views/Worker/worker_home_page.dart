// lib/Views/Worker/worker_home_page.dart

import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Core/Constants/api_constants.dart';
import 'package:sporta/Services/worker_service.dart';
import 'package:sporta/Views/Worker/worker_courts_page.dart';
import 'package:sporta/Views/Worker/worker_reservations_page.dart';
import 'package:sporta/Views/Worker/worker_upcoming_page.dart';
import 'package:sporta/Views/Worker/worker_profile_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class WorkerHomePage extends StatefulWidget {
  final String? workerToken;
  const WorkerHomePage({super.key, this.workerToken});

  @override
  State<WorkerHomePage> createState() => _WorkerHomePageState();
}

class _WorkerHomePageState extends State<WorkerHomePage> {
  late String _token;
  bool _isLoading = true;
  String? _error;

  // Worker data
  Map<String, dynamic>? _workerProfile;
  List<dynamic> _assignedCourts = [];
  List<dynamic> _upcomingReservations = [];
  List<dynamic> _pendingReservations = [];

  // Stats
  int _totalCourts = 0;
  int _todayReservations = 0;
  int _pendingCount = 0;
  int _confirmedCount = 0;

  String _getFullImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '${ApiConstants.mediaBaseUrl}$url';
  }

  @override
  void initState() {
    super.initState();
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
      await _loadWorkerData();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadWorkerData() async {
    setState(() => _isLoading = true);

    try {
      // Get worker profile
      final worker = await WorkerService.getMe(_token);
      setState(() => _workerProfile = worker);

      // Get assigned courts
      final courts = await WorkerService.getMyCourts(_token);
      setState(() => _assignedCourts = courts);
      _totalCourts = courts.length;

      // Get upcoming reservations
      final upcoming = await WorkerService.getUpcomingReservations(_token);
      setState(() => _upcomingReservations = upcoming);

      // Count today's reservations
      final today = DateTime.now().toString().split(' ')[0];
      _todayReservations = upcoming.where((r) {
        final date = r['booking_date_play']?.toString().split(' ')[0] ?? '';
        return date == today;
      }).length;

      // Get pending reservations
      final allReservations = await WorkerService.getMyReservations(_token);
      final pending = allReservations.where((r) {
        return r['booking_status'] == 'pending';
      }).toList();
      setState(() => _pendingReservations = pending);
      _pendingCount = pending.length;

      // Count confirmed reservations
      _confirmedCount = allReservations.where((r) {
        return r['booking_status'] == 'confirmed';
      }).length;

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: RefreshIndicator(
        onRefresh: _loadWorkerData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: kPrimary))
            : _error != null
                ? _buildErrorWidget()
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with tappable avatar
                        _buildHeader(),
                        const SizedBox(height: 24),

                        // Stats Cards Row
                        _buildStatsRow(),
                        const SizedBox(height: 24),

                        // Quick Actions
                        _buildQuickActions(),
                        const SizedBox(height: 24),

                        // Today's Schedule
                        _buildTodaySchedule(),
                        const SizedBox(height: 24),

                        // Pending Reservations
                        _buildPendingReservations(),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildHeader() {
    final workerName = _workerProfile?['nom'] ?? 
                       _workerProfile?['worker']?['username'] ?? 
                       'Worker';
    
    // Get photo URL - check multiple possible locations
    String? photoUrl = _workerProfile?['photo_url'];
    if (photoUrl == null || photoUrl.isEmpty) {
      photoUrl = _workerProfile?['photo']?['url'];
    }
    if (photoUrl != null && photoUrl.isNotEmpty) {
      photoUrl = _getFullImageUrl(photoUrl);
    }
    
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WorkerProfilePage(
                  workerToken: _token,
                  currentWorker: _workerProfile,
                  onProfileUpdated: (updatedWorker) {
                    setState(() {
                      _workerProfile = updatedWorker;
                    });
                  },
                ),
              ),
            );
          },
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: photoUrl != null && photoUrl.isNotEmpty
                  ? null
                  : const LinearGradient(
                      colors: [kPrimary, Color(0xFF007B7D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: kPrimary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: photoUrl != null && photoUrl.isNotEmpty
                  ? Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      width: 50,
                      height: 50,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(
                          workerName.isNotEmpty ? workerName[0].toUpperCase() : 'W',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        workerName.isNotEmpty ? workerName[0].toUpperCase() : 'W',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                workerName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: kTextDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.work_outline,
            color: kPrimary,
            size: 22,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Courts',
            value: _totalCourts.toString(),
            icon: Icons.sports_tennis_rounded,
            color: kPrimary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkerCourtsPage(workerToken: _token),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _StatCard(
            title: 'Today',
            value: _todayReservations.toString(),
            icon: Icons.today_rounded,
            color: Colors.orange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkerUpcomingPage(workerToken: _token),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _StatCard(
            title: 'Pending',
            value: _pendingCount.toString(),
            icon: Icons.pending_actions_rounded,
            color: Colors.red,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkerReservationsPage(workerToken: _token),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
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
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: kTextDark,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.sports_tennis_rounded,
                  label: 'My Courts',
                  color: kPrimary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkerCourtsPage(workerToken: _token),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Icons.calendar_month_rounded,
                  label: 'Reservations',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkerReservationsPage(workerToken: _token),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Icons.today_rounded,
                  label: 'Today',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkerUpcomingPage(workerToken: _token),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySchedule() {
    final todayReservations = _upcomingReservations.where((r) {
      final date = r['booking_date_play']?.toString().split(' ')[0] ?? '';
      final today = DateTime.now().toString().split(' ')[0];
      return date == today;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Schedule",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: kTextDark,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WorkerUpcomingPage(workerToken: _token),
                    ),
                  );
                },
                child: const Text(
                  'View All',
                  style: TextStyle(color: kPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (todayReservations.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_busy_rounded, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'No reservations today',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: todayReservations.take(3).length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final res = todayReservations[i];
                return _ReservationTile(
                  reservation: res,
                  onTap: () {
                    // Navigate to reservation detail
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPendingReservations() {
    if (_pendingReservations.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pending Confirmations',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: kTextDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_pendingReservations.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _pendingReservations.take(3).length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final res = _pendingReservations[i];
              return _PendingReservationTile(
                reservation: res,
                onConfirm: () async {
                  try {
                    await WorkerService.confirmReservation(
                      token: _token,
                      reservationId: res['id'].toString(),
                    );
                    await _loadWorkerData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reservation confirmed!'),
                        backgroundColor: kGreen,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: kRed,
                      ),
                    );
                  }
                },
              );
            },
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
              onPressed: _loadWorkerData,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// STAT CARD
// ─────────────────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTION BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RESERVATION TILE - FIXED: using time_slot for time display
// ─────────────────────────────────────────────────────────────────────────────
class _ReservationTile extends StatelessWidget {
  final Map<String, dynamic> reservation;
  final VoidCallback onTap;

  const _ReservationTile({
    required this.reservation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final court = reservation['court'] ?? {};
    final player = reservation['player'] ?? {};
    final playerUser = player['player'] ?? {};
    final playerName = playerUser['username'] ?? player['nom'] ?? 'Player';
    
    // Get time from time_slot relation
    final timeSlot = reservation['time_slot'] ?? {};
    final startTime = timeSlot['startTime']?.toString() ?? '--:--';
    final endTime = timeSlot['endTime']?.toString() ?? '--:--';
    
    final status = reservation['booking_status'];

    Color statusColor = Colors.orange;
    String statusText = 'Pending';
    
    if (status == 'confirmed') {
      statusColor = kGreen;
      statusText = 'Confirmed';
    } else if (status == 'completed') {
      statusColor = Colors.blue;
      statusText = 'Completed';
    } else if (status == 'cancelled') {
      statusColor = Colors.red;
      statusText = 'Cancelled';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person_outline, color: kPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    court['name'] ?? 'Court',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: kTextDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$playerName • $startTime - $endTime',
                    style: const TextStyle(
                      fontSize: 11,
                      color: kTextMid,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PENDING RESERVATION TILE - FIXED: using time_slot for time display
// ─────────────────────────────────────────────────────────────────────────────
class _PendingReservationTile extends StatelessWidget {
  final Map<String, dynamic> reservation;
  final VoidCallback onConfirm;

  const _PendingReservationTile({
    required this.reservation,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final court = reservation['court'] ?? {};
    final player = reservation['player'] ?? {};
    final playerUser = player['player'] ?? {};
    final playerName = playerUser['username'] ?? player['nom'] ?? 'Player';
    
    // Get time from time_slot relation
    final timeSlot = reservation['time_slot'] ?? {};
    final startTime = timeSlot['startTime']?.toString() ?? '--:--';
    final endTime = timeSlot['endTime']?.toString() ?? '--:--';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.pending_actions_rounded, color: Colors.red),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  court['name'] ?? 'Court',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kTextDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$playerName • $startTime - $endTime',
                  style: const TextStyle(
                    fontSize: 11,
                    color: kTextMid,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onConfirm,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: kGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Confirm',
                    style: TextStyle(
                      fontSize: 11,
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
    );
  }
}