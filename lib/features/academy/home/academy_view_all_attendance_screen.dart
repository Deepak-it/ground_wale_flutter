import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';

class AcademyViewAllAttendanceScreen extends StatefulWidget {
  const AcademyViewAllAttendanceScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  final String studentId;
  final String studentName;

  @override
  State<AcademyViewAllAttendanceScreen> createState() =>
      _AcademyViewAllAttendanceScreenState();
}

class _AcademyViewAllAttendanceScreenState
    extends State<AcademyViewAllAttendanceScreen> {
  bool _isLoading = true;
  List<_AttendanceItem> _items = <_AttendanceItem>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      if (mounted) {
        setState(() {
          _items = <_AttendanceItem>[];
          _isLoading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final List<Map<String, dynamic>> attendance = await GroundWaleApi.instance
          .listAcademyAttendance(ownerId);

      final List<_AttendanceItem> items = <_AttendanceItem>[];
      for (final Map<String, dynamic> dayRecord in attendance) {
        final DateTime? parsedRaw = DateTime.tryParse(
          dayRecord['date']?.toString() ?? '',
        );
        final DateTime? parsedDate = parsedRaw == null
            ? null
            : DateTime(
                parsedRaw.toLocal().year,
                parsedRaw.toLocal().month,
                parsedRaw.toLocal().day,
              );
        final List<dynamic> entries =
            dayRecord['entries'] as List<dynamic>? ?? <dynamic>[];

        for (final dynamic rawEntry in entries) {
          if (rawEntry is! Map) {
            continue;
          }
          final Map<String, dynamic> entry = Map<String, dynamic>.from(
            rawEntry,
          );
          final dynamic studentRaw = entry['studentId'];

          String studentId = '';
          if (studentRaw is String) {
            studentId = studentRaw;
          } else if (studentRaw is Map) {
            final Map<String, dynamic> s = Map<String, dynamic>.from(
              studentRaw,
            );
            studentId = s['_id']?.toString() ?? s['id']?.toString() ?? '';
          }

          if (studentId != widget.studentId) {
            continue;
          }

          final String status =
              entry['status']?.toString().toLowerCase().trim() ?? 'absent';
          items.add(
            _AttendanceItem(
              date: parsedDate,
              status: status == 'present'
                  ? 'present'
                  : status == 'absent'
                  ? 'absent'
                  : 'leave',
            ),
          );
        }
      }

      items.sort((a, b) {
        final DateTime ad = a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime bd = b.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });

      if (!mounted) {
        return;
      }
      setState(() {
        _items = items;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: const Color(0x0FFFFFFF),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back,
                            size: 20,
                            color: Color(0xFFE6F7F4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${widget.studentName} Attendance',
                        style: const TextStyle(
                          color: Color(0xFFE6F7F4),
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: const Color(0x0FFFFFFF),
                    ),
                    child: IconButton(
                      onPressed: null,
                      icon: const Icon(
                        Icons.more_vert,
                        size: 18,
                        color: Color(0xFFE6F7F4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF00C9A7),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const SizedBox(height: 12),
                          const Text(
                            'Attendance',
                            style: TextStyle(
                              color: Color(0xFFE6F7F4),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: const Color(0x0FFFFFFF),
                            ),
                            child: _items.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text(
                                      'No attendance records found',
                                      style: TextStyle(
                                        color: Color(0x99E6F7F4),
                                        fontSize: 14,
                                      ),
                                    ),
                                  )
                                : Column(
                                    children: <Widget>[
                                      for (int i = 0; i < _items.length; i++)
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            border: i == _items.length - 1
                                                ? null
                                                : const Border(
                                                    bottom: BorderSide(
                                                      color: Color(0x14000000),
                                                    ),
                                                  ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: <Widget>[
                                              Text(
                                                _dayLabel(_items[i].date),
                                                style: const TextStyle(
                                                  color: Color(0xFFE6F7F4),
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              _statusPill(_items[i].status),
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
          ],
        ),
      ),
    );
  }

  Widget _statusPill(String status) {
    final bool present = status == 'present';
    final bool absent = status == 'absent';
    final Color color = present
        ? const Color(0xFF16A34A)
        : absent
        ? const Color(0xFFEF4444)
        : const Color(0xFFF59E0B);
    final Color bg = present
        ? const Color(0x3316A34A)
        : absent
        ? const Color(0x33EF4444)
        : const Color(0x33F59E0B);
    final IconData icon = present
        ? Icons.check_circle_outline
        : absent
        ? Icons.cancel_outlined
        : Icons.pending_outlined;

    final String text = status == 'present'
        ? 'Present'
        : status == 'absent'
        ? 'Absent'
        : 'Leave';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: bg,
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _dayLabel(DateTime? date) {
    if (date == null) {
      return '-';
    }
    final DateTime d = DateTime(date.year, date.month, date.day);
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime yesterday = today.subtract(const Duration(days: 1));

    if (d == today) {
      return 'Today, ${_dayMonth(d)}';
    }
    if (d == yesterday) {
      return 'Yesterday, ${_dayMonth(d)}';
    }
    return _dayMonth(d);
  }

  String _dayMonth(DateTime d) {
    const List<String> months = <String>[
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
    return '${d.day} ${months[d.month - 1]}';
  }
}

class _AttendanceItem {
  const _AttendanceItem({required this.date, required this.status});

  final DateTime? date;
  final String status;
}
