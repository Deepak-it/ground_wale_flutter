import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import '../../../core/utils/ist_greeting.dart';
import 'box_cricket_add_booking_screen.dart';
import 'box_cricket_booking_details_screen.dart';
import 'box_cricket_bottom_nav.dart';
import 'box_cricket_earning_screen.dart';
import 'box_cricket_manage_slots_screen.dart';
import 'box_cricket_profile_screen.dart';
import 'box_cricket_upcoming_bookings_screen.dart';

class BoxCricketDashboardScreen extends StatefulWidget {
  const BoxCricketDashboardScreen({super.key, this.showBottomNav = true});

  final bool showBottomNav;

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

  List<Map<String, dynamic>> _grounds() {
    final List<dynamic> raw =
        _dashboard['grounds'] as List<dynamic>? ?? <dynamic>[];
    if (raw.isNotEmpty) {
      return raw
          .whereType<Map>()
          .map((Map item) => Map<String, dynamic>.from(item))
          .toList();
    }

    final String fallbackName =
        _dashboard['groundName']?.toString() ?? 'Green Valley Cricket Ground';
    final String fallbackLocation =
        _dashboard['groundLocation']?.toString() ?? 'Sector 118, Mohali';
    return <Map<String, dynamic>>[
      <String, dynamic>{
        'name': fallbackName,
        'location': fallbackLocation,
        'rating': (_dashboard['groundRating'] ?? 4.6).toString(),
        'imageUrl': _dashboard['groundImage']?.toString() ?? '',
        'facilities': <String>['Parking', 'Washroom', 'Water', 'Lighting'],
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final int todaysEarnings = _toInt(_dashboard['todaysEarnings']);
    final int availableSlots = _toInt(_dashboard['slotStatus']?['available']);
    final int bookedSlots = _toInt(_dashboard['slotStatus']?['booked']);
    final int blockedSlots = _toInt(_dashboard['slotStatus']?['blocked']);
    final int totalSlots = availableSlots + bookedSlots + blockedSlots;

    final String ownerName =
        ApiSession.instance.ownerName?.trim().isNotEmpty == true
        ? ApiSession.instance.ownerName!.trim()
        : 'Owner';
    final String greetingMessage = istGreetingMessage(ownerName);

    final List<Map<String, dynamic>> bookings = _upcomingBookings();

    final Map<String, dynamic> teamActivity = Map<String, dynamic>.from(
      _dashboard['teamActivity'] as Map? ?? <String, dynamic>{},
    );

    final String mostActive = teamActivity['mostActiveTeam']?.toString() ?? '-';
    final String repeatTeams = teamActivity['repeatTeams']?.toString() ?? '-';

    final List<Map<String, dynamic>> grounds = _grounds();

    return Scaffold(
      backgroundColor: const Color(0xFF1B1F1B),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFDDF730)),
              )
            : RefreshIndicator(
                onRefresh: _load,
                color: const Color(0xFFDDF730),
                backgroundColor: const Color(0xFF1B1F1B),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 92),
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0x14FFFFFF),
                                ),
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
                            Text(
                              greetingMessage,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            _iconChip(Icons.campaign_outlined),
                            const SizedBox(width: 12),
                            _iconChip(Icons.notifications_none_rounded),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    SizedBox(
                      height: 336,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: grounds.length + 1,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (_, int index) {
                          if (index == grounds.length) {
                            return _addFacilityCard();
                          }
                          return _groundCard(grounds[index]);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            _monthNavBtn(
                              icon: Icons.chevron_left,
                              onTap: () {},
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'May 2025',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            _monthNavBtn(
                              icon: Icons.chevron_right,
                              onTap: () {},
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: const Color(0x263B82F6),
                          ),
                          child: const Text(
                            'Today',
                            style: TextStyle(
                              color: Color(0xFF3B82F6),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0x333B82F6)),
                        color: const Color(0x143B82F6),
                      ),
                      child: Row(
                        children: <Widget>[
                          SizedBox(
                            width: 112,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Rs $todaysEarnings',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Earnings This Month',
                                  style: TextStyle(
                                    color: Color(0xFF9CA3AF),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(child: _MiniWeeklyGraph()),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _actionTile(
                            icon: Icons.assessment_outlined,
                            label: 'Report',
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
                        const SizedBox(width: 12),
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
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _overlayCardDecoration(),
                      child: const Row(
                        children: <Widget>[
                          SizedBox(
                            width: 36,
                            height: 36,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Color(0x29DDF730),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                              ),
                              child: Icon(
                                Icons.access_time_rounded,
                                color: Color(0xFFDDF730),
                                size: 18,
                              ),
                            ),
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Timing: 06:00 AM - 11:00 PM',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Total Slots per Day: 8',
                                  style: TextStyle(
                                    color: Color(0xFF9CA3AF),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
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
                              color: Color(0xFFDDF730),
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
                    const SizedBox(height: 20),
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
      bottomNavigationBar: widget.showBottomNav
          ? BoxCricketBottomNav(
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
            )
          : null,
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
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 99,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0x08FFFFFF),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 24, color: const Color(0xFFDDF730)),
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

  Widget _monthNavBtn({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color(0x0DFFFFFF),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _groundCard(Map<String, dynamic> ground) {
    final String name = ground['name']?.toString() ?? 'Cricket Ground';
    final String location =
        ground['location']?.toString() ?? 'Location not available';
    final String rating = ground['rating']?.toString() ?? '4.6';
    final String imageValue =
        ground['image']?.toString() ?? ground['imageUrl']?.toString() ?? '';
    final String groundId =
        ground['_id']?.toString() ?? ground['id']?.toString() ?? '';
    final List<dynamic> rawFacilities =
        ground['facilities'] as List<dynamic>? ?? <dynamic>[];
    final List<String> facilities = rawFacilities
        .map((dynamic item) => item.toString())
        .where((String item) => item.trim().isNotEmpty)
        .take(4)
        .toList();

    return Container(
      width: 263,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1F242424)),
        color: const Color(0x0AFFFFFF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              height: 140,
              width: double.infinity,
              color: const Color(0x29242424),
              child: Stack(
                children: <Widget>[
                  if (imageValue.isNotEmpty)
                    Positioned.fill(child: _groundImageWidget(imageValue)),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(0xCC0B0E0C),
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(
                            Icons.star_border,
                            color: Color(0xFFEAB308),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        color: const Color(0xFF08B36A),
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Color(0x99FFFFFF),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0x99FFFFFF),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: facilities
                      .map(
                        (String item) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: const Color(0x0AFFFFFF),
                          ),
                          child: Text(
                            item,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    InkWell(
                      onTap: () {
                        if (groundId.isNotEmpty) {
                          ApiSession.instance.setGroundId(groundId);
                        }
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const BoxCricketManageSlotsScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Manage Slots',
                        style: TextStyle(
                          color: Color(0xFFDDF730),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (groundId.isNotEmpty) {
                          ApiSession.instance.setGroundId(groundId);
                        }
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                const BoxCricketUpcomingBookingsScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDDF730),
                        foregroundColor: const Color(0xFF242424),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Bookings',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _groundImageWidget(String imageValue) {
    final String value = imageValue.trim();
    if (value.isEmpty) {
      return const SizedBox.shrink();
    }

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return Image.network(
        value,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      );
    }

    String base64Part = value;
    if (value.startsWith('data:image') && value.contains(',')) {
      base64Part = value.split(',').last;
    }

    base64Part = _normalizeBase64(base64Part);
    if (base64Part.isEmpty) {
      return const SizedBox.shrink();
    }

    try {
      final Uint8List bytes = Uint8List.fromList(base64Decode(base64Part));
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  String _normalizeBase64(String input) {
    String normalized = input.trim().replaceAll(RegExp(r'\s+'), '');
    if (normalized.isEmpty) {
      return '';
    }

    normalized = normalized.replaceAll('-', '+').replaceAll('_', '/');

    final int remainder = normalized.length % 4;
    if (remainder != 0) {
      normalized = normalized.padRight(
        normalized.length + (4 - remainder),
        '=',
      );
    }

    return normalized;
  }

  Widget _addFacilityCard() {
    return Container(
      width: 263,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1F242424)),
        color: const Color(0x0AFFFFFF),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: const Color(0xFFDDF730),
            ),
            child: const Icon(Icons.add, size: 54, color: Colors.black),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: 229,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDDF730),
                foregroundColor: const Color(0xFF242424),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Add more facilities',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
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
          left: BorderSide(color: Color(0xFFDDF730), width: 4),
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
                      backgroundColor: const Color(0xFFDDF730),
                      foregroundColor: const Color(0xFF242424),
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

class _MiniWeeklyGraph extends StatelessWidget {
  const _MiniWeeklyGraph();

  @override
  Widget build(BuildContext context) {
    final List<double> bars = <double>[0.40, 0.52, 0.60, 0.72, 0.86];
    final List<Color> colors = <Color>[
      const Color(0xFFFBB831),
      const Color(0xFFFB569C),
      const Color(0xFFE850E0),
      const Color(0xFF8225E2),
      const Color(0xFF9C27B0),
    ];

    return SizedBox(
      height: 74,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          for (int i = 0; i < bars.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Container(
                  height: 58 * bars[i],
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        colors[i].withValues(alpha: 0.95),
                        colors[i],
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
