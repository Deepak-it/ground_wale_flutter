import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import '../profile/profile_turf_ui.dart';
import 'booking_details_turf_screen.dart';

class BookingsTurfScreen extends StatefulWidget {
  const BookingsTurfScreen({super.key, this.showBackButton = true});

  final bool showBackButton;

  @override
  State<BookingsTurfScreen> createState() => _BookingsTurfScreenState();
}

class _BookingsTurfScreenState extends State<BookingsTurfScreen> {
  static const List<String> _tabs = <String>['upcoming', 'completed', 'reject'];

  String _activeTab = _tabs.first;
  late Future<Map<String, dynamic>> _future = _load();

  Future<Map<String, dynamic>> _load() async {
    final ApiSession session = ApiSession.instance;
    if (!session.hasGround && session.isAuthenticated) {
      session.setGroundId(await GroundWaleApi.instance.ensureGroundIdForOwner(session.ownerId!));
    }
    if (!session.hasGround) {
      return <String, dynamic>{
        'summary': <String, dynamic>{'totalBookings': 0, 'totalRevenue': 0},
        'bookings': <Map<String, dynamic>>[],
      };
    }

    final String status = _activeTab;
    final Future<Map<String, dynamic>> summaryFuture = GroundWaleApi.instance.getBookingSummary(session.groundId!, status: status);
    final Future<List<Map<String, dynamic>>> listFuture = GroundWaleApi.instance.listBookings(session.groundId!, status: status);
    final List<dynamic> result = await Future.wait(<Future<dynamic>>[summaryFuture, listFuture]);

    return <String, dynamic>{
      'summary': result[0] as Map<String, dynamic>,
      'bookings': result[1] as List<Map<String, dynamic>>,
    };
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  String _tabLabel(String key) {
    switch (key) {
      case 'upcoming':
        return 'Upcoming';
      case 'completed':
        return 'Completed';
      default:
        return 'Reject';
    }
  }

  Color _chipBg(String status) {
    switch (status) {
      case 'completed':
      case 'confirmed':
        return const Color(0x3308B36A);
      case 'cancelled':
        return const Color(0x22E3220D);
      default:
        return const Color(0x22F59E0B);
    }
  }

  Color _chipText(String status) {
    switch (status) {
      case 'completed':
      case 'confirmed':
        return const Color(0xFF08B36A);
      case 'cancelled':
        return const Color(0xFFE3220D);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'cancelled':
        return 'Reject';
      case 'completed':
        return 'Completed';
      case 'confirmed':
        return 'Confirmed';
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return TurfPageScaffold(
      title: 'Upcoming Bookings',
      showBackButton: widget.showBackButton,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFDDF730)));
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString().replaceFirst('Exception: ', '')));
          }

          final Map<String, dynamic> data = snapshot.data ?? <String, dynamic>{};
          final Map<String, dynamic> summary = Map<String, dynamic>.from(data['summary'] as Map? ?? <String, dynamic>{});
          final List<Map<String, dynamic>> bookings = List<Map<String, dynamic>>.from(data['bookings'] as List? ?? <Map<String, dynamic>>[]);

          return ListView(
            children: <Widget>[
              Row(
                children: _tabs.map((String key) {
                  final bool active = _activeTab == key;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          if (_activeTab == key) {
                            return;
                          }
                          setState(() {
                            _activeTab = key;
                            _future = _load();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: active ? const Color(0xFFDDF730) : const Color(0x10FFFFFF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: active ? const Color(0xFFDDF730) : const Color(0x30FFFFFF)),
                          ),
                          child: Text(
                            _tabLabel(key),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: active ? const Color(0xFF242424) : Colors.white,
                              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TurfCard(
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text('Total Booking', style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 3),
                          Text('${summary['totalBookings'] ?? 0} Slots', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text('Total Revenue', style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 3),
                          Text('₹${summary['totalRevenue'] ?? 0}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (bookings.isEmpty)
                const TurfCard(
                  child: Text('No bookings found for this tab.', style: TextStyle(color: Colors.white70)),
                ),
              ...bookings.map((Map<String, dynamic> item) {
                final String bookingStatus = item['bookingStatus']?.toString() ?? 'pending';
                final String paymentStatus = item['paymentStatus']?.toString() ?? 'pending';
                final String paymentMethod = item['paymentMethod']?.toString().toUpperCase() ?? 'UPI';
                final String paymentText = paymentMethod == 'COD' && paymentStatus == 'pending'
                    ? 'COD (₹${item['amount'] ?? 0})'
                    : 'Paid (₹${item['amount'] ?? 0})';

                return TurfCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            '${item['startTime'] ?? '--'} - ${item['endTime'] ?? '--'}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          Text('#${item['bookingCode'] ?? 'BK-0000'}', style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(item['teamName']?.toString() ?? 'Team', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('Captain: ${item['captainName'] ?? item['teamName'] ?? '-'}', style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: _chipBg(bookingStatus), borderRadius: BorderRadius.circular(6)),
                            child: Text(
                              _statusText(bookingStatus),
                              style: TextStyle(color: _chipText(bookingStatus), fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(paymentText, style: const TextStyle(color: Color(0xFF08B36A), fontWeight: FontWeight.w600)),
                        ],
                      ),
                      if (_activeTab == 'upcoming') ...<Widget>[
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  final String phone = item['captainPhone']?.toString() ?? '';
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(phone.isEmpty ? 'Captain phone not available.' : 'Captain: $phone')),
                                  );
                                },
                                style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0x55DDF730))),
                                child: const Text('Call Captain'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => BookingDetailsTurfScreen(bookingId: item['_id']?.toString() ?? ''),
                                    ),
                                  );
                                  _refresh();
                                },
                                style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0x55DDF730))),
                                child: const Text('View Details'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
