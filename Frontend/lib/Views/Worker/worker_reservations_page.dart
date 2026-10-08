// lib/Views/Worker/worker_reservations_page.dart
// Worker can: confirm | reject | complete | cancel (approve player's cancel request)
// Each action sends a notification to the player via the backend.
// cancel_requested reservations are highlighted with the player's reason.
// NEW: Player phone number is displayed in the reservation card.

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Core/Constants/api_constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ─────────────────────────────────────────────────────────────────────────────
// STATUS HELPERS
// ─────────────────────────────────────────────────────────────────────────────
Color _statusColor(String status) {
  switch (status) {
    case 'pending':          return const Color(0xFFF59E0B);
    case 'confirmed':        return const Color(0xFF16A34A);
    case 'completed':        return const Color(0xFF3B82F6);
    case 'cancelled':        return const Color(0xFFDC2626);
    case 'rejected':         return const Color(0xFFDC2626);
    case 'cancel_requested': return const Color(0xFFF97316);
    default:                 return const Color(0xFF6B7280);
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'pending':          return 'Pending';
    case 'confirmed':        return 'Confirmed';
    case 'completed':        return 'Completed';
    case 'cancelled':        return 'Cancelled';
    case 'rejected':         return 'Rejected';
    case 'cancel_requested': return 'Cancel Requested';
    default:                 return status;
  }
}

