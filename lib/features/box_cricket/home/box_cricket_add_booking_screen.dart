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

class _BoxCricketAddBookingScreenState extends State<BoxCricketAddBookingScreen> {
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _slots = <Map<String, dynamic>>[];
  String? _selectedSlotId;

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    final String? groundId = ApiSession.instance.groundId;
    if (groundId == null || groundId.isEmpty) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final List<Map<String, dynamic>> slots = await GroundWaleApi.instance.listSlots(
        groundId,
        date: _apiDate(_selectedDate),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _slots = slots;
        _selectedSlotId = null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  int _hourFromTime(String value) {
    final RegExpMatch? match = RegExp(r'^(\d{1,2})').firstMatch(value);
    if (match == null) {
      return 0;
    }
    return int.tryParse(match.group(1) ?? '') ?? 0;
  }

  String _apiDate(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _weekDay(DateTime date) {
    const List<String> days = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  List<Map<String, dynamic>> _slotsForSection(int startHour, int endHour) {
    return _slots.where((Map<String, dynamic> slot) {
      final int hour = _hourFromTime(slot['startTime']?.toString() ?? '0');
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
    return (slot['status']?.toString() ?? 'available') == 'available';
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

    if (mounted) {
      _loadSlots();
    }
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
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF08B36A)))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              children: <Widget>[
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
                    itemCount: 7,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (BuildContext context, int index) {
                      final DateTime date = DateTime.now().add(Duration(days: index));
                      final bool selectedDate =
                          DateUtils.isSameDay(date, _selectedDate);
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
                final String status = slot['status']?.toString() ?? 'available';
                final bool selected = _selectedSlotId == slotId;
                final bool canSelect = _isSlotSelectable(slot);

                return GestureDetector(
                  onTap: canSelect
                      ? () => setState(() => _selectedSlotId = slotId)
                      : null,
                  child: Container(
                    width: 104,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
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
