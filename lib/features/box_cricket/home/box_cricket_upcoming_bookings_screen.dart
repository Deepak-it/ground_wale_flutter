import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import 'box_cricket_booking_details_screen.dart';
import 'box_cricket_add_booking_screen.dart';
class BoxCricketUpcomingBookingsScreen extends StatefulWidget {
  const BoxCricketUpcomingBookingsScreen({
    super.key,
    this.showBottomNav = true,
    this.initialTabIndex = 1,
  });

  final bool showBottomNav;
  final int initialTabIndex;

  @override
  State<BoxCricketUpcomingBookingsScreen> createState() =>
      _BoxCricketUpcomingBookingsScreenState();
}

class _BoxCricketUpcomingBookingsScreenState
    extends State<BoxCricketUpcomingBookingsScreen> {
  int _tabIndex = 1;
  bool _isLoading = true;
  bool _hasLoadError = false;
  List<Map<String, dynamic>> _grounds = <Map<String, dynamic>>[];
  String? _selectedGroundId;
  List<Map<String, dynamic>> _bookings = <Map<String, dynamic>>[];
  Map<String, dynamic> _summary = <String, dynamic>{};

  // Per-tab caches – loaded once, switched locally without extra API calls.
  final Map<int, List<Map<String, dynamic>>> _cachedBookings =
      <int, List<Map<String, dynamic>>>{};
  final Map<int, Map<String, dynamic>> _cachedSummaries =
      <int, Map<String, dynamic>>{};

  String _bookingStatus(Map<String, dynamic> booking) {
    return (booking['bookingStatus']?.toString() ?? '').trim().toLowerCase();
  }

  List<Map<String, dynamic>> _dedupeByBookingId(
    List<Map<String, dynamic>> input,
  ) {
    final Map<String, Map<String, dynamic>> byId =
        <String, Map<String, dynamic>>{};
    final List<Map<String, dynamic>> withoutId = <Map<String, dynamic>>[];
    for (final Map<String, dynamic> booking in input) {
      final String id = booking['_id']?.toString() ?? '';
      if (id.isEmpty) {
        withoutId.add(booking);
        continue;
      }
      byId[id] = booking;
    }
    return <Map<String, dynamic>>[...byId.values, ...withoutId];
  }

  List<Map<String, dynamic>> _sanitizeForTab(
    int tab,
    List<Map<String, dynamic>> source,
  ) {
    return source.where((Map<String, dynamic> booking) {
      final String status = _bookingStatus(booking);
      if (tab == 0) {
        return status == 'pending';
      }
      if (tab == 1) {
        return status == 'confirmed';
      }
      if (tab == 2) {
        return status == 'completed';
      }
      return status == 'cancelled' || status == 'rejected';
    }).toList();
  }

  Map<String, dynamic> _summaryFromBookings(List<Map<String, dynamic>> bookings) {
    final int totalBookings = bookings.length;
    int totalRevenue = 0;
    for (final Map<String, dynamic> booking in bookings) {
      final String paymentStatus =
          (booking['paymentStatus']?.toString() ?? '').trim().toLowerCase();
      final String bookingStatus =
          (booking['bookingStatus']?.toString() ?? '').trim().toLowerCase();
      if (paymentStatus == 'paid' && bookingStatus != 'cancelled') {
        totalRevenue += _toInt(booking['amount']);
      }
    }
    return <String, dynamic>{
      'totalBookings': totalBookings,
      'totalRevenue': totalRevenue,
    };
  }

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTabIndex.clamp(0, 3);
    _load();
  }

  String _groundId(Map<String, dynamic> ground) {
    return ground['_id']?.toString() ?? ground['id']?.toString() ?? '';
  }

  String _groundName(Map<String, dynamic> ground) {
    final String name = ground['groundName']?.toString().trim() ?? '';
    if (name.isNotEmpty) {
      return name;
    }
    return 'Unnamed Ground';
  }

  Future<String?> _resolveGroundId() async {
    if (_selectedGroundId != null && _selectedGroundId!.isNotEmpty) {
      return _selectedGroundId;
    }

    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      return null;
    }

    final List<Map<String, dynamic>> grounds = await GroundWaleApi.instance
        .listGrounds(ownerId: ownerId);
    if (grounds.isEmpty) {
      return null;
    }

    final String preferred = ApiSession.instance.groundId ?? '';
    String selected = _groundId(grounds.first);
    if (preferred.isNotEmpty) {
      for (final Map<String, dynamic> ground in grounds) {
        if (_groundId(ground) == preferred) {
          selected = preferred;
          break;
        }
      }
    }

    if (mounted) {
      setState(() {
        _grounds = grounds;
        _selectedGroundId = selected;
      });
    }
    ApiSession.instance.setGroundId(selected);
    return selected;
  }

  Future<void> _load() async {
    final String? groundId = await _resolveGroundId();
    if (groundId == null || groundId.isEmpty) {
      if (mounted) {
        setState(() {
          _bookings = <Map<String, dynamic>>[];
          _summary = <String, dynamic>{};
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No grounds found for this owner.')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    // Helper: swallow individual call errors so one failure doesn't abort
    // the rest.
    Future<T?> safely<T>(Future<T> Function() fn) async {
      try {
        return await fn();
      } catch (_) {
        return null;
      }
    }

    // Fetch all tab statuses in parallel – includes both rejected/cancelled
    // so queue transitions are reflected immediately after actions.
    const List<String> statuses = <String>[
      'upcoming',
      'completed',
      'rejected',
      'cancelled',
    ];
    final List<dynamic> results = await Future.wait<dynamic>(<Future<dynamic>>[
      safely(() => GroundWaleApi.instance.listBookings(groundId, status: statuses[0])),
      safely(() => GroundWaleApi.instance.listBookings(groundId, status: statuses[1])),
      safely(() => GroundWaleApi.instance.listBookings(groundId, status: statuses[2])),
      safely(() => GroundWaleApi.instance.listBookings(groundId, status: statuses[3])),
      safely(() => GroundWaleApi.instance.getBookingSummary(groundId, status: statuses[0])),
      safely(() => GroundWaleApi.instance.getBookingSummary(groundId, status: statuses[1])),
      safely(() => GroundWaleApi.instance.getBookingSummary(groundId, status: statuses[2])),
      safely(() => GroundWaleApi.instance.getBookingSummary(groundId, status: statuses[3])),
    ]);

    if (!mounted) {
      return;
    }

    final bool anyError = results.every((dynamic r) => r == null);
    final List<Map<String, dynamic>> upcoming =
      (results[0] as List<Map<String, dynamic>>?) ?? <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> completed =
      (results[1] as List<Map<String, dynamic>>?) ?? <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> rejected =
      (results[2] as List<Map<String, dynamic>>?) ?? <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> cancelled =
      (results[3] as List<Map<String, dynamic>>?) ?? <Map<String, dynamic>>[];

    final List<Map<String, dynamic>> rejectedCombined = _dedupeByBookingId(
      <Map<String, dynamic>>[...rejected, ...cancelled],
    );

    _cachedBookings[0] = _sanitizeForTab(0, upcoming);
    _cachedBookings[1] = _sanitizeForTab(1, upcoming);
    _cachedBookings[2] = _sanitizeForTab(2, completed);
    _cachedBookings[3] = _sanitizeForTab(3, rejectedCombined);
    _cachedSummaries[0] = _summaryFromBookings(_cachedBookings[0]!);
    _cachedSummaries[1] = _summaryFromBookings(_cachedBookings[1]!);
    _cachedSummaries[2] = _summaryFromBookings(_cachedBookings[2]!);
    _cachedSummaries[3] = _summaryFromBookings(_cachedBookings[3]!);

    setState(() {
      _bookings = _cachedBookings[_tabIndex] ?? <Map<String, dynamic>>[];
      _summary = _cachedSummaries[_tabIndex] ?? <String, dynamic>{};
      _hasLoadError = anyError;
      _isLoading = false;
    });
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> items = _bookings;
    final int totalBookings = _toInt(_summary['totalBookings'] ?? items.length);
    final int totalRevenue = _toInt(_summary['totalRevenue']);

    return Scaffold(
      backgroundColor: const Color(0xFF1B1F1B),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF08B36A)),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: <Widget>[
                  const Text(
                    'Select Ground',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0x0AFFFFFF),
                      border: Border.all(color: const Color(0x1FFFFFFF)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedGroundId,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1B1F1B),
                        iconEnabledColor: const Color(0xCCFFFFFF),
                        hint: const Text(
                          'Choose ground',
                          style: TextStyle(color: Color(0x99FFFFFF)),
                        ),
                        items: _grounds.map((Map<String, dynamic> ground) {
                          final String id = _groundId(ground);
                          return DropdownMenuItem<String>(
                            value: id,
                            child: Text(
                              _groundName(ground),
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          if (value == null || value == _selectedGroundId) {
                            return;
                          }
                          setState(() => _selectedGroundId = value);
                          ApiSession.instance.setGroundId(value);
                          // Clear per-tab caches so the new ground's data is
                          // fetched fresh.
                          _cachedBookings.clear();
                          _cachedSummaries.clear();
                          _load();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(child: _tabChip('Request', 0)),
                      const SizedBox(width: 12),
                      Expanded(child: _tabChip('Upcoming', 1)),
                      const SizedBox(width: 12),
                      Expanded(child: _tabChip('Complete', 2)),
                      const SizedBox(width: 12),
                      Expanded(child: _tabChip('Reject', 3)),
                    ],
                  ),
Padding(
  padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
  child: SizedBox(
    width: double.infinity,
    height: 52,
    child: ElevatedButton.icon(
      onPressed: () async {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const BoxCricketAddBookingScreen(),
          ),
        );

        // Refresh bookings after returning
        _load(); // Replace with your refresh method
      },
      icon: const Icon(Icons.add),
      label: const Text(
        'Add Booking',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF08B36A),
        foregroundColor: const Color(0xFF1C333B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  ),
),                  
                  const SizedBox(height: 12),
                  Container(
                    height: 72,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0x08FFFFFF),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        _summaryBlock('Total Booking', '$totalBookings'),
                        _summaryBlock('Total Revenue', 'Rs $totalRevenue'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (items.isEmpty)
                    _emptyState()
                  else
                    ...items.map((Map<String, dynamic> booking) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _bookingCard(booking),
                      );
                    }),
                ],
              ),
      ),
      bottomNavigationBar: null,
    );
  }

  Widget _emptyState() {
    final String message = _hasLoadError
        ? 'Could not load bookings right now.'
        : 'No bookings found for this tab.';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0x08FFFFFF),
      ),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.event_note_rounded,
            color: Color(0x99FFFFFF),
            size: 30,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xCCFFFFFF),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabChip(String label, int index) {
    final bool selected = _tabIndex == index;
    return InkWell(
      onTap: () {
        if (_tabIndex == index) {
          return;
        }
        // Switch from the in-memory cache – no API call needed.
        setState(() {
          _tabIndex = index;
          _bookings = _cachedBookings[index] ?? <Map<String, dynamic>>[];
          _summary = _cachedSummaries[index] ?? <String, dynamic>{};
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: selected ? null : Border.all(color: const Color(0x1F1C333B)),
          color: selected ? const Color(0xFF08B36A) : const Color(0x0F1C333B),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: selected ? 16 : 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryBlock(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: Color(0x99FFFFFF),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _bookingCard(Map<String, dynamic> booking) {
    final String start = booking['startTime']?.toString() ?? '06:00 AM';
    final String end = booking['endTime']?.toString() ?? '07:00 AM';
    final String code = booking['bookingCode']?.toString() ?? '#BK-9821';
    final String team = booking['teamName']?.toString() ?? 'Team';
    final String captain = booking['captainName']?.toString() ?? '-';
    final String status = (booking['bookingStatus']?.toString() ?? '')
        .toLowerCase();
    final String paymentStatus = (booking['paymentStatus']?.toString() ?? '')
        .toLowerCase();
    final bool isRefunded = paymentStatus == 'refunded';
    final int amount = _toInt(booking['amount']);

    final bool isRejected = status == 'cancelled' || _tabIndex == 3;
    final bool isCompleted = status == 'completed' || _tabIndex == 2;
    final bool isPending = status == 'pending';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0x08FFFFFF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                '$start - $end',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                code.startsWith('#') ? code : '#$code',
                style: const TextStyle(
                  color: Color(0x99FFFFFF),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            team,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Captain: $captain',
            style: const TextStyle(
              color: Color(0x99FFFFFF),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: isRejected
                      ? const Color(0x14E3220D)
                      : isPending
                      ? const Color(0x1FF59E0B)
                      : const Color(0x3608B36A),
                ),
                child: Text(
                  isRejected
                      ? 'Reject'
                      : isPending
                      ? 'Pending'
                      : isCompleted
                      ? 'Confirmed'
                      : 'Confirmed',
                  style: TextStyle(
                    color: isRejected
                        ? const Color(0xFFE3220D)
                        : isPending
                        ? Colors.white
                        : const Color(0xFF08B36A),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                isRejected
                  ? isRefunded
                    ? 'Refunded (Rs $amount)'
                    : 'Cancelled (Rs $amount)'
                    : paymentStatus == 'pending'
                    ? 'COD (Rs $amount)'
                    : 'Paid (Rs $amount)',
                style: TextStyle(
                  color: isRejected
                    ? isRefunded
                      ? const Color(0xFF60A5FA)
                      : const Color(0xFFE3220D)
                      : paymentStatus == 'pending'
                      ? Colors.white
                      : const Color(0xFF08B36A),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (isRejected) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              'Reason: ${booking['refundReason'] ?? booking['cancellationReason'] ?? 'Not Available'}',
              style: const TextStyle(
                color: Color(0x99FFFFFF),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else ...<Widget>[
            const SizedBox(height: 10),
            Container(height: 1, color: const Color(0x33FFFFFF)),
            const SizedBox(height: 10),
            if (_tabIndex == 0 || _tabIndex == 1)
              Row(
                children: <Widget>[
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        final String phone =
                            booking['captainPhone']?.toString() ?? '';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              phone.isEmpty
                                  ? 'Captain phone not available.'
                                  : 'Captain: $phone',
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0x1F08B36A),
                        ),
                        child: const Center(
                          child: Text(
                            'Call Captain',
                            style: TextStyle(
                              color: Color(0xFF08B36A),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final String bookingId =
                            booking['_id']?.toString() ?? '';
                        if (bookingId.isEmpty) {
                          return;
                        }
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => BoxCricketBookingDetailsScreen(
                              bookingId: bookingId,
                            ),
                          ),
                        );
                        _load();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0x0AFFFFFF),
                        ),
                        child: const Center(
                          child: Text(
                            'View Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            if (_tabIndex == 2)
              Container(
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0x1F08B36A),
                ),
                child: const Center(
                  child: Text(
                    'Completed',
                    style: TextStyle(
                      color: Color(0xFF08B36A),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
