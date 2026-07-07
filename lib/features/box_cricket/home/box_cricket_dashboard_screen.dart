import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import 'box_cricket_add_booking_screen.dart';
import 'box_cricket_booking_details_screen.dart';
import 'box_cricket_bottom_nav.dart';
import 'box_cricket_earning_screen.dart';
import 'box_cricket_manage_slots_screen.dart';
import 'box_cricket_profile_screen.dart';
import 'box_cricket_upcoming_bookings_screen.dart';

class BoxCricketDashboardScreen extends StatefulWidget {
  const BoxCricketDashboardScreen({super.key});

  @override
  State<BoxCricketDashboardScreen> createState() =>
      _BoxCricketDashboardScreenState();
}

class _BoxCricketDashboardScreenState extends State<BoxCricketDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _dashboard = <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      final Map<String, dynamic> dashboard = await GroundWaleApi.instance
          .getBoxCricketDashboard(ownerId);
      if (!mounted) {
        return;
      }
      setState(() {
        _dashboard = dashboard;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
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

  List<Map<String, dynamic>> _upcomingBookings() {
    final List<dynamic> raw =
        _dashboard['upcomingBookings'] as List<dynamic>? ?? <dynamic>[];
    if (raw.isNotEmpty) {
      return raw
          .whereType<Map>()
          .map((Map item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  @override
  Widget build(BuildContext context) {
    final int todaysEarnings = _toInt(_dashboard['todaysEarnings']);
    final int availableSlots = _toInt(_dashboard['slotStatus']?['available']);
    final int bookedSlots = _toInt(_dashboard['slotStatus']?['booked']);
    final int blockedSlots = _toInt(_dashboard['slotStatus']?['blocked']);
    final int totalSlots = (availableSlots + bookedSlots + blockedSlots).clamp(
      1,
      1000000,
    );

    final String ownerName =
        ApiSession.instance.ownerName?.trim().isNotEmpty == true
        ? ApiSession.instance.ownerName!.trim()
        : 'Owner';

    final List<Map<String, dynamic>> bookings = _upcomingBookings();

    final Map<String, dynamic> teamActivity = Map<String, dynamic>.from(
      _dashboard['teamActivity'] as Map? ?? <String, dynamic>{},
    );

    final String mostActive = teamActivity['mostActiveTeam']?.toString() ?? '-';
    final String repeatTeams = teamActivity['repeatTeams']?.toString() ?? '-';

    return Scaffold(
      backgroundColor: const Color(0xFF1B1F1B),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF00C9A7)),
              )
            : RefreshIndicator(
                onRefresh: _load,
                color: const Color(0xFF00C9A7),
                backgroundColor: const Color(0xFF203A43),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 92),
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0x14FFFFFF)),
                          ),
                          child: IconButton(
                            onPressed: () {
                              Navigator.of(context).maybePop();
                            },
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                              color: Color(0xFFDDF730),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Good Morning, $ownerName',
                                style: const TextStyle(
                                  color: Color(0xFF7B8A97),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Box Cricket',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _iconChip(Icons.sports_cricket_rounded),
                        const SizedBox(width: 12),
                        _iconChip(Icons.notifications_none_rounded),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: <Color>[Color(0xFF1E293B), Color(0xFF334155)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const BoxCricketEarningScreen(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'Today\'s Earnings',
                              style: TextStyle(
                                color: Color(0xCCFFFFFF),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Rs $todaysEarnings',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: const Color(0x1AFFFFFF),
                              ),
                              child: const Text(
                                '+12% from last yesterday',
                                style: TextStyle(
                                  color: Color(0xE6FFFFFF),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        const Text(
                          'Upcoming Bookings',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    const BoxCricketUpcomingBookingsScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'View All',
                            style: TextStyle(
                              color: Color(0xFF08B36A),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (bookings.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        decoration: _overlayCardDecoration(),
                        child: const Text(
                          'No upcoming bookings available.',
                          style: TextStyle(
                            color: Color(0xCCFFFFFF),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    else
                      ...bookings.map((Map<String, dynamic> booking) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _bookingCard(booking),
                        );
                      }),
                    const SizedBox(height: 8),
                    const Text(
                      'Slot Status',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _overlayCardDecoration(),
                      child: Column(
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              _slotMeta(
                                'Available',
                                '$availableSlots',
                                const Color(0xFF22C55E),
                              ),
                              _slotMeta(
                                'Booked',
                                '$bookedSlots',
                                const Color(0xFF0B84FF),
                              ),
                              _slotMeta(
                                'Blocked',
                                '$blockedSlots',
                                const Color(0xFFEF4444),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  flex: availableSlots == 0
                                      ? 1
                                      : availableSlots,
                                  child: Container(
                                    height: 8,
                                    color: const Color(0xFF22C55E),
                                  ),
                                ),
                                Expanded(
                                  flex: bookedSlots == 0 ? 1 : bookedSlots,
                                  child: Container(
                                    height: 8,
                                    color: const Color(0xFF0B84FF),
                                  ),
                                ),
                                Expanded(
                                  flex: blockedSlots == 0 ? 1 : blockedSlots,
                                  child: Container(
                                    height: 8,
                                    color: const Color(0xFFEF4444),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: _actionTile(
                                  icon: Icons.add_rounded,
                                  label: 'Add Booking',
                                  onTap: () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const BoxCricketAddBookingScreen(),
                                      ),
                                    );
                                    _load();
                                  },
                                  highlighted: true,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _actionTile(
                                  icon: Icons.schedule_rounded,
                                  label: 'Manage Slots',
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const BoxCricketManageSlotsScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: _actionTile(
                              icon: Icons.assessment_outlined,
                              label: 'Reports',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        const BoxCricketEarningScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Teams Activity',
                      style: TextStyle(
                        color: Color(0xFFE6F7F4),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _overlayCardDecoration(),
                      child: Column(
                        children: <Widget>[
                          _activityRow('Most Active Team', mostActive),
                          const SizedBox(height: 10),
                          _activityRow('Repeat Teams', repeatTeams),
                          const SizedBox(height: 10),
                          _activityRow('Total Slots', '$totalSlots'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: BoxCricketBottomNav(
        currentIndex: 0,
        onHome: () {},
        onAnnouncement: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const BoxCricketUpcomingBookingsScreen(),
            ),
          );
        },
        onSlots: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const BoxCricketManageSlotsScreen(),
            ),
          );
        },
        onProfile: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const BoxCricketProfileScreen(),
            ),
          );
        },
      ),
    );
  }

  BoxDecoration _overlayCardDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0x1FFFFFFF)),
      color: const Color(0x0AFFFFFF),
    );
  }

  Widget _iconChip(IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0x0AFFFFFF),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Icon(icon, size: 21, color: const Color(0xFFE6F7F4)),
    );
  }

  Widget _slotMeta(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF7B8A97),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _activityRow(String key, String value) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            key,
            style: const TextStyle(
              color: Color(0x99E6F7F4),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFFE6F7F4),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool highlighted = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 95,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x1FFFFFFF)),
          color: highlighted
              ? const Color(0x10FFFFFF)
              : const Color(0x08FFFFFF),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0x1F08B36A),
              ),
              child: Icon(icon, size: 24, color: const Color(0xFF08B36A)),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFE6F7F4),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bookingCard(Map<String, dynamic> booking) {
    final String timeRange =
        booking['timeRange']?.toString() ??
        '${booking['startTime'] ?? '--'} - ${booking['endTime'] ?? '--'}';
    final String team = booking['teamName']?.toString() ?? 'Team';
    final int players = _toInt(booking['players'] ?? booking['playerCount']);
    final String paymentLabel =
        booking['paymentLabel']?.toString() ??
        booking['paymentStatus']?.toString().toUpperCase() ??
        'Pending';

    final bool paid = paymentLabel.toLowerCase() == 'paid';
    final String amountText =
        booking['amountLabel']?.toString() ?? 'Rs ${_toInt(booking['amount'])}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: Color(0xFF08B36A), width: 4),
        ),
        color: const Color(0x08FFFFFF),
      ),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                timeRange,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: paid
                      ? const Color(0x2622C55E)
                      : const Color(0x0AFFFFFF),
                ),
                child: Text(
                  paymentLabel,
                  style: TextStyle(
                    color: paid ? const Color(0xFF22C55E) : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      team,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$players Players',
                      style: const TextStyle(
                        color: Color(0x99FFFFFF),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                amountText,
                style: TextStyle(
                  color: paid ? Colors.white : const Color(0xFFF59E0B),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton(
                    onPressed: () {
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
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0x1FDDF730)),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Call',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton(
                    onPressed: () async {
                      final String bookingId = booking['_id']?.toString() ?? '';
                      if (bookingId.isEmpty) {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                const BoxCricketUpcomingBookingsScreen(),
                          ),
                        );
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF08B36A),
                      foregroundColor: const Color(0xFF1C333B),
                      elevation: 0,
                    ),
                    child: const Text(
                      'View',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