IconData _statusIcon(String status) {
  switch (status) {
    case 'pending':          return Icons.hourglass_top_rounded;
    case 'confirmed':        return Icons.check_circle_rounded;
    case 'completed':        return Icons.sports_score_rounded;
    case 'cancelled':        return Icons.cancel_rounded;
    case 'rejected':         return Icons.block_rounded;
    case 'cancel_requested': return Icons.pending_actions_rounded;
    default:                 return Icons.info_outline_rounded;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────────────────────
class WorkerReservationsPage extends StatefulWidget {
  final String? workerToken;
  const WorkerReservationsPage({super.key, this.workerToken});
  @override State<WorkerReservationsPage> createState() => _WorkerReservationsPageState();
}

class _WorkerReservationsPageState extends State<WorkerReservationsPage>
    with SingleTickerProviderStateMixin {
  String? _token;
  bool    _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _all      = [];
  List<Map<String, dynamic>> _filtered = [];

  String _selectedStatus = 'all';
  String _searchQuery    = '';
  late TabController _tabCtrl;

  static const _statusFilters = [
    'all', 'cancel_requested', 'pending', 'confirmed', 'completed', 'cancelled', 'rejected',
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _init();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _init() async {
    try {
      _token = widget.workerToken ?? await const FlutterSecureStorage().read(key: 'jwt_token');
      if (_token == null || _token!.isEmpty) {
        setState(() { _error = 'Not authenticated. Please login again.'; _isLoading = false; });
        return;
      }
      await _load();
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      // Use the general /reservations endpoint — controller filters by worker's courts
      final res = await http.get(
        Uri.parse(
          '${ApiConstants.reservations}'
          '?populate[court][populate][court_img]=*'
          '&populate[court][populate][photos]=*'
          '&populate[court][populate][venue]=*'
          '&populate[player][populate][player]=*'
          '&populate[time_slot]=*'
          '&sort=booking_date_play:desc',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        // Handle both { data: [...] } and plain list
        final raw  = body['data'] ?? body;
        final List<dynamic> list = raw is List ? raw : [];

        final reservations = list.map((item) {
          // Flatten Strapi v4 { id, attributes } structure if present
          if (item is Map && item['attributes'] != null) {
            final flat = Map<String, dynamic>.from(item['attributes'] as Map);
            flat['id'] = item['id'];
            return flat;
          }
          return Map<String, dynamic>.from(item as Map);
        }).toList();

        setState(() { _all = reservations; _applyFilters(); _isLoading = false; });
      } else {
        final err = json.decode(res.body);
        throw Exception(err['error']?['message'] ?? 'Failed to load reservations');
      }
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception:', '').trim(); _isLoading = false; });
    }
  }

  void _applyFilters() {
    var list = List<Map<String, dynamic>>.from(_all);

    if (_selectedStatus != 'all') {
      list = list.where((r) => r['booking_status'] == _selectedStatus).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((r) {
        final court     = r['court'] is Map ? r['court'] as Map : {};
        final player    = r['player'] is Map ? r['player'] as Map : {};
        final playerUser = player['player'] is Map ? player['player'] as Map : {};
        return (court['name']?.toString().toLowerCase().contains(q) ?? false)
            || (r['booking_reference']?.toString().toLowerCase().contains(q) ?? false)
            || (playerUser['username']?.toString().toLowerCase().contains(q) ?? false)
            || (player['nom']?.toString().toLowerCase().contains(q) ?? false);
      }).toList();
    }

    // Sort: cancel_requested first so worker sees them immediately
    list.sort((a, b) {
      const priority = {'cancel_requested': 0, 'pending': 1, 'confirmed': 2, 'completed': 3, 'rejected': 4, 'cancelled': 5};
      final pa = priority[a['booking_status']] ?? 9;
      final pb = priority[b['booking_status']] ?? 9;
      if (pa != pb) return pa.compareTo(pb);
      // Then by date desc
      return (b['booking_date_play']?.toString() ?? '').compareTo(a['booking_date_play']?.toString() ?? '');
    });

    setState(() => _filtered = list);
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _doAction(String reservationId, String action, {String? reason}) async {
    final url = switch (action) {
      'confirm'  => ApiConstants.confirmReservation(reservationId),
      'reject'   => ApiConstants.rejectReservation(reservationId),
      'cancel'   => ApiConstants.cancelReservation(reservationId),
      'complete' => ApiConstants.completeReservation(reservationId),
      _          => throw Exception('Unknown action: $action'),
    };

    final body = (action == 'reject' && reason != null)
        ? json.encode({'reason': reason})
        : null;

    final res = await http.put(
      Uri.parse(url),
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: body,
    );

    if (res.statusCode != 200) {
      final err = json.decode(res.body);
      throw Exception(err['error']?['message'] ?? err['message'] ?? 'Action failed');
    }
  }

  Future<void> _handleAction(Map<String, dynamic> reservation, String action) async {
    final id     = reservation['id']?.toString() ?? '';
    final status = reservation['booking_status'] as String? ?? '';

    // Guard: which actions are allowed in which states
    final allowed = switch (action) {
      'confirm'  => status == 'pending',
      'reject'   => ['pending', 'confirmed'].contains(status),
      'cancel'   => ['pending', 'confirmed', 'cancel_requested'].contains(status),
      'complete' => status == 'confirmed',
      _          => false,
    };

    if (!allowed) {
      _snack('Cannot $action a "$status" reservation', kRed);
      return;
    }

    // Confirm dialog — for reject ask for a reason
    String? rejectReason;
    if (action == 'reject') {
      rejectReason = await _showRejectReasonDialog();
      if (rejectReason == null) return; // cancelled
    } else {
      final label = switch (action) {
        'confirm'  => 'confirm',
        'cancel'   => 'approve this cancellation request',
        'complete' => 'mark as completed',
        _          => action,
      };
      final confirmed = await _showConfirmDialog(
        title:   _actionTitle(action),
        message: 'Are you sure you want to $label this reservation?'
            + (action == 'cancel' && status == 'cancel_requested'
                ? '\n\nThis will free the time slot for other players.' : ''),
        actionColor: _actionColor(action),
      );
      if (confirmed != true) return;
    }

    try {
      await _doAction(id, action, reason: rejectReason);
      _snack(_successMsg(action), kGreen);
      await _load();
    } catch (e) {
      _snack('Error: ${e.toString().replaceAll('Exception:', '').trim()}', kRed);
    }
  }

  String _actionTitle(String a) => switch (a) {
    'confirm'  => 'Confirm Reservation',
    'reject'   => 'Reject Reservation',
    'cancel'   => 'Approve Cancellation',
    'complete' => 'Mark as Completed',
    _          => a,
  };

  Color _actionColor(String a) => switch (a) {
    'confirm'  => kGreen,
    'complete' => Colors.blue,
    'reject'   => kRed,
    'cancel'   => const Color(0xFFF97316),
    _          => kPrimary,
  };

  String _successMsg(String a) => switch (a) {
    'confirm'  => 'Reservation confirmed! Player has been notified.',
    'reject'   => 'Reservation rejected. Player has been notified.',
    'cancel'   => 'Cancellation approved. Time slot is now available.',
    'complete' => 'Reservation marked as completed.',
    _          => 'Done.',
  };

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required Color actionColor,
  }) => showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      content: Text(message, style: const TextStyle(fontSize: 13, height: 1.5)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Back', style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(backgroundColor: actionColor, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.w700))),
      ],
    ),
  );

  Future<String?> _showRejectReasonDialog() async {
    final ctrl     = TextEditingController();
    String? reason;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(builder: (_, setInner) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reject Reservation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Reason for rejection (optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextMid)),
          const SizedBox(height: 8),
          TextField(
            controller: ctrl,
            maxLines: 3, minLines: 2,
            onChanged: (v) => setInner(() => reason = v.trim()),
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'e.g. Court is under maintenance…',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
              filled: true, fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kRed, width: 1.5)),
              contentPadding: const EdgeInsets.all(12)),
          ),
        ]),
        actions: [
          TextButton(onPressed: () { reason = null; Navigator.pop(ctx); },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: kRed, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w700))),
        ],
      )),
    );
    ctrl.dispose();
    // Return empty string if no reason given (API accepts it)
    return reason ?? '';
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBg,
    appBar: AppBar(
      title: const Text('Reservations', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kTextDark)),
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: kTextDark), onPressed: () => Navigator.pop(context)),
      actions: [
        IconButton(icon: const Icon(Icons.refresh_rounded, color: kPrimary), onPressed: _load),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Container(
            height: 40,
            decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(12)),
            child: TextField(
              onChanged: (v) { setState(() => _searchQuery = v); _applyFilters(); },
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search court, reference, player…',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search_rounded, size: 18, color: Colors.grey[400]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 11)),
            ),
          ),
        ),
      ),
    ),
    body: Column(children: [
      // ── Status filter chips ──────────────────────────────────────────────
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _statusFilters.map((s) {
              final isSel   = _selectedStatus == s;
              final color   = s == 'all' ? kPrimary : _statusColor(s);
              final count   = s == 'all' ? _all.length : _all.where((r) => r['booking_status'] == s).length;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () { setState(() => _selectedStatus = s); _applyFilters(); },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSel ? color : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSel ? color : Colors.grey.shade300)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(
                        s == 'all' ? 'All' : _statusLabel(s),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                            color: isSel ? Colors.white : Colors.grey[600])),
                      if (count > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: isSel ? Colors.white.withOpacity(0.3) : color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10)),
                          child: Text('$count', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                              color: isSel ? Colors.white : color))),
                      ],
                    ],
                  ),
                ),
              ));
            }).toList(),
          ),
        ),
      ),

      // Result count
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Row(children: [
          Text('${_filtered.length} reservation${_filtered.length == 1 ? '' : 's'}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
          const Spacer(),
          if (_selectedStatus == 'cancel_requested' || _all.any((r) => r['booking_status'] == 'cancel_requested'))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFF97316).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.pending_actions_rounded, size: 11, color: Color(0xFFF97316)),
                const SizedBox(width: 4),
                Text(
                  '${_all.where((r) => r['booking_status'] == 'cancel_requested').length} cancel requests',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFF97316))),
              ])),
        ]),
      ),

      // ── List ─────────────────────────────────────────────────────────────
      Expanded(child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : _error != null
              ? _buildError()
              : _filtered.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _ReservationCard(
                          reservation: _filtered[i],
                          onAction: (action) => _handleAction(_filtered[i], action),
                        ),
                      ),
                    )),
    ]),
  );

  Widget _buildError() => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.error_outline, size: 64, color: kRed),
    const SizedBox(height: 16),
    Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: kTextMid)),
    const SizedBox(height: 24),
    ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: kPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: const Text('Retry', style: TextStyle(color: Colors.white))),
  ])));

  Widget _buildEmpty() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey[300]),
    const SizedBox(height: 16),
    Text(_selectedStatus == 'all' && _searchQuery.isEmpty ? 'No reservations yet' : 'No reservations found',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.grey[600])),
    const SizedBox(height: 8),
    Text(_selectedStatus == 'all' && _searchQuery.isEmpty
        ? 'Reservations appear here once players book your courts'
        : 'Try changing your filters',
        textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
  ]));
}

