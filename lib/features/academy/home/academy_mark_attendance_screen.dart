import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';

class AcademyMarkAttendanceScreen extends StatefulWidget {
  const AcademyMarkAttendanceScreen({super.key});

  @override
  State<AcademyMarkAttendanceScreen> createState() =>
      _AcademyMarkAttendanceScreenState();
}

class _AcademyMarkAttendanceScreenState
    extends State<AcademyMarkAttendanceScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  List<Map<String, dynamic>> _batches = <Map<String, dynamic>>[];
  List<_AttendanceStudent> _students = <_AttendanceStudent>[];
  String? _selectedBatchId;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  String? get _ownerId => ApiSession.instance.ownerId;

  String _batchId(Map<String, dynamic> batch) {
    return batch['_id']?.toString() ?? batch['id']?.toString() ?? '';
  }

  Map<String, dynamic>? get _selectedBatch {
    if (_selectedBatchId == null || _selectedBatchId!.isEmpty) {
      return null;
    }
    for (final Map<String, dynamic> batch in _batches) {
      if (_batchId(batch) == _selectedBatchId) {
        return batch;
      }
    }
    return null;
  }

  Future<void> _loadBatches() async {
    final String? ownerId = _ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      final List<Map<String, dynamic>> batches = await GroundWaleApi.instance
          .listAcademyBatches(ownerId);
      if (!mounted) {
        return;
      }
      setState(() {
        _batches = batches;
        _selectedBatchId = batches.isNotEmpty ? _batchId(batches.first) : null;
      });
      await _loadStudents();
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    }
  }

  Future<void> _loadStudents() async {
    final String? ownerId = _ownerId;
    final String? batchId = _selectedBatchId;
    if (ownerId == null ||
        ownerId.isEmpty ||
        batchId == null ||
        batchId.isEmpty) {
      if (mounted) {
        setState(() {
          _students = <_AttendanceStudent>[];
          _isLoading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final Map<String, dynamic> response = await GroundWaleApi.instance
          .listAcademyStudents(ownerId, batchId: batchId, limit: 200);
      final List<dynamic> itemsRaw =
          response['items'] as List<dynamic>? ?? <dynamic>[];
      final List<_AttendanceStudent> students = itemsRaw.asMap().entries.map((
        MapEntry<int, dynamic> entry,
      ) {
        final Map<String, dynamic> student = Map<String, dynamic>.from(
          entry.value as Map,
        );
        return _AttendanceStudent(
          id: student['_id']?.toString() ?? '',
          name: student['fullName']?.toString() ?? 'Student',
          rollNo: 'Roll ${(entry.key + 1).toString().padLeft(2, '0')}',
          status: _AttendanceStatus.unmarked,
        );
      }).toList();

      if (!mounted) {
        return;
      }
      setState(() {
        _students = students;
        _isLoading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    }
  }

  int get _presentCount =>
      _students.where((s) => s.status == _AttendanceStatus.present).length;

  int get _absentCount =>
      _students.where((s) => s.status == _AttendanceStatus.absent).length;

  String get _selectedDateLabel {
    final DateTime now = DateTime.now();
    final bool isToday =
        _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
    if (isToday) {
      return 'Today';
    }
    final String day = _selectedDate.day.toString().padLeft(2, '0');
    final String month = _selectedDate.month.toString().padLeft(2, '0');
    final String year = _selectedDate.year.toString();
    return '$day-$month-$year';
  }

  String get _selectedTimeRange {
    final Map<String, dynamic>? batch = _selectedBatch;
    final String start = batch?['startTime']?.toString() ?? '--:--';
    final String end = batch?['endTime']?.toString() ?? '--:--';
    return '$start - $end';
  }

  void _markAll(_AttendanceStatus status) {
    setState(() {
      for (final _AttendanceStudent student in _students) {
        student.status = status;
      }
    });
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() => _selectedDate = selected);
  }

  Future<void> _saveAttendance() async {
    final String? ownerId = _ownerId;
    final String? batchId = _selectedBatchId;
    if (ownerId == null ||
        ownerId.isEmpty ||
        batchId == null ||
        batchId.isEmpty) {
      return;
    }

    final List<Map<String, dynamic>> entries = _students
        .where(
          (final _AttendanceStudent s) =>
              s.status != _AttendanceStatus.unmarked,
        )
        .map(
          (final _AttendanceStudent s) => <String, dynamic>{
            'studentId': s.id,
            'status': switch (s.status) {
              _AttendanceStatus.present => 'present',
              _AttendanceStatus.absent => 'absent',
              _AttendanceStatus.unmarked => 'leave',
            },
          },
        )
        .toList();

    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mark attendance for at least one student'),
        ),
      );
      return;
    }

    final DateTime date = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      DateTime.now().hour,
      DateTime.now().minute,
    );

    setState(() => _isSaving = true);
    try {
      await GroundWaleApi.instance.markAcademyAttendance(
        ownerId,
        <String, dynamic>{
          'batchId': batchId,
          'date': date.toIso8601String(),
          'entries': entries,
        },
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Attendance saved')));
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

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? selectedBatch = _selectedBatch;
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF00C9A7)),
              )
            : Column(
                children: <Widget>[
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                              const Text(
                                'Mark Attendance',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 44,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _batches.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (BuildContext context, int index) {
                                final Map<String, dynamic> batch =
                                    _batches[index];
                                final String id = _batchId(batch);
                                final bool selected = id == _selectedBatchId;
                                return GestureDetector(
                                  onTap: () {
                                    if (id.isEmpty || selected) {
                                      return;
                                    }
                                    setState(() => _selectedBatchId = id);
                                    _loadStudents();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0x1F242424),
                                      ),
                                      color: selected
                                          ? const Color(0xFF00C9A7)
                                          : const Color(0x0FFFFFFF),
                                    ),
                                    child: Text(
                                      batch['name']?.toString() ?? 'Batch',
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
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Text(
                                    'DATE',
                                    style: TextStyle(
                                      color: Color(0xCCFFFFFF),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  GestureDetector(
                                    onTap: _pickDate,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: const Color(0x1F08B36A),
                                      ),
                                      child: Row(
                                        children: <Widget>[
                                          Text(
                                            _selectedDateLabel,
                                            style: const TextStyle(
                                              color: Color(0xFF22C55E),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: Color(0xFF08B36A),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: <Widget>[
                                  const Text(
                                    'TIME',
                                    style: TextStyle(
                                      color: Color(0xCCFFFFFF),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _selectedTimeRange,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Text(
                                    'STUDENTS',
                                    style: TextStyle(
                                      color: Color(0xCCFFFFFF),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${_students.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () =>
                                      _markAll(_AttendanceStatus.present),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Color(0xFF00C9A7),
                                    ),
                                    backgroundColor: const Color(0x0800C9A7),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  child: const Text(
                                    'Mark All Present',
                                    style: TextStyle(
                                      color: Color(0xFF00C9A7),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () =>
                                      _markAll(_AttendanceStatus.absent),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Color(0xFFEF4444),
                                    ),
                                    backgroundColor: const Color(0x08EF4444),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  child: const Text(
                                    'Mark All Absent',
                                    style: TextStyle(
                                      color: Color(0xFFEF4444),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0x1FFFFFFF),
                              ),
                              color: const Color(0x0AFFFFFF),
                            ),
                            child: const Text(
                              'Tip: Swipe right for present, left for absent',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0x99E6F7F4),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0x1FFFFFFF),
                              ),
                              color: const Color(0x0AFFFFFF),
                            ),
                            child: _students.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                      child: Text(
                                        'No students in selected batch',
                                        style: TextStyle(
                                          color: Color(0x99E6F7F4),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  )
                                : Column(
                                    children: _students
                                        .map(
                                          (
                                            _AttendanceStudent student,
                                          ) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 16,
                                            ),
                                            child: _StudentAttendanceTile(
                                              student: student,
                                              onStatusChanged:
                                                  (_AttendanceStatus status) {
                                                    setState(
                                                      () => student.status =
                                                          status,
                                                    );
                                                  },
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0x1FFFFFFF),
                              ),
                              color: const Color(0x0AFFFFFF),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      color: Color(0xFFE6F7F4),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    children: <InlineSpan>[
                                      const TextSpan(text: 'Present: '),
                                      TextSpan(
                                        text: '$_presentCount',
                                        style: const TextStyle(
                                          color: Color(0xFF08B36A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      color: Color(0xFFE6F7F4),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    children: <InlineSpan>[
                                      const TextSpan(text: 'Absent: '),
                                      TextSpan(
                                        text: '$_absentCount',
                                        style: const TextStyle(
                                          color: Color(0xFFE3220D),
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
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: Column(
                      children: <Widget>[
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isSaving || selectedBatch == null
                                ? null
                                : _saveAttendance,
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
                                : const Text(
                                    'Save Attendance',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Save & Notify to student Parents',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
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
}

class _StudentAttendanceTile extends StatelessWidget {
  const _StudentAttendanceTile({
    required this.student,
    required this.onStatusChanged,
  });

  final _AttendanceStudent student;
  final ValueChanged<_AttendanceStatus> onStatusChanged;

  String _initials(String name) {
    final List<String> parts = name
        .split(' ')
        .where((String part) => part.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'S';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bool present = student.status == _AttendanceStatus.present;
    final bool absent = student.status == _AttendanceStatus.absent;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                color: const Color(0x1AFFFFFF),
              ),
              alignment: Alignment.center,
              child: Text(
                _initials(student.name),
                style: const TextStyle(
                  color: Color(0xFFE6F7F4),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              student.name,
              style: const TextStyle(
                color: Color(0xFFE6F7F4),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Row(
          children: <Widget>[
            GestureDetector(
              onTap: () => onStatusChanged(_AttendanceStatus.present),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: present
                      ? const Color(0x1F08B36A)
                      : const Color(0x08FFFFFF),
                ),
                child: Text(
                  'Present',
                  style: TextStyle(
                    color: present
                        ? const Color(0xFF08B36A)
                        : const Color(0x99FFFFFF),
                    fontSize: 14,
                    fontWeight: present ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => onStatusChanged(_AttendanceStatus.absent),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: absent
                      ? const Color(0x1FE3220D)
                      : const Color(0x08FFFFFF),
                ),
                child: Text(
                  'Absent',
                  style: TextStyle(
                    color: absent
                        ? const Color(0xFFE3220D)
                        : const Color(0x99FFFFFF),
                    fontSize: 14,
                    fontWeight: absent ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

enum _AttendanceStatus { present, absent, unmarked }

class _AttendanceStudent {
  _AttendanceStudent({
    required this.id,
    required this.name,
    required this.rollNo,
    required this.status,
  });

  final String id;
  final String name;
  final String rollNo;
  _AttendanceStatus status;
}
