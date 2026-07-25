import 'package:flutter/material.dart';

import '../../../../core/api/api_session.dart';
import '../../../../core/api/ground_wale_api.dart';
import '../controllers/ground_flow_controller.dart';
import '../models/ground_registration_data.dart';

// ignore_for_file: use_build_context_synchronously

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

  final bool _isLoading = false;
  bool _isSavingAll = false;

  // ── All durations currently configured ───────────────────────────────────
  final List<_DurationDraft> _durations = <_DurationDraft>[];

  // ── "Add new duration" form state ─────────────────────────────────────────
  bool _showDurationForm = false;
  final TextEditingController _nameCtrl = TextEditingController();
  DateTime _newFrom = DateTime.now();
  DateTime _newTo = DateTime.now().add(const Duration(days: 30));

  // ── "Add slot" inline form state (index into _durations, null = closed) ──
  int? _activeSlotForDuration; // which duration card shows the slot-add form
  TimeOfDay _slotStart = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _slotEnd = const TimeOfDay(hour: 7, minute: 0);

  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadFromDrafts();
    // If nothing loaded yet, start with the add-duration form open
    if (_durations.isEmpty) {
      _showDurationForm = true;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  // ── Load existing customSlotDrafts into the _DurationDraft list ───────────
  void _loadFromDrafts() {
    final Map<String, _DurationDraft> byKey = <String, _DurationDraft>{};
    for (final Map<String, dynamic> d in widget.data.customSlotDrafts) {
      final String fromStr = d['dateFrom']?.toString() ?? '';
      final String toStr = d['dateTo']?.toString() ?? '';
      final String key = '$fromStr|$toStr';
      final DateTime from = _tryParseDate(fromStr) ?? DateTime.now();
      final DateTime to = _tryParseDate(toStr) ?? DateTime.now();
      final _DurationDraft draft = byKey.putIfAbsent(
        key,
        () => _DurationDraft(
          name: d['name']?.toString() ?? 'Duration',
          from: _dateOnly(from),
          to: _dateOnly(to),
        ),
      );
      final TimeOfDay start = _parseTime(
        d['startTime']?.toString() ?? '06:00 AM',
      );
      final TimeOfDay end = _parseTime(d['endTime']?.toString() ?? '07:00 AM');
      draft.slots.add(_SlotTime(startTime: start, endTime: end));
    }
    _durations.addAll(byKey.values);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime? _tryParseDate(String raw) {
    if (raw.trim().isEmpty) return null;
    final DateTime? parsed = DateTime.tryParse(raw.trim());
    if (parsed == null) return null;
    final DateTime local = parsed.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  String _apiDate(DateTime d) {
    final String m = d.month.toString().padLeft(2, '0');
    final String day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  String _fmtDate(DateTime d) {
    const List<String> mn = <String>[
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
    const List<String> wd = <String>[
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];
    return '${wd[d.weekday - 1]}, ${d.day} ${mn[d.month - 1]} ${d.year}';
  }

  String _fmtTime(TimeOfDay t) {
    int h = t.hour;
    final String period = h >= 12 ? 'PM' : 'AM';
    h = h % 12;
    if (h == 0) h = 12;
    return '${h.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} $period';
  }

  TimeOfDay _parseTime(String raw) {
    final RegExpMatch? m = RegExp(
      r'^(\d{1,2}):(\d{2})\s*([AaPp][Mm])$',
    ).firstMatch(raw.trim());
    if (m == null) return const TimeOfDay(hour: 6, minute: 0);
    int h = int.tryParse(m.group(1) ?? '') ?? 6;
    final int min = int.tryParse(m.group(2) ?? '') ?? 0;
    final String p = (m.group(3) ?? 'AM').toUpperCase();
    if (h == 12) h = 0;
    if (p == 'PM') h += 12;
    return TimeOfDay(hour: h, minute: min);
  }

  int _toMins(TimeOfDay t) => t.hour * 60 + t.minute;

  bool _dateRangesOverlap(DateTime fa, DateTime ta, DateTime fb, DateTime tb) {
    return !ta.isBefore(fb) && !tb.isBefore(fa);
  }

  bool _timesOverlap(TimeOfDay sa, TimeOfDay ea, TimeOfDay sb, TimeOfDay eb) {
    int aS = _toMins(sa), aE = _toMins(ea);
    int bS = _toMins(sb), bE = _toMins(eb);
    if (aE <= aS) aE += 24 * 60;
    if (bE <= bS) bE += 24 * 60;
    return aS < bE && bS < aE;
  }

  /// Returns an overlap message if [start]-[end] on dates [from]-[to] clashes
  /// with any existing slot across all durations (except slots in
  /// [ignoreDurationIndex] at [ignoreSlotIndex]).
  String? _overlapMessage(
    DateTime from,
    DateTime to,
    TimeOfDay start,
    TimeOfDay end, {
    int? ignoreDurationIndex,
    int? ignoreSlotIndex,
  }) {
    for (int di = 0; di < _durations.length; di++) {
      final _DurationDraft dur = _durations[di];
      if (!_dateRangesOverlap(from, to, dur.from, dur.to)) continue;
      for (int si = 0; si < dur.slots.length; si++) {
        if (di == ignoreDurationIndex && si == ignoreSlotIndex) continue;
        if (_timesOverlap(
          start,
          end,
          dur.slots[si].startTime,
          dur.slots[si].endTime,
        )) {
          return 'Slot ${_fmtTime(start)}–${_fmtTime(end)} overlaps with an existing slot in "${dur.name}". Choose a different time.';
        }
      }
    }
    return null;
  }

  // ── Add Duration form actions ─────────────────────────────────────────────
  Future<void> _pickNewFrom() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _newFrom,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _newFrom = _dateOnly(picked);
      if (_newTo.isBefore(_newFrom)) _newTo = _newFrom;
    });
  }

  Future<void> _pickNewTo() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _newTo.isBefore(_newFrom) ? _newFrom : _newTo,
      firstDate: _newFrom,
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked == null || !mounted) return;
    setState(() => _newTo = _dateOnly(picked));
  }

  void _confirmAddDuration() {
    final String name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Duration name is required.')),
      );
      return;
    }
    setState(() {
      _durations.add(_DurationDraft(name: name, from: _newFrom, to: _newTo));
      _nameCtrl.clear();
      _newFrom = DateTime.now();
      _newTo = DateTime.now().add(const Duration(days: 30));
      _showDurationForm = false;
      _activeSlotForDuration = _durations.length - 1; // auto-open slot form
      _slotStart = const TimeOfDay(hour: 6, minute: 0);
      _slotEnd = const TimeOfDay(hour: 7, minute: 0);
    });
  }

  // ── Add Slot to a duration ────────────────────────────────────────────────
  Future<void> _pickSlotStart() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _slotStart,
      builder: (BuildContext ctx, Widget? child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: false),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (picked != null && mounted) setState(() => _slotStart = picked);
  }

  Future<void> _pickSlotEnd() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _slotEnd,
      builder: (BuildContext ctx, Widget? child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: false),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (picked != null && mounted) setState(() => _slotEnd = picked);
  }

  void _confirmAddSlot(int durationIndex) {
    final _DurationDraft dur = _durations[durationIndex];
    final int sS = _toMins(_slotStart), sE = _toMins(_slotEnd);
    if (sE <= sS) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }
    final String? conflict = _overlapMessage(
      dur.from,
      dur.to,
      _slotStart,
      _slotEnd,
      ignoreDurationIndex: durationIndex,
    );
    if (conflict != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(conflict)));
      return;
    }
    setState(() {
      dur.slots.add(_SlotTime(startTime: _slotStart, endTime: _slotEnd));
      // Keep form open but reset times for next slot
      _slotStart = _slotEnd; // next slot starts where this one ended
      _slotEnd = TimeOfDay(
        hour: (_slotEnd.hour + 1) % 24,
        minute: _slotEnd.minute,
      );
    });
  }

  // ── Delete ────────────────────────────────────────────────────────────────
  void _deleteDuration(int index) {
    setState(() {
      _durations.removeAt(index);
      if (_activeSlotForDuration == index) {
        _activeSlotForDuration = null;
      } else if (_activeSlotForDuration != null &&
          _activeSlotForDuration! > index) {
        _activeSlotForDuration = _activeSlotForDuration! - 1;
      }
    });
  }

  void _deleteSlot(int durIndex, int slotIndex) {
    setState(() => _durations[durIndex].slots.removeAt(slotIndex));
  }

  // ── Save All ──────────────────────────────────────────────────────────────
  Future<void> _saveAll() async {
    if (_isSavingAll) return;

    // Validate at least one duration with at least one slot
    for (final _DurationDraft dur in _durations) {
      if (dur.slots.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '"${dur.name}" has no slots. Add at least one slot or delete the duration.',
            ),
          ),
        );
        return;
      }
    }
    if (_durations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one duration with slots.')),
      );
      return;
    }

    // Build flat customSlotDrafts list
    final List<Map<String, dynamic>> drafts = <Map<String, dynamic>>[];
    for (final _DurationDraft dur in _durations) {
      for (final _SlotTime slot in dur.slots) {
        drafts.add(<String, dynamic>{
          'name': dur.name,
          'dateFrom': _apiDate(dur.from),
          'dateTo': _apiDate(dur.to),
          'startTime': _fmtTime(slot.startTime),
          'endTime': _fmtTime(slot.endTime),
          'price': 0,
        });
      }
    }
    widget.data.customSlotDrafts
      ..clear()
      ..addAll(drafts);
    widget.data.totalCreatedSlots = drafts.length;

    // Registration mode: just save in memory and advance
    if (widget.controller != null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Slots saved.')));
      }
      widget.controller!.nextStep();
      return;
    }

    // Standalone / post-login mode: write to API
    setState(() => _isSavingAll = true);
    try {
      String? groundId = _session.groundId;
      if (groundId == null || groundId.isEmpty) {
        final String? ownerId = _session.ownerId;
        if (ownerId != null && ownerId.isNotEmpty) {
          final String? resolved = await _api.ensureGroundIdForOwner(ownerId);
          if (resolved != null && resolved.isNotEmpty) {
            _session.setGroundId(resolved);
            groundId = resolved;
          }
        }
      }
      if (groundId == null || groundId.isEmpty) {
        throw Exception('Ground not found for this owner.');
      }

      for (final Map<String, dynamic> draft in drafts) {
        await _api.createSlot(groundId, <String, dynamic>{
          'dateFrom': draft['dateFrom'],
          'dateTo': draft['dateTo'],
          'startTime': draft['startTime'],
          'endTime': draft['endTime'],
          'price': 0,
          'status': 'available',
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All slots saved successfully.')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSavingAll = false);
    }
  }

  // ── UI helpers ────────────────────────────────────────────────────────────
  Widget _pickerBtn(
    String text,
    VoidCallback onTap, {
    IconData icon = Icons.calendar_month_outlined,
  }) {
    return GestureDetector(
      onTap: onTap,
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
            Icon(icon, size: 16, color: const Color(0x99FFFFFF)),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D1D1D),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              Color(0xFF21452E),
              Color(0xFF1D1D1D),
              Color(0xFF141414),
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
              : Column(
                  children: <Widget>[
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        children: <Widget>[
                          // ── Header ───────────────────────────────────────
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
                                      } else {
                                        Navigator.of(context).maybePop();
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      color: Color(0xFFDDF730),
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 4),
                              const Text(
                                'Add Custom Slots',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Create durations with multiple time slots. Overlapping slots across durations are blocked.',
                            style: TextStyle(
                              color: Color(0x99FFFFFF),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ── Duration cards ────────────────────────────────
                          ..._buildDurationCards(),

                          const SizedBox(height: 12),

                          // ── Add Duration form / button ────────────────────
                          if (_showDurationForm)
                            _buildAddDurationForm()
                          else
                            GestureDetector(
                              onTap: () => setState(() {
                                _showDurationForm = true;
                                _activeSlotForDuration = null;
                              }),
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFDDF730),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Icon(
                                      Icons.add_circle_outline_rounded,
                                      color: Color(0xFFDDF730),
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Add Duration',
                                      style: TextStyle(
                                        color: Color(0xFFDDF730),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),

                    // ── Bottom action bar ─────────────────────────────────
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
                                      } else {
                                        Navigator.of(context).maybePop();
                                      }
                                    },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFFDDF730),
                                ),
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

  // ── Duration cards ────────────────────────────────────────────────────────
  List<Widget> _buildDurationCards() {
    final List<Widget> cards = <Widget>[];
    for (int di = 0; di < _durations.length; di++) {
      final _DurationDraft dur = _durations[di];
      final bool slotFormOpen = _activeSlotForDuration == di;

      cards.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0x08FFFFFF),
              border: Border.all(color: const Color(0x1FFFFFFF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Duration header
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFDDF730)),
                        ),
                        child: Text(
                          '${di + 1}',
                          style: const TextStyle(
                            color: Color(0xFFDDF730),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              dur.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${_fmtDate(dur.from)} – ${_fmtDate(dur.to)}',
                              style: const TextStyle(
                                color: Color(0x99FFFFFF),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Color(0x99FFFFFF),
                          size: 20,
                        ),
                        onPressed: () => _deleteDuration(di),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

                // Slots list
                if (dur.slots.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'No slots yet. Add a time slot below.',
                      style: const TextStyle(
                        color: Color(0x66FFFFFF),
                        fontSize: 12,
                      ),
                    ),
                  )
                else
                  ...dur.slots.asMap().entries.map((
                    MapEntry<int, _SlotTime> entry,
                  ) {
                    final int si = entry.key;
                    final _SlotTime slot = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 3,
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(
                            Icons.schedule,
                            size: 14,
                            color: Color(0xFFDDF730),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_fmtTime(slot.startTime)} – ${_fmtTime(slot.endTime)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => _deleteSlot(di, si),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Color(0x99FFFFFF),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                const SizedBox(height: 8),

                // Inline slot-add form or "Add Slot" button
                if (slotFormOpen)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Divider(color: Color(0x1FFFFFFF)),
                        const Text(
                          'Add slot time',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _pickerBtn(
                                _fmtTime(_slotStart),
                                _pickSlotStart,
                                icon: Icons.access_time,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _pickerBtn(
                                _fmtTime(_slotEnd),
                                _pickSlotEnd,
                                icon: Icons.access_time,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _confirmAddSlot(di),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFDDF730),
                                  foregroundColor: const Color(0xFF1D1D1D),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                ),
                                child: const Text(
                                  'Add Slot',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () =>
                                  setState(() => _activeSlotForDuration = null),
                              child: const Text(
                                'Done',
                                style: TextStyle(color: Color(0x99FFFFFF)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _activeSlotForDuration = di;
                        _showDurationForm = false;
                        _slotStart = dur.slots.isEmpty
                            ? const TimeOfDay(hour: 6, minute: 0)
                            : TimeOfDay(
                                hour: dur.slots.last.endTime.hour,
                                minute: dur.slots.last.endTime.minute,
                              );
                        _slotEnd = TimeOfDay(
                          hour: (_slotStart.hour + 1) % 24,
                          minute: _slotStart.minute,
                        );
                      }),
                      child: Row(
                        children: <Widget>[
                          const Icon(
                            Icons.add_circle_outline,
                            size: 16,
                            color: Color(0xFFDDF730),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Add time slot',
                            style: const TextStyle(
                              color: Color(0xFFDDF730),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    return cards;
  }

  // ── Add Duration inline form ──────────────────────────────────────────────
  Widget _buildAddDurationForm() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0x08FFFFFF),
        border: Border.all(color: const Color(0x66DDF730)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'New Duration',
            style: TextStyle(
              color: Color(0xFFDDF730),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          // Name
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0x1FFFFFFF)),
              color: const Color(0x0AFFFFFF),
            ),
            child: TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration.collapsed(
                hintText: 'Duration name (e.g. Summer, Weekend)',
                hintStyle: TextStyle(color: Color(0x66FFFFFF), fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Date range
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'From',
                      style: TextStyle(color: Color(0x99FFFFFF), fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    _pickerBtn(_fmtDate(_newFrom), _pickNewFrom),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'To',
                      style: TextStyle(color: Color(0x99FFFFFF), fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    _pickerBtn(_fmtDate(_newTo), _pickNewTo),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: ElevatedButton(
                  onPressed: _confirmAddDuration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDDF730),
                    foregroundColor: const Color(0xFF1D1D1D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Add Duration',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              if (_durations.isNotEmpty) ...<Widget>[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => setState(() => _showDurationForm = false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Color(0x99FFFFFF)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Data models ───────────────────────────────────────────────────────────────

class _DurationDraft {
  _DurationDraft({required this.name, required this.from, required this.to});

  String name;
  DateTime from;
  DateTime to;
  final List<_SlotTime> slots = <_SlotTime>[];
}

class _SlotTime {
  _SlotTime({required this.startTime, required this.endTime});
  TimeOfDay startTime;
  TimeOfDay endTime;
}