// ─────────────────────────────────────────────────────────────────────────────
// RESERVATION CARD
// ─────────────────────────────────────────────────────────────────────────────
class _ReservationCard extends StatelessWidget {
  final Map<String, dynamic> reservation;
  final Future<void> Function(String action) onAction;

  const _ReservationCard({required this.reservation, required this.onAction});

  String _courtImg() {
    final court = reservation['court'] is Map ? reservation['court'] as Map : {};
    String build(String? p) {
      if (p == null || p.isEmpty) return '';
      if (p.startsWith('http')) return p;
      return '${ApiConstants.mediaBaseUrl}$p';
    }
    if (court['court_img_url']?.toString().isNotEmpty == true) return build(court['court_img_url'].toString());
    if (court['court_img'] is Map) return build((court['court_img'] as Map)['url']?.toString());
    if (court['photos_urls'] is List && (court['photos_urls'] as List).isNotEmpty) return build((court['photos_urls'] as List)[0].toString());
    if (court['photos'] is List && (court['photos'] as List).isNotEmpty) {
      final f = (court['photos'] as List)[0];
      if (f is Map) return build(f['url']?.toString());
    }
    return '';
  }

  String _getPlayerPhone() {
    final player = reservation['player'] is Map ? reservation['player'] as Map : {};
    final playerUser = player['player'] is Map ? player['player'] as Map : {};
    
    // Try to get phone from playerUser first, then from player profile
    final phone = playerUser['phone']?.toString() ?? player['phone']?.toString();
    if (phone != null && phone.isNotEmpty) return phone;
    return 'No phone number';
  }

