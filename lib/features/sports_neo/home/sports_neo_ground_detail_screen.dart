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
  bool _isLoadingSlots = false;
  List<Map<String, dynamic>> _slots = <Map<String, dynamic>>[];
  String? _selectedSlotId;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _loadSlots();
  }

  String _apiDate(DateTime date) {
    final String m = date.month.toString().padLeft(2, '0');
    final String d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  Future<void> _loadSlots() async {
    if (widget.groundId.isEmpty) {
      return;
    }
    setState(() => _isLoadingSlots = true);
    try {
      final List<Map<String, dynamic>> slots =
          await GroundWaleApi.instance.listSlots(
        widget.groundId,
        date: _apiDate(_selectedDate),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _slots = slots;
        _selectedSlotId = null;
        _isLoadingSlots = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
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
    final String status =
        (slot['status']?.toString() ?? 'available').toLowerCase();
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
            if (status == 'Available') {
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

    final DateTime today = DateTime.now();
    final List<DateTime> dateDays = List<DateTime>.generate(
      7,
      (int i) {
        final DateTime d = today.add(Duration(days: i));
        return DateTime(d.year, d.month, d.day);
      },
    );
    const List<String> _weekLabels = <String>[
      'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
    ];

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
                      selPrice > 0 ? 'â‚¹$selPrice' : widget.price,
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
                                      SizedBox(
                                        height: 78,
                                        child: ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: dateDays.length,
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(width: 12),
                                          itemBuilder: (
                                            BuildContext ctx,
                                            int i,
                                          ) {
                                            final DateTime d = dateDays[i];
                                            final bool sel =
                                                _selectedDate.year ==
                                                        d.year &&
                                                    _selectedDate.month ==
                                                        d.month &&
                                                    _selectedDate.day == d.day;
                                            return GestureDetector(
                                              onTap: () {
                                                setState(
                                                  () => _selectedDate = d,
                                                );
                                                _loadSlots();
                                              },
                                              child: _DateChip(
                                                label:
                                                    _weekLabels[d.weekday - 1],
                                                day: '${d.day}',
                                                selected: sel,
                                              ),
                                            );
                                          },
                                        ),
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
          const Spacer(),
          _RoundIcon(icon: Icons.notifications_none_rounded),
          const SizedBox(width: 8),
          _RoundIcon(icon: Icons.shopping_cart_outlined),
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

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.label,
    required this.day,
    this.selected = false,
  });

  final String label;
  final String day;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        color: selected ? const Color(0xFF2563EB) : Colors.transparent,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFFDDDDDD),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            day,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFFDDDDDD),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
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
