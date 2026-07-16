import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import '../../../core/utils/base64_image.dart';
import 'academy_edit_student_screen.dart';
import 'academy_view_all_attendance_screen.dart';

class AcademyStudentDetailsScreen extends StatefulWidget {
  const AcademyStudentDetailsScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.batchName,
    required this.attendanceStatus,
    required this.feeStatus,
  });

  final String studentId;
  final String studentName;
  final String batchName;
  final String attendanceStatus;
  final String feeStatus;

  @override
  State<AcademyStudentDetailsScreen> createState() =>
      _AcademyStudentDetailsScreenState();
}

class _AcademyStudentDetailsScreenState extends State<AcademyStudentDetailsScreen> {
  bool _isLoading = true;
  bool _isSendingReminder = false;
  Map<String, dynamic> _student = <String, dynamic>{};
  List<Map<String, dynamic>> _fees = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _attendance = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      final Map<String, dynamic> student = await GroundWaleApi.instance
          .getAcademyStudent(ownerId, widget.studentId);
      final List<Map<String, dynamic>> fees = await GroundWaleApi.instance
          .listAcademyFees(ownerId, studentId: widget.studentId);
      final List<Map<String, dynamic>> attendance = await GroundWaleApi.instance
          .listAcademyAttendance(ownerId);

      final List<Map<String, dynamic>> studentAttendance = attendance.where((
        Map<String, dynamic> item,
      ) {
        final List<dynamic> entries = item['entries'] as List<dynamic>? ?? <dynamic>[];
        return entries.any((dynamic raw) {
          final Map<String, dynamic> e = Map<String, dynamic>.from(raw as Map);
          final dynamic studentRef = e['studentId'];
          if (studentRef is Map<String, dynamic>) {
            return studentRef['_id']?.toString() == widget.studentId;
          }
          return studentRef?.toString() == widget.studentId;
        });
      }).toList();