  @override
  Widget build(BuildContext context) {
    final court      = reservation['court'] is Map ? reservation['court'] as Map : {};
    final player     = reservation['player'] is Map ? reservation['player'] as Map : {};
    final playerUser = player['player'] is Map ? player['player'] as Map : {};
    final timeSlot   = reservation['time_slot'] is Map ? reservation['time_slot'] as Map : {};

    final courtName  = court['name']?.toString() ?? 'Court';
    final venueName  = (court['venue'] is Map ? (court['venue'] as Map)['name']?.toString() : null) ?? '';
    final playerName = playerUser['username']?.toString() ?? player['nom']?.toString() ?? 'Player';
    final playerPhone = _getPlayerPhone();
    final date       = reservation['booking_date_play']?.toString().split('T')[0] ?? '';
    final startTime  = timeSlot['startTime']?.toString() ?? reservation['start_time']?.toString() ?? '--:--';
    final endTime    = timeSlot['endTime']?.toString() ?? reservation['end_time']?.toString() ?? '--:--';
    final price      = reservation['total_price'] ?? 0;
    final reference  = reservation['booking_reference']?.toString() ?? '';
    final status     = reservation['booking_status']?.toString() ?? 'pending';
    final cancelReason = reservation['cancellation_reason']?.toString();
    final imgUrl     = _courtImg();

    final sc   = _statusColor(status);
    final isCR = status == 'cancel_requested';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isCR ? Border.all(color: const Color(0xFFF97316), width: 1.5) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isCR ? 0.08 : 0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Court image + status ──────────────────────────────────────────
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Stack(children: [
            imgUrl.isNotEmpty
                ? Image.network(imgUrl, height: 120, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                    loadingBuilder: (_, child, p) => p == null ? child
                        : Container(height: 120, color: kPrimary.withOpacity(0.08),
                            child: const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary)))))
                : _placeholder(),

