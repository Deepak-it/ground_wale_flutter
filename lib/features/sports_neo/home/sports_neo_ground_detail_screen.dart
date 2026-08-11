import 'package:flutter/material.dart';

import '../../../core/api/ground_wale_api.dart';
import '../../../core/utils/base64_image.dart';
import 'sports_neo_booking_summary_screen.dart';

class SportsNeoGroundDetailScreen extends StatefulWidget {
  const SportsNeoGroundDetailScreen({
    super.key,
    required this.name,
    required this.location,
    required this.image,
    required this.rating,
    required this.facilities,
    required this.price,
    this.groundId = '',
  });

  final String name;
  final String location;
  final String image;
  final double rating;
  final List<String> facilities;
  final String price;
  final String groundId;

  @override
  State<SportsNeoGroundDetailScreen> createState() =>
      _SportsNeoGroundDetailScreenState();
}

class _SportsNeoGroundDetailScreenState
    extends State<SportsNeoGroundDetailScreen> {
  late DateTime _selectedDate;
  late DateTime _visibleMonth;
  bool _isLoadingSlots = false;
  List<Map<String, dynamic>> _slots = <Map<String, dynamic>>[];
  String? _selectedSlotId;
  Set<String> _activeBookedSlotKeys = <String>{};
  bool _hasBookingLookup = false;
  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _visibleMonth = DateTime(now.year, now.month, 1);
    _loadSlots();
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
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

  void _selectCalendarDate(DateTime date) {
    setState(() {
      _selectedDate = _dateOnly(date);
      _visibleMonth = DateTime(date.year, date.month, 1);
      _selectedSlotId = null;
    });
    _loadSlots();
  }

  void _goToPreviousMonth() {
    final DateTime today = _dateOnly(DateTime.now());
    final DateTime previous = DateTime(_visibleMonth.year, _visibleMonth.month - 1, 1);
    final DateTime firstAllowed = DateTime(today.year, today.month, 1);
    if (previous.isBefore(firstAllowed)) {
      return;
    }
    setState(() => _visibleMonth = previous);
  }

  void _goToNextMonth() {
    final DateTime today = _dateOnly(DateTime.now());
    final DateTime lastAllowed = DateTime(today.year, today.month + 12, 1);
    final DateTime next = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 1);
    if (next.isAfter(lastAllowed)) {
      return;
    }
    setState(() => _visibleMonth = next);
  }

  String _apiDate(DateTime date) {
    final String m = date.month.toString().padLeft(2, '0');
    final String d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }
  String _bookingStatus(Map<String, dynamic> booking) {
    return (booking['bookingStatus']?.toString() ?? '')
        .trim()
        .toLowerCase();
  }

  String _bookingDateKey(Map<String, dynamic> booking) {
    for (final String key in <String>[
      'date',
      'bookingDate',
      'slotDate',
    ]) {
      final String raw = booking[key]?.toString().trim() ?? '';

      if (raw.isEmpty) continue;

      final RegExpMatch? ymd =
          RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(raw);

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
        (slot['status']?.toString() ?? 'available')
            .trim()
            .toLowerCase();

    if (baseStatus != 'booked' || !_hasBookingLookup) {
      return baseStatus;
    }

    final String slotId = _slotId(slot);

    if (slotId.isEmpty) {
      return baseStatus;
    }

    final String slotDate = _apiDate(_selectedDate);

    final bool hasActiveBooking = _activeBookedSlotKeys.contains(
      _slotDateKey(slotId, slotDate),
    );

    return hasActiveBooking ? 'booked' : 'available';
  }
  Future<void> _loadSlots() async {
    if (widget.groundId.isEmpty) {
      return;
    }

    setState(() => _isLoadingSlots = true);

    try {
      final List<dynamic> results = await Future.wait<dynamic>([
        GroundWaleApi.instance.listSlots(
          widget.groundId,
          date: _apiDate(_selectedDate),
        ),
        GroundWaleApi.instance.listBookings(widget.groundId),
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
        if (slotId.isEmpty) continue;

        final String bookingDateKey = _bookingDateKey(booking);

        if (bookingDateKey != selectedDateKey) continue;

        activeBookedKeys.add(_slotDateKey(slotId, bookingDateKey));
      }

      if (!mounted) return;

      setState(() {
        _slots = slots;
        _activeBookedSlotKeys = activeBookedKeys;
        _hasBookingLookup = true;
        _selectedSlotId = null;
        _isLoadingSlots = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() => _isLoadingSlots = false);
    }
  }

  int _slotPrice(Map<String, dynamic> slot) {
    final dynamic p = slot['price'];
    if (p is int) {
      return p;
    }
    if (p is double) {
      return p.round();
    }
    if (p is String) {
      return int.tryParse(p) ?? 0;
    }
    return 0;
  }

  String _slotId(Map<String, dynamic> slot) {
    return slot['_id']?.toString() ?? slot['id']?.toString() ?? '';
  }

  int _hourFromTime(String time) {
    final RegExpMatch? match = RegExp(r'^(\d{1,2})').firstMatch(time);
    if (match == null) {
      return 0;
    }
    int h = int.tryParse(match.group(1) ?? '') ?? 0;
    final String upper = time.toUpperCase();
    if (upper.contains('PM') && h < 12) {
      h += 12;
    }
    if (upper.contains('AM') && h == 12) {
      h = 0;
    }
    return h;
  }

  List<Map<String, dynamic>> _slotsForSection(int startHour, int endHour) {
    return _slots.where((Map<String, dynamic> s) {
      final int h = _hourFromTime(s['startTime']?.toString() ?? '');
      return h >= startHour && h < endHour;
    }).toList();
  }

  _SlotItem _toSlotItem(Map<String, dynamic> slot) {

    final String status = _effectiveSlotStatus(slot);
    final String statusLabel = status == 'booked'
        ? 'Booked'
        : status == 'blocked'
            ? 'Blocked'
            : 'Available';

    Color colorA, colorB;
    if (status == 'booked') {
      colorA = const Color(0xFFE5C28F);
      colorB = const Color(0xFFDE8E19);
    } else if (status == 'blocked') {
      colorA = const Color(0xFF629CDD);
      colorB = const Color(0xFF1F5C9F);
    } else {
      colorA = const Color(0xFF77A2C4);
      colorB = const Color(0xFF7FC2F9);
    }

    final int price = _slotPrice(slot);
    return _SlotItem(
      time:
          '${slot['startTime'] ?? ''} - ${slot['endTime'] ?? ''}'.trim(),
      weather: price > 0 ? 'Rs $price' : '',
      temp: '',
      status: statusLabel,
      colorA: colorA,
      colorB: colorB,
    );
  }

  Map<String, dynamic>? get _selectedSlot {
    if (_selectedSlotId == null) {
      return null;
    }
    for (final Map<String, dynamic> s in _slots) {
      if (_slotId(s) == _selectedSlotId) {
        return s;
      }
    }
    return null;
  }

  Widget _buildSlotSections() {
    if (widget.groundId.isEmpty) {
      return const SizedBox.shrink();
    }
    if (_isLoadingSlots) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF2563EB)),
        ),
      );
    }
    if (_slots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0x0AFFFFFF),
          border: Border.all(color: const Color(0x1FFFFFFF)),
        ),
        child: const Text(
          'No slots available for this date.',
          style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 14),
        ),
      );
    }

    final List<Widget> sections = <Widget>[];
    final Map<String, List<Map<String, dynamic>>> sectionMap =
        <String, List<Map<String, dynamic>>>{
      'Morning': _slotsForSection(5, 12),
      'Afternoon': _slotsForSection(12, 17),
      'Evening': _slotsForSection(17, 24),
    };

    for (final MapEntry<String, List<Map<String, dynamic>>> entry
        in sectionMap.entries) {
      if (entry.value.isEmpty) {
        continue;
      }
      if (sections.isNotEmpty) {
        sections.add(const SizedBox(height: 16));
      }
      sections.add(
        _SlotSection(
          title: entry.key,
          slots: entry.value
              .map((Map<String, dynamic> slot) => _toSlotItem(slot))
              .toList(),
          selectedId: _selectedSlotId,
          slotIds:
              entry.value.map((Map<String, dynamic> s) => _slotId(s)).toList(),
          onSlotTap: (String id, String status) {
            if (status.toLowerCase() == 'available') {
              setState(
                () => _selectedSlotId = _selectedSlotId == id ? null : id,
              );
            }
          },
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> shownFacilities = widget.facilities.isEmpty
        ? const <String>['Parking', 'Washroom', 'Water', 'Lighting']
        : widget.facilities;

    final Map<String, dynamic>? selSlot = _selectedSlot;
    final int selPrice = selSlot != null ? _slotPrice(selSlot) : 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF0A0F1E),
            border: Border(top: BorderSide(color: Color(0x1F000000))),
            boxShadow: <BoxShadow>[
              BoxShadow(color: Color(0x0F000000), blurRadius: 24),
            ],
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      selSlot != null ? '1 slot(s) selected' : 'No slot selected',
                      style: const TextStyle(
                        color: Color(0x99FFFFFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      selPrice > 0 ? 'Rs $selPrice' : widget.price,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2563EB)),
                ),
                child: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: selSlot == null
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => SportsNeoBookingSummaryScreen(
                                groundName: widget.name,
                                location: widget.location,
                                slotId: _slotId(selSlot),
                                date: _apiDate(_selectedDate),
                                startTime:
                                    selSlot['startTime']?.toString() ?? '',
                                endTime: selSlot['endTime']?.toString() ?? '',
                                amount: selPrice,
                                groundId: widget.groundId,
                              ),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    disabledBackgroundColor: const Color(0x662563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Book Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          Positioned(
            top: 104,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 240,
              child: buildBase64OrNetworkImage(
                value: widget.image,
                fit: BoxFit.cover,
                fallback: Container(
                  color: const Color(0xFF1E293B),
                  child: const Icon(
                    Icons.image_outlined,
                    color: Colors.white54,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: <Widget>[
                _TopHeader(
                  title: 'Ground Detail',
                  onBack: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Stack(
                    children: <Widget>[
                      Positioned(
                        top: 224,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF0A0F1E),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Column(
                              children: <Widget>[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.fromLTRB(
                                    16, 20, 16, 16,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF0A0F1E),
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(24),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: <Widget>[
                                                Text(
                                                  widget.name,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: <Widget>[
                                                    const Icon(
                                                      Icons
                                                          .location_on_outlined,
                                                      color: Color(0x99FFFFFF),
                                                      size: 18,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        widget.location,
                                                        style: const TextStyle(
                                                          color:
                                                              Color(0x99FFFFFF),
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0x3DFFFFFF),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              children: <Widget>[
                                                const Icon(
                                                  Icons.star_border_rounded,
                                                  color: Color(0xFFEAB308),
                                                  size: 14,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  widget.rating > 0
                                                      ? widget.rating
                                                          .toStringAsFixed(1)
                                                      : '4.6',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 4,
                                        runSpacing: 4,
                                        children: shownFacilities
                                            .take(4)
                                            .map((String f) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              color: const Color(0x14FFFFFF),
                                            ),
                                            child: Text(
                                              f,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16, 24, 16, 0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      _PanelCard(
                                        title: 'About Us',
                                        child: const Text(
                                          'Professional cricket ground with well-maintained turf pitch. '
                                          'Suitable for practice matches and tournaments.',
                                          style: TextStyle(
                                            color: Color(0xFFDDDDDD),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: const Color(0x1F2563EB),
                                          ),
                                          color: const Color(0x0A2563EB),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            _CircleAction(
                                              icon: Icons.call,
                                              color: const Color(0xFF08B36A),
                                            ),
                                            _divider(),
                                            _CircleAction(
                                              icon: Icons.near_me_rounded,
                                              color: const Color(0xFFDA321F),
                                            ),
                                            _divider(),
                                            _CircleAction(
                                              icon: Icons.chat,
                                              color: const Color(0xFF22C55E),
                                            ),
                                            _divider(),
                                            _CircleAction(
                                              icon: Icons.sports_cricket,
                                              color: Colors.white,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const _SectionTitle(title: 'Select Date'),
                                      const SizedBox(height: 12),
                                      _MonthCalendarCard(
                                        monthLabel: _monthLabel(_visibleMonth),
                                        days: _calendarGridDays(_visibleMonth),
                                        selectedDate: _selectedDate,
                                        visibleMonth: _visibleMonth,
                                        minDate: _dateOnly(DateTime.now()),
                                        maxDate: _dateOnly(
                                          DateTime.now().add(const Duration(days: 365)),
                                        ),
                                        onPreviousMonth: _goToPreviousMonth,
                                        onNextMonth: _goToNextMonth,
                                        onSelectDate: _selectCalendarDate,
                                      ),
                                      const SizedBox(height: 16),
                                      const _SlotLegend(),
                                      const SizedBox(height: 16),
                                      _buildSlotSections(),
                                      const SizedBox(height: 8),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 49,
      color: const Color(0x1FFFFFFF),
    );
  }
}


class _TopHeader extends StatelessWidget {
  const _TopHeader({
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF121C3E),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Row(
        children: <Widget>[
          Row(
            children: <Widget>[
              InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0x26FFFFFF),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0x0AFFFFFF),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 26),
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFDDDDDD),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFFDDDDDD),
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _MonthCalendarCard extends StatelessWidget {
  const _MonthCalendarCard({
    required this.monthLabel,
    required this.days,
    required this.selectedDate,
    required this.visibleMonth,
    required this.minDate,
    required this.maxDate,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onSelectDate,
  });

  final String monthLabel;
  final List<DateTime> days;
  final DateTime selectedDate;
  final DateTime visibleMonth;
  final DateTime minDate;
  final DateTime maxDate;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onSelectDate;

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  @override
  Widget build(BuildContext context) {
    const List<String> weekLabels = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final DateTime firstAllowedMonth = DateTime(minDate.year, minDate.month, 1);
    final DateTime lastAllowedMonth = DateTime(maxDate.year, maxDate.month, 1);
    final bool canGoPrevious = !visibleMonth.isBefore(firstAllowedMonth) &&
        visibleMonth != firstAllowedMonth;
    final bool canGoNext = !visibleMonth.isAfter(lastAllowedMonth) &&
        visibleMonth != lastAllowedMonth;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0x0AFFFFFF),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                onPressed: canGoPrevious ? onPreviousMonth : null,
                icon: const Icon(Icons.chevron_left_rounded),
                color: Colors.white,
              ),
              Expanded(
                child: Text(
                  monthLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: canGoNext ? onNextMonth : null,
                icon: const Icon(Icons.chevron_right_rounded),
                color: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: weekLabels
                .map(
                  (String label) => Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Color(0x99FFFFFF),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemBuilder: (BuildContext context, int index) {
              final DateTime day = days[index];
              final bool inMonth = day.month == visibleMonth.month &&
                  day.year == visibleMonth.year;
              final bool disabled = day.isBefore(minDate) || day.isAfter(maxDate) || !inMonth;
              final bool selected = _isSameDay(day, selectedDate);

              return InkWell(
                onTap: disabled ? null : () => onSelectDate(day),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: selected
                        ? const Color(0xFF2563EB)
                        : disabled
                            ? const Color(0x05000000)
                            : const Color(0x12FFFFFF),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF2563EB)
                          : const Color(0x1FFFFFFF),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : disabled
                              ? const Color(0x55FFFFFF)
                              : const Color(0xFFDDDDDD),
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SlotLegend extends StatelessWidget {
  const _SlotLegend();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const <Widget>[
        _LegendItem(label: 'Available', color: Color(0xFF08B36A)),
        _LegendItem(label: 'Booked', color: Color(0x99DDDDDD)),
        _LegendItem(label: 'Blocked', color: Color(0xFFD73321)),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFDDDDDD),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SlotSection extends StatelessWidget {
  const _SlotSection({
    required this.title,
    required this.slots,
    this.selectedId,
    this.slotIds = const <String>[],
    this.onSlotTap,
  });

  final String title;
  final List<_SlotItem> slots;
  final String? selectedId;
  final List<String> slotIds;
  final void Function(String id, String status)? onSlotTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFDDDDDD),
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        ...List<Widget>.generate(slots.length, (int i) {
          final _SlotItem slot = slots[i];
          final String id = i < slotIds.length ? slotIds[i] : '';
          final bool selected = id.isNotEmpty && id == selectedId;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: onSlotTap != null && id.isNotEmpty
                  ? () => onSlotTap!(id, slot.status)
                  : null,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: selected
                      ? Border.all(color: const Color(0xFF2563EB), width: 2)
                      : null,
                ),
                child: _SlotCard(slot: slot),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _SlotItem {
  const _SlotItem({
    required this.time,
    required this.weather,
    required this.temp,
    required this.status,
    required this.colorA,
    required this.colorB,
  });

  final String time;
  final String weather;
  final String temp;
  final String status;
  final Color colorA;
  final Color colorB;
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({required this.slot});

  final _SlotItem slot;

  @override
  Widget build(BuildContext context) {
    final Color statusColor = slot.status == 'Available'
        ? const Color(0xFF08B36A)
        : slot.status == 'Booked'
        ? const Color(0xFF6B7280)
        : const Color(0xFFDB3220);

    return Container(
      width: double.infinity,
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: <Color>[slot.colorA, slot.colorB],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  slot.time,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${slot.weather}  ${slot.temp}',
                  style: const TextStyle(
                    color: Color(0xCCFFFFFF),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              slot.status,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
