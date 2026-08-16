import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import '../../../core/utils/sport_icons_util.dart' as sport_icons_util;

class SportsNeoBookingHistoryScreen extends StatefulWidget {
  const SportsNeoBookingHistoryScreen({super.key});

  @override
  State<SportsNeoBookingHistoryScreen> createState() =>
      _SportsNeoBookingHistoryScreenState();
}

class _SportsNeoBookingHistoryScreenState
    extends State<SportsNeoBookingHistoryScreen> {
  final GroundWaleApi _api = GroundWaleApi.instance;

  bool _isLoading = true;
  List<_UserBookingItem> _bookings = <_UserBookingItem>[];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final String contact = ApiSession.instance.contactNumber?.trim() ?? '';
    final String ownerName =
        ApiSession.instance.ownerName?.trim().toLowerCase() ?? '';

    if (contact.isEmpty && ownerName.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _bookings = <_UserBookingItem>[];
        _isLoading = false;
      });
      return;
    }

    try {
      final List<Map<String, dynamic>> grounds = await _api.listGrounds();
      final List<Future<List<_UserBookingItem>>> jobs =
          <Future<List<_UserBookingItem>>>[];

      for (final Map<String, dynamic> ground in grounds) {
        final String groundId =
            ground['_id']?.toString() ?? ground['id']?.toString() ?? '';
        if (groundId.isEmpty) {
          continue;
        }

        jobs.add(_loadBookingsForGround(ground, groundId, contact, ownerName));
      }

      final List<List<_UserBookingItem>> chunks = await Future.wait(jobs);
      final List<_UserBookingItem> merged = chunks.expand((e) => e).toList();
      merged.sort((a, b) => b.sortTime.compareTo(a.sortTime));

      if (!mounted) {
        return;
      }

      setState(() {
        _bookings = merged;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _bookings = <_UserBookingItem>[];
        _isLoading = false;
      });
    }
  }
Future<List<_UserBookingItem>> _loadBookingsForGround(
  Map<String, dynamic> ground,
  String groundId,
  String contact,
  String ownerName,
) async {
  try {
    final List<Map<String, dynamic>> bookings =
        await _api.listBookings(groundId);

    final String groundName =
        ground['groundName']?.toString() ??
        ground['name']?.toString() ??
        'Ground';

    final String location =
        ground['city']?.toString() ??
        ground['location']?.toString() ??
        ground['address']?.toString() ??
        'Location unavailable';

    final String groundSport = _extractGroundSport(ground);

    return bookings
        .where(
          (Map<String, dynamic> booking) => _isUserBooking(
            booking,
            contact: contact,
            ownerName: ownerName,
          ),
        )
        .map(
          (Map<String, dynamic> booking) => _UserBookingItem.fromMaps(
            booking: booking,
            groundName: groundName,
            location: location,
            groundSport: groundSport,
          ),
        )
        .toList();
  } catch (_) {
    return <_UserBookingItem>[];
  }
}

