import 'package:flutter/material.dart';
import 'package:ground_wale/core/widgets/app_text_field.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import 'box_cricket_bottom_nav.dart';
import 'box_cricket_dashboard_screen.dart';
import 'box_cricket_profile_screen.dart';
import 'box_cricket_upcoming_bookings_screen.dart';

class BoxCricketManageSlotsScreen extends StatefulWidget {
  const BoxCricketManageSlotsScreen({
    super.key,
    this.showBottomNav = true,
  });

  final bool showBottomNav;

  @override
  State<BoxCricketManageSlotsScreen> createState() =>
      _BoxCricketManageSlotsScreenState();
}

class _BoxCricketManageSlotsScreenState
    extends State<BoxCricketManageSlotsScreen> {
  bool _isLoading = true;
  int _dayFilterIndex = 0;
  String _statusFilter = 'all';

  List<Map<String, dynamic>> _slots = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _bookings = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  DateTime get _today {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get _rangeStart {
    if (_dayFilterIndex == 1) {
      return _today.add(const Duration(days: 1));
    }
    return _today;
  }

  DateTime get _rangeEnd {
    if (_dayFilterIndex == 2) {
      return _today.add(const Duration(days: 6));
    }
    return _rangeStart;
  }

  String _dateKey(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  DateTime _parseDate(dynamic value) {
    if (value is DateTime) {
      return DateTime(value.year, value.month, value.day);
    }
    if (value is String && value.isNotEmpty) {
      final DateTime? parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return DateTime(parsed.year, parsed.month, parsed.day);
      }
    }
    return _today;
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

  Future<String?> _resolveGroundId() async {
    final String? currentGroundId = ApiSession.instance.groundId;
    if (currentGroundId != null && currentGroundId.isNotEmpty) {
      return currentGroundId;
    }

    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      return null;
    }

    final String? resolved = await GroundWaleApi.instance
        .ensureGroundIdForOwner(ownerId);
    if (resolved != null && resolved.isNotEmpty) {
      ApiSession.instance.setGroundId(resolved);
    }
    return resolved;
  }

  Future<void> _load() async {
    final String? groundId = await _resolveGroundId();
    if (groundId == null || groundId.isEmpty) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ground not found for this owner.')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String from = _dateKey(_rangeStart);
      final String to = _dateKey(_rangeEnd);
      final List<Map<String, dynamic>> slots = await GroundWaleApi.instance
          .listSlots(groundId, from: from, to: to);
      final List<Map<String, dynamic>> bookings = await GroundWaleApi.instance
          .listBookings(groundId);

      if (!mounted) {
        return;
      }
      setState(() {
        _slots = slots;
        _bookings = bookings;
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

  List<Map<String, dynamic>> get _filteredSlots {
    return _slots.where((Map<String, dynamic> slot) {
      if (_statusFilter == 'all') {
        return true;
      }
      return (slot['status']?.toString() ?? 'available') == _statusFilter;
    }).toList();
  }

  Map<String, dynamic>? _bookingForSlot(Map<String, dynamic> slot) {
    final String slotId = slot['_id']?.toString() ?? '';
    final DateTime slotDate = _parseDate(slot['date']);

    for (final Map<String, dynamic> booking in _bookings) {
      final String bSlotId = booking['slotId']?.toString() ?? '';
      if (bSlotId != slotId) {
        continue;
      }
      final DateTime bDate = _parseDate(booking['date']);
      if (_dateKey(bDate) == _dateKey(slotDate)) {
        return booking;
      }
    }
    return null;
  }

  int _earnedAmount() {
    int sum = 0;
    for (final Map<String, dynamic> booking in _bookings) {
      final DateTime bDate = _parseDate(booking['date']);
      if (bDate.isBefore(_rangeStart) || bDate.isAfter(_rangeEnd)) {
        continue;
      }
      if ((booking['paymentStatus']?.toString() ?? '') == 'paid' &&
          (booking['bookingStatus']?.toString() ?? '') != 'cancelled') {
        sum += _toInt(booking['amount']);
      }
    }
    return sum;
  }

  Future<void> _showAddSheet() async {
    final TextEditingController startCtrl = TextEditingController(
      text: '09:00 AM',
    );
    final TextEditingController endCtrl = TextEditingController(
      text: '10:00 AM',
    );
    final TextEditingController priceCtrl = TextEditingController(text: '0');
    DateTime selectedDate = _today;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder:
              (
                BuildContext context,
                void Function(void Function()) setModalState,
              ) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF1B1F1B),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            const Text(
                              'Add Slot',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: const Color(0x1F08B36A),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Color(0xFF08B36A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Create New Availability',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Define a new booking window for your clients.',
                          style: TextStyle(
                            color: Color(0x99FFFFFF),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Select Date',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 72,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: 4,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 12),
                            itemBuilder: (_, int index) {
                              final DateTime d = _today.add(
                                Duration(days: index),
                              );
                              final bool selected =
                                  _dateKey(d) == _dateKey(selectedDate);
                              const List<String> dayNames = <String>[
                                'Mon',
                                'Tue',
                                'Wed',
                                'Thu',
                                'Fri',
                                'Sat',
                                'Sun',
                              ];
                              return GestureDetector(
                                onTap: () =>
                                    setModalState(() => selectedDate = d),
                                child: Container(
                                  width: 64,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0x3DFFFFFF),
                                    ),
                                    color: selected
                                        ? const Color(0xFF08B36A)
                                        : Colors.transparent,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Text(
                                        dayNames[d.weekday - 1],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${d.day}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _fieldCard('Start Time', startCtrl),
                            ),
                            const SizedBox(width: 16),
                            Expanded(child: _fieldCard('End Time', endCtrl)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _fieldCard('Hourly Rate', priceCtrl, prefix: 'Rs '),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () async {
                              final String? groundId = await _resolveGroundId();
                              if (groundId == null || groundId.isEmpty) {
                                if (mounted) {
                                  ScaffoldMessenger.of(
                                    this.context,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Ground not found. Unable to create slot.',
                                      ),
                                    ),
                                  );
                                }
                                return;
                              }

                              if (startCtrl.text.trim().isEmpty ||
                                  endCtrl.text.trim().isEmpty) {
                                if (mounted) {
                                  ScaffoldMessenger.of(
                                    this.context,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Start time and end time are required.',
                                      ),
                                    ),
                                  );
                                }
                                return;
                              }

                              try {
                                await GroundWaleApi.instance
                                    .createSlot(groundId, <String, dynamic>{
                                      'date': _dateKey(selectedDate),
                                      'startTime': startCtrl.text.trim(),
                                      'endTime': endCtrl.text.trim(),
                                      'price': _toInt(priceCtrl.text.trim()),
                                      'status': 'available',
                                    });
                                if (mounted) {
                                  Navigator.of(this.context).pop();
                                  _load();
                                }
                              } catch (error) {
                                if (mounted) {
                                  ScaffoldMessenger.of(
                                    this.context,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        error.toString().replaceFirst(
                                          'Exception: ',
                                          '',
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF08B36A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Add New Slot',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
        );
      },
    );
  }

  Future<void> _showEditSheet(Map<String, dynamic> slot) async {
    final TextEditingController startCtrl = TextEditingController(
      text: slot['startTime']?.toString() ?? '',
    );
    final TextEditingController endCtrl = TextEditingController(
      text: slot['endTime']?.toString() ?? '',
    );
    final TextEditingController priceCtrl = TextEditingController(
      text: '${_toInt(slot['price'])}',
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 26),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Center(
                  child: Text(
                    'Edit Slot',
                    style: TextStyle(
                      color: Color(0xFF242424),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: <Widget>[
                    Expanded(child: _lightFieldCard('Start Time', startCtrl)),
                    const SizedBox(width: 16),
                    Expanded(child: _lightFieldCard('End Time', endCtrl)),
                  ],
                ),
                const SizedBox(height: 16),
                _lightFieldCard('Price', priceCtrl, prefix: 'Rs '),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await GroundWaleApi.instance.updateSlot(
                          slot['_id']?.toString() ?? '',
                          <String, dynamic>{
                            'startTime': startCtrl.text.trim(),
                            'endTime': endCtrl.text.trim(),
                            'price': _toInt(priceCtrl.text.trim()),
                            'status': slot['status']?.toString() ?? 'available',
                          },
                        );
                        if (mounted) {
                          Navigator.of(context).pop();
                          _load();
                        }
                      } catch (error) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                error.toString().replaceFirst(
                                  'Exception: ',
                                  '',
                                ),
                              ),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1C333B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> slot) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Center(
            child: Text(
              'Delete Slot?',
              style: TextStyle(
                color: Color(0xFF242424),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          content: const Text(
            'This action cannot be undone.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0x99242424)),
          ),
          actions: <Widget>[
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0x1F08B36A),
                  foregroundColor: const Color(0xFF08B36A),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0x1FE3220D),
                  foregroundColor: const Color(0xFFE3220D),
                ),
                child: const Text('Delete'),
              ),
            ),
          ],
        );
      },
    );

    if (ok == true) {
      await GroundWaleApi.instance.deleteSlot(slot['_id']?.toString() ?? '');
      _load();
    }
  }

  Future<void> _confirmBlock(Map<String, dynamic> slot) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Center(
            child: Text(
              'Block Slot?',
              style: TextStyle(
                color: Color(0xFF242424),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          content: const Text(
            'Are you sure this slot blocked.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0x99242424)),
          ),
          actions: <Widget>[
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0x1F08B36A),
                  foregroundColor: const Color(0xFF08B36A),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0x1FE3220D),
                  foregroundColor: const Color(0xFFE3220D),
                ),
                child: const Text('Block'),
              ),
            ),
          ],
        );
      },
    );

    if (ok == true) {
      await GroundWaleApi.instance.blockSlot(
        slot['_id']?.toString() ?? '',
        'Blocked by owner',
      );
      _load();
    }
  }

  String _dayTitle(DateTime day) {
    const List<String> dayNames = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const List<String> monthNames = <String>[
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
    return '${dayNames[day.weekday - 1]}, ${day.day} ${monthNames[day.month - 1]}';
  }

  int _slotHour(Map<String, dynamic> slot) {
    final String start = slot['startTime']?.toString() ?? '';
    final RegExpMatch? match = RegExp(r'^(\d{1,2})').firstMatch(start);
    return int.tryParse(match?.group(1) ?? '') ?? 0;
  }

  List<Map<String, dynamic>> _sectionSlots(
    List<Map<String, dynamic>> daySlots,
    String section,
  ) {
    return daySlots.where((Map<String, dynamic> slot) {
      final int hour = _slotHour(slot);
      if (section == 'Morning') {
        return hour >= 5 && hour < 12;
      }
      if (section == 'Afternoon') {
        return hour >= 12 && hour < 17;
      }
      return hour >= 17 || hour < 5;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> slots = _filteredSlots;
    final int bookedCount = slots
        .where(
          (Map<String, dynamic> item) => item['status']?.toString() == 'booked',
        )
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFF1B1F1B),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF08B36A)),
              )
            : RefreshIndicator(
                onRefresh: _load,
                color: const Color(0xFF08B36A),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            SizedBox(
                              width: 44,
                              height: 44,
                              child: IconButton(
                                onPressed: () =>
                                    Navigator.of(context).maybePop(),
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Manage Slots',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: _showAddSheet,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: const Color(0x1F08B36A),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Color(0xFF08B36A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: <Widget>[
                        Expanded(child: _dayChip('Today', 0)),
                        const SizedBox(width: 12),
                        Expanded(child: _dayChip('Tomorrow', 1)),
                        const SizedBox(width: 12),
                        Expanded(child: _dayChip('This Week', 2)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: <Widget>[
                          _statusChip('All', 'all'),
                          const SizedBox(width: 8),
                          _statusChip('Available', 'available'),
                          const SizedBox(width: 8),
                          _statusChip('Booked', 'booked'),
                          const SizedBox(width: 8),
                          _statusChip('Blocked', 'blocked'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x1FFFFFFF)),
                        color: const Color(0x08FFFFFF),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          _summaryTile(
                            '${slots.length} Slots',
                            'Created today',
                          ),
                          _summaryTile('$bookedCount Booked', 'Live bookings'),
                          _summaryTile('Rs ${_earnedAmount()}', 'Earned'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._buildDaySections(slots),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? BoxCricketBottomNav(
        currentIndex: 2,
        onHome: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(
              builder: (_) => const BoxCricketDashboardScreen(),
            ),
            (Route<dynamic> route) => false,
          );
        },
        onAnnouncement: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => const BoxCricketUpcomingBookingsScreen(),
            ),
          );
        },
        onSlots: () {},
        onProfile: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => const BoxCricketProfileScreen(),
            ),
          );
        },
      )
          : null,
    );
  }

  Widget _dayChip(String label, int index) {
    final bool selected = _dayFilterIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _dayFilterIndex = index);
        _load();
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: selected ? const Color(0xFF08B36A) : const Color(0x08FFFFFF),
          border: selected ? null : Border.all(color: const Color(0x1FFFFFFF)),
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

  Widget _statusChip(String label, String value) {
    final bool selected = _statusFilter == value;
    return InkWell(
      onTap: () => setState(() => _statusFilter = value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF08B36A) : const Color(0x1FFFFFFF),
          ),
          color: selected ? const Color(0x1FDDF730) : const Color(0x08FFFFFF),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? const Color(0xFF08B36A) : Colors.white,
              fontSize: selected ? 16 : 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryTile(String top, String bottom) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          top,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          bottom,
          style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12),
        ),
      ],
    );
  }

  List<Widget> _buildDaySections(List<Map<String, dynamic>> slots) {
    final Map<String, List<Map<String, dynamic>>> grouped =
        <String, List<Map<String, dynamic>>>{};
    for (final Map<String, dynamic> slot in slots) {
      final DateTime date = _parseDate(slot['date']);
      final String key = _dateKey(date);
      grouped.putIfAbsent(key, () => <Map<String, dynamic>>[]).add(slot);
    }

    final List<String> keys = grouped.keys.toList()..sort();
    final List<Widget> ui = <Widget>[];

    for (final String key in keys) {
      final DateTime day = DateTime.parse(key);
      final List<Map<String, dynamic>> daySlots = grouped[key]!;
      daySlots.sort(
        (Map<String, dynamic> a, Map<String, dynamic> b) =>
            (a['startTime']?.toString() ?? '').compareTo(
              b['startTime']?.toString() ?? '',
            ),
      );

      ui.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                _dayTitle(day),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${daySlots.length} slots',
                style: const TextStyle(
                  color: Color(0xFF08B36A),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );

      for (final String section in <String>[
        'Morning',
        'Afternoon',
        'Evening',
      ]) {
        final List<Map<String, dynamic>> sectionSlots = _sectionSlots(
          daySlots,
          section,
        );
        if (sectionSlots.isEmpty) {
          continue;
        }
        ui.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Text(
              section == 'Morning'
                  ? 'Morning (5 AM - 12 PM)'
                  : section == 'Afternoon'
                  ? 'Afternoon (12 PM - 5 PM)'
                  : 'Evening (4 PM - 7 PM)',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );

        for (final Map<String, dynamic> slot in sectionSlots) {
          ui.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _slotCard(slot),
            ),
          );
        }
      }
    }

    if (ui.isEmpty) {
      return <Widget>[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0x08FFFFFF),
            border: Border.all(color: const Color(0x1FFFFFFF)),
          ),
          child: const Text(
            'No slots found for selected filters.',
            style: TextStyle(color: Color(0xCCFFFFFF)),
          ),
        ),
      ];
    }

    return ui;
  }

  Widget _slotCard(Map<String, dynamic> slot) {
    final String status = slot['status']?.toString() ?? 'available';
    final Map<String, dynamic>? booking = _bookingForSlot(slot);

    final bool isBooked = status == 'booked';
    final bool isBlocked = status == 'blocked';

    final String subtitle = isBooked
        ? 'By ${booking?['teamName'] ?? slot['bookedByTeam'] ?? 'Team'}'
        : isBlocked
        ? 'Blocked'
        : 'Available';

    final String rightText = isBooked
        ? '${(booking?['paymentMethod']?.toString() ?? 'UPI').toUpperCase()} Rs ${_toInt(booking?['amount'] ?? slot['price'])}'
        : 'Rs ${_toInt(slot['price'])}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        color: const Color(0x08FFFFFF),
      ),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${slot['startTime']} - ${slot['endTime']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: <Widget>[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isBooked
                              ? const Color(0xFF0B84FF)
                              : isBlocked
                              ? const Color(0xFFE3220D)
                              : const Color(0xFF22C55E),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0x99FFFFFF),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                rightText,
                style: const TextStyle(
                  color: Color(0xFF08B36A),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _actionBtn(
                  'Edit',
                  const Color(0x1F08B36A),
                  const Color(0xFF08B36A),
                  status == 'available' ? () => _showEditSheet(slot) : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionBtn(
                  'Block',
                  const Color(0x1FF59E0B),
                  const Color(0xFFF59E0B),
                  status == 'available' ? () => _confirmBlock(slot) : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionBtn(
                  status == 'booked' ? 'Booked' : 'Delete',
                  status == 'booked'
                      ? const Color(0x1F08B36A)
                      : const Color(0x1FE3220D),
                  status == 'booked' ? Colors.white : const Color(0xFFE3220D),
                  status == 'available' ? () => _confirmDelete(slot) : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, Color bg, Color fg, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 37,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: onTap == null ? bg.withValues(alpha: 0.4) : bg,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldCard(
    String label,
    TextEditingController controller, {
    String prefix = '',
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        color: const Color(0x08FFFFFF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          AppTextField(
            controller: controller,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              prefixText: prefix,
              prefixStyle: const TextStyle(color: Colors.white),
              isDense: true,
              filled: true,
              fillColor: const Color(0x0FFFFFFF),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0x1FFFFFFF)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0x1FFFFFFF)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF08B36A)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lightFieldCard(
    String label,
    TextEditingController controller, {
    String prefix = '',
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1F242424)),
        color: const Color(0x0A242424),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: Color(0x99242424),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: controller,
            style: const TextStyle(
              color: Color(0xFF242424),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              prefixText: prefix,
              prefixStyle: const TextStyle(
                color: Color(0xFF242424),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}


