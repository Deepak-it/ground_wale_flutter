import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import 'box_cricket_booking_details_screen.dart';
import 'box_cricket_booking_flow_models.dart';

class BoxCricketAddBookingScreen extends StatefulWidget {
  const BoxCricketAddBookingScreen({super.key});

  @override
  State<BoxCricketAddBookingScreen> createState() =>
      _BoxCricketAddBookingScreenState();
}

class _BoxCricketAddBookingScreenState
    extends State<BoxCricketAddBookingScreen> {
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _grounds = <Map<String, dynamic>>[];
  String? _selectedGroundId;
  List<Map<String, dynamic>> _slots = <Map<String, dynamic>>[];
  String? _selectedSlotId;
  Set<String> _activeBookedSlotKeys = <String>{};
  bool _hasBookingLookup = false;

  @override
  void initState() {
    super.initState();
    _loadSlots();
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

  Future<void> _loadSlots() async {
    final String? groundId = await _resolveGroundId();
    if (groundId == null || groundId.isEmpty) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No grounds found for this owner.')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final List<dynamic> results = await Future.wait<dynamic>(<Future<dynamic>>[
        GroundWaleApi.instance.listSlots(groundId, date: _apiDate(_selectedDate)),
        GroundWaleApi.instance.listBookings(groundId),
      ]);

      final List<Map<String, dynamic>> slots =
          results[0] as List<Map<String, dynamic>>;
      final List<Map<String, dynamic>> bookings =
          results[1] as List<Map<String, dynamic>>;

      final String selectedDateKey = _apiDate(_selectedDate);
      final Set<String> activeBookedKeys = <String>{};
      for (final Map<String, dynamic> booking in bookings) {
        final String status = _bookingStatus(booking);
        if (status == 'cancelled' || status == 'rejected') {
          continue;
        }

        final String slotId = booking['slotId']?.toString() ?? '';
        if (slotId.isEmpty) {
          continue;
        }

        final String bookingDateKey = _bookingDateKey(booking);
        if (bookingDateKey != selectedDateKey) {
          continue;
        }

        activeBookedKeys.add(_slotDateKey(slotId, bookingDateKey));
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _slots = slots;
        _activeBookedSlotKeys = activeBookedKeys;
        _hasBookingLookup = true;
        _selectedSlotId = null;
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

  String _bookingStatus(Map<String, dynamic> booking) {
    return (booking['bookingStatus']?.toString() ?? '').trim().toLowerCase();
  }

  String _bookingDateKey(Map<String, dynamic> booking) {
    for (final String key in <String>['date', 'bookingDate', 'slotDate']) {
      final String raw = booking[key]?.toString().trim() ?? '';
      if (raw.isEmpty) {
        continue;
      }
      final RegExpMatch? ymd = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(raw);
      if (ymd != null) {
        return '${ymd.group(1)}-${ymd.group(2)}-${ymd.group(3)}';
      }
      final DateTime? parsed = DateTime.tryParse(raw);
      if (parsed != null) {
        return _apiDate(parsed.toLocal());
      }
    }
    return _apiDate(_selectedDate);
  }

  String _slotDateKey(String slotId, String dateKey) {
    return '$slotId|$dateKey';
  }

  String _effectiveSlotStatus(Map<String, dynamic> slot) {
    final String baseStatus =
        (slot['status']?.toString() ?? 'available').trim().toLowerCase();
    if (baseStatus != 'booked' || !_hasBookingLookup) {
      return baseStatus;
    }

    final String slotId = slot['_id']?.toString() ?? '';
    if (slotId.isEmpty) {
      return baseStatus;
    }

    final String slotDate = _apiDate(_selectedDate);
    final bool hasActiveBooking = _activeBookedSlotKeys.contains(
      _slotDateKey(slotId, slotDate),
    );
    return hasActiveBooking ? 'booked' : 'available';
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  int? _hourFromTime(String value) {
    final String raw = value.trim().toLowerCase();
    if (raw.isEmpty) {
      return null;
    }

    final RegExpMatch? match = RegExp(
      r'^(\d{1,2})(?::(\d{1,2}))?\s*(am|pm)?$',
      caseSensitive: false,
    ).firstMatch(raw);
    if (match == null) {
      return null;
    }

    int hour = int.tryParse(match.group(1) ?? '') ?? -1;
    if (hour < 0 || hour > 23) {
      return null;
    }

    final String meridiem = (match.group(3) ?? '').toLowerCase();
    if (meridiem == 'am') {
      if (hour == 12) {
        hour = 0;
      }
    } else if (meridiem == 'pm') {
      if (hour != 12) {
        hour += 12;
      }
    }

    if (hour < 0 || hour > 23) {
      return null;
    }
    return hour;
  }

  DateTime? _dateTimeFromSlotStart(DateTime date, String startTime) {
    final String raw = startTime.trim().toLowerCase();
    if (raw.isEmpty) {
      return null;
    }

    final RegExpMatch? match = RegExp(
      r'^(\d{1,2})(?::(\d{1,2}))?\s*(am|pm)?$',
      caseSensitive: false,
    ).firstMatch(raw);
    if (match == null) {
      return null;
    }

    int hour = int.tryParse(match.group(1) ?? '') ?? -1;
    int minute = int.tryParse(match.group(2) ?? '0') ?? -1;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }

    final String meridiem = (match.group(3) ?? '').toLowerCase();
    if (meridiem == 'am') {
      if (hour == 12) {
        hour = 0;
      }
    } else if (meridiem == 'pm') {
      if (hour != 12) {
        hour += 12;
      }
    }

    if (hour < 0 || hour > 23) {
      return null;
    }
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  bool _isPastSlotForSelectedDate(Map<String, dynamic> slot) {
    final DateTime today = _dateOnly(DateTime.now());
    final DateTime selected = _dateOnly(_selectedDate);
    if (selected.isAfter(today) || selected.isBefore(today)) {
      return false;
    }

    final DateTime? slotStart = _dateTimeFromSlotStart(
      selected,
      slot['startTime']?.toString() ?? '',
    );
    if (slotStart == null) {
      return false;
    }
    return slotStart.isBefore(DateTime.now());
  }

  String _apiDate(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _formatSelectedDate(DateTime date) {
    const months = [
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

    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year} (${weekdays[date.weekday - 1]})';
  }

  String _weekDay(DateTime date) {
    const List<String> days = <String>[
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];
    return days[date.weekday - 1];
  }

  List<Map<String, dynamic>> _slotsForSection(int startHour, int endHour) {
    return _slots.where((Map<String, dynamic> slot) {
      if (_isPastSlotForSelectedDate(slot)) {
        return false;
      }
      final int? hour = _hourFromTime(slot['startTime']?.toString() ?? '');
      if (hour == null) {
        return false;
      }
      return hour >= startHour && hour < endHour;
    }).toList();
  }

  Color _slotBg(String status, bool selected) {
    if (selected) {
      return const Color(0xFF08B36A);
    }
    switch (status) {
      case 'booked':
        return const Color(0x330B84FF);
      case 'blocked':
        return const Color(0x33E53935);
      default:
        return const Color(0x14FFFFFF);
    }
  }

  Color _slotText(String status, bool selected) {
    if (selected) {
      return const Color(0xFF1C333B);
    }
    switch (status) {
      case 'booked':
        return const Color(0xFF0B84FF);
      case 'blocked':
        return const Color(0xFFE53935);
      default:
        return Colors.white;
    }
  }

  bool _isSlotSelectable(Map<String, dynamic> slot) {
    if (_isPastSlotForSelectedDate(slot)) {
      return false;
    }
    return _effectiveSlotStatus(slot) == 'available';
  }

  Map<String, dynamic>? get _selectedSlot {
    if (_selectedSlotId == null) {
      return null;
    }
    for (final Map<String, dynamic> slot in _slots) {
      if (slot['_id']?.toString() == _selectedSlotId) {
        return slot;
      }
    }
    return null;
  }

  Future<void> _continue() async {
    final Map<String, dynamic>? slot = _selectedSlot;
    if (slot == null) {
      return;
    }

    final String? groundId = await _resolveGroundId();
    if (!mounted) {
      return;
    }

    if (groundId == null || groundId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a ground first.')),
      );
      return;
    }
    ApiSession.instance.setGroundId(groundId);

    final BoxCricketBookingDraft draft = BoxCricketBookingDraft(
      slotId: slot['_id']?.toString() ?? '',
      date: _apiDate(_selectedDate),
      startTime: slot['startTime']?.toString() ?? '',
      endTime: slot['endTime']?.toString() ?? '',
      amount: (slot['price'] as num?)?.round() ?? 0,
    );

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BoxCricketBookingDetailsScreen(draft: draft),
      ),
    );

    if (!mounted) {
      return;
    }

    _loadSlots();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? selected = _selectedSlot;

    return Scaffold(
      backgroundColor: const Color(0xFF1B1F1B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1F1B),
        elevation: 0,
        title: const Text('Add Booking'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF08B36A)),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              children: <Widget>[
                const Text(
                  'Select Ground',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
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
                        setState(() {
                          _selectedGroundId = value;
                          _selectedSlotId = null;
                        });
                        ApiSession.instance.setGroundId(value);
                        _loadSlots();
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Date',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 78,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 8,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (BuildContext context, int index) {
                      if (index == 7) {
                        return InkWell(
                          onTap: () async {
                            final DateTime now = DateTime.now();
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate.isBefore(now)
                                  ? now
                                  : _selectedDate,
                              firstDate: DateTime(now.year, now.month, now.day),
                              lastDate: DateTime(now.year + 2, 12, 31),
                              builder: (BuildContext context, Widget? child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.dark(
                                      primary: Color(0xFF08B36A),
                                      onPrimary: Color(0xFF1C333B),
                                      surface: Color(0xFF1B1F1B),
                                    ),
                                  ),
                                  child: child ?? const SizedBox.shrink(),
                                );
                              },
                            );
                            if (picked == null || !mounted) {
                              return;
                            }
                            setState(() {
                              _selectedDate = _dateOnly(picked);
                              _selectedSlotId = null;
                            });
                            _loadSlots();
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 92,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: const Color(0x0DFFFFFF),
                              border: Border.all(
                                color: const Color(0x1FFFFFFF),
                              ),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Icon(
                                  Icons.calendar_month_rounded,
                                  color: Color(0xCCFFFFFF),
                                  size: 20,
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Calendar',
                                  style: TextStyle(
                                    color: Color(0xCCFFFFFF),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      final DateTime date = DateTime.now().add(
                        Duration(days: index),
                      );
                      final bool selectedDate = DateUtils.isSameDay(
                        date,
                        _selectedDate,
                      );
                      return InkWell(
                        onTap: () {
                          setState(() => _selectedDate = date);
                          _loadSlots();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 62,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: selectedDate
                                ? const Color(0xFF08B36A)
                                : const Color(0x0DFFFFFF),
                            border: Border.all(color: const Color(0x1FFFFFFF)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                _weekDay(date),
                                style: TextStyle(
                                  color: selectedDate
                                      ? const Color(0xFF1C333B)
                                      : const Color(0xCCFFFFFF),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                date.day.toString().padLeft(2, '0'),
                                style: TextStyle(
                                  color: selectedDate
                                      ? const Color(0xFF1C333B)
                                      : Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x0AFFFFFF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x1FFFFFFF)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        color: Color(0xFF08B36A),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Selected Date: ${_formatSelectedDate(_selectedDate)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                const SizedBox(height: 14),
                Wrap(
                  spacing: 14,
                  runSpacing: 10,
                  children: <Widget>[
                    _legend(const Color(0xFF08B36A), 'Available'),
                    _legend(const Color(0xFF0B84FF), 'Booked'),
                    _legend(const Color(0xFFE53935), 'Blocked'),
                  ],
                ),
                const SizedBox(height: 16),
                _slotSection('Morning', _slotsForSection(0, 12)),
                const SizedBox(height: 16),
                _slotSection('Afternoon', _slotsForSection(12, 17)),
                const SizedBox(height: 16),
                _slotSection('Evening', _slotsForSection(17, 24)),
                const SizedBox(height: 16),
                if (selected != null)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0x0AFFFFFF),
                      border: Border.all(color: const Color(0x1FFFFFFF)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Selected Slot',
                          style: TextStyle(
                            color: Color(0x99FFFFFF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${selected['startTime']} - ${selected['endTime']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rs ${(selected['price'] as num?)?.round() ?? 0}',
                          style: const TextStyle(
                            color: Color(0xFF08B36A),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _selectedSlot == null ? null : _continue,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF08B36A),
                foregroundColor: const Color(0xFF1C333B),
                disabledBackgroundColor: const Color(0x2212B76A),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 13),
        ),
      ],
    );
  }

  Widget _slotSection(String title, List<Map<String, dynamic>> sectionSlots) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0x0AFFFFFF),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          if (sectionSlots.isEmpty)
            const Text(
              'No slots available',
              style: TextStyle(color: Color(0x99FFFFFF)),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sectionSlots.map((Map<String, dynamic> slot) {
                final String slotId = slot['_id']?.toString() ?? '';
                final String status = _effectiveSlotStatus(slot);
                final bool selected = _selectedSlotId == slotId;
                final bool canSelect = _isSlotSelectable(slot);

                return GestureDetector(
                  onTap: canSelect
                      ? () => setState(() => _selectedSlotId = slotId)
                      : null,
                  child: Container(
                    width: 104,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: _slotBg(status, selected),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF08B36A)
                            : const Color(0x1FFFFFFF),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${slot['startTime']} - ${slot['endTime']}',
                          style: TextStyle(
                            color: _slotText(status, selected),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Rs ${(slot['price'] as num?)?.round() ?? 0}',
                          style: TextStyle(
                            color: _slotText(status, selected),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