String _extractGroundSport(Map<String, dynamic> ground) {
  final dynamic sports = ground['sports'];

  if (sports is List && sports.isNotEmpty) {
    for (final dynamic value in sports) {
      final String sport = value.toString().trim();

      if (sport.isNotEmpty) {
        return sport;
      }
    }
  }

  final String sport =
      ground['sport']?.toString().trim() ?? '';

  if (sport.isNotEmpty) {
    return sport;
  }

  final String sportName =
      ground['sportName']?.toString().trim() ?? '';

  if (sportName.isNotEmpty) {
    return sportName;
  }

  return 'Sport';
}

  bool _isUserBooking(
    Map<String, dynamic> booking, {
    required String contact,
    required String ownerName,
  }) {
    final String captainPhone =
        booking['captainPhone']?.toString().trim() ?? '';
    final String captainName =
        booking['captainName']?.toString().trim().toLowerCase() ?? '';

    final bool phoneMatch = contact.isNotEmpty && captainPhone == contact;
    final bool nameMatch = ownerName.isNotEmpty && captainName == ownerName;
    return phoneMatch || nameMatch;
  }

  Color _bookingStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'refunded':
        return const Color(0xFF60A5FA);
      case 'confirmed':
        return const Color(0xFF08B36A);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'cancelled':
        return const Color(0xFFE3220D);
      case 'completed':
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _prettyStatus(String status) {
    if (status.isEmpty) {
      return 'Unknown';
    }
    final String lower = status.toLowerCase();
    if (lower == 'refunded') {
      return 'Refunded';
    }
    return '${lower[0].toUpperCase()}${lower.substring(1)}';
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFF0A0F1E),
    body: SafeArea(
      child: Column(
        children: <Widget>[
          const _TopHeader(title: 'Booking History'),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF2563EB),
                    ),
                  )
                : _bookings.isEmpty
                    ? const _EmptyState()
                    : RefreshIndicator(
                        color: const Color(0xFF2563EB),
                        onRefresh: _loadBookings,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            16,
                            20,
                            16,
                            24,
                          ),
                          itemCount: _bookings.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, int index) {
                            final _UserBookingItem item = _bookings[index];

                            final Color bookingColor =
                                _bookingStatusColor(item.bookingStatus);

                            final Color paymentColor =
                                _bookingStatusColor(item.paymentStatus);

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0x0AFFFFFF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0x1FFFFFFF),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          item.groundName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      _StatusChip(
                                        label: _prettyStatus(
                                          item.bookingStatus,
                                        ),
                                        color: bookingColor,
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 6),

                                  Text(
                                    item.location,
                                    style: const TextStyle(
                                      color: Color(0x99FFFFFF),
                                      fontSize: 13,
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  Row(
                                    children: <Widget>[
                                      Text(
                                        item.sportIcon,
                                        style: const TextStyle(
                                          fontSize: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item.sport,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),

                                  Row(
                                    children: <Widget>[
                                      const Icon(
                                        Icons.calendar_month_outlined,
                                        size: 16,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        item.dateLabel,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(
                                        Icons.schedule,
                                        size: 16,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          item.timeRange,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  Row(
                                    children: <Widget>[
                                      Text(
                                        'Rs ${item.amount.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          color: Color(0xFF60A5FA),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const Spacer(),
                                      _StatusChip(
                                        label: _prettyStatus(
                                          item.paymentStatus,
                                        ),
                                        color: paymentColor,
                                      ),
                                    ],
                                  ),

                                  if (item.bookingStatus.toLowerCase() ==
                                          'cancelled' &&
                                      item.cancellationReason.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0x14E3220D),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        border: Border.all(
                                          color: const Color(0x33E3220D),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          const Text(
                                            'Rejection Reason',
                                            style: TextStyle(
                                              color: Color(0xFFE3220D),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            item.cancellationReason,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    ),
  );
}




}

class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.title});

  final String title;

@override
Widget build(BuildContext context) {
  return Container(
    decoration: const BoxDecoration(
      color: Color(0xFF121C3E),
      borderRadius: BorderRadius.vertical(
        bottom: Radius.circular(24),
      ),
    ),
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
    child: Row(
      children: <Widget>[
        InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(22),
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 24),
      children: const <Widget>[
        Icon(Icons.event_busy_outlined, color: Color(0xFF94A3B8), size: 38),
        SizedBox(height: 12),
        Text(
          'No bookings yet',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Your requested and confirmed bookings will appear here with status.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0x99FFFFFF), fontSize: 13),
        ),
      ],
    );
  }
}
class _UserBookingItem {
  const _UserBookingItem({
    required this.groundName,
    required this.location,
    required this.sport,
    required this.sportIcon,
    required this.dateLabel,
    required this.timeRange,
    required this.amount,
    required this.bookingStatus,
    required this.paymentStatus,
    required this.sortTime,
    required this.cancellationReason,
  });

  final String groundName;
  final String location;
  final String sport;
  final String sportIcon;
  final String dateLabel;
  final String timeRange;
  final double amount;
  final String bookingStatus;
  final String paymentStatus;
  final DateTime sortTime;
  final String cancellationReason;
  factory _UserBookingItem.fromMaps({
  required Map<String, dynamic> booking,
  required String groundName,
  required String location,
  required String groundSport,
}) {
  final String rawDate =
      booking['date']?.toString() ?? '';

  final DateTime parsedDate =
      DateTime.tryParse(rawDate)?.toLocal() ??
      DateTime(1970);

  final String start =
      booking['startTime']?.toString().trim().isNotEmpty == true
          ? booking['startTime'].toString().trim()
          : '-';

  final String end =
      booking['endTime']?.toString().trim().isNotEmpty == true
          ? booking['endTime'].toString().trim()
          : '-';

  final String sportName =
      groundSport.trim().isNotEmpty
          ? groundSport.trim()
          : 'Sport';

  final String bookingStatus =
      booking['bookingStatus']?.toString().trim().isNotEmpty == true
          ? booking['bookingStatus'].toString().trim()
          : 'pending';

  final String paymentStatus =
      booking['paymentStatus']?.toString().trim().isNotEmpty == true
          ? booking['paymentStatus'].toString().trim()
          : 'pending';

  final String cancellationReason =
      booking['cancellationReason']?.toString().trim() ?? '';

  return _UserBookingItem(
    groundName: groundName,
    location: location,
    sport: sportName,
    sportIcon: sport_icons_util.sportIcon(sportName),
    dateLabel: _formatDate(rawDate),
    timeRange: '$start - $end',
    amount: _toDouble(booking['amount']),
    bookingStatus: bookingStatus,
    paymentStatus: paymentStatus,
    sortTime: DateTime(
      parsedDate.year,
      parsedDate.month,
      parsedDate.day,
    ),
    cancellationReason: cancellationReason,
  );
}

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }

  static String _formatDate(String raw) {
    final DateTime? date = DateTime.tryParse(raw)?.toLocal();

    if (date == null) {
      return raw.isEmpty ? '-' : raw;
    }

    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}