            // Status badge
            Positioned(top: 10, right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: sc.withOpacity(0.92), borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: sc.withOpacity(0.4), blurRadius: 6)]),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_statusIcon(status), size: 11, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(_statusLabel(status), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                ]))),

            // "Cancel Requested" banner on image
            if (isCR)
              Positioned(top: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  color: const Color(0xFFF97316).withOpacity(0.9),
                  child: Row(children: [
                    const Icon(Icons.pending_actions_rounded, size: 13, color: Colors.white),
                    const SizedBox(width: 6),
                    const Text('Player requested cancellation', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                  ]))),
          ]),
        ),

        // ── Body ─────────────────────────────────────────────────────────
        Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Court + venue
          Text(courtName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kTextDark), maxLines: 1, overflow: TextOverflow.ellipsis),
          if (venueName.isNotEmpty) ...[
            const SizedBox(height: 2),
            Row(children: [Icon(Icons.location_on_rounded, size: 12, color: Colors.grey[400]), const SizedBox(width: 3),
              Text(venueName, style: TextStyle(fontSize: 11, color: Colors.grey[500]))]),
          ],
          const SizedBox(height: 8),

          // Player + phone + date + time
          Wrap(spacing: 14, runSpacing: 4, children: [
            _Chip(Icons.person_outline_rounded, playerName),
            _Chip(Icons.phone_rounded, playerPhone, color: Colors.blue),
            _Chip(Icons.calendar_today_rounded, date),
            _Chip(Icons.schedule_rounded, '$startTime – $endTime'),
            _Chip(Icons.attach_money_rounded, '$price DT', color: kPrimary),
          ]),
          const SizedBox(height: 8),

          // Reference
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(8)),
            child: Text('Ref: $reference', style: TextStyle(fontSize: 10, color: Colors.grey[500]))),

          // ── Cancellation reason card (cancel_requested) ────────────────
          if (isCR) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF97316).withOpacity(0.4))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFF97316)),
                  SizedBox(width: 6),
                  Text('Player\'s cancellation reason', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFF97316))),
                ]),
                const SizedBox(height: 6),
                Text(
                  (cancelReason != null && cancelReason.isNotEmpty) ? cancelReason : 'No reason provided',
                  style: TextStyle(fontSize: 12, color: Colors.orange[800], height: 1.4)),
              ])),
          ],

          // ── Action buttons ─────────────────────────────────────────────
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 12),
          _buildActions(status),
        ])),
      ]),
    );
  }

  Widget _buildActions(String status) {
    // Which buttons to show per status
    switch (status) {
      case 'pending':
        return Row(children: [
          Expanded(child: _ActionBtn('Confirm', Icons.check_rounded, kGreen, () => onAction('confirm'))),
          const SizedBox(width: 8),
          Expanded(child: _ActionBtn('Reject', Icons.block_rounded, kRed, () => onAction('reject'), outlined: true)),
        ]);

      case 'confirmed':
        return Row(children: [
          Expanded(child: _ActionBtn('Complete', Icons.sports_score_rounded, Colors.blue, () => onAction('complete'))),
          const SizedBox(width: 8),
          Expanded(child: _ActionBtn('Reject', Icons.block_rounded, kRed, () => onAction('reject'), outlined: true)),
        ]);

      case 'cancel_requested':
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _ActionBtn('Approve Cancellation', Icons.check_circle_outline_rounded,
              const Color(0xFFF97316), () => onAction('cancel')),
          const SizedBox(height: 8),
          _ActionBtn('Deny — Keep Reservation', Icons.undo_rounded,
              kPrimary, () => onAction('confirm'), outlined: true),
        ]);

      default:
        // cancelled / rejected / completed — no actions
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(10)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(_statusIcon(status), size: 14, color: _statusColor(status)),
            const SizedBox(width: 6),
            Text('Reservation is ${_statusLabel(status).toLowerCase()}',
                style: TextStyle(fontSize: 12, color: _statusColor(status), fontWeight: FontWeight.w600)),
          ]));
    }
  }

  Widget _placeholder() => Container(height: 120, width: double.infinity,
    color: kPrimary.withOpacity(0.08), child: const Center(child: Icon(Icons.stadium_rounded, size: 40, color: kPrimary)));
}

// ─────────────────────────────────────────────────────────────────────────────
// SMALL WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final IconData icon; final String label; final Color? color;
  const _Chip(this.icon, this.label, {this.color});
  @override Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 12, color: color ?? Colors.grey[500]),
    const SizedBox(width: 4),
    Text(label, style: TextStyle(fontSize: 11, color: color ?? kTextMid, fontWeight: color != null ? FontWeight.w600 : FontWeight.w400)),
  ]);
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool outlined;

  const _ActionBtn(this.label, this.icon, this.color, this.onTap, {this.outlined = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color,
        borderRadius: BorderRadius.circular(12),
        border: outlined ? Border.all(color: color, width: 1.5) : null,
        boxShadow: outlined ? null : [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 15, color: outlined ? color : Colors.white),
        const SizedBox(width: 6),
        Flexible(child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
            color: outlined ? color : Colors.white), overflow: TextOverflow.ellipsis)),
      ]),
    ),
  );
}















