import 'package:flutter/material.dart';
import 'package:ground_wale/core/widgets/app_text_field.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import 'academy_manage_students_screen.dart';

class AcademyEditBatchScreen extends StatefulWidget {
  const AcademyEditBatchScreen({
    super.key,
    this.batchId,
    required this.batchName,
    required this.coachName,
    required this.startTime,
    required this.endTime,
    this.days = const <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
    this.capacity = 30,
    this.status = 'active',
    this.monthlyFee = 0,
    this.feePlans = const <Map<String, String>>[],
    this.coachExperience = 0,
    this.enrolledStudents = 0,
    this.isCreate = false,
  });

  final String? batchId;
  final String batchName;
  final String coachName;
  final String startTime;
  final String endTime;
  final List<String> days;
  final int capacity;
  final String status;
  final double monthlyFee;
  final List<Map<String, String>> feePlans;
  final int coachExperience;
  final int enrolledStudents;
  final bool isCreate;

  @override
  State<AcademyEditBatchScreen> createState() => _AcademyEditBatchScreenState();
}

class _AcademyEditBatchScreenState extends State<AcademyEditBatchScreen> {
  late final TextEditingController _batchNameController;
  late final TextEditingController _coachController;
  late final TextEditingController _startTimeController;
  late final TextEditingController _endTimeController;
  late final TextEditingController _monthlyFeeController;

  late bool _active;
  late Set<String> _selectedDays;
  late int _capacity;
  late int _enrolledStudents;
  late int _coachExperience;
  late List<Map<String, String>> _feePlans;
  bool _isSaving = false;
  bool _isDeleting = false;

  static const List<String> _durationOptions = <String>[
    'Monthly',
    'Quarterly',
    'Yearly',
    'Custom',
  ];

  static const List<String> _days = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  void initState() {
    super.initState();
    _batchNameController = TextEditingController(text: widget.batchName);
    _coachController = TextEditingController(text: widget.coachName);
    _startTimeController = TextEditingController(
      text: widget.startTime.isEmpty ? '00:00' : widget.startTime,
    );
    _endTimeController = TextEditingController(
      text: widget.endTime.isEmpty ? '00:00' : widget.endTime,
    );
    _monthlyFeeController = TextEditingController(
      text: widget.monthlyFee <= 0
          ? ''
          : widget.monthlyFee.toStringAsFixed(
              widget.monthlyFee % 1 == 0 ? 0 : 2,
            ),
    );

    _active = widget.status.toLowerCase() != 'inactive';
    _capacity = widget.capacity < 1 ? 1 : widget.capacity;
    _coachExperience = widget.coachExperience < 0 ? 0 : widget.coachExperience;
    _enrolledStudents = widget.enrolledStudents < 0 ? 0 : widget.enrolledStudents;
    _feePlans = widget.feePlans.isEmpty
        ? <Map<String, String>>[
            <String, String>{'duration': 'Monthly', 'price': '0'},
          ]
        : widget.feePlans.map((Map<String, String> p) => Map<String, String>.from(p)).toList();
    _selectedDays = widget.days.isEmpty
        ? <String>{'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'}
        : widget.days
              .map((String day) => day.trim())
              .where((String day) => _days.contains(day))
              .toSet();
    if (_selectedDays.isEmpty) {
      _selectedDays = <String>{'Mon'};
    }

    _refreshEnrolledCount();
  }

  Future<void> _refreshEnrolledCount() async {
    final String batchId = widget.batchId ?? '';
    final String? ownerId = ApiSession.instance.ownerId;
    if (widget.isCreate || batchId.isEmpty || ownerId == null || ownerId.isEmpty) {
      return;
    }

    try {
      final Map<String, dynamic> response = await GroundWaleApi.instance
          .listAcademyStudents(ownerId, batchId: batchId, page: 1, limit: 1);
      final int total = (response['total'] as num?)?.toInt() ??
          ((response['items'] as List<dynamic>?)?.length ?? 0);
      if (!mounted) {
        return;
      }
      setState(() => _enrolledStudents = total);
    } catch (_) {
      // Keep existing value when count refresh fails.
    }
  }

