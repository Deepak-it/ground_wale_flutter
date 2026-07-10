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
  const BoxCricketDashboardScreen({
    super.key,
    this.showBottomNav = true,
    this.onOpenBookings,
    this.onOpenSlots,
    this.onOpenProfile,
  });

  final bool showBottomNav;
  final VoidCallback? onOpenBookings;
  final VoidCallback? onOpenSlots;
  final VoidCallback? onOpenProfile;

  @override
  State<BoxCricketDashboardScreen> createState() =>
      _BoxCricketDashboardScreenState();
}

class _BoxCricketDashboardScreenState extends State<BoxCricketDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _dashboard = <String, dynamic>{};
  bool _isCalendarLoading = false;
  bool _isGroundDataLoading = false;
  List<Map<String, dynamic>> _groundOptions = <Map<String, dynamic>>[];
  String? _selectedGroundId;
  String? _calendarGroundId;
  Map<String, Map<String, int>> _slotStatsByDate =
      <String, Map<String, int>>{};
  List<Map<String, dynamic>> _selectedGroundBookings =
      <Map<String, dynamic>>[];
  Map<String, int> _selectedGroundSlotSummary = <String, int>{
    'available': 0,
    'booked': 0,
    'blocked': 0,
  };
  DateTime _visibleMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );
  DateTime _selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

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
      _syncSelectedGroundFromDashboard();
      await _loadGroundScopedData();
      await _loadCalendarSlots();
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

  void _syncSelectedGroundFromDashboard() {
    final List<Map<String, dynamic>> grounds = _grounds();
    final String? sessionGroundId = ApiSession.instance.groundId;

    String? selected = _selectedGroundId;
    if (selected == null ||
        !grounds.any((Map<String, dynamic> ground) => _groundId(ground) == selected)) {
      selected = sessionGroundId;
    }
    if (selected == null ||
        !grounds.any((Map<String, dynamic> ground) => _groundId(ground) == selected)) {
      selected = grounds.isEmpty ? null : _groundId(grounds.first);
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _groundOptions = grounds;
      _selectedGroundId = selected;
    });

    if (selected != null && selected.isNotEmpty) {
      ApiSession.instance.setGroundId(selected);
    }
  }

  String? _bookingGroundId(Map<String, dynamic> booking) {
    return booking['groundId']?.toString();
  }

  Future<void> _loadGroundScopedData() async {
    final String? groundId = _selectedGroundId;
    if (groundId == null || groundId.isEmpty) {
      if (mounted) {
        setState(() {
          _selectedGroundBookings = <Map<String, dynamic>>[];
          _selectedGroundSlotSummary = <String, int>{
            'available': 0,
            'booked': 0,
            'blocked': 0,
          };
        });
      }
      return;
    }

    if (mounted) {
      setState(() => _isGroundDataLoading = true);
    }

    try {
      final DateTime today = DateTime.now();
      final List<dynamic> results = await Future.wait<dynamic>(<Future<dynamic>>[
        GroundWaleApi.instance.listBookings(groundId, status: 'upcoming'),
        GroundWaleApi.instance.listSlots(groundId, date: _apiDate(today)),
      ]);

      final List<Map<String, dynamic>> bookings =
          results[0] as List<Map<String, dynamic>>;
      final List<Map<String, dynamic>> todaySlots =
          results[1] as List<Map<String, dynamic>>;

      int available = 0;
      int booked = 0;
      int blocked = 0;
      for (final Map<String, dynamic> slot in todaySlots) {
        final String status = (slot['status']?.toString() ?? 'available').toLowerCase();
        if (status == 'booked') {
          booked += 1;
        } else if (status == 'blocked') {
          blocked += 1;
        } else {
          available += 1;
        }
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _selectedGroundBookings = bookings;
        _selectedGroundSlotSummary = <String, int>{
          'available': available,
          'booked': booked,
          'blocked': blocked,
        };
        _isGroundDataLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedGroundBookings = <Map<String, dynamic>>[];
        _selectedGroundSlotSummary = <String, int>{
          'available': 0,
          'booked': 0,
          'blocked': 0,
        };
        _isGroundDataLoading = false;
      });
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

  String _groundId(Map<String, dynamic> ground) {
    return ground['_id']?.toString() ?? ground['id']?.toString() ?? '';
  }

  String _groundName(Map<String, dynamic> ground) {
    final String fromGroundName = ground['groundName']?.toString().trim() ?? '';
    if (fromGroundName.isNotEmpty) {
      return fromGroundName;
    }
    final String fromName = ground['name']?.toString().trim() ?? '';
    if (fromName.isNotEmpty) {
      return fromName;
    }
    return 'Ground';
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

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _dayKey(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  DateTime? _extractBookingDate(Map<String, dynamic> booking) {
    final List<String> keys = <String>[
      'date',
      'bookingDate',
      'slotDate',
      'createdAt',
    ];
    for (final String key in keys) {
      final dynamic raw = booking[key];
      if (raw is String && raw.trim().isNotEmpty) {
        final DateTime? parsed = DateTime.tryParse(raw);
        if (parsed != null) {
          return _dateOnly(parsed.toLocal());
        }
      }
    }
    return null;
  }

  DateTime? _extractSlotDate(Map<String, dynamic> slot) {
    final dynamic raw = slot['date'];
    if (raw is String && raw.trim().isNotEmpty) {
      final DateTime? parsed = DateTime.tryParse(raw);
      if (parsed != null) {
        return _dateOnly(parsed.toLocal());
      }
    }
    return null;
  }

  String _apiDate(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String? _resolveCalendarGroundId() {
    if (_selectedGroundId != null && _selectedGroundId!.isNotEmpty) {
      return _selectedGroundId;
    }

    final String? sessionGroundId = ApiSession.instance.groundId;
    if (sessionGroundId != null && sessionGroundId.isNotEmpty) {
      return sessionGroundId;
    }

    final List<Map<String, dynamic>> grounds = _grounds();
    for (final Map<String, dynamic> ground in grounds) {
      final String id =
          ground['_id']?.toString() ?? ground['id']?.toString() ?? '';
      if (id.isNotEmpty) {
        return id;
      }
    }
    return null;
  }

  Future<void> _loadCalendarSlots() async {
    final String? groundId = _resolveCalendarGroundId();
    if (groundId == null || groundId.isEmpty) {
      if (mounted) {
        setState(() {
          _calendarGroundId = null;
          _slotStatsByDate = <String, Map<String, int>>{};
        });
      }
      return;
    }

    final DateTime monthStart = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final DateTime monthEnd = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0);

    if (mounted) {
      setState(() {
        _isCalendarLoading = true;
        _calendarGroundId = groundId;
      });
    }

    try {
      final List<Map<String, dynamic>> slots = await GroundWaleApi.instance
          .listSlots(
            groundId,
            from: _apiDate(monthStart),
            to: _apiDate(monthEnd),
          );

      final Map<String, Map<String, int>> stats = <String, Map<String, int>>{};
      for (final Map<String, dynamic> slot in slots) {
        final DateTime? day = _extractSlotDate(slot);
        if (day == null) {
          continue;
        }
        final String key = _dayKey(day);
        final Map<String, int> bucket =
              stats[key] ?? <String, int>{
                'total': 0,
                'booked': 0,
                'blocked': 0,
                'available': 0,
                'maintenance': 0,
              };
        bucket['total'] = (bucket['total'] ?? 0) + 1;

        final String status =
            (slot['status']?.toString() ?? 'available').toLowerCase();
        if (status == 'booked') {
          bucket['booked'] = (bucket['booked'] ?? 0) + 1;
        } else if (status == 'blocked') {
          bucket['blocked'] = (bucket['blocked'] ?? 0) + 1;
            final String blockedReason =
                (slot['blockedReason']?.toString() ?? '').toLowerCase();
            final String notes = (slot['notes']?.toString() ?? '').toLowerCase();
            if (blockedReason.contains('maintenance') ||
                notes.contains('maintenance')) {
              bucket['maintenance'] = (bucket['maintenance'] ?? 0) + 1;
            }
          } else {
            bucket['available'] = (bucket['available'] ?? 0) + 1;
        }

        stats[key] = bucket;
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _slotStatsByDate = stats;
        _isCalendarLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _slotStatsByDate = <String, Map<String, int>>{};
        _isCalendarLoading = false;
      });
    }
  }

  Map<String, int> _bookingCountsByDate(List<Map<String, dynamic>> bookings) {
    final Map<String, int> counts = <String, int>{};
    for (final Map<String, dynamic> booking in bookings) {
      final DateTime? date = _extractBookingDate(booking);
      if (date == null) {
        continue;
      }
      final String key = _dayKey(date);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  List<Map<String, dynamic>> _bookingsForDate(
    List<Map<String, dynamic>> bookings,
    DateTime day,
  ) {
    return bookings.where((Map<String, dynamic> booking) {
      final DateTime? date = _extractBookingDate(booking);
      if (date == null) {
        return false;
      }
      return _isSameDay(date, day);
    }).toList();
  }

  String _monthLabel(DateTime month) {
    const List<String> names = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${names[month.month - 1]} ${month.year}';
  }

  List<DateTime> _calendarGridDays(DateTime month) {
    final DateTime first = DateTime(month.year, month.month, 1);
    final int leading = first.weekday - DateTime.monday;
    final DateTime start = first.subtract(Duration(days: leading));
    return List<DateTime>.generate(
      42,
      (int index) => _dateOnly(start.add(Duration(days: index))),
    );
  }

  void _goToPreviousMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1, 1);
      if (_selectedDate.year != _visibleMonth.year ||
          _selectedDate.month != _visibleMonth.month) {
        _selectedDate = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
      }
    });
    _loadCalendarSlots();
  }

  void _goToNextMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 1);
      if (_selectedDate.year != _visibleMonth.year ||
          _selectedDate.month != _visibleMonth.month) {
        _selectedDate = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
      }
    });
    _loadCalendarSlots();
  }

  void _jumpToToday() {
    final DateTime now = _dateOnly(DateTime.now());
    setState(() {
      _visibleMonth = DateTime(now.year, now.month, 1);
      _selectedDate = now;
    });
    _loadCalendarSlots();
  }

  void _openBookings() {
    if (!widget.showBottomNav && widget.onOpenBookings != null) {
      widget.onOpenBookings!.call();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const BoxCricketUpcomingBookingsScreen(),
      ),
    );
  }

  void _openSlots() {
    if (!widget.showBottomNav && widget.onOpenSlots != null) {
      widget.onOpenSlots!.call();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const BoxCricketManageSlotsScreen(),
      ),
    );
  }

  void _openProfile() {
    if (!widget.showBottomNav && widget.onOpenProfile != null) {
      widget.onOpenProfile!.call();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const BoxCricketProfileScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int todaysEarnings = _toInt(_dashboard['todaysEarnings']);
    final int availableSlots = _selectedGroundId == null
      ? _toInt(_dashboard['slotStatus']?['available'])
      : (_selectedGroundSlotSummary['available'] ?? 0);
    final int bookedSlots = _selectedGroundId == null
      ? _toInt(_dashboard['slotStatus']?['booked'])
      : (_selectedGroundSlotSummary['booked'] ?? 0);
    final int blockedSlots = _selectedGroundId == null
      ? _toInt(_dashboard['slotStatus']?['blocked'])
      : (_selectedGroundSlotSummary['blocked'] ?? 0);
    final int totalSlots = availableSlots + bookedSlots + blockedSlots;

    final String ownerName =
        ApiSession.instance.ownerName?.trim().isNotEmpty == true
        ? ApiSession.instance.ownerName!.trim()
        : 'Owner';
    final String greetingMessage = istGreetingMessage(ownerName);

    final List<Map<String, dynamic>> bookings = _selectedGroundId == null
        ? _upcomingBookings()
        : (_selectedGroundBookings.isNotEmpty
              ? _selectedGroundBookings
              : _upcomingBookings().where((Map<String, dynamic> booking) {
                  return _bookingGroundId(booking) == _selectedGroundId;
                }).toList());
    final List<Map<String, dynamic>> selectedDateBookings = _bookingsForDate(
      bookings,
      _selectedDate,
    );

    final Map<String, dynamic> teamActivity = Map<String, dynamic>.from(
      _dashboard['teamActivity'] as Map? ?? <String, dynamic>{},
    );

    final String mostActive = teamActivity['mostActiveTeam']?.toString() ?? '-';
    final String repeatTeams = teamActivity['repeatTeams']?.toString() ?? '-';

    final List<Map<String, dynamic>> grounds = _groundOptions.isEmpty
      ? _grounds()
      : _groundOptions;

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
                            'Select Ground',
                            style: TextStyle(color: Color(0x99FFFFFF)),
                          ),
                          items: _groundOptions.map((Map<String, dynamic> ground) {
                            final String id = _groundId(ground);
                            return DropdownMenuItem<String>(
                              value: id,
                              child: Text(
                                _groundName(ground),
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? value) async {
                            if (value == null || value == _selectedGroundId) {
                              return;
                            }
                            setState(() {
                              _selectedGroundId = value;
                              _selectedGroundBookings = <Map<String, dynamic>>[];
                              _selectedGroundSlotSummary = <String, int>{
                                'available': 0,
                                'booked': 0,
                                'blocked': 0,
                              };
                            });
                            ApiSession.instance.setGroundId(value);
                            await _loadGroundScopedData();
                            await _loadCalendarSlots();
                          },
                        ),
                      ),
                    ),
                    if (_isGroundDataLoading) ...<Widget>[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(
                        minHeight: 2,
                        color: Color(0xFFDDF730),
                        backgroundColor: Color(0x1FFFFFFF),
                      ),
                    ],

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
                              onTap: _goToPreviousMonth,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _monthLabel(_visibleMonth),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            _monthNavBtn(
                              icon: Icons.chevron_right,
                              onTap: _goToNextMonth,
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: _jumpToToday,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
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
                    _calendarCard(),


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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'Upcoming Bookings',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              style: const TextStyle(
                                color: Color(0x99FFFFFF),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: _openBookings,
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
                    if (selectedDateBookings.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        decoration: _overlayCardDecoration(),
                        child: const Text(
                          'No bookings on selected date.',
                          style: TextStyle(
                            color: Color(0xCCFFFFFF),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    else
                      ...selectedDateBookings.map((Map<String, dynamic> booking) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _bookingCard(booking),
                        );
                      }),
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
              onAnnouncement: _openBookings,
              onSlots: _openSlots,
              onProfile: _openProfile,
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

  Widget _calendarCard() {
    final DateTime today = _dateOnly(DateTime.now());
    final List<DateTime> days = _calendarGridDays(_visibleMonth);
    const List<String> week = <String>['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        color: const Color(0x08FFFFFF),
      ),
      child: Column(
        children: <Widget>[
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: <Widget>[
              _calendarLegendItem(
                color: const Color(0xFF10B981),
                label: 'Available',
              ),
              _calendarLegendItem(
                color: const Color(0xFF0B84FF),
                label: 'Booked',
              ),
              _calendarLegendItem(
                color: const Color(0xFFEF4444),
                label: 'Blocked',
              ),
              _calendarLegendItem(
                color: const Color(0xFFF59E0B),
                label: 'Maintenance',
              ),
              _calendarLegendItem(
                color: const Color(0xFF9CA3AF),
                label: 'No Booking',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: week
                .map(
                  (String label) => Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (_, int index) {
              final DateTime day = days[index];
              final bool inMonth = day.month == _visibleMonth.month;
              final bool isToday = _isSameDay(day, today);
              final bool isSelected = _isSameDay(day, _selectedDate);
              final bool isPast = day.isBefore(today);
                final Map<String, int> stats =
                  _slotStatsByDate[_dayKey(day)] ??
                    <String, int>{
                      'total': 0,
                      'booked': 0,
                      'blocked': 0,
                      'available': 0,
                      'maintenance': 0,
                    };
                final int total = stats['total'] ?? 0;
                final int booked = stats['booked'] ?? 0;
                final int blocked = stats['blocked'] ?? 0;
                final int available = stats['available'] ?? 0;
                final int maintenance = stats['maintenance'] ?? 0;

              Color bg;
              Color border;
              Color text;
              String? sub;
                Color subColor = const Color(0xFF10B981);

              if (!inMonth) {
                bg = const Color(0x089CA3AF);
                border = const Color(0x1A9CA3AF);
                text = const Color(0x669CA3AF);
              } else if (isSelected) {
                  bg = const Color(0x1410B981);
                  border = const Color(0xFFDDF730);
                text = Colors.white;
                  if (maintenance >= total && total > 0) {
                    sub = 'Maintenance';
                    subColor = const Color(0xFFF59E0B);
                  } else if (blocked >= total && total > 0) {
                    sub = 'Blocked';
                    subColor = const Color(0xFFEF4444);
                  } else if (booked > 0) {
                    sub = '$booked/$total booked';
                    subColor = const Color(0xFF0B84FF);
                  } else if (available > 0) {
                    sub = 'No Booking';
                    subColor = const Color(0xFF9CA3AF);
                  } else {
                    sub = 'No Slots';
                  subColor = const Color(0xFF9CA3AF);
                }
              } else if (isPast) {
                bg = const Color(0x0D9CA3AF);
                border = const Color(0x1A9CA3AF);
                text = const Color(0xFF9CA3AF);
                sub = 'Past';
                subColor = const Color(0xFF9CA3AF);
                } else if (total > 0 && maintenance >= total) {
                  bg = const Color(0x14F59E0B);
                  border = const Color(0x33F59E0B);
                  text = Colors.white;
                  sub = 'Maint.';
                  subColor = const Color(0xFFF59E0B);
                } else if (total > 0 && blocked >= total) {
                bg = const Color(0x14EF4444);
                border = const Color(0x33EF4444);
                text = Colors.white;
                  sub = 'Blocked';
                subColor = const Color(0xFFEF4444);
                } else if (total > 0 && booked > 0) {
                  bg = const Color(0x140B84FF);
                  border = const Color(0x330B84FF);
                  text = Colors.white;
                  sub = '$booked/$total';
                  subColor = const Color(0xFF0B84FF);
                } else if (total > 0 && available > 0) {
                bg = const Color(0x1410B981);
                border = const Color(0x3310B981);
                text = Colors.white;
                  sub = 'Open';
                  subColor = const Color(0xFF10B981);
              } else {
                bg = const Color(0x0AFFFFFF);
                border = const Color(0x1FFFFFFF);
                text = Colors.white;
              }

              return InkWell(
                onTap: inMonth
                    ? () => setState(() => _selectedDate = day)
                    : null,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border, width: isSelected ? 1.6 : 1),
                    color: bg,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          color: text,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (sub != null) ...<Widget>[
                        const SizedBox(height: 3),
                        Text(
                          sub,
                          style: TextStyle(
                            color: subColor,
                            fontSize: 8.8,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (isToday && !isSelected) ...<Widget>[
                        const SizedBox(height: 3),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Color(0xFF3B82F6),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          if (_isCalendarLoading) ...<Widget>[
            const SizedBox(height: 8),
            const LinearProgressIndicator(
              minHeight: 2,
              color: Color(0xFFDDF730),
              backgroundColor: Color(0x1FFFFFFF),
            ),
          ],
          const SizedBox(height: 10),
          const Text(
            'Tap on a date to view bookings and details',
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _calendarLegendItem({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xCCFFFFFF),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
                        _openSlots();
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
                        _openBookings();
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