/*// lib/Views/Worker/worker_reservations_page.dart

import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Core/Constants/api_constants.dart';
import 'package:sporta/Services/worker_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class WorkerReservationsPage extends StatefulWidget {
  final String? workerToken;
  const WorkerReservationsPage({super.key, this.workerToken});

  @override
  State<WorkerReservationsPage> createState() => _WorkerReservationsPageState();
}

class _WorkerReservationsPageState extends State<WorkerReservationsPage>
    with SingleTickerProviderStateMixin {
  late String _token;
  bool _isLoading = true;
  String? _error;
  List<dynamic> _reservations = [];
  List<dynamic> _filteredReservations = [];
  
  late TabController _tabController;
  String _selectedStatus = 'all';
  String _searchQuery = '';
  
  final List<String> _statusFilters = ['all', 'pending', 'confirmed', 'completed', 'cancelled'];

  String _getFullImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '${ApiConstants.mediaBaseUrl}$url';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      final reservations = await WorkerService.getMyReservations(_token);
      setState(() {
        _reservations = reservations;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<dynamic> filtered = List.from(_reservations);
    
    // Apply status filter
    if (_selectedStatus != 'all') {
      filtered = filtered.where((r) {
        return r['booking_status'] == _selectedStatus;
      }).toList();
    }
    
    // Apply search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((r) {
        final courtName = r['court']?['name']?.toString().toLowerCase() ?? '';
        final reference = r['booking_reference']?.toString().toLowerCase() ?? '';
        final player = r['player']?['player']?['username']?.toString().toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        
        return courtName.contains(query) ||
               reference.contains(query) ||
               player.contains(query);
      }).toList();
    }
    
    setState(() {
      _filteredReservations = filtered;
    });
  }

  void _updateStatusFilter(String status) {
    setState(() {
      _selectedStatus = status;
      _applyFilters();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  String _getStatusColor(String status) {
    switch (status) {
      case 'pending': return '#F59E0B';
      case 'confirmed': return '#16A34A';
      case 'completed': return '#3B82F6';
      case 'cancelled': return '#DC2626';
      default: return '#6B7280';
    }
  }

  String _getStatusIcon(String status) {
    switch (status) {
      case 'pending': return '⏳';
      case 'confirmed': return '✅';
      case 'completed': return '✓';
      case 'cancelled': return '❌';
      default: return '📋';
    }
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
        title: const Text(
          'Reservations',
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search by court, reference, or player...',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.search_rounded, size: 18, color: Colors.grey[400]),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            setState(() {
                              _searchQuery = '';
                              _applyFilters();
                            });
                          },
                          child: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Status Filter Chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statusFilters.map((status) {
                  final isSelected = _selectedStatus == status;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : kTextMid,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (_) => _updateStatusFilter(status),
                      backgroundColor: Colors.white,
                      selectedColor: _getStatusColor(status) == '#F59E0B' 
                          ? kOrange 
                          : (_getStatusColor(status) == '#16A34A' 
                              ? kGreen 
                              : (_getStatusColor(status) == '#3B82F6'
                                  ? Colors.blue
                                  : (_getStatusColor(status) == '#DC2626'
                                      ? kRed
                                      : kPrimary))),
                      shape: StadiumBorder(
                        side: BorderSide(
                          color: isSelected ? Colors.transparent : Colors.grey[300]!,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          // Results Count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredReservations.length} reservations found',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Reservations List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: kPrimary))
                : _error != null
                    ? _buildErrorWidget()
                    : _filteredReservations.isEmpty
                        ? _buildEmptyWidget()
                        : RefreshIndicator(
                            onRefresh: _loadReservations,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredReservations.length,
                              itemBuilder: (context, index) {
                                final reservation = _filteredReservations[index];
                                return _ReservationCard(
                                  reservation: reservation,
                                  token: _token,
                                  getFullImageUrl: _getFullImageUrl,
                                  onStatusChanged: _loadReservations,
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

  Widget _buildEmptyWidget() {
    String message = 'No reservations found';
    String subMessage = 'Try changing your filters';
    
    if (_selectedStatus == 'all' && _searchQuery.isEmpty) {
      message = 'No reservations yet';
      subMessage = 'Reservations will appear here once players book your courts';
    }
    
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
            message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subMessage,
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
// RESERVATION CARD
// ─────────────────────────────────────────────────────────────────────────────
class _ReservationCard extends StatefulWidget {
  final Map<String, dynamic> reservation;
  final String token;
  final String Function(String?) getFullImageUrl;
  final VoidCallback onStatusChanged;

  const _ReservationCard({
    required this.reservation,
    required this.token,
    required this.getFullImageUrl,
    required this.onStatusChanged,
  });

  @override
  State<_ReservationCard> createState() => _ReservationCardState();
}

class _ReservationCardState extends State<_ReservationCard> {
  bool _isProcessing = false;

  String _getCourtImageUrl() {
    final court = widget.reservation['court'] ?? {};
    
    // Priority order for image URL
    if (court['court_img_url'] != null && court['court_img_url'].toString().isNotEmpty) {
      return widget.getFullImageUrl(court['court_img_url'].toString());
    }
    if (court['court_img'] != null && court['court_img']['url'] != null) {
      return widget.getFullImageUrl(court['court_img']['url'].toString());
    }
    if (court['photos_urls'] != null && court['photos_urls'] is List && court['photos_urls'].isNotEmpty) {
      return widget.getFullImageUrl(court['photos_urls'][0].toString());
    }
    if (court['photos'] != null && court['photos'] is List && court['photos'].isNotEmpty) {
      final firstPhoto = court['photos'][0];
      if (firstPhoto is Map && firstPhoto['url'] != null) {
        return widget.getFullImageUrl(firstPhoto['url'].toString());
      }
    }
    return '';
  }

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
            backgroundColor: kGreen,
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
            backgroundColor: kRed,
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
            style: ElevatedButton.styleFrom(backgroundColor: kRed),
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
            backgroundColor: kGreen,
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
            backgroundColor: kRed,
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
    final bookingDate = reservation['booking_date_play']?.toString().split(' ')[0] ?? 'Unknown date';
    
    // Get time from time_slot relation
    final timeSlot = reservation['time_slot'] ?? {};
    final startTime = timeSlot['startTime']?.toString() ?? '--:--';
    final endTime = timeSlot['endTime']?.toString() ?? '--:--';
    
    final totalPrice = reservation['total_price'] ?? 0;
    final reference = reservation['booking_reference'] ?? '';
    final status = reservation['booking_status'];
    final paymentMethod = reservation['payment_method'] ?? 'pay_at_venue';
    final courtImageUrl = _getCourtImageUrl();

    Color statusColor;
    String statusText;
    
    switch (status) {
      case 'pending':
        statusColor = kOrange;
        statusText = 'Pending';
        break;
      case 'confirmed':
        statusColor = kGreen;
        statusText = 'Confirmed';
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusText = 'Completed';
        break;
      case 'cancelled':
        statusColor = kRed;
        statusText = 'Cancelled';
        break;
      default:
        statusColor = Colors.grey;
        statusText = status ?? 'Unknown';
    }

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
          // Court Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: courtImageUrl.isNotEmpty
                ? Stack(
                    children: [
                      Image.network(
                        courtImageUrl,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 120,
                            color: kPrimary.withOpacity(0.08),
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
                      ),
                      // Status Badge on Image
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
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
                    ],
                  )
                : _buildImagePlaceholder(),
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
                    color: kTextDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                
                // Player and Date
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      playerName,
                      style: const TextStyle(fontSize: 11, color: kTextMid),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.calendar_today_rounded, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      bookingDate,
                      style: const TextStyle(fontSize: 11, color: kTextMid),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                
                // Time (from time_slot)
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '$startTime - $endTime',
                      style: const TextStyle(fontSize: 11, color: kTextMid),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.attach_money_rounded, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '$totalPrice DT',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: kPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Reference
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: kBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Ref: $reference',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                      fontFamily: 'monospace',
                    ),
                  ),
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
                            backgroundColor: kGreen,
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
                            side: const BorderSide(color: kRed),
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
    return Container(
      height: 120,
      width: double.infinity,
      color: kPrimary.withOpacity(0.08),
      child: const Center(
        child: Icon(
          Icons.stadium_rounded,
          size: 40,
          color: kPrimary,
        ),
      ),
    );
  }
}*/