      if (!mounted) {
        return;
      }
      setState(() {
        _student = student;
        _fees = fees;
        _attendance = studentAttendance;
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

  String _status(Map<String, dynamic> attendanceItem) {
    final List<dynamic> entries =
        attendanceItem['entries'] as List<dynamic>? ?? <dynamic>[];
    for (final dynamic raw in entries) {
      final Map<String, dynamic> entry = Map<String, dynamic>.from(raw as Map);
      final dynamic studentRef = entry['studentId'];
      final String id = studentRef is Map<String, dynamic>
          ? studentRef['_id']?.toString() ?? ''
          : studentRef?.toString() ?? '';
      if (id == widget.studentId) {
        return entry['status']?.toString().toLowerCase() ?? 'unmarked';
      }
    }
    return 'unmarked';
  }

  String _fmtDate(String? raw) {
    if (raw == null || raw.isEmpty) {
      return '-';
    }
    final DateTime? parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw;
    }
    final DateTime local = parsed.toLocal();
    final DateTime d = DateTime(local.year, local.month, local.day);
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
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  Future<void> _sendReminder() async {
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty || _isSendingReminder) {
      return;
    }
    final Map<String, dynamic>? pendingFee = _fees.cast<Map<String, dynamic>?>().firstWhere(
      (Map<String, dynamic>? fee) =>
          (fee?['status']?.toString().toLowerCase() ?? '') != 'paid',
      orElse: () => null,
    );

    final String feeId = pendingFee?['_id']?.toString() ?? '';
    if (feeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pending fee found')),
      );
      return;
    }

    setState(() => _isSendingReminder = true);
    try {
      await GroundWaleApi.instance.sendAcademyFeeReminder(ownerId, feeId);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder sent')),
      );
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
        setState(() => _isSendingReminder = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String name = _student['fullName']?.toString() ?? widget.studentName;
    final String phone = _student['phone']?.toString() ?? '+91 98765 43210';
    final String batch = widget.batchName;

    final double totalFeeValue = _fees.fold<double>(
      0,
      (double sum, Map<String, dynamic> fee) =>
          sum + ((fee['amount'] as num?)?.toDouble() ?? 0),
    );
    final double paidFeeValue = _fees.fold<double>(
      0,
      (double sum, Map<String, dynamic> fee) =>
          sum + ((fee['paidAmount'] as num?)?.toDouble() ?? 0),
    );
    final int totalFee = totalFeeValue.round();
    final int paidFee = paidFeeValue.round();
    final int pendingFee = (totalFee - paidFee).clamp(0, 999999999);

    final int presentDays = _attendance
        .where((Map<String, dynamic> item) => _status(item) == 'present')
        .length;
    final int absentDays = _attendance
        .where((Map<String, dynamic> item) => _status(item) == 'absent')
        .length;
    final int totalDays = presentDays + absentDays;
    final String attendancePercent = totalDays == 0
        ? '0%'
        : '${((presentDays * 100) / totalDays).round()}%';

    final bool isPaid = pendingFee == 0;

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
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            _CircleButton(
                              icon: Icons.arrow_back_ios_new_rounded,
                              onTap: () => Navigator.of(context).pop(),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Student Details',
                                style: TextStyle(
                                  color: Color(0xFFE6F7F4),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            _CircleButton(icon: Icons.more_horiz_rounded, onTap: () {}),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _sectionCard(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              _buildAvatarWidget(
                                _student['photoBase64']?.toString(),
                                name,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        color: Color(0xFFE6F7F4),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      phone,
                                      style: const TextStyle(
                                        color: Color(0xFF9FB9B3),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      batch,
                                      style: const TextStyle(
                                        color: Color(0xFFDFF7F0),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _pill(
                                label: isPaid ? 'Active' : 'Pending',
                                textColor: isPaid
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFF59E0B),
                                bgColor: isPaid
                                    ? const Color(0x3316A34A)
                                    : const Color(0x33F59E0B),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 2.1,
                          children: <Widget>[
                            _statTile('Attendance', attendancePercent),
                            _statTile('Present', '$presentDays Days'),
                            _statTile('Pending Fee', 'Rs $pendingFee'),
                            _statTile(
                              'Joined On',
                              _fmtDate(_student['joinDate']?.toString()),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Attendance Timeline',
                          style: TextStyle(
                            color: Color(0xFFE6F7F4),
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _sectionCard(
                          child: Column(
                            children: <Widget>[
                              ..._attendance.take(3).map((Map<String, dynamic> item) {
                                final String st = _status(item);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _attendanceRow(
                                    _fmtDate(item['date']?.toString()),
                                    st == 'present',
                                  ),
                                );
                              }),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => AcademyViewAllAttendanceScreen(
                                          studentId: widget.studentId,
                                          studentName: name,
                                        ),
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFE6F7F4),
                                    side: const BorderSide(color: Color(0x33FFFFFF)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: const Text('View All Attendance'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Fee Details',
                          style: TextStyle(
                            color: Color(0xFFE6F7F4),
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _sectionCard(
                          child: Column(
                            children: <Widget>[
                              _keyValue('Total Fee', 'Rs $totalFee', bold: true),
                              const SizedBox(height: 10),
                              _keyValue(
                                'Paid',
                                'Rs $paidFee',
                                valueColor: const Color(0xFF16A34A),
                              ),
                              const SizedBox(height: 8),
                              _keyValue(
                                'Pending',
                                'Rs $pendingFee',
                                valueColor: pendingFee == 0
                                    ? const Color(0xFF9FB9B3)
                                    : const Color(0xFFF59E0B),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F2027),
                      border: Border(top: BorderSide(color: Color(0x1AFFFFFF))),
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: _isSendingReminder ? null : _sendReminder,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFDFF7F0),
                                side: const BorderSide(color: Color(0x1FFFFFFF)),
                              ),
                              child: _isSendingReminder
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Send Reminder'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () async {
                                final bool? updated = await Navigator.of(context)
                                    .push<bool>(
                                  MaterialPageRoute<bool>(
                                    builder: (_) => AcademyEditStudentScreen(
                                      studentId: widget.studentId,
                                      studentName: name,
                                      batchName: batch,
                                      feeStatus: pendingFee == 0 ? 'Paid' : 'Pending',
                                      phoneNumber: phone,
                                      feesAmount: '$totalFee',
                                      joiningDate: _fmtDate(
                                        _student['joinDate']?.toString(),
                                      ),
                                      paymentMode: _fees.isNotEmpty
                                          ? _fees.first['paymentMode']?.toString() ?? 'UPI'
                                          : 'UPI',
                                    ),
                                  ),
                                );
                                if (updated == true && mounted) {
                                  await _load();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00C9A7),
                                foregroundColor: const Color(0xFF052017),
                              ),
                              child: const Text('Edit Student'),
                            ),
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

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x0FFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: child,
    );
  }

  Widget _statTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x0FFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF9FB9B3),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFE6F7F4),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _attendanceRow(String dateText, bool present) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          dateText,
          style: const TextStyle(
            color: Color(0xFFE6F7F4),
            fontWeight: FontWeight.w600,
          ),
        ),
        _pill(
          label: present ? 'Present' : 'Absent',
          textColor:
              present ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
          bgColor: present ? const Color(0x3316A34A) : const Color(0x33EF4444),
        ),
      ],
    );
  }

  Widget _pill({
    required String label,
    required Color textColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _keyValue(
    String label,
    String value, {
    bool bold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(color: Color(0xFFE6F7F4), fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? const Color(0xFFE6F7F4),
            fontSize: 14,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _initials(String fullName) {
    final List<String> parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return 'ST';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length > 1 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Widget _buildAvatarWidget(String? photoBase64, String name) {
    final Uint8List? bytes = decodeBase64ImageBytes(photoBase64);
    return Container(
      width: 66,
      height: 66,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0x1AFFFFFF),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      clipBehavior: Clip.antiAlias,
      child: bytes != null
          ? Image.memory(bytes, fit: BoxFit.cover)
          : Container(
              alignment: Alignment.center,
              child: Text(
                _initials(name),
                style: const TextStyle(
                  color: Color(0xFFE6F7F4),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0x0FFFFFFF),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x1FFFFFFF)),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: const Color(0xFFE6F7F4)),
      ),
    );
  }
}