  Future<void> _openManageStudents() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AcademyManageStudentsScreen(),
      ),
    );
    await _refreshEnrolledCount();
  }

  void _changeCoachExperience(int delta) {
    setState(() => _coachExperience = (_coachExperience + delta).clamp(0, 99));
  }

  Future<void> _selectDuration(int index) async {
    final String? selected = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: 8),
            const Text(
              'Choose Plan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ..._durationOptions.map((String option) => ListTile(
                  title: Text(option),
                  onTap: () => Navigator.of(ctx).pop(option),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (selected == null) return;
    String value = selected;
    if (selected == 'Custom' && mounted) {
      final TextEditingController ctrl = TextEditingController();
      final String? custom = await showDialog<String>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          title: const Text('Custom Duration'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'e.g. 75 Days'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
              child: const Text('Save'),
            ),
          ],
        ),
      );
      ctrl.dispose();
      if (custom == null || custom.isEmpty) return;
      value = custom;
    }
    if (!mounted) return;
    setState(() => _feePlans[index]['duration'] = value);
  }

  Future<void> _editPlanPrice(int index) async {
    final TextEditingController ctrl = TextEditingController(
      text: _feePlans[index]['price'],
    );
    final String? updated = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Edit Price'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter price'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (updated == null || updated.isEmpty || !mounted) return;
    setState(() => _feePlans[index]['price'] =
        updated.startsWith('₹') ? updated.substring(1) : updated);
  }

  void _deletePlanAt(int index) {
    // Monthly plan is required and cannot be deleted
    final String dur = _feePlans[index]['duration']?.toLowerCase() ?? '';
    if (dur == 'monthly') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Monthly fee plan is required and cannot be removed'),
        ),
      );
      return;
    }
    if (_feePlans.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one fee plan is required')),
      );
      return;
    }
    setState(() => _feePlans.removeAt(index));
  }

  void _addFeePlan() {
    setState(() => _feePlans.add(
          <String, String>{'duration': 'Monthly', 'price': '0'},
        ));
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final TimeOfDay? selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1C333B),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF242424),
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected == null || !mounted) {
      return;
    }

    final String hh = selected.hour.toString().padLeft(2, '0');
    final String mm = selected.minute.toString().padLeft(2, '0');
    setState(() => controller.text = '$hh:$mm');
  }

  Future<void> _save() async {
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Owner session not found')),
        );
      }
      return;
    }

    if (_batchNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Batch name is required')));
      return;
    }

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select at least one day')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final double monthlyFee =
          double.tryParse(_monthlyFeeController.text.trim()) ?? 0;
      final Map<String, dynamic> payload = <String, dynamic>{
        'name': _batchNameController.text.trim(),
        'coachName': _coachController.text.trim(),
        'coachExperience': _coachExperience,
        'startTime': _startTimeController.text.trim(),
        'endTime': _endTimeController.text.trim(),
        'days': _days
            .where((String day) => _selectedDays.contains(day))
            .toList(),
        'capacity': _capacity.clamp(1, 999),
        'status': _active ? 'active' : 'inactive',
        'monthlyFee': monthlyFee,
        'feePlans': _feePlans,
      };

      if (widget.isCreate) {
        await GroundWaleApi.instance.createAcademyBatch(ownerId, payload);
      } else {
        final String batchId = widget.batchId ?? '';
        if (batchId.isEmpty) {
          throw Exception('Batch id missing');
        }
        await GroundWaleApi.instance.updateAcademyBatch(
          ownerId,
          batchId,
          payload,
        );
      }

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteBatch() async {
    if (widget.isCreate) {
      return;
    }
    final String batchId = widget.batchId ?? '';
    final String? ownerId = ApiSession.instance.ownerId;
    if (batchId.isEmpty || ownerId == null || ownerId.isEmpty) {
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF203A43),
          title: const Text(
            'Delete batch?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'This will remove this batch and unassign students from it.',
            style: TextStyle(color: Color(0xFFCEE9E2)),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Color(0xFFE3220D)),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() => _isDeleting = true);
    try {
      await GroundWaleApi.instance.deleteAcademyBatch(ownerId, batchId);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  void _changeCapacity(int delta) {
    setState(() {
      _capacity = (_capacity + delta).clamp(1, 999);
    });
  }

  @override
  void dispose() {
    _batchNameController.dispose();
    _coachController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _monthlyFeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.isCreate ? 'Add Batch' : 'Edit Batch';
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (!widget.isCreate)
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: const Color(0xFFE3220D)),
                        color: const Color(0x14E3220D),
                      ),
                      child: IconButton(
                        onPressed: _isDeleting ? null : _deleteBatch,
                        icon: _isDeleting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFE3220D),
                                ),
                              )
                            : const Icon(
                                Icons.delete_outline_rounded,
                                color: Color(0xFFE3220D),
                                size: 24,
                              ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const _DarkLabel('Batch Name'),
              const SizedBox(height: 12),
              _DarkInputField(
                controller: _batchNameController,
                hintText: 'Morning Batch',
              ),
              const SizedBox(height: 12),
              const _DarkLabel('Coach / Trainer (Optional)'),
              const SizedBox(height: 12),
              _DarkInputField(controller: _coachController, hintText: 'Rahul'),
              const SizedBox(height: 12),
              // Coach Experience stepper
              const _DarkLabel('Coach Experience'),
              const SizedBox(height: 4),
              const Text(
                'In years',
                style: TextStyle(color: Color(0x80FFFFFF), fontSize: 12),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0x1FFFFFFF)),
                  color: const Color(0x0FFFFFFF),
                ),
                child: Row(
                  children: <Widget>[
                    _CapacityButton(
                      icon: Icons.remove,
                      onTap: () => _changeCoachExperience(-1),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          '$_coachExperience yr${_coachExperience == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    _CapacityButton(
                      icon: Icons.add,
                      onTap: () => _changeCoachExperience(1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const _DarkLabel('Start Time'),
                        const SizedBox(height: 8),
                        _DarkTimeField(
                          controller: _startTimeController,
                          onTap: () => _pickTime(_startTimeController),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const _DarkLabel('End Time'),
                        const SizedBox(height: 8),
                        _DarkTimeField(
                          controller: _endTimeController,
                          onTap: () => _pickTime(_endTimeController),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const _DarkSectionTitle('Schedule (Recurring)'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _days.map((String day) {
                  final bool selected = _selectedDays.contains(day);
                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (selected) {
                          _selectedDays.remove(day);
                        } else {
                          _selectedDays.add(day);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 63,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0x1FFFFFFF)),
                        color: selected
                            ? const Color(0xFF00C9A7)
                            : const Color(0x0FFFFFFF),
                      ),
                      child: Text(
                        day,
                        style: TextStyle(
                          color: selected
                              ? const Color(0xFF242424)
                              : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              const _DarkLabel('Batch Capacity (Optional)'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0x1FFFFFFF)),
                  color: const Color(0x0FFFFFFF),
                ),
                child: Row(
                  children: <Widget>[
                    _CapacityButton(
                      icon: Icons.remove,
                      onTap: () => _changeCapacity(-1),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          '$_capacity',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    _CapacityButton(
                      icon: Icons.add,
                      onTap: () => _changeCapacity(1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const _DarkLabel('Monthly Fees (quick)'),
              const SizedBox(height: 12),
              _DarkInputField(
                controller: _monthlyFeeController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                hintText: '₹2000',
              ),
              const SizedBox(height: 16),
              // ── Fee Structure (multi-plan) ──────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text(
                    'Fee Structure',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addFeePlan,
                    icon: const Icon(Icons.add, size: 16, color: Color(0xFF00C9A7)),
                    label: const Text(
                      'Add Plan',
                      style: TextStyle(color: Color(0xFF00C9A7), fontSize: 14),
                    ),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0x1FFFFFFF)),
                  color: const Color(0x0FFFFFFF),
                ),
                child: Column(
                  children: <Widget>[
                    for (int i = 0; i < _feePlans.length; i++) ...<Widget>[
                      Row(
                        children: <Widget>[
                          // Duration selector
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDuration(i),
                              child: Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0x1FFFFFFF)),
                                  color: const Color(0x0FFFFFFF),
                                ),
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        _feePlans[i]['duration'] ?? 'Monthly',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.keyboard_arrow_down,
                                      color: Colors.white70,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Price display
                          Expanded(
                            child: InkWell(
                              onTap: () => _editPlanPrice(i),
                              child: Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                alignment: Alignment.centerLeft,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0x1FFFFFFF)),
                                  color: const Color(0x0FFFFFFF),
                                ),
                                child: Text(
                                  '₹${_feePlans[i]['price'] ?? '0'}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Edit icon
                          InkWell(
                            onTap: () => _editPlanPrice(i),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0x3DFFFFFF)),
                              ),
                              child: const Icon(
                                Icons.edit_outlined,
                                size: 16,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Delete icon
                          InkWell(
                            onTap: () => _deletePlanAt(i),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0x3DFFFFFF)),
                              ),
                              child: const Icon(
                                Icons.delete_outline,
                                size: 16,
                                color: Color(0xFFE3220D),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (i < _feePlans.length - 1) const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0x1FFFFFFF)),
                  color: const Color(0x0FFFFFFF),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Batch Status',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _active ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: _active
                                  ? const Color(0xFF08B36A)
                                  : const Color(0xFFF97316),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _active,
                      onChanged: (bool value) =>
                          setState(() => _active = value),
                      activeThumbColor: Colors.white,
                      activeTrackColor: const Color(0xFF08B36A),
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: const Color(0x66FFFFFF),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0x1FFFFFFF)),
                  color: const Color(0x0FFFFFFF),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Manage Students',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_enrolledStudents Enrolled',
                      style: const TextStyle(
                        color: Color(0x99FFFFFF),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _openManageStudents,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                        ),
                        child: const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Add Students',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C9A7),
                    foregroundColor: const Color(0xFF1D1D1D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF1D1D1D),
                          ),
                        )
                      : Text(
                          widget.isCreate ? 'Create Batch' : 'Save Changes',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DarkLabel extends StatelessWidget {
  const _DarkLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFFE6F7F4),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _DarkSectionTitle extends StatelessWidget {
  const _DarkSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _DarkInputField extends StatelessWidget {
  const _DarkInputField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        color: const Color(0x0FFFFFFF),
      ),
      child: AppTextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0x99FFFFFF),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          isDense: true,
        ),
      ),
    );
  }
}

class _DarkTimeField extends StatelessWidget {
  const _DarkTimeField({required this.controller, required this.onTap});

  final TextEditingController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x1FFFFFFF)),
          color: const Color(0x0FFFFFFF),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: IgnorePointer(
                child: AppTextField(
                  controller: controller,
                  readOnly: true,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
            const Icon(
              Icons.access_time_outlined,
              size: 18,
              color: Color(0x99FFFFFF),
            ),
          ],
        ),
      ),
    );
  }
}

class _CapacityButton extends StatelessWidget {
  const _CapacityButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 45,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF12252B),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}


