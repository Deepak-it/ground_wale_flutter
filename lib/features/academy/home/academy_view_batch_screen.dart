import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import 'academy_add_student_screen.dart';
import 'academy_fee_details_screen.dart';
import 'academy_mark_attendance_screen.dart';

class AcademyViewBatchScreen extends StatefulWidget {
  const AcademyViewBatchScreen({
    super.key,
    required this.batchName,
    required this.coachName,
    required this.time,
    required this.days,
    this.batchId,
  });

  final String batchName;
  final String coachName;
  final String time;
  final String days;

  final String? batchId;

  @override
  State<AcademyViewBatchScreen> createState() => _AcademyViewBatchScreenState();
}

class _AcademyViewBatchScreenState extends State<AcademyViewBatchScreen> {
  bool _isLoading = true;
  String _batchStatus = 'active';
  int _studentsCount = 0;
  int _attendancePresent = 0;
  int _attendanceTotal = 0;
  double _totalCollection = 0;
  double _pendingAmount = 0;
  int _paidStudents = 0;
  int _pendingStudents = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _todayIso() {
    final DateTime now = DateTime.now();
    final String mm = now.month.toString().padLeft(2, '0');
    final String dd = now.day.toString().padLeft(2, '0');
    return '${now.year}-$mm-$dd';
  }

  String _monthKey() {
    final DateTime now = DateTime.now();
    final String mm = now.month.toString().padLeft(2, '0');
    return '${now.year}-$mm';
  }

  Future<String?> _resolveBatchId(String ownerId) async {
    final String? passedId = widget.batchId;
    if (passedId != null && passedId.isNotEmpty) {
      return passedId;
    }

    final List<Map<String, dynamic>> batches = await GroundWaleApi.instance
        .listAcademyBatches(ownerId);
    for (final Map<String, dynamic> batch in batches) {
      final String id =
          batch['_id']?.toString() ?? batch['id']?.toString() ?? '';
      final String name = batch['name']?.toString() ?? '';
      if (id.isNotEmpty &&
          name.trim().toLowerCase() == widget.batchName.trim().toLowerCase()) {
        return id;
      }
    }
    return null;
  }

