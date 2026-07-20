import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import 'box_cricket_booking_details_screen.dart';

class BoxCricketUpcomingBookingsScreen extends StatefulWidget {
  const BoxCricketUpcomingBookingsScreen({
    super.key,
    this.showBottomNav = true,
  });

  final bool showBottomNav;

  @override
  State<BoxCricketUpcomingBookingsScreen> createState() =>
      _BoxCricketUpcomingBookingsScreenState();
}

class _BoxCricketUpcomingBookingsScreenState
    extends State<BoxCricketUpcomingBookingsScreen> {
  int _tabIndex = 0;
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

  @override
  void initState() {
    super.initState();
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

    // Fetch all three tab statuses in parallel – single round-trip cost.
    const List<String> statuses = <String>['upcoming', 'completed', 'rejected'];
    final List<dynamic> results = await Future.wait<dynamic>(<Future<dynamic>>[
      safely(() => GroundWaleApi.instance.listBookings(groundId, status: statuses[0])),
      safely(() => GroundWaleApi.instance.listBookings(groundId, status: statuses[1])),
      safely(() => GroundWaleApi.instance.listBookings(groundId, status: statuses[2])),
      safely(() => GroundWaleApi.instance.getBookingSummary(groundId, status: statuses[0])),
      safely(() => GroundWaleApi.instance.getBookingSummary(groundId, status: statuses[1])),
      safely(() => GroundWaleApi.instance.getBookingSummary(groundId, status: statuses[2])),
    ]);

    if (!mounted) {
      return;
    }

    final bool anyError = results.every((dynamic r) => r == null);
    for (int i = 0; i < 3; i++) {
      _cachedBookings[i] =
          (results[i] as List<Map<String, dynamic>>?) ?? <Map<String, dynamic>>[];
      _cachedSummaries[i] =
          (results[i + 3] as Map<String, dynamic>?) ?? <String, dynamic>{};
    }

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
                      Expanded(child: _tabChip('Upcoming', 0)),
                      const SizedBox(width: 12),
                      Expanded(child: _tabChip('Complete', 1)),
                      const SizedBox(width: 12),
                      Expanded(child: _tabChip('Reject', 2)),
                    ],
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
    final int amount = _toInt(booking['amount']);

    final bool isRejected = status == 'cancelled' || _tabIndex == 2;
    final bool isCompleted = status == 'completed' || _tabIndex == 1;
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
                    ? 'Refund - $amount'
                    : paymentStatus == 'pending'
                    ? 'COD (Rs $amount)'
                    : 'Paid (Rs $amount)',
                style: TextStyle(
                  color: isRejected
                      ? const Color(0xFFE3220D)
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
              'Reason: ${booking['cancellationReason'] ?? 'Not Available'}',
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
            if (_tabIndex == 0)
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
            if (_tabIndex == 1)
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
