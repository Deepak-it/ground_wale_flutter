import 'package:flutter/material.dart';

import '../../../../core/api/api_session.dart';
import '../../../../core/api/ground_wale_api.dart';
import '../controllers/ground_flow_controller.dart';
import '../models/ground_registration_data.dart';

class AddCustomSlotsScreen extends StatefulWidget {
  const AddCustomSlotsScreen({
    super.key,
    required this.data,
    this.showBackButton = true,
    this.controller,
  });

  final GroundRegistrationData data;
  final bool showBackButton;
  final GroundFlowController? controller;

  @override
  State<AddCustomSlotsScreen> createState() => _AddCustomSlotsScreenState();
}

class _AddCustomSlotsScreenState extends State<AddCustomSlotsScreen> {
  final GroundWaleApi _api = GroundWaleApi.instance;
  final ApiSession _session = ApiSession.instance;

  final TextEditingController _slotNameCtrl =
      TextEditingController(text: 'Morning slot');

  bool _isLoading = true;
  bool _isSavingAll = false;
  bool _isAdding = false;

  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _startTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 7, minute: 0);

  final List<_CustomSlotDraft> _items = <_CustomSlotDraft>[];

  @override
  void initState() {
    super.initState();
    _fromDate = _dateOnly(widget.data.startDate);
    _toDate = _dateOnly(widget.data.endDate);
    if (widget.data.slotViewName.trim().isNotEmpty) {
      _slotNameCtrl.text = widget.data.slotViewName.trim();
    }
    _loadExisting();
  }

  @override
  void dispose() {
    _slotNameCtrl.dispose();
    super.dispose();
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String _apiDate(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _fmtDateShort(DateTime date) {
    const List<String> day = <String>[
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];
    const List<String> month = <String>[
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
    return '${day[date.weekday - 1]}, ${date.day} ${month[date.month - 1]} ${date.year}';
  }

  String _fmtTime(TimeOfDay time) {
    int hour = time.hour;
    final int minute = time.minute;
    final String period = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) {
      hour = 12;
    }
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  TimeOfDay _parseTime(String raw) {
    final RegExp regExp = RegExp(r'^(\d{1,2}):(\d{2})\s*([AaPp][Mm])$');
    final RegExpMatch? match = regExp.firstMatch(raw.trim());
    if (match == null) {
      return const TimeOfDay(hour: 6, minute: 0);
    }
    int hour = int.tryParse(match.group(1) ?? '') ?? 6;
    final int minute = int.tryParse(match.group(2) ?? '') ?? 0;
    final String period = (match.group(3) ?? 'AM').toUpperCase();
    if (hour == 12) {
      hour = 0;
    }
    if (period == 'PM') {
      hour += 12;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  int _minutesBetween(TimeOfDay start, TimeOfDay end) {
    int startMins = start.hour * 60 + start.minute;
    int endMins = end.hour * 60 + end.minute;
    if (endMins <= startMins) {
      endMins += 24 * 60;
    }
    return endMins - startMins;
  }

  String _durationLabelFromMinutes(int minutes) {
    final int h = minutes ~/ 60;
    final int m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}h ${m.toString().padLeft(2, '0')}m';
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

  String? _slotId(Map<String, dynamic> map) {
    final String id = map['_id']?.toString() ?? map['id']?.toString() ?? '';
    return id.isEmpty ? null : id;
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

  Future<void> _loadExisting() async {
    try {
      final String? groundId = await _resolveGroundId();
      if (groundId == null || groundId.isEmpty) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      final DateTime from = _dateOnly(widget.data.startDate);
      final DateTime to = _dateOnly(widget.data.endDate);
      final List<Map<String, dynamic>> existing = await _api.listSlots(
        groundId,
        from: _apiDate(from),
        to: _apiDate(to),
      );

      final List<_CustomSlotDraft> loaded = <_CustomSlotDraft>[];
      for (final Map<String, dynamic> item in existing) {
        final DateTime? date = _tryParseDate(item['date']);
        if (date == null) {
          continue;
        }
        loaded.add(
          _CustomSlotDraft(
            id: _slotId(item),
            slotName: 'Morning slot',
            from: date,
            to: date,
            startTime: _parseTime(item['startTime']?.toString() ?? '06:00 AM'),
            endTime: _parseTime(item['endTime']?.toString() ?? '07:00 AM'),
            isPersisted: true,
          ),
        );
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _items
          ..clear()
          ..addAll(loaded);
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickDate(bool isFrom) async {
    final DateTime initial = isFrom ? _fromDate : _toDate;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      if (isFrom) {
        _fromDate = _dateOnly(picked);
        if (_toDate.isBefore(_fromDate)) {
          _toDate = _fromDate;
        }
      } else {
        _toDate = _dateOnly(picked);
        if (_toDate.isBefore(_fromDate)) {
          _fromDate = _toDate;
        }
      }
    });
  }

  Future<void> _pickTime(bool isStart) async {
    final TimeOfDay initial = isStart ? _startTime : _endTime;
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  Future<void> _addDraft() async {
    if (_isAdding || _isSavingAll) {
      return;
    }
    final String slotName = _slotNameCtrl.text.trim();
    if (slotName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Slot name is required.')),
      );
      return;
    }

    final int duration = _minutesBetween(_startTime, _endTime);
    if (duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }

    setState(() {
      _isAdding = true;
      widget.data.slotViewName = slotName;
      _items.insert(
        0,
        _CustomSlotDraft(
          slotName: slotName,
          from: _fromDate,
          to: _toDate,
          startTime: _startTime,
          endTime: _endTime,
          isPersisted: false,
        ),
      );
      _isAdding = false;
    });
  }

  Future<void> _deleteItem(int index) async {
    final _CustomSlotDraft draft = _items[index];
    if (draft.isPersisted && draft.id != null && draft.id!.isNotEmpty) {
      try {
        await _api.deleteSlot(draft.id!);
      } catch (error) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
        return;
      }
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _editItem(int index) async {
    final _CustomSlotDraft item = _items[index];
    final TextEditingController nameCtrl = TextEditingController(
      text: item.slotName,
    );
    DateTime from = item.from;
    DateTime to = item.to;
    TimeOfDay start = item.startTime;
    TimeOfDay end = item.endTime;

    final bool? save = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (
            BuildContext dialogInnerContext,
            void Function(void Function()) setDialog,
          ) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1D1D1D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Edit Slot',
                style: TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Slot Name',
                        labelStyle: TextStyle(color: Color(0x99FFFFFF)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final DateTime? picked = await showDatePicker(
                                context: dialogInnerContext,
                                initialDate: from,
                                firstDate: DateTime.now()
                                    .subtract(const Duration(days: 365)),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365 * 3)),
                              );
                              if (picked == null) {
                                return;
                              }
                              setDialog(() {
                                from = _dateOnly(picked);
                                if (to.isBefore(from)) {
                                  to = from;
                                }
                              });
                            },
                            child: Text(_fmtDateShort(from)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final DateTime? picked = await showDatePicker(
                                context: dialogInnerContext,
                                initialDate: to,
                                firstDate: DateTime.now()
                                    .subtract(const Duration(days: 365)),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365 * 3)),
                              );
                              if (picked == null) {
                                return;
                              }
                              setDialog(() {
                                to = _dateOnly(picked);
                                if (to.isBefore(from)) {
                                  from = to;
                                }
                              });
                            },
                            child: Text(_fmtDateShort(to)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final TimeOfDay? picked = await showTimePicker(
                                context: dialogInnerContext,
                                initialTime: start,
                              );
                              if (picked != null) {
                                setDialog(() => start = picked);
                              }
                            },
                            child: Text(_fmtTime(start)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final TimeOfDay? picked = await showTimePicker(
                                context: dialogInnerContext,
                                initialTime: end,
                              );
                              if (picked != null) {
                                setDialog(() => end = picked);
                              }
                            },
                            child: Text(_fmtTime(end)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (save != true || !mounted) {
      nameCtrl.dispose();
      return;
    }

    final _CustomSlotDraft updated = item.copyWith(
      slotName: nameCtrl.text.trim().isEmpty ? item.slotName : nameCtrl.text.trim(),
      from: from,
      to: to,
      startTime: start,
      endTime: end,
      isPersisted: false,
    );

    setState(() {
      _items[index] = updated;
    });
    nameCtrl.dispose();
  }

  Future<void> _saveAll() async {
    if (_isSavingAll) {
      return;
    }
    widget.data.slotViewName = _slotNameCtrl.text.trim().isEmpty
        ? widget.data.slotViewName
        : _slotNameCtrl.text.trim();

    String? groundId = await _resolveGroundId();
    if ((groundId == null || groundId.isEmpty) && widget.controller != null) {
      try {
        groundId = await widget.controller!.ensureDraftGroundId();
      } catch (_) {
        // If draft creation fails, fall through to existing error handling below.
      }
    }
    if (groundId == null || groundId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ground not found for this owner.')),
        );
      }
      return;
    }

    setState(() => _isSavingAll = true);
    try {
      final DateTime dateFrom = _dateOnly(widget.data.startDate);
      final DateTime dateTo = _dateOnly(widget.data.endDate);

      final List<Map<String, dynamic>> existing = await _api.listSlots(
        groundId,
        from: _apiDate(dateFrom),
        to: _apiDate(dateTo),
      );
      final Set<String> existingKeys = <String>{};
      for (final Map<String, dynamic> slot in existing) {
        final DateTime? d = _tryParseDate(slot['date']);
        if (d == null) {
          continue;
        }
        existingKeys.add(
          '${_apiDate(d)}|${slot['startTime']?.toString() ?? ''}|${slot['endTime']?.toString() ?? ''}',
        );
      }

      for (int i = 0; i < _items.length; i++) {
        final _CustomSlotDraft item = _items[i];

        if (item.id != null && item.id!.isNotEmpty) {
          await _api.updateSlot(item.id!, <String, dynamic>{
            'startTime': _fmtTime(item.startTime),
            'endTime': _fmtTime(item.endTime),
            'status': 'available',
          });
          _items[i] = item.copyWith(isPersisted: true);
          continue;
        }

        for (
          DateTime cursor = _dateOnly(item.from);
          !cursor.isAfter(_dateOnly(item.to));
          cursor = cursor.add(const Duration(days: 1))
        ) {
          final String key =
              '${_apiDate(cursor)}|${_fmtTime(item.startTime)}|${_fmtTime(item.endTime)}';
          if (existingKeys.contains(key)) {
            continue;
          }
          final Map<String, dynamic> created = await _api.createSlot(
            groundId,
            <String, dynamic>{
              'date': _apiDate(cursor),
              'startTime': _fmtTime(item.startTime),
              'endTime': _fmtTime(item.endTime),
              'price': 0,
              'status': 'available',
            },
          );
          existingKeys.add(key);
          final String? createdId = _slotId(created);
          if (createdId != null && _dateOnly(item.from) == _dateOnly(item.to)) {
            _items[i] = item.copyWith(id: createdId, isPersisted: true);
          }
        }
      }

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All slots saved successfully.')),
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
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingAll = false);
      }
    }
  }

  int _totalSlots() => _items.length;

  String _totalDurationPerDayLabel() {
    int total = 0;
    for (final _CustomSlotDraft item in _items) {
      total += _minutesBetween(item.startTime, item.endTime);
    }
    return _durationLabelFromMinutes(total);
  }

  Widget _cardField({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0x1FFFFFFF)),
            color: const Color(0x0AFFFFFF),
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _pickerBtn({
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x1FFFFFFF)),
          color: const Color(0x0AFFFFFF),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12),
              ),
            ),
            const Icon(Icons.calendar_month_outlined, size: 18, color: Color(0x99FFFFFF)),
          ],
        ),
      ),
    );
  }

  Widget _timeBtn({
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x1FFFFFFF)),
          color: const Color(0x0AFFFFFF),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              text,
              style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12),
            ),
            const Icon(Icons.access_time, size: 18, color: Color(0xFFDDF730)),
          ],
        ),
      ),
    );
  }

  Widget _slotTile(_CustomSlotDraft item, int index) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: const Color(0x0FFFFFFF),
        border: Border.all(color: const Color(0x1CFFFFFF)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: const Color(0xFFDDF730)),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Color(0xFFDDF730),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.slotName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_fmtTime(item.startTime)} - ${_fmtTime(item.endTime)}',
                    style: const TextStyle(
                      color: Color(0x99FFFFFF),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: <Widget>[
              IconButton(
                onPressed: () => _editItem(index),
                icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
              ),
              IconButton(
                onPressed: () => _deleteItem(index),
                icon: const Icon(Icons.delete_outline, color: Colors.white, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D1D1D),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[Color(0xFF21452E), Color(0xFF1D1D1D), Color(0xFF141414)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFDDF730)))
              : Column(
                  children: <Widget>[
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              if (widget.showBackButton)
                                SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: IconButton(
                                    onPressed: () {
                                      if (widget.controller != null) {
                                        widget.controller!.previousStep();
                                        return;
                                      }
                                      Navigator.of(context).maybePop();
                                    },
                                    icon: const Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      color: Color(0xFFDDF730),
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              const Text(
                                'Back',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Add Custom Slots',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Create your own time slots for your ground / court.',
                            style: TextStyle(color: Color(0x99FFFFFF), fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: const Color(0x08FFFFFF),
                              border: Border.all(color: const Color(0x1FFFFFFF)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                _cardField(
                                  label: 'Slot Name',
                                  child: TextField(
                                    controller: _slotNameCtrl,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration.collapsed(
                                      hintText: 'e.g. summer session, winter session',
                                      hintStyle: TextStyle(
                                        color: Color(0x99FFFFFF),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Slot Duration (Date Range)',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          const Text(
                                            'From',
                                            style: TextStyle(
                                              color: Color(0x99FFFFFF),
                                              fontSize: 11,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          _pickerBtn(
                                            text: _fmtDateShort(_fromDate),
                                            onTap: () => _pickDate(true),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          const Text(
                                            'To',
                                            style: TextStyle(
                                              color: Color(0x99FFFFFF),
                                              fontSize: 11,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          _pickerBtn(
                                            text: _fmtDateShort(_toDate),
                                            onTap: () => _pickDate(false),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Slot Time',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          const Text(
                                            'Start Time',
                                            style: TextStyle(
                                              color: Color(0x99FFFFFF),
                                              fontSize: 11,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          _timeBtn(
                                            text: _fmtTime(_startTime),
                                            onTap: () => _pickTime(true),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          const Text(
                                            'End Time',
                                            style: TextStyle(
                                              color: Color(0x99FFFFFF),
                                              fontSize: 11,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          _timeBtn(
                                            text: _fmtTime(_endTime),
                                            onTap: () => _pickTime(false),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: (_isAdding || _isSavingAll) ? null : _addDraft,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFDDF730),
                                      foregroundColor: const Color(0xFF1D1D1D),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Add Slot',
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Center(
                                  child: Text(
                                    'Add one slot at a time, You can add multiple slots for the same date range',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0x99FFFFFF),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                    ),
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
                                'Added Slots',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${_fmtDateShort(_fromDate)} - ${_fmtDateShort(_toDate)}',
                                style: const TextStyle(
                                  color: Color(0xCCFFFFFF),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_items.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: const Color(0x10FFFFFF),
                                border: Border.all(color: const Color(0x1CFFFFFF)),
                              ),
                              child: const Text(
                                'No slots added yet.',
                                style: TextStyle(color: Color(0xCCFFFFFF)),
                              ),
                            )
                          else
                            ...List<Widget>.generate(_items.length, (int index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _slotTile(_items[index], index),
                              );
                            }),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: const Color(0x08FFFFFF),
                              border: Border.all(color: const Color(0x1FFFFFFF)),
                            ),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      const Text(
                                        'Total Slots',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${_totalSlots()}',
                                        style: const TextStyle(
                                          color: Color(0xFFDDF730),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      const Text(
                                        'Total Duration (per Day)',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _totalDurationPerDayLabel(),
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
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Column(
                        children: <Widget>[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSavingAll ? null : _saveAll,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDDF730),
                                foregroundColor: const Color(0xFF1D1D1D),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isSavingAll
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF1D1D1D),
                                      ),
                                    )
                                  : const Text(
                                      'Save All Slots',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _isSavingAll
                                  ? null
                                  : () {
                                      if (widget.controller != null) {
                                        widget.controller!.previousStep();
                                        return;
                                      }
                                      Navigator.of(context).maybePop();
                                    },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFDDF730)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Color(0xFFDDF730),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
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
      ),
    );
  }
}

class _CustomSlotDraft {
  const _CustomSlotDraft({
    this.id,
    required this.slotName,
    required this.from,
    required this.to,
    required this.startTime,
    required this.endTime,
    required this.isPersisted,
  });

  final String? id;
  final String slotName;
  final DateTime from;
  final DateTime to;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool isPersisted;

  _CustomSlotDraft copyWith({
    String? id,
    String? slotName,
    DateTime? from,
    DateTime? to,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? isPersisted,
  }) {
    return _CustomSlotDraft(
      id: id ?? this.id,
      slotName: slotName ?? this.slotName,
      from: from ?? this.from,
      to: to ?? this.to,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isPersisted: isPersisted ?? this.isPersisted,
    );
  }
}