  Future<void> _load() async {
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final String? batchId = await _resolveBatchId(ownerId);
      if (batchId == null || batchId.isEmpty) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final Map<String, dynamic> batch = await GroundWaleApi.instance
          .getAcademyBatch(ownerId, batchId);

      final Map<String, dynamic> studentsResponse = await GroundWaleApi.instance
          .listAcademyStudents(ownerId, batchId: batchId, limit: 500);
      final List<dynamic> studentItems =
          studentsResponse['items'] as List<dynamic>? ?? <dynamic>[];
      final Set<String> studentIds = studentItems
          .whereType<Map>()
          .map((Map item) {
            final Map<String, dynamic> s = Map<String, dynamic>.from(item);
            return s['_id']?.toString() ?? s['id']?.toString() ?? '';
          })
          .where((String id) => id.isNotEmpty)
          .toSet();

      final List<Map<String, dynamic>> attendance = await GroundWaleApi.instance
          .listAcademyAttendance(
            ownerId,
            batchId: batchId,
            dateFrom: _todayIso(),
            dateTo: _todayIso(),
          );

      int present = 0;
      int total = 0;
      for (final Map<String, dynamic> item in attendance) {
        final List<dynamic> entries =
            item['entries'] as List<dynamic>? ?? <dynamic>[];
        for (final dynamic entryRaw in entries) {
          if (entryRaw is! Map) {
            continue;
          }
          final Map<String, dynamic> entry = Map<String, dynamic>.from(
            entryRaw,
          );
          final String status = entry['status']?.toString().toLowerCase() ?? '';
          if (status == 'present' || status == 'absent' || status == 'leave') {
            total++;
          }
          if (status == 'present') {
            present++;
          }
        }
      }

      final List<Map<String, dynamic>> fees = await GroundWaleApi.instance
          .listAcademyFees(ownerId, monthKey: _monthKey());
      final List<Map<String, dynamic>> batchFees = fees.where((
        Map<String, dynamic> fee,
      ) {
        final dynamic studentRaw = fee['studentId'];
        if (studentRaw is Map) {
          final Map<String, dynamic> student = Map<String, dynamic>.from(
            studentRaw,
          );
          final String id =
              student['_id']?.toString() ?? student['id']?.toString() ?? '';
          return studentIds.contains(id);
        }
        if (studentRaw is String) {
          return studentIds.contains(studentRaw);
        }
        return false;
      }).toList();

      double collected = 0;
      double pending = 0;
      int paidCount = 0;
      int pendingCount = 0;

      for (final Map<String, dynamic> fee in batchFees) {
        final double amount = (fee['amount'] as num?)?.toDouble() ?? 0;
        final double paidAmount = (fee['paidAmount'] as num?)?.toDouble() ?? 0;
        final String status =
            fee['status']?.toString().toLowerCase() ?? 'pending';

        collected += paidAmount;
        pending += (amount - paidAmount) > 0 ? (amount - paidAmount) : 0;

        if (status == 'paid') {
          paidCount++;
        } else {
          pendingCount++;
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _batchStatus = batch['status']?.toString().toLowerCase() == 'inactive'
            ? 'inactive'
            : 'active';
        _studentsCount = studentIds.length;
        _attendancePresent = present;
        _attendanceTotal = total == 0 ? studentIds.length : total;
        _totalCollection = collected;
        _pendingAmount = pending;
        _paidStudents = paidCount;
        _pendingStudents = pendingCount;
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
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF00C9A7)),
              )
            : RefreshIndicator(
                onRefresh: _load,
                color: const Color(0xFF00C9A7),
                backgroundColor: const Color(0xFF203A43),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
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
                          Expanded(
                            child: Text(
                              widget.batchName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _BatchOverviewCard(
                        batchName: widget.batchName,
                        time: widget.time,
                        days: widget.days,
                        coachName: widget.coachName,
                        status: _batchStatus,
                        studentsCount: _studentsCount,
                      ),
                      const SizedBox(height: 16),
                      _HorizontalStats(
                        attendancePresent: _attendancePresent,
                        attendanceTotal: _attendanceTotal,
                        totalCollection: _totalCollection,
                        pendingAmount: _pendingAmount,
                      ),
                      const SizedBox(height: 16),
                      _AddStudentButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const AcademyAddStudentScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _FeesSection(
                        paidStudents: _paidStudents,
                        pendingStudents: _pendingStudents,
                        onViewFeesDetails: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const AcademyFeeDetailsScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _AttendanceSection(
                        attendancePresent: _attendancePresent,
                        attendanceTotal: _attendanceTotal,
                        onMarkAttendance: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  const AcademyMarkAttendanceScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _BatchOverviewCard extends StatelessWidget {
  const _BatchOverviewCard({
    required this.batchName,
    required this.time,
    required this.days,
    required this.coachName,
    required this.status,
    required this.studentsCount,
  });

  final String batchName;
  final String time;
  final String days;
  final String coachName;
  final String status;
  final int studentsCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        color: const Color(0x0FFFFFFF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  batchName,
                  style: const TextStyle(
                    color: Color(0xFFE6F7F4),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: status == 'active'
                      ? const Color(0x1A22C55E)
                      : const Color(0x33F97316),
                ),
                child: Text(
                  status == 'active' ? 'ACTIVE' : status.toUpperCase(),
                  style: TextStyle(
                    color: status == 'active'
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFF97316),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            runSpacing: 12,
            spacing: 12,
            children: <Widget>[
              _MetaItem(icon: Icons.schedule_rounded, text: time),
              _MetaItem(icon: Icons.calendar_month_outlined, text: days),
              _MetaItem(
                icon: Icons.person_outline_rounded,
                text: 'Coach: $coachName',
              ),
              _MetaItem(
                icon: Icons.group_outlined,
                text: 'Students: $studentsCount',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Row(
        children: <Widget>[
          Icon(icon, color: const Color(0xFF9FB9B3), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF9FB9B3),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HorizontalStats extends StatelessWidget {
  const _HorizontalStats({
    required this.attendancePresent,
    required this.attendanceTotal,
    required this.totalCollection,
    required this.pendingAmount,
  });

  final int attendancePresent;
  final int attendanceTotal;
  final double totalCollection;
  final double pendingAmount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          _StatCard(
            label: 'Attendance Today',
            value: '$attendancePresent / $attendanceTotal',
          ),
          SizedBox(width: 12),
          _StatCard(
            label: 'Total Collection',
            value: 'Rs ${totalCollection.toStringAsFixed(0)}',
          ),
          SizedBox(width: 12),
          _StatCard(
            label: 'Pending Amount',
            value: 'Rs ${pendingAmount.toStringAsFixed(0)}',
            valueColor: Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    this.valueColor = const Color(0xFFE6F7F4),
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 172,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        color: const Color(0x0FFFFFFF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFE6F7F4),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddStudentButton extends StatelessWidget {
  const _AddStudentButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add_rounded, color: Color(0xFF00C9A7)),
        label: const Text(
          'Add Student',
          style: TextStyle(
            color: Color(0xFF00C9A7),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(
            color: Color(0xFF00C9A7),
            style: BorderStyle.solid,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _FeesSection extends StatelessWidget {
  const _FeesSection({
    required this.onViewFeesDetails,
    required this.paidStudents,
    required this.pendingStudents,
  });

  final VoidCallback onViewFeesDetails;
  final int paidStudents;
  final int pendingStudents;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        color: const Color(0x0FFFFFFF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Fees Section',
            style: TextStyle(
              color: Color(0xFFE6F7F4),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              _MiniStat(
                label: 'Paid Students',
                value: '$paidStudents',
                valueColor: Color(0xFF08B36A),
              ),
              _MiniStat(
                label: 'Pending',
                value: '$pendingStudents',
                valueColor: Color(0xFFF59E0B),
                alignRight: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: onViewFeesDetails,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0x66FFFFFF)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'View Fees Details',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.valueColor,
    this.alignRight = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: Color(0x99FFFFFF),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _AttendanceSection extends StatelessWidget {
  const _AttendanceSection({
    required this.onMarkAttendance,
    required this.attendancePresent,
    required this.attendanceTotal,
  });

  final VoidCallback onMarkAttendance;
  final int attendancePresent;
  final int attendanceTotal;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        color: const Color(0x0FFFFFFF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Attendance Status',
            style: TextStyle(
              color: Color(0xFFE6F7F4),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Today\'s Presence',
            style: TextStyle(
              color: Color(0x99FFFFFF),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$attendancePresent / $attendanceTotal',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 8,
              color: const Color(0xFF12252B),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: attendanceTotal <= 0
                    ? 0
                    : (attendancePresent / attendanceTotal).clamp(0, 1),
                child: Container(color: const Color(0xFF22C55E)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: onMarkAttendance,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0x66FFFFFF)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Mark Attendance',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
