import 'package:flutter/material.dart';

import '../../../../core/api/api_session.dart';
import '../../../../core/api/ground_wale_api.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../controllers/ground_flow_controller.dart';
import '../models/ground_registration_data.dart';

class SlotManagementScreen extends StatefulWidget {
  const SlotManagementScreen({super.key, this.controller});

  final GroundFlowController? controller;

  @override
  State<SlotManagementScreen> createState() => _SlotManagementScreenState();
}

class _SlotManagementScreenState extends State<SlotManagementScreen> {
  final GroundWaleApi _api = GroundWaleApi.instance;
  final ApiSession _session = ApiSession.instance;

  bool _isSaving = false;
  bool _isLoading = true;
  bool _isApplyingGroupPrice = false;
  DateTime _startDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  DateTime _endDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day + 30,
  );
  List<_DayPricingConfig> _dayConfigs = <_DayPricingConfig>[];

  @override
  void initState() {
    super.initState();
    _initializeDayConfigs();
    _hydrateFromController();
    _loadFromApi();
  }

  @override
  void dispose() {
    for (final _DayPricingConfig day in _dayConfigs) {
      day.dispose();
    }
    super.dispose();
  }

  void _initializeDayConfigs() {
    _dayConfigs = <_DayPricingConfig>[
      _DayPricingConfig(
        dayLabel: 'Monday',
        shortDay: 'Mon',
        enabled: true,
        expanded: true,
      ),
      _DayPricingConfig(dayLabel: 'Tuesday', shortDay: 'Tue', enabled: true),
      _DayPricingConfig(dayLabel: 'Wednesday', shortDay: 'Wed', enabled: true),
      _DayPricingConfig(dayLabel: 'Thursday', shortDay: 'Thu', enabled: true),
      _DayPricingConfig(dayLabel: 'Friday', shortDay: 'Fri', enabled: true),
      _DayPricingConfig(
        dayLabel: 'Saturday',
        shortDay: 'Sat',
        enabled: true,
        isWeekend: true,
      ),
      _DayPricingConfig(
        dayLabel: 'Sunday',
        shortDay: 'Sun',
        enabled: false,
        isWeekend: true,
      ),
    ];
  }

  void _hydrateFromController() {
    final GroundFlowController? controller = widget.controller;
    if (controller == null) {
      return;
    }
    final GroundRegistrationData data = controller.data;
    _startDate = _dateOnly(data.startDate);
    _endDate = _dateOnly(data.endDate);
    final Map<String, DaySlotConfig> byDay = <String, DaySlotConfig>{
      for (final DaySlotConfig day in data.daySlots) day.day: day,
    };
    for (final _DayPricingConfig day in _dayConfigs) {
      final DaySlotConfig? saved = byDay[day.shortDay];
      if (saved == null) {
        continue;
      }
      day.enabled = saved.isEnabled;
      final int count = saved.slotsPerDay < 0 ? 0 : saved.slotsPerDay;
      if (count == 0) {
        day.slots = <_EditableSlot>[];
      } else {
        day.slots = _defaultSlots().take(count).map((_EditableSlot template) {
          return _EditableSlot(
            icon: template.icon,
            startTime: template.startTime,
            endTime: template.endTime,
            price: template.priceController.text,
          );
        }).toList();
      }
      if (saved.startTime.trim().isNotEmpty && day.slots.isNotEmpty) {
        final _EditableSlot first = day.slots.first;
        final List<String> parts = saved.startTime.split('-');
        if (parts.length == 2) {
          first.startTime = parts.first.trim();
          first.endTime = parts.last.trim();
        } else {
          first.startTime = saved.startTime;
        }
      }
    }
  }

  List<_EditableSlot> _defaultSlots() {
    return <_EditableSlot>[
      _EditableSlot(
        icon: Icons.wb_sunny_outlined,
        startTime: '06:00 AM',
        endTime: '09:00 AM',
        price: '500',
      ),
      _EditableSlot(
        icon: Icons.sunny,
        startTime: '09:00 AM',
        endTime: '01:00 PM',
        price: '500',
      ),
      _EditableSlot(
        icon: Icons.nights_stay_outlined,
        startTime: '07:00 PM',
        endTime: '10:00 PM',
        price: '500',
      ),
    ];
  }

  Future<void> _loadFromApi() async {
    // Registration mode: no ground exists yet, skip API load.
    if (widget.controller != null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    final String? groundId = await _resolveGroundId();
    if (groundId == null || groundId.isEmpty) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      final Map<String, dynamic> ground = await _api.getGround(groundId);
      final DateTime? start = _tryParseDate(ground['startDate']);
      final DateTime? end = _tryParseDate(ground['endDate']);
      final List<dynamic> rawDays =
          ground['daySlots'] as List<dynamic>? ?? <dynamic>[];

      if (start != null) {
        _startDate = start;
      }
      if (end != null) {
        _endDate = end;
      }

      final Map<String, dynamic> byDay = <String, dynamic>{};
      for (final dynamic raw in rawDays) {
        if (raw is! Map) {
          continue;
        }
        final Map<String, dynamic> map = Map<String, dynamic>.from(raw);
        final String key = map['day']?.toString() ?? '';
        if (key.isNotEmpty) {
          byDay[key] = map;
        }
      }

      for (final _DayPricingConfig day in _dayConfigs) {
        final Map<String, dynamic>? saved =
            byDay[day.shortDay] as Map<String, dynamic>?;
        if (saved == null) {
          continue;
        }
        day.enabled = saved['isEnabled'] as bool? ?? day.enabled;
        final int slotsPerDay = _toInt(saved['slotsPerDay']);
        if (slotsPerDay <= 0) {
          day.slots = <_EditableSlot>[];
        } else {
          day.slots = _defaultSlots().take(slotsPerDay).map((
            _EditableSlot template,
          ) {
            return _EditableSlot(
              icon: template.icon,
              startTime: template.startTime,
              endTime: template.endTime,
              price: template.priceController.text,
            );
          }).toList();
        }
      }
    } catch (_) {
      // Keep local defaults if API load fails.
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DateTime? _tryParseDate(dynamic raw) {
    final String value = raw?.toString() ?? '';
    if (value.trim().isEmpty) {
      return null;
    }
    final DateTime? parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return null;
    }
    final DateTime local = parsed.toLocal();
    return DateTime(local.year, local.month, local.day);
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

  String _apiDate(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<String?> _resolveGroundId() async {
    if (_session.hasGround) {
      return _session.groundId;
    }
    final String? ownerId = _session.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      return null;
    }
    final String? resolved = await _api.ensureGroundIdForOwner(ownerId);
    if (resolved != null && resolved.isNotEmpty) {
      _session.setGroundId(resolved);
    }
    return resolved;
  }

  Future<void> _pickDate(bool isStart) async {
    final DateTime initialDate = isStart ? _startDate : _endDate;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = _dateOnly(picked);
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = _dateOnly(picked);
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  int _totalEnabledDays() {
    return _dayConfigs.where((_DayPricingConfig day) => day.enabled).length;
  }

  int _totalSlots() {
    int total = 0;
    for (final _DayPricingConfig day in _dayConfigs) {
      if (!day.enabled) {
        continue;
      }
      total += day.slots.length;
    }
    return total;
  }

  void _applyGroupPriceFromFirstSlot({
    required _DayPricingConfig sourceDay,
    required int slotIndex,
    required String rawValue,
  }) {
    if (_isApplyingGroupPrice || slotIndex != 0) {
      return;
    }

    final String price = rawValue.trim();
    _isApplyingGroupPrice = true;
    try {
      for (final _DayPricingConfig day in _dayConfigs) {
        if (day.isWeekend != sourceDay.isWeekend) {
          continue;
        }
        for (int i = 0; i < day.slots.length; i++) {
          if (identical(day, sourceDay) && i == slotIndex) {
            continue;
          }
          final TextEditingController controller = day.slots[i].priceController;
          if (controller.text == price) {
            continue;
          }
          controller.value = TextEditingValue(
            text: price,
            selection: TextSelection.collapsed(offset: price.length),
          );
        }
      }
    } finally {
      _isApplyingGroupPrice = false;
    }
  }

  Future<void> _persistGroundConfiguration(String groundId) async {
    final List<Map<String, dynamic>> payloadDaySlots = _dayConfigs.map((
      _DayPricingConfig day,
    ) {
      final String start = day.slots.isNotEmpty
          ? '${day.slots.first.startTime} - ${day.slots.first.endTime}'
          : '06:00 AM - 09:00 AM';
      return <String, dynamic>{
        'day': day.shortDay,
        'isEnabled': day.enabled,
        'slotsPerDay': day.enabled ? day.slots.length : 0,
        'startTime': start,
      };
    }).toList();

    await _api.updateGround(groundId, <String, dynamic>{
      'startDate': _startDate.toIso8601String(),
      'endDate': _endDate.toIso8601String(),
      'daySlots': payloadDaySlots,
    });
  }

  Future<void> _syncSlotsCollection(String groundId) async {
    final List<Map<String, dynamic>> existing = await _api.listSlots(
      groundId,
      from: _apiDate(_startDate),
      to: _apiDate(_endDate),
    );

    final Set<String> existingKeys = <String>{};
    for (final Map<String, dynamic> slot in existing) {
      final DateTime? parsed = _tryParseDate(slot['date']);
      if (parsed == null) {
        continue;
      }
      final String key =
          '${_apiDate(parsed)}|${slot['startTime'] ?? ''}|${slot['endTime'] ?? ''}';
      existingKeys.add(key);
    }

    final Map<int, _DayPricingConfig> byWeekday = <int, _DayPricingConfig>{
      DateTime.monday: _dayConfigs[0],
      DateTime.tuesday: _dayConfigs[1],
      DateTime.wednesday: _dayConfigs[2],
      DateTime.thursday: _dayConfigs[3],
      DateTime.friday: _dayConfigs[4],
      DateTime.saturday: _dayConfigs[5],
      DateTime.sunday: _dayConfigs[6],
    };

    for (
      DateTime cursor = _startDate;
      !cursor.isAfter(_endDate);
      cursor = cursor.add(const Duration(days: 1))
    ) {
      final _DayPricingConfig? config = byWeekday[cursor.weekday];
      if (config == null || !config.enabled) {
        continue;
      }
      for (final _EditableSlot slot in config.slots) {
        final String key =
            '${_apiDate(cursor)}|${slot.startTime}|${slot.endTime}';
        if (existingKeys.contains(key)) {
          continue;
        }
        final int price = int.tryParse(slot.priceController.text.trim()) ?? 0;
        await _api.createSlot(groundId, <String, dynamic>{
          'date': _apiDate(cursor),
          'startTime': slot.startTime,
          'endTime': slot.endTime,
          'price': price,
          'status': 'available',
        });
        existingKeys.add(key);
      }
    }
  }

  void _syncToFlowData() {
    final GroundFlowController? controller = widget.controller;
    if (controller == null) {
      return;
    }
    final GroundRegistrationData data = controller.data;
    data.startDate = _startDate;
    data.endDate = _endDate;
    data.daySlots
      ..clear()
      ..addAll(
        _dayConfigs.map((_DayPricingConfig day) {
          final String start = day.slots.isNotEmpty
              ? '${day.slots.first.startTime} - ${day.slots.first.endTime}'
              : '06:00 AM - 09:00 AM';
          return DaySlotConfig(
            day: day.shortDay,
            isEnabled: day.enabled,
            slotsPerDay: day.enabled ? day.slots.length : 0,
            startTime: start,
          );
        }).toList(),
      );
    controller.update();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      _syncToFlowData();

      // ── Registration mode: no API calls, just navigate ────────────────
      if (widget.controller != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pricing saved.')),
        );
        widget.controller!.nextStep();
        return;
      }

      // ── Standalone / post-login mode: full API sync ───────────────────
      String? groundId = await _resolveGroundId();
      if (groundId != null && groundId.isNotEmpty) {
        await _persistGroundConfiguration(groundId);
        await _syncSlotsCollection(groundId);
      }

      if (!mounted) {
        return;
      }
      final String title = _slotViewTitle();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title saved successfully.')),
      );

      if (widget.controller != null) {
        widget.controller!.nextStep();
      } else {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _cancel() {
    if (widget.controller != null) {
      widget.controller!.previousStep();
      return;
    }
    Navigator.of(context).maybePop();
  }

  String _slotViewTitle() {
    final String configured = widget.controller?.data.slotViewName.trim() ?? '';
    if (configured.isNotEmpty) {
      return configured;
    }
    return 'Day-wise Pricing';
  }

  String _dateRangeLabel() {
    final List<String> shortWeek = <String>[
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];
    final List<String> shortMonth = <String>[
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
    final DateTime a = _startDate;
    final DateTime b = _endDate;
    return '${shortWeek[a.weekday - 1]}, ${a.day} ${shortMonth[a.month - 1]} - ${shortWeek[b.weekday - 1]}, ${b.day} ${shortMonth[b.month - 1]} ${b.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D1D1D),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              const Color(0xFF22452E).withValues(alpha: 0.38),
              const Color(0xFF1D1D1D),
              const Color(0xFF151515),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFDDF730)),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: IconButton(
                            onPressed: _cancel,
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Color(0xFFDDF730),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _slotViewTitle(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 52),
                      child: Row(
                        children: <Widget>[
                          const Icon(
                            Icons.calendar_month_outlined,
                            size: 16,
                            color: Color(0xFFDDF730),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _dateRangeLabel(),
                              style: const TextStyle(
                                color: Color(0x99FFFFFF),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Day-wise Pricing',
                      style: TextStyle(
                        color: Color(0xFFE6F7EF),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Set prices and time slots for each day or the week.',
                      style: TextStyle(color: Color(0x99E6F7EF), fontSize: 10),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0x08FFFFFF),
                        border: Border.all(color: const Color(0x1FFFFFFF)),
                      ),
                      child: Column(
                        children: _dayConfigs.map((_DayPricingConfig day) {
                          return _dayCard(day);
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _dateStatCard(
                            icon: Icons.calendar_month_outlined,
                            label: 'Total Days',
                            value: '${_totalEnabledDays()} Days',
                            onTap: () => _pickDate(true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _dateStatCard(
                            icon: Icons.access_time,
                            label: 'Total Time Slots',
                            value: '${_totalSlots()} Slots',
                            onTap: () => _pickDate(false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton(
                              onPressed: _isSaving ? null : _cancel,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0x40FFFFFF),
                                ),
                                backgroundColor: const Color(0x1FFFFFFF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDDF730),
                                foregroundColor: const Color(0xFF1D1D1D),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Color(0xFF1D1D1D),
                                      ),
                                    )
                                  : const Text(
                                      'Save',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _dateStatCard({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0x08FFFFFF),
          border: Border.all(color: const Color(0x1FFFFFFF)),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 16, color: const Color(0xFFDDF730)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0x99E6F7EF),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Color(0xFFDDF730),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayCard(_DayPricingConfig day) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.only(bottom: day == _dayConfigs.last ? 0 : 14),
      decoration: BoxDecoration(
        border: day == _dayConfigs.last
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0x2EFFFFFF), width: 1),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Switch(
                    value: day.enabled,
                    activeThumbColor: const Color(0xFFFFFFFF),
                    activeTrackColor: const Color(0xFF08B36A),
                    inactiveTrackColor: const Color(0x3DFFFFFF),
                    inactiveThumbColor: const Color(0xFFFFFFFF),
                    onChanged: (bool value) {
                      setState(() {
                        day.enabled = value;
                        if (value && day.slots.isEmpty) {
                          day.slots = _defaultSlots();
                        }
                      });
                    },
                  ),
                  Text(
                    day.dayLabel,
                    style: const TextStyle(
                      color: Color(0xFFE6F7EF),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (day.isWeekend) ...<Widget>[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x1A00E36A),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'WEEKEND',
                        style: TextStyle(
                          color: Color(0xFF00E36A),
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              InkWell(
                onTap: () => setState(() => day.expanded = !day.expanded),
                child: Row(
                  children: <Widget>[
                    Text(
                      '${day.enabled ? day.slots.length : 0} slots',
                      style: const TextStyle(
                        color: Color(0xFFDDF730),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      day.expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: const Color(0xFFDDF730),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (day.expanded && day.enabled) ...<Widget>[
            const SizedBox(height: 10),
            SizedBox(
              height: 118,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: day.slots.length,
                separatorBuilder: (BuildContext context, int index) =>
                    const SizedBox(width: 8),
                itemBuilder: (_, int index) {
                  final _EditableSlot slot = day.slots[index];
                  return _slotTile(day, index, slot);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _slotTile(_DayPricingConfig day, int slotIndex, _EditableSlot slot) {
    return Container(
      width: 96,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x2EFFFFFF)),
        color: const Color(0x0DFFFFFF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Icon(slot.icon, size: 18, color: const Color(0xFFF59E0B)),
          const SizedBox(height: 8),
          Text(
            '${slot.startTime} - ${slot.endTime}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 9),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: const Color(0x14FFFFFF),
              border: Border.all(color: const Color(0x17FFFFFF)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'Rs',
                  style: TextStyle(
                    color: Color(0xFF8AA39A),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                SizedBox(
                  width: 38,
                  child: AppTextField(
                    controller: slot.priceController,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    onChanged: (String value) {
                      _applyGroupPriceFromFirstSlot(
                        sourceDay: day,
                        slotIndex: slotIndex,
                        rawValue: value,
                      );
                    },
                    style: const TextStyle(
                      color: Color(0xFFE6F7EF),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableSlot {
  _EditableSlot({
    required this.icon,
    required this.startTime,
    required this.endTime,
    required String price,
  }) : priceController = TextEditingController(text: price);

  final IconData icon;
  String startTime;
  String endTime;
  final TextEditingController priceController;

  String get price => priceController.text;

  void dispose() {
    priceController.dispose();
  }
}

class _DayPricingConfig {
  _DayPricingConfig({
    required this.dayLabel,
    required this.shortDay,
    required this.enabled,
    this.expanded = false,
    this.isWeekend = false,
    List<_EditableSlot>? slots,
  }) : slots =
           slots ??
           <_EditableSlot>[
             _EditableSlot(
               icon: Icons.wb_sunny_outlined,
               startTime: '06:00 AM',
               endTime: '09:00 AM',
               price: '500',
             ),
             _EditableSlot(
               icon: Icons.sunny,
               startTime: '09:00 AM',
               endTime: '01:00 PM',
               price: '500',
             ),
             _EditableSlot(
               icon: Icons.nights_stay_outlined,
               startTime: '07:00 PM',
               endTime: '10:00 PM',
               price: '500',
             ),
           ];

  final String dayLabel;
  final String shortDay;
  final bool isWeekend;
  bool enabled;
  bool expanded;
  List<_EditableSlot> slots;

  void dispose() {
    for (final _EditableSlot slot in slots) {
      slot.dispose();
    }
  }
